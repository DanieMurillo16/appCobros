import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/desing/coloresapp.dart';

class BotonFlotanteCierreCaja extends StatelessWidget {
  final String? rolSeleccionado;
  final String? nombreEmpleadoSeleccionado;
  final String fecha;
  final String cobro;
  final Map<String, dynamic> cajaDetalles;
  final Future<String>? futureCaja;
  final Function? onCajaCerrada;
  final bool puedeCerrarCaja;

  const BotonFlotanteCierreCaja({
    super.key,
    required this.rolSeleccionado,
    required this.nombreEmpleadoSeleccionado,
    required this.fecha,
    required this.cobro,
    required this.cajaDetalles,
    required this.futureCaja,
    this.onCajaCerrada,
    this.puedeCerrarCaja = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: ColoresApp.rojo,
      foregroundColor: Colors.white,
      tooltip: 'Cerrar caja',
      onPressed: () async {
        if (!puedeCerrarCaja) {
          SmartDialog.showToast('Seleccione un empleado y fecha primero');
          return;
        }

        // Capturar el context antes de la operación async
        final currentContext = context;

        final saldoCaja = await futureCaja; // Obtener saldo de caja

        // Verificar que el widget siga montado
        if (!currentContext.mounted) return; // Obtener saldo de caja

        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado
                  const Text(
                    'Cierre de Caja',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColoresApp.rojoLogo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Información del empleado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.verde.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: ColoresApp.verde),
                            const SizedBox(width: 8),
                            Text(
                              nombreEmpleadoSeleccionado ?? 'No seleccionado',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID Empleado: ${rolSeleccionado ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Fecha: $fecha',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resumen de caja
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.azulRey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Saldo de Caja',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColoresApp.azulRey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              FormatoMiles().formatearCantidad(saldoCaja!),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ColoresApp.azulRey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Entradas:'),
                            Text(
                              FormatoMiles().formatearCantidad(
                                cajaDetalles['totalEntradas'].toString(),
                              ),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Salidas:'),
                            Text(
                              FormatoMiles().formatearCantidad(
                                cajaDetalles['totalSalidas'].toString(),
                              ),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pregunta de confirmación
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresApp.rojo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '¿Está seguro que desea cerrar la caja?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColoresApp.rojo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final dialogContext = context;
                          // Mostrar loading mientras se procesa
                          SmartDialog.showLoading(msg: "Cerrando caja...");

                          try {
                            final data =
                                await Databaseservices().cerrarCajaCobrador(
                              rolSeleccionado!,
                              saldoCaja,
                              cobro,
                              descripcion: "Cierre automático de caja",
                            );

                            SmartDialog.dismiss();

                            // Verificar que el widget siga montado
                            if (!dialogContext.mounted) return;

                            if (data['success'] == true) {
                              SmartDialog.showToast(
                                "Caja cerrada con éxito",
                                displayTime: const Duration(seconds: 2),
                              );
                              Navigator.pop(dialogContext);
                              if (onCajaCerrada != null) {
                                onCajaCerrada!();
                              }
                            } else {
                              throw Exception(
                                  data['error'] ?? 'Error al insertar');
                            }
                          } catch (e) {
                            SmartDialog.dismiss();
                            // Verificar que el widget siga montado antes de mostrar toast
                            if (dialogContext.mounted) {
                              SmartDialog.showToast(
                                "Error: ${e.toString()}",
                                displayTime: const Duration(seconds: 2),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: ColoresApp.rojo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Confirmar Cierre',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: const Icon(Icons.lock),
    );
  }
}
