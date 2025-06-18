
class RedimientoEmpleadosEntity {
  final int empleadoId;
  final String perNombre;
  final String perApellido;
  final int cantidadPrestamos;
  final String dineroSeguro;
  final String dineroPrestado;
  final String dineroRecogidoAbonos;
  final String ingresos;
  final String salidas;
  final String gananciaPrestamo;
  final String rendimientoPrestamo;
  final String flujoNetoCaja;

  RedimientoEmpleadosEntity({
    required this.empleadoId,
    required this.perNombre,
    required this.perApellido,
    required this.cantidadPrestamos,
    required this.dineroSeguro,
    required this.dineroPrestado,
    required this.dineroRecogidoAbonos,
    required this.ingresos,
    required this.salidas,
    required this.gananciaPrestamo,
    required this.rendimientoPrestamo,
    required this.flujoNetoCaja,
  });

  factory RedimientoEmpleadosEntity.fromJson(Map<String, dynamic> json) => RedimientoEmpleadosEntity(
    empleadoId: json["EmpleadoId"],
    perNombre: json["per_nombre"],
    perApellido: json["per_apellido"],
    cantidadPrestamos: json["CantidadPrestamos"],
    dineroSeguro: json["DineroSeguro"],
    dineroPrestado: json["DineroPrestado"],
    dineroRecogidoAbonos: json["DineroRecogidoAbonos"],
    ingresos: json["Ingresos"],
    salidas: json["Salidas"],
    gananciaPrestamo: json["GananciaPrestamo"],
    rendimientoPrestamo: json["RendimientoPrestamo"],
    flujoNetoCaja: json["FlujoNetoCaja"],
  );

  Map<String, dynamic> toJson() => {
    "EmpleadoId": empleadoId,
    "per_nombre": perNombre,
    "per_apellido": perApellido,
    "CantidadPrestamos": cantidadPrestamos,
    "DineroSeguro": dineroSeguro,
    "DineroPrestado": dineroPrestado,
    "DineroRecogidoAbonos": dineroRecogidoAbonos,
    "Ingresos": ingresos,
    "Salidas": salidas,
    "GananciaPrestamo": gananciaPrestamo,
    "RendimientoPrestamo": rendimientoPrestamo,
    "FlujoNetoCaja": flujoNetoCaja,
  };
}
