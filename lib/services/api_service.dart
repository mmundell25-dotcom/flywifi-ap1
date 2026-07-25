import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

/// Cambiar por la URL real del backend en producción.
const String kBaseUrl = 'https://api.flywifi.com.ar';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> _guardarToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> cerrarSesion() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> haySesionActiva() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  // --- Auth ---

  Future<Cliente> registro({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    required String planId,
    String? direccion,
  }) async {
    final res = await _dio.post('/api/auth/registro', data: {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'password': password,
      'planId': planId,
      if (direccion != null) 'direccion': direccion,
    });
    await _guardarToken(res.data['token']);
    return Cliente.fromJson(res.data['cliente']);
  }

  Future<Cliente> login({required String email, required String password}) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _guardarToken(res.data['token']);
    return Cliente.fromJson(res.data['cliente']);
  }

  // --- Planes ---

  Future<List<Plan>> obtenerPlanes() async {
    final res = await _dio.get('/api/clientes/planes');
    return (res.data as List).map((p) => Plan.fromJson(p)).toList();
  }

  // --- Cliente ---

  Future<Cliente> obtenerPerfil() async {
    final res = await _dio.get('/api/clientes/perfil');
    return Cliente.fromJson(res.data);
  }

  // --- Señal ---

  Future<MetricaSenal?> obtenerSenalActual() async {
    final res = await _dio.get('/api/senal/actual');
    if (res.data['disponible'] == false) return null;
    return MetricaSenal.fromJson(res.data);
  }

  Future<List<MetricaSenal>> obtenerHistorialSenal({int limite = 50}) async {
    final res = await _dio.get('/api/senal/historial', queryParameters: {'limite': limite});
    return (res.data as List).map((m) => MetricaSenal.fromJson(m)).toList();
  }

  // --- Pagos ---

  Future<String> crearPreferenciaPago() async {
    final res = await _dio.post('/api/pagos/crear-preferencia');
    return res.data['initPoint'] as String; // URL de checkout de Mercado Pago
  }

  Future<List<Pago>> obtenerHistorialPagos() async {
    final res = await _dio.get('/api/pagos/historial');
    return (res.data as List).map((p) => Pago.fromJson(p)).toList();
  }
}
