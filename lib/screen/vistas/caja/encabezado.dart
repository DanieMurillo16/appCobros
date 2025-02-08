import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/screen/vistas/caja/car_movimientos.dart';
import 'package:flutter/material.dart';

class EncabezadoBody extends StatelessWidget {
  const EncabezadoBody({
    super.key,
    required Future<List<dynamic>> futureTotalMovimientos,
  }) : _futureTotalMovimientos = futureTotalMovimientos;

  final Future<List<dynamic>> _futureTotalMovimientos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: _futureTotalMovimientos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay movimientos'));
          } else {
            final totalCaja = snapshot.data![0] as String;
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Saldo actual:",
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FormatoNumero(
                  numero: totalCaja,
                  color: ColoresApp.negro,
                  fontSize: 35,
                  fontSize2: 12,
                ),
                const Divider(),
              ],
            );
          }
        },
      ),
    );
  }
}
