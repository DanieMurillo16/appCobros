// ignore_for_file: unused_field

import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/screen/vistas/caja/btones.dart';
import 'package:cobrosapp/screen/vistas/caja/encabezado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';

import '../../../desing/textosapp.dart';
import '../../widgets/appbar.dart';
import '../../widgets/drawemenu.dart';

// ignore: must_be_immutable
class VerCajaEmpleado2 extends StatefulWidget {
  const VerCajaEmpleado2({super.key});

  @override
  State<VerCajaEmpleado2> createState() => _VerCajaEmpleado2State();
}

class _VerCajaEmpleado2State extends State<VerCajaEmpleado2> {
  late Future<String> _futureTotalMovimientos;

  final _pref = PreferenciasUsuario();
  final _formKey = GlobalKey<FormBuilderState>();
  late Future<List<dynamic>> _futureDatos;
  late Future<List<Map<String, dynamic>>> _futureMovimientos,
      _futureReporteAbonosClientes;

  bool mostrarReporte = false;

  @override
  void initState() {
    super.initState();
    _futureDatos = obtenerDatos();
    _futureMovimientos = Databaseservices().listaMovimientoscaja2(
        _pref.idUser, Databaseservices().obtenerFechaActual());
    _futureReporteAbonosClientes = Databaseservices()
        .consultarListadoReporteAbonosClientes(
            _pref.idUser, Databaseservices().obtenerFechaActual());
  }

  Future<List<dynamic>> obtenerDatos() async {
    try {
      final totalCaja = Databaseservices()
          .totalCajaDia(_pref.idUser, Databaseservices().obtenerFechaActual());
      final totalIngresos = Databaseservices().sumaMovimientosCajaIngresos(
          _pref.idUser, Databaseservices().obtenerFechaActual(), "1");
      final totalEgresos = Databaseservices().sumaMovimientosCajaIngresos(
          _pref.idUser, Databaseservices().obtenerFechaActual(), "2");

      return await Future.wait([totalCaja, totalIngresos, totalEgresos]);
    } catch (e) {
      debugPrint('Error: $e');
      return ['0', '0', '0'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo100),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloCaja),
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          EncabezadoBody(futureTotalMovimientos: _futureDatos),
          Btones(
            onReportePressed: () {
              setState(() {
                mostrarReporte = true;
              });
            },
            onPrestamosPressed: () {
              setState(() {
                mostrarReporte = false;
              });
            },
            onMovimientosPressed: () {
              setState(() {
                mostrarReporte = false;
              });
            },
          ),
          Expanded(
            child: mostrarReporte ? reporteAbonosClientes() : movimientos(),
          ),
        ],
      ),
    );
  }

  Widget reporteAbonosClientes() {
    return Expanded(
      flex: 7,
      child: Card(
        color: ColoresApp.blanco,
        margin: const EdgeInsets.all(5),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Reporte",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureReporteAbonosClientes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No hay datos disponibles'),
                      );
                    } else {
                      final abonos = snapshot.data!;
                      int totalClientes = abonos.length;
                      int clientesAbonaron = abonos
                          .where((abono) => abono['estado_abono'] == 'Abonó')
                          .length;
                      int clientesNoAbonaron = totalClientes - clientesAbonaron;

                      // Encontrar el índice donde cambia de "Abonó" a "No Abonó"
                      abonos.indexWhere(
                          (abono) => abono['estado_abono'] == 'No Abonó');

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total clientes: $totalClientes',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'Abonaron: $clientesAbonaron',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: ColoresApp.verde,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'No abonaron: $clientesNoAbonaron',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: ColoresApp.rojo,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: abonos.length,
                              itemBuilder: (context, index) {
                                final abono = abonos[index];
                                String montoAbonadoFormateado =
                                    NumberFormat('#,###', 'es_CO').format(
                                        double.tryParse(abono['monto_abonado']
                                                .toString()) ??
                                            0.0);

                                // Cálculo del índice donde empieza "No Abonó"
                                int dividerIndex = abonos.indexWhere(
                                  (abono) =>
                                      abono['estado_abono'] == 'No Abonó',
                                );

                                bool mostrarDivider =
                                    dividerIndex > 0 && index == dividerIndex;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (mostrarDivider)
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(
                                          'No abonaron', // Encabezado de la sección
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: ColoresApp.rojo,
                                          ),
                                        ),
                                      ),
                                    ListTile(
                                      title: Text(abono['cliente']
                                          .toString()
                                          .toUpperCase()),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Monto Abonado: $montoAbonadoFormateado'),
                                          Text(
                                              'Estado Abono: ${abono['estado_abono']}'),
                                          Text(
                                              'Fecha Préstamo: ${abono['fecha_prestamo']}'),
                                          Text(
                                              'Fecha Abono: ${abono['fecha_abono'] ?? 'N/A'}'),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      color: mostrarDivider
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget movimientos() {
    return Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureMovimientos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los movimientos'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No hay movimientos registrados hoy'));
          } else {
            final movimientos = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                final tipoMovimiento =
                    movimiento['tipoMovimiento'] == 1 ? 'Ingreso' : 'Gasto';

                final colorValor = tipoMovimiento == 'Ingreso'
                    ? ColoresApp.verde
                    : ColoresApp.rojo;
                return ListTile(
                  title: Text(tipoMovimiento),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movimiento['movi_descripcion']
                          .toString()
                          .toUpperCase()),
                      Text(movimiento['movi_fecha']),
                    ],
                  ),
                  trailing: Text(
                    FormatoMiles().formatearCantidad(movimiento['movi_valor']),
                    style: TextStyle(
                      fontSize: 16,
                      color: colorValor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
