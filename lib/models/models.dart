class Plan {
  final String id;
  final String nombre;
  final int velocidadBajada;
  final int velocidadSubida;
  final double precioMensual;

  Plan({
    required this.id,
    required this.nombre,
    required this.velocidadBajada,
    required this.velocidadSubida,
    required this.precioMensual,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'],
        nombre: json['nombre'],
        velocidadBajada: json['velocidadBajada'],
        velocidadSubida: json['velocidadSubida'],
        precioMensual: double.parse(json['precioMensual'].toString()),
      );
}

class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String estadoServicio;
  final Plan? plan;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.estadoServicio,
    this.plan,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'],
        nombre: json['nombre'],
        apellido: json['apellido'],
        email: json['email'],
        telefono: json['telefono'],
        estadoServicio: json['estadoServicio'] ?? 'ACTIVO',
        plan: json['plan'] != null ? Plan.fromJson(json['plan']) : null,
      );
}

class MetricaSenal {
  final DateTime timestamp;
  final double? potenciaOpticaRx;
  final bool estadoConexion;
  final int? uptime;
  final double? velocidadBajadaActual;
  final double? velocidadSubidaActual;
  final double? latenciaMs;
  final String? calidad;

  MetricaSenal({
    required this.timestamp,
    this.potenciaOpticaRx,
    required this.estadoConexion,
    this.uptime,
    this.velocidadBajadaActual,
    this.velocidadSubidaActual,
    this.latenciaMs,
    this.calidad,
  });

  factory MetricaSenal.fromJson(Map<String, dynamic> json) => MetricaSenal(
        timestamp: DateTime.parse(json['timestamp']),
        potenciaOpticaRx: json['potenciaOpticaRx'] != null
            ? double.parse(json['potenciaOpticaRx'].toString())
            : null,
        estadoConexion: json['estadoConexion'] ?? false,
        uptime: json['uptime'],
        velocidadBajadaActual: json['velocidadBajadaActual'] != null
            ? double.parse(json['velocidadBajadaActual'].toString())
            : null,
        velocidadSubidaActual: json['velocidadSubidaActual'] != null
            ? double.parse(json['velocidadSubidaActual'].toString())
            : null,
        latenciaMs: json['latenciaMs'] != null
            ? double.parse(json['latenciaMs'].toString())
            : null,
        calidad: json['calidad'],
      );
}

class Pago {
  final String id;
  final double monto;
  final String estado;
  final String periodoFacturado;
  final DateTime fechaCreacion;
  final DateTime? fechaPago;

  Pago({
    required this.id,
    required this.monto,
    required this.estado,
    required this.periodoFacturado,
    required this.fechaCreacion,
    this.fechaPago,
  });

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        id: json['id'],
        monto: double.parse(json['monto'].toString()),
        estado: json['estado'],
        periodoFacturado: json['periodoFacturado'],
        fechaCreacion: DateTime.parse(json['fechaCreacion']),
        fechaPago: json['fechaPago'] != null ? DateTime.parse(json['fechaPago']) : null,
      );
}
