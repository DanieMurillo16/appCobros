List<DateTime> generarFechasDePago({
  required DateTime fechaInicial,
  required int numeroCuotas,
  required String tipoPago, // diario, semanal, mensual
}) {
  List<DateTime> fechasPago = [];
  DateTime fecha = fechaInicial;

  for (int i = 0; i < numeroCuotas; i++) {
    // Incrementar la fecha según el tipo de pago
    if (tipoPago == 'diario') {
      fecha = fecha.add(const Duration(days: 1));
    } else if (tipoPago == 'semanal') {
      fecha = fecha.add(const Duration(days: 7));
    } else if (tipoPago == 'mensual') {
      fecha = DateTime(fecha.year, fecha.month + 1, fecha.day);
    }

    // Excluir domingos
    if (fecha.weekday != DateTime.sunday) {
      fechasPago.add(fecha);
    } else {
      // Si cae en domingo, saltar al próximo día hábil
      fecha = fecha.add(const Duration(days: 1));
      fechasPago.add(fecha);
    }
  }

  return fechasPago;
}
