import 'dart:convert';

import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:flutter/material.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class DialogoModificarPrestamoScreen extends StatefulWidget {
  final String idPrestamo;
  final String montoActual;
  final String valorCuotas;
  final String cantidadCuotas;
  final VoidCallback? onSuccess; // Callback para refrescar la pantalla padre

  const DialogoModificarPrestamoScreen({
    super.key,
    required this.idPrestamo,
    required this.montoActual,
    required this.valorCuotas,
    required this.cantidadCuotas,
    this.onSuccess,
  });

  @override
  State<DialogoModificarPrestamoScreen> createState() =>
      _DialogoModificarPrestamoScreenState();
}

class _DialogoModificarPrestamoScreenState
    extends State<DialogoModificarPrestamoScreen> {
  late TextEditingController montoBaseController;
  late TextEditingController cantidadCuotasController;
  bool isFormattingMontoBase = false;
  bool isFormattingCantidad = false;
  bool isLoading = false;

  // Variables calculadas automáticamente
  double montoConInteres = 0.0;
  double valorCuotaCalculado = 0.0;

  @override
  void initState() {
    super.initState();

    // Calcular el monto base original (quitando el 20% de interés)
    double montoActualDouble = double.tryParse(widget.montoActual.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    double montoBaseOriginal = montoActualDouble / 1.2; // Quitar el 20%

    // Inicializar los controladores
    montoBaseController = TextEditingController(
        text: FormatoMiles().formatearCantidad(montoBaseOriginal.toString()));
    cantidadCuotasController = TextEditingController(
        text: FormatoMiles().formatearCantidad(widget.cantidadCuotas));

    // Agregar listeners para cálculo automático
    montoBaseController.addListener(_onMontoBaseChanged);
    cantidadCuotasController.addListener(_onCantidadChanged);

    // Calcular valores iniciales
    _calcularValores();
  }

  @override
  void dispose() {
    montoBaseController.dispose();
    cantidadCuotasController.dispose();
    super.dispose();
  }

  void _onMontoBaseChanged() {
    if (isFormattingMontoBase) return;
    _formatearCampo(montoBaseController, () => isFormattingMontoBase = true,
            () => isFormattingMontoBase = false);
    _calcularValores();
  }

  void _onCantidadChanged() {
    if (isFormattingCantidad) return;
    _formatearCampo(cantidadCuotasController, () => isFormattingCantidad = true,
            () => isFormattingCantidad = false);
    _calcularValores();
  }

  void _formatearCampo(TextEditingController controller,
      VoidCallback setFormatting, VoidCallback resetFormatting) {
    String text = controller.text;
    // Eliminar cualquier carácter que no sea dígito
    String cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedText.isEmpty) return;

    // Parsear el texto limpio a un número
    double value = double.tryParse(cleanedText) ?? 0.0;

    // Formatear el número como pesos colombianos
    final formatter = NumberFormat('#,###', 'es_CO');
    String formatted = formatter.format(value);

    // Actualizar el controlador si el texto formateado cambió
    if (formatted != text) {
      setFormatting();
      controller.text = formatted;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      resetFormatting();
    }
  }

  void _calcularValores() {
    String montoBaseLimpio = _limpiarTexto(montoBaseController.text);
    String cantidadLimpio = _limpiarTexto(cantidadCuotasController.text);

    double montoBase = double.tryParse(montoBaseLimpio) ?? 0;
    int cantidadCuotas = int.tryParse(cantidadLimpio) ?? 1;

    setState(() {
      // Calcular monto con 20% de interés
      montoConInteres = montoBase * 1.2;

      // Calcular valor de cada cuota
      if (cantidadCuotas > 0) {
        valorCuotaCalculado = montoConInteres / cantidadCuotas;
      } else {
        valorCuotaCalculado = 0;
      }
    });
  }

  String _limpiarTexto(String texto) {
    return texto.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> _actualizarPrestamo() async {
    // Prevenir múltiples clicks
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Limpiar y validar campos
    String montoBaseLimpio = _limpiarTexto(montoBaseController.text.trim());
    String cantidadLimpio = _limpiarTexto(cantidadCuotasController.text.trim());

    // Validar que los campos no estén vacíos
    if (montoBaseLimpio.isEmpty || cantidadLimpio.isEmpty) {
      SmartDialog.showToast('Por favor, complete todos los campos.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Validar que sean números válidos
    final montoBase = double.tryParse(montoBaseLimpio);
    final cantidadCuotas = int.tryParse(cantidadLimpio);

    if (montoBase == null || montoBase <= 0) {
      SmartDialog.showToast('El monto base debe ser un número válido mayor a 0.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (cantidadCuotas == null || cantidadCuotas <= 0) {
      SmartDialog.showToast(
          'La cantidad de cuotas debe ser un número válido mayor a 0.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Enviar el monto con interés y el valor de cuota calculado
      String montoConInteresStr = montoConInteres.toInt().toString();
      String valorCuotaStr = valorCuotaCalculado.toInt().toString();

      var url = Uri.parse(ApiConstants.actualizarDatosPrestamo);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'idpe': widget.idPrestamo,
          'cantidad': montoBaseLimpio, // Monto con 20% de interés
          'cantidadConInteres': montoConInteresStr, // Monto con 20% de interés
          'cuotas': cantidadCuotas.toString(),    // Cantidad de cuotas
          'valor': valorCuotaStr,      // Valor calculado de cada cuota
        },
      );

      if (response.statusCode == 200) {
        final respuesta = jsonDecode(response.body);
        if (respuesta['success'] == true) {
          SmartDialog.showToast('Préstamo modificado exitosamente');

          // Llamar al callback antes de cerrar el diálogo
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }

          // Pequeño delay para que el usuario vea el mensaje de éxito
          await Future.delayed(const Duration(milliseconds: 500));

          // Cerrar el diálogo con resultado exitoso
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          SmartDialog.showToast(
              respuesta['message'] ?? 'Error al modificar el préstamo');
        }
      } else {
        SmartDialog.showToast('Error de conexión: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al actualizar préstamo: $e');
      SmartDialog.showToast(
          'Error al modificar el préstamo. Intente nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'es_CO');

    return AlertDialog(
      backgroundColor: ColoresApp.blanco,
      title: const Text(
        'Modificar Préstamo',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColoresApp.negro,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Información actual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Valores Actuales:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ColoresApp.negro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monto: \$${FormatoMiles().formatearCantidad(widget.montoActual)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Número Cuotas: ${FormatoMiles().formatearCantidad(widget.cantidadCuotas)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Valor Cuotas: \$${FormatoMiles().formatearCantidad(widget.valorCuotas)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campos de entrada
              const Text(
                'Ingrese los nuevos valores:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ColoresApp.negro,
                ),
              ),
              const SizedBox(height: 12),

              // Campo Monto Base
              TextField(
                controller: montoBaseController,
                keyboardType: TextInputType.number,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Monto Base (sin interés)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Campo Cantidad de Cuotas
              TextField(
                controller: cantidadCuotasController,
                keyboardType: TextInputType.number,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Número de Cuotas',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Valores calculados automáticamente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Nuevos valores calculados:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ColoresApp.negro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monto (20%): \$${formatter.format(montoConInteres.toInt())}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Valor por cuota: \$${formatter.format(valorCuotaCalculado.toInt())}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botones lado a lado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: ColoresApp.rojo),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : _actualizarPrestamo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColoresApp.verde,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}