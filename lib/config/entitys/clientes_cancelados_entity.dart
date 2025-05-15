
class ClientesCanceladosEntity {
    final String cedulaPersona;
    final String nombre;
    final String telefono;
    final String direccion;
    final String apellido;
    final DateTime fechaPrestamo;
    final DateTime fechaFinalizo;
    final String idPrestamo;
    final String valorCuota;
    final String tipoPrestamo;
    final String cantidadPrestamo;
    final String totalAbonos;
    final DateTime ultimoAbono;
    final String cantidadCuotas;

    ClientesCanceladosEntity({
        required this.cedulaPersona,
        required this.nombre,
        required this.telefono,
        required this.direccion,
        required this.apellido,
        required this.fechaPrestamo,
        required this.fechaFinalizo,
        required this.idPrestamo,
        required this.valorCuota,
        required this.tipoPrestamo,
        required this.cantidadPrestamo,
        required this.totalAbonos,
        required this.ultimoAbono,
        required this.cantidadCuotas,
    });

    factory ClientesCanceladosEntity.fromJson(Map<String, dynamic> json) => ClientesCanceladosEntity(
        cedulaPersona: json["cedulaPersona"],
        nombre: json["nombre"],
        telefono: json["telefono"],
        direccion: json["direccion"],
        apellido: json["apellido"],
        fechaPrestamo: DateTime.parse(json["fechaPrestamo"]),
        fechaFinalizo: DateTime.parse(json["fechaFinalizo"]),
        idPrestamo: json["idPrestamo"],
        valorCuota: json["valorCuota"],
        tipoPrestamo: json["tipoPrestamo"],
        cantidadPrestamo: json["cantidadPrestamo"],
        totalAbonos: json["total_abonos"],
        ultimoAbono: DateTime.parse(json["ultimo_abono"]),
        cantidadCuotas: json["cantidad_cuotas"],
    );

    Map<String, dynamic> toJson() => {
        "cedulaPersona": cedulaPersona,
        "nombre": nombre,
        "telefono": telefono,
        "direccion": direccion,
        "apellido": apellido,
        "fechaPrestamo": "${fechaPrestamo.year.toString().padLeft(4, '0')}-${fechaPrestamo.month.toString().padLeft(2, '0')}-${fechaPrestamo.day.toString().padLeft(2, '0')}",
        "idPrestamo": idPrestamo,
        "valorCuota": valorCuota,
        "tipoPrestamo": tipoPrestamo,
        "cantidadPrestamo": cantidadPrestamo,
        "total_abonos": totalAbonos,
        "ultimo_abono": "${ultimoAbono.year.toString().padLeft(4, '0')}-${ultimoAbono.month.toString().padLeft(2, '0')}-${ultimoAbono.day.toString().padLeft(2, '0')}",
        "cantidad_cuotas": cantidadCuotas,
    };
}
