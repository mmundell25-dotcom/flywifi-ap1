import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const FlyWifiApp());
}

class FlyWifiApp extends StatelessWidget {
  const FlyWifiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fly WiFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _RaizApp(),
    );
  }
}

/// Decide si mostrar el login o ir directo al dashboard
/// dependiendo de si ya hay un token JWT guardado.
class _RaizApp extends StatefulWidget {
  const _RaizApp();

  @override
  State<_RaizApp> createState() => _RaizAppState();
}

class _RaizAppState extends State<_RaizApp> {
  final _api = ApiService();
  bool _cargando = true;
  bool _haySesion = false;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final activa = await _api.haySesionActiva();
    setState(() {
      _haySesion = activa;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _haySesion ? const DashboardScreen() : const LoginScreen();
  }
}
