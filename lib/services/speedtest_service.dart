import 'dart:async';
import 'package:http/http.dart' as http;

/// Cambiar por un endpoint propio (ideal: un servidor LibreSpeed self-hosted
/// en tu propia infraestructura de Fly WiFi, así medís tu red real y no
/// dependés de un tercero).
///
/// Necesitás:
///  - Un archivo grande estático (ej. 100MB) para medir descarga.
///  - Un endpoint que acepte POST y descarte el body, para medir subida.
class SpeedtestEndpoints {
  static const String downloadUrl = 'https://speedtest.flywifi.com.ar/download-test-100mb.bin';
  static const String uploadUrl = 'https://speedtest.flywifi.com.ar/upload-test';
  static const String pingHost = 'speedtest.flywifi.com.ar';
}

class SpeedtestResult {
  final double descargaMbps;
  final double subidaMbps;
  final double latenciaMs;
  final double jitterMs;

  SpeedtestResult({
    required this.descargaMbps,
    required this.subidaMbps,
    required this.latenciaMs,
    required this.jitterMs,
  });
}

/// Callback de progreso para actualizar la UI en tiempo real,
/// tipo la animación de fast.com.
typedef ProgresoCallback = void Function(double mbpsInstantaneo, String etapa);

class SpeedtestService {
  /// Mide latencia haciendo varios pings HTTP cortos (HEAD request)
  /// y calculando el promedio + jitter (variación entre mediciones).
  Future<Map<String, double>> _medirLatencia() async {
    final mediciones = <int>[];

    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      try {
        await http.head(Uri.parse('https://${SpeedtestEndpoints.pingHost}'));
      } catch (_) {
        continue;
      }
      sw.stop();
      mediciones.add(sw.elapsedMilliseconds);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mediciones.isEmpty) return {'latencia': 0, 'jitter': 0};

    final promedio = mediciones.reduce((a, b) => a + b) / mediciones.length;
    final jitter = mediciones.isEmpty
        ? 0.0
        : (mediciones.map((m) => (m - promedio).abs()).reduce((a, b) => a + b) /
            mediciones.length);

    return {'latencia': promedio, 'jitter': jitter};
  }

  /// Mide velocidad de descarga leyendo el stream de bytes y calculando
  /// Mbps en ventanas de tiempo cortas para dar feedback fluido a la UI.
  Future<double> _medirDescarga(ProgresoCallback? onProgreso) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(SpeedtestEndpoints.downloadUrl));
    final response = await client.send(request);

    int bytesEnVentana = 0;
    int bytesTotales = 0;
    final swTotal = Stopwatch()..start();
    var ultimoTick = 0;

    await for (final chunk in response.stream) {
      bytesEnVentana += chunk.length;
      bytesTotales += chunk.length;

      final tickActual = swTotal.elapsedMilliseconds ~/ 200; // ventanas de 200ms
      if (tickActual != ultimoTick) {
        final mbpsInstantaneo = (bytesEnVentana * 8) / (200 / 1000) / 1_000_000;
        onProgreso?.call(mbpsInstantaneo, 'descarga');
        bytesEnVentana = 0;
        ultimoTick = tickActual;
      }

      // Cortamos a los ~10 segundos, como fast.com
      if (swTotal.elapsedMilliseconds > 10000) break;
    }

    client.close();
    swTotal.stop();

    final segundosTotales = swTotal.elapsedMilliseconds / 1000;
    if (segundosTotales == 0) return 0;

    return (bytesTotales * 8) / segundosTotales / 1_000_000; // Mbps
  }

  /// Mide velocidad de subida enviando un buffer de datos generado en memoria.
  Future<double> _medirSubida(ProgresoCallback? onProgreso) async {
    final bufferSize = 5 * 1024 * 1024; // 5MB por iteración
    final buffer = List<int>.filled(bufferSize, 0);

    final sw = Stopwatch()..start();
    int totalEnviado = 0;
    int iteraciones = 0;

    while (sw.elapsedMilliseconds < 8000 && iteraciones < 5) {
      final swIter = Stopwatch()..start();
      try {
        await http.post(
          Uri.parse(SpeedtestEndpoints.uploadUrl),
          body: buffer,
          headers: {'Content-Type': 'application/octet-stream'},
        );
      } catch (_) {
        break;
      }
      swIter.stop();

      totalEnviado += bufferSize;
      iteraciones++;

      final mbpsInstantaneo =
          (bufferSize * 8) / (swIter.elapsedMilliseconds / 1000) / 1_000_000;
      onProgreso?.call(mbpsInstantaneo, 'subida');
    }

    sw.stop();
    final segundosTotales = sw.elapsedMilliseconds / 1000;
    if (segundosTotales == 0 || totalEnviado == 0) return 0;

    return (totalEnviado * 8) / segundosTotales / 1_000_000; // Mbps
  }

  Future<SpeedtestResult> ejecutarTest({ProgresoCallback? onProgreso}) async {
    onProgreso?.call(0, 'latencia');
    final latenciaData = await _medirLatencia();

    final descarga = await _medirDescarga(onProgreso);
    final subida = await _medirSubida(onProgreso);

    return SpeedtestResult(
      descargaMbps: descarga,
      subidaMbps: subida,
      latenciaMs: latenciaData['latencia'] ?? 0,
      jitterMs: latenciaData['jitter'] ?? 0,
    );
  }
}
