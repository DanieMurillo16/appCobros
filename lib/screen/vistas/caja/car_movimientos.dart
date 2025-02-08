import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:flutter/material.dart';

enum TipoMovimiento { ingreso, egreso }

class CardMovimientos extends StatelessWidget {
  final TipoMovimiento tipoMovimiento;
  final String total;
  const CardMovimientos(
      {super.key, required this.tipoMovimiento, required this.total});

  @override
  Widget build(BuildContext context) {
    var ingreso = const Icon(
      Icons.arrow_upward,
      color: ColoresApp.verde,
    );
    var egreso = const Icon(
      Icons.arrow_downward,
      color: ColoresApp.rojo,
    );
    return Container(
      margin: const EdgeInsets.all(5),
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: tipoMovimiento == TipoMovimiento.ingreso
            ? ColoresApp.verde
            : ColoresApp.rojo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: ColoresApp.blanco,
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: tipoMovimiento == TipoMovimiento.ingreso ? ingreso : egreso,
          ),
          Expanded(
            flex: 2,
            child: Text(
              tipoMovimiento == TipoMovimiento.ingreso ? 'Ingresos' : 'Gastos',
              style: const TextStyle(
                color: ColoresApp.blanco,
                fontSize: 20,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FormatoNumero(numero: total),
                const Text(
                  '12/12/2021',
                  style: TextStyle(
                    color: ColoresApp.blanco,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColoresApp.blanco, width: 1)),
              child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.chevron_right_outlined,
                    color: ColoresApp.blanco,
                  ))),
        ],
      ),
    );
  }
}

class FormatoNumero extends StatelessWidget {
  final String numero;
  final Color? color;
  final double? fontSize, fontSize2;
  const FormatoNumero(
      {super.key,
      required this.numero,
      this.color,
      this.fontSize,
      this.fontSize2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 3, right: 5),
          child: Text("\$",
              style: TextStyle(
                color: color ?? ColoresApp.blanco,
                fontSize: fontSize2 ?? 12,
              )),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: FormatoMiles().formatearCantidad(numero),
                style: TextStyle(
                  color: color ?? ColoresApp.blanco,
                  fontSize: fontSize ?? 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}