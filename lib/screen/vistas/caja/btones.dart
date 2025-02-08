import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:flutter/material.dart';

class Btones extends StatelessWidget {
  final VoidCallback onReportePressed;
  final VoidCallback onPrestamosPressed;
  final VoidCallback onMovimientosPressed;

  const Btones({
    super.key,
    required this.onReportePressed,
    required this.onPrestamosPressed,
    required this.onMovimientosPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 60, // Altura fija para los botones
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton("Reporte", onReportePressed),
                const SizedBox(width: 10),
                _buildButton("Prestamos", onPrestamosPressed),
                const SizedBox(width: 10),
                _buildButton("Movimientos", onMovimientosPressed),
                // Agrega más botones aquí si es necesario
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: ColoresApp.grisClarito,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: const TextStyle(color: ColoresApp.negro),
        ),
      ),
    );
  }
}