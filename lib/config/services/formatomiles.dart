import 'package:intl/intl.dart';

class FormatoMiles {

  String formatearCantidad(String cantidad) {
    double value = double.tryParse(cantidad) ?? 0.0;
    final formatter = NumberFormat('#,###', 'es_CO');
    return formatter.format(value);
  }


}

