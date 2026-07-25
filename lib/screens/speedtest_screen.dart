import 'package:flutter/material.dart';
import '../services/speedtest_service.dart';
import '../theme/app_theme.dart';

class SpeedtestScreen extends StatefulWidget {
  const SpeedtestScreen({super.key});

  @override
  State<SpeedtestScreen> createState() => _SpeedtestScreenState();
}

class _SpeedtestScreenState extends State<SpeedtestScreen> {
  final _service = SpeedtestService();

  bool _corriendo = false;
  double _mbpsActual = 0;
  String _etapa = '';
  SpeedtestResult? _resultado;

  Future<void> _correrTest() async {
    setState(() {
      _corriendo = true;
      _resultado = null;
      _mbpsActual = 0;
    });

    final resultado = await _service.ejecutarTest(
      onProgreso: (mbps, etapa) {
        if (!mounted) return;
        setState(() {
          _mbpsActual = mbps;
          _etapa = etapa;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _resultado = resultado;
      _corriendo = false;
    });
  }

  String _etapaLabel(String etapa) {
    switch (etapa) {
      case 'latencia':
        return 'Midiendo latencia...';
      case 'descarga':
        return 'Midiendo descarga...';
      case 'subida':
        return 'Midiendo subida...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test de velocidad')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_corriendo)
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: AppColors.cyan,
                          value: null,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _corriendo
                              ? _mbpsActual.toStringAsFixed(0)
                              : (_resultado?.descargaMbps.toStringAsFixed(0) ?? '—'),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                        const Text('Mbps', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_corriendo)
                Text(_etapaLabel(_etapa), style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              if (_resultado != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultadoChip(
                      etiqueta: 'Subida',
                      valor: '${_resultado!.subidaMbps.toStringAsFixed(0)} Mbps',
                    ),
                    _ResultadoChip(
                      etiqueta: 'Latencia',
                      valor: '${_resultado!.latenciaMs.toStringAsFixed(0)} ms',
                    ),
                    _ResultadoChip(
                      etiqueta: 'Jitter',
                      valor: '${_resultado!.jitterMs.toStringAsFixed(0)} ms',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _corriendo ? null : _correrTest,
                  child: Text(_resultado == null ? 'Iniciar test' : 'Repetir test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultadoChip extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _ResultadoChip({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(etiqueta, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
