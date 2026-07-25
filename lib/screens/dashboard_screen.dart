import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'speedtest_screen.dart';
import 'pago_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Cliente? _cliente;
  MetricaSenal? _senal;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final cliente = await _api.obtenerPerfil();
      final senal = await _api.obtenerSenalActual();
      setState(() {
        _cliente = cliente;
        _senal = senal;
      });
    } catch (_) {
      // Si falla la autenticación, mandamos al login
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return AppColors.success;
      case 'SUSPENDIDO':
      case 'MOROSO':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return 'Servicio activo';
      case 'SUSPENDIDO':
        return 'Servicio suspendido';
      case 'MOROSO':
        return 'Pago pendiente';
      default:
        return 'Servicio dado de baja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente != null ? 'Hola, ${_cliente!.nombre}' : 'Fly WiFi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _api.cerrarSesion();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _EstadoServicioCard(
                    estado: _cliente?.estadoServicio ?? 'ACTIVO',
                    color: _colorEstado(_cliente?.estadoServicio ?? 'ACTIVO'),
                    texto: _textoEstado(_cliente?.estadoServicio ?? 'ACTIVO'),
                    plan: _cliente?.plan,
                  ),
                  const SizedBox(height: 16),
                  _SenalCard(senal: _senal),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AccionCard(
                          icono: Icons.speed,
                          titulo: 'Test de velocidad',
                          color: AppColors.cyan,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SpeedtestScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccionCard(
                          icono: Icons.payment,
                          titulo: 'Pagar factura',
                          color: AppColors.lime,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PagoScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _EstadoServicioCard extends StatelessWidget {
  final String estado;
  final Color color;
  final String texto;
  final Plan? plan;

  const _EstadoServicioCard({
    required this.estado,
    required this.color,
    required this.texto,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (plan != null)
                    Text(
                      'Plan ${plan!.nombre}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SenalCard extends StatelessWidget {
  final MetricaSenal? senal;

  const _SenalCard({this.senal});

  @override
  Widget build(BuildContext context) {
    if (senal == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Todavía no hay datos de señal disponibles',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado de la conexión', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metrica(
                  etiqueta: 'Señal óptica',
                  valor: senal!.potenciaOpticaRx != null
                      ? '${senal!.potenciaOpticaRx!.toStringAsFixed(1)} dBm'
                      : '—',
                  subvalor: senal!.calidad ?? '',
                ),
                _Metrica(
                  etiqueta: 'Bajada',
                  valor: senal!.velocidadBajadaActual != null
                      ? '${senal!.velocidadBajadaActual!.toStringAsFixed(0)} Mbps'
                      : '—',
                ),
                _Metrica(
                  etiqueta: 'Subida',
                  valor: senal!.velocidadSubidaActual != null
                      ? '${senal!.velocidadSubidaActual!.toStringAsFixed(0)} Mbps'
                      : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String subvalor;

  const _Metrica({required this.etiqueta, required this.valor, this.subvalor = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (subvalor.isNotEmpty)
          Text(subvalor, style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
      ],
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icono,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Icon(icono, color: color, size: 32),
              const SizedBox(height: 10),
              Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
