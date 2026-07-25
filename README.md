# Fly WiFi — App de Clientes

App completa para que los clientes de Fly WiFi se registren, paguen su factura
con tarjeta (Mercado Pago), vean el estado de su conexión (señal, niveles
ópticos), y midan la velocidad de su internet estilo fast.com.

## Estructura del proyecto

```
flywifi-app/
├── backend/          → API REST (Node.js + Express + Prisma + PostgreSQL)
├── mobile-app/        → App Android/iOS (Flutter)
├── signal-service/    → Poller Python que consulta MikroTik + OLT
└── docker-compose.yml → Postgres local para desarrollo
```

## Cómo encajan las piezas

```
Cliente (app Flutter)
        │
        ▼
  Backend API  ──────► Mercado Pago (cobro de factura mensual)
        ▲
        │  reporta métricas cada X minutos
        │
  signal-service (Python) ──► MikroTik (sesiones PPPoE, tráfico)
                          └──► OLT (potencia óptica vía SNMP)
```

El **signal-service** es un proceso separado que corre en tu servidor/PC
de la oficina de Fly WiFi (donde tenga red hacia el MikroTik y la OLT),
y le manda los datos al backend por HTTPS. El backend nunca habla
directo con tus equipos de red — así separás la seguridad de tu
infraestructura interna de la API pública que usan los clientes.

---

## 1. Backend

### Requisitos
- Node.js 18+
- PostgreSQL (usá el `docker-compose.yml` de la raíz para levantarlo rápido)

### Pasos

```bash
cd backend
cp .env.example .env
# Editá .env con tus credenciales reales (DB, JWT_SECRET, Mercado Pago, SERVICE_API_KEY)

npm install
npx prisma migrate dev --name init   # crea las tablas
npx prisma db seed                   # carga los 4 planes (Básico, Plus, Full, Gamer)

npm run dev
```

La API queda en `http://localhost:3000`. Podés probar que está viva con:
```bash
curl http://localhost:3000/health
```

### Endpoints principales

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/registro` | Alta de cliente nuevo |
| POST | `/api/auth/login` | Login, devuelve JWT |
| GET | `/api/clientes/planes` | Lista de planes disponibles (público) |
| GET | `/api/clientes/perfil` | Datos del cliente autenticado |
| GET | `/api/clientes/estado-servicio` | Estado (activo/suspendido) + última métrica |
| GET | `/api/senal/actual` | Última métrica de señal |
| GET | `/api/senal/historial` | Histórico de métricas (para graficar) |
| POST | `/api/pagos/crear-preferencia` | Genera el link de pago de Mercado Pago |
| POST | `/api/pagos/webhook` | Recibido por Mercado Pago, no lo llama el cliente |
| GET | `/api/pagos/historial` | Historial de pagos del cliente |
| POST | `/api/ingest/metrica` | Usado por el signal-service (requiere `x-service-key`) |

### Deploy

Para producción, cualquier VPS chico alcanza (DigitalOcean, Hetzner, Railway,
Render). Necesitás:
1. Postgres administrado o en el mismo VPS.
2. Variables de entorno reales cargadas.
3. Dominio con HTTPS (Mercado Pago exige `notification_url` con HTTPS).
4. Correr `npx prisma migrate deploy` en vez de `migrate dev`.

---

## 2. Mobile App (Flutter)

### Requisitos
- Flutter SDK 3.3+
- Un dispositivo Android o emulador

### Pasos

```bash
cd mobile-app
flutter pub get
```

Antes de correr, editá `lib/services/api_service.dart` y cambiá:
```dart
const String kBaseUrl = 'https://api.flywifi.com.ar';
```
por la URL real de tu backend (o `http://10.0.2.2:3000` si estás probando
contra el backend local desde el emulador Android).

```bash
flutter run
```

### Pantallas incluidas
- **Login / Registro** con selección de plan
- **Dashboard**: estado del servicio, señal óptica, velocidad en tiempo real
- **Test de velocidad**: descarga, subida, latencia y jitter, con animación en vivo
- **Pago**: WebView con el checkout de Mercado Pago

### Sobre el test de velocidad

El servicio (`lib/services/speedtest_service.dart`) está armado para pegarle
a un servidor propio (`speedtest.flywifi.com.ar`). Necesitás:
1. Un archivo estático grande (ej. 100MB) en algún servidor tuyo para medir descarga.
2. Un endpoint que reciba POST y descarte el body, para medir subida.

La alternativa más simple es instalar **LibreSpeed** (open source, self-hosted)
en tu VPS — con eso tenés los dos endpoints resueltos de una, y de paso medís
tu red real en vez de depender de un tercero.

### Sobre pagos con Mercado Pago

La app abre el `init_point` que devuelve el backend en un WebView. El backend
detecta la vuelta exitosa por la `back_url` configurada, y el estado real del
pago se confirma vía **webhook** (no confiar nunca en la redirección del
navegador sola, porque se puede manipular — por eso el webhook es la fuente
de verdad).

---

## 3. Signal Service (Python)

Este es el componente que le da vida real a los datos que ve el cliente
en la app. Corre como un proceso continuo (o cron) en tu red interna.

### Requisitos
- Python 3.10+
- Acceso de red al MikroTik (puerto API 8728) y a la OLT (puerto SNMP 161)

### Pasos

```bash
cd signal-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Editá con las IPs/credenciales reales de tu MikroTik y OLT

python src/main.py
```

### ⚠️ Lo que falta completar antes de producción

El archivo `src/olt_client.py` tiene **OIDs de SNMP placeholder**. La
potencia óptica de las ONUs es específica de cada fabricante (VSOL vs
TP-Link tienen MIBs distintas). Pasos para completarlo:

1. Pedile a soporte de VSOL / TP-Link la MIB oficial de tu modelo de OLT
   (V1600 / P1201-08).
2. Cargala en un MIB Browser (ej. iReasoning, gratuito) y hacé un SNMP WALK
   sobre la OLT para encontrar los OIDs reales de potencia RX/TX por ONU.
3. Reemplazá los `OID_POTENCIA_RX_BASE` / `OID_POTENCIA_TX_BASE` en
   `olt_client.py` con los valores reales.
4. Definí cómo vas a mapear "usuario PPPoE" ↔ "índice de ONU en la OLT" —
   esto depende de cómo aprovisionás altas hoy. Si tenés esa tabla en algún
   lado (Excel, sistema propio), lo más simple es cargarla como diccionario
   o tabla auxiliar en el servicio.

La parte de **MikroTik ya está funcional** (sesiones PPPoE activas, uptime,
tráfico si tenés Simple Queues por cliente) — no necesita ajustes, solo
tus credenciales reales.

### Cómo el servicio identifica al cliente

Para que el signal-service pueda asociar una métrica a un cliente, la base
de datos necesita el campo `pppoeUsername` (o `onuSerial`) cargado en cada
`Cliente`. Hoy el registro desde la app no pide ese dato — es información
que vos como administrador del ISP le asignás al aprovisionar el servicio
físico. Convendría agregar un panel de administración simple (o hacerlo
directo en Prisma Studio: `npx prisma studio`) para completar ese campo
cuando instalás a cada cliente nuevo.

---

## Próximos pasos sugeridos

1. **Levantar el backend y probar los endpoints** con Postman/curl antes de tocar la app.
2. **Completar los OIDs reales de la OLT** (es lo único con incertidumbre real).
3. **Armar el panel de administración** para vincular clientes con su PPPoE/ONU
   (hoy no existe — se completa manual en la DB por ahora).
4. **Conseguir las credenciales de Mercado Pago** (modo test primero, después producción).
5. **Levantar LibreSpeed** en tu VPS para el test de velocidad.
6. **Generar el ícono y splash screen** de la app con tu branding de Fly WiFi.
