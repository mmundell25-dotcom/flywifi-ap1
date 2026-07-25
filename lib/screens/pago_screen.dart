import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PagoScreen extends StatefulWidget {
  const PagoScreen({super.key});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _api = ApiService();
  String? _initPoint;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciarPago();
  }

  Future<void> _iniciarPago() async {
    try {
      final url = await _api.crearPreferenciaPago();
      setState(() {
        _initPoint = url;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo iniciar el pago. Puede que ya tengas la factura del mes pagada.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar factura')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                )
              : _CheckoutWebView(
                  url: _initPoint!,
                  onPagoCompletado: () => Navigator.of(context).pop(true),
                ),
    );
  }
}

class _CheckoutWebView extends StatefulWidget {
  final String url;
  final VoidCallback onPagoCompletado;

  const _CheckoutWebView({required this.url, required this.onPagoCompletado});

  @override
  State<_CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<_CheckoutWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Detectamos la vuelta a nuestras back_urls definidas en el backend
            if (request.url.contains('/pago-exitoso')) {
              widget.onPagoCompletado();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
