// ignore_for_file: unused_field, prefer_final_fields, unused_local_variable, use_build_context_synchronously

import 'dart:convert';

import 'package:cobrosapp/config/services/conexioninternet.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/config/services/validacion_estado_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:http/http.dart' as http;
import 'package:cobrosapp/screen/widgets/spinner.dart';
import 'package:sizer/sizer.dart';

import 'caja/car_movimientos.dart';

class CajaCuentas extends StatefulWidget {
  const CajaCuentas({super.key});

  @override
  State<CajaCuentas> createState() => _CajaCuentasState();
}

class _CajaCuentasState extends BaseScreen<CajaCuentas> {
  final _pref = PreferenciasUsuario();
  final _formKey = GlobalKey<FormBuilderState>();
  final _dataBaseServices = Databaseservices();
  final TextEditingController fecha = TextEditingController();
  late Future<List<Map<String, dynamic>>> _futureMovimientos;
  Future<String>? _futureCaja;
  bool _mostrarClientes = true;
  bool _mostrarCancelados = false;
  bool _mostrarPrestamos = false;

  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  bool _cargarAbonos = false;

  @override
  void initState() {
    super.initState();
    if (_pref.cargo == '4' || _pref.cargo == '3') {
      // Cargar empleados
      _loadEmpleados();
      _futureCaja = Future.value("0");
    } else {
      // Otros cargos => sin Spinner, fecha del día
      fecha.text = _dataBaseServices.obtenerFechaActual();
      _futureCaja = _calcularTotalRecaudado(context);
      _futureMovimientos = _dataBaseServices.listaMovimientoscaja2(
          _pref.idUser, _dataBaseServices.obtenerFechaActual());
      _cargarAbonos = true;
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final empleados = await _dataBaseServices.fetchEmpleados(_pref.cargo);
      setState(() {
        _roles = empleados.isNotEmpty ? empleados : [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar empleados: $e")),
      );
    }
  }

  String? _nombreEmpleadoSeleccionado;
  void _onEmpleadoChanged(String? value) {
    setState(() {
      _rolSeleccionado = value;
      // Busca en la lista _roles el elemento cuyo id coincida con 'value'
      final empleadoSeleccionado = _roles.firstWhere(
        (role) => role['fk_roll'].toString() == value,
        orElse: () => {},
      );

      _nombreEmpleadoSeleccionado = empleadoSeleccionado.isNotEmpty
          ? empleadoSeleccionado['nombreCompleto']
          : null;

      if (_pref.cargo == '3' && _rolSeleccionado != null) {
        fecha.text = _dataBaseServices.obtenerFechaActual(); // Fecha actual
        _futureCaja = _calcularTotalRecaudado(context); // Consulta de caja
        _buscarAbonos(); // Realizar búsqueda de abonos y movimientos
      }
    });
  }

  void _buscarAbonos() {
    if (_pref.cargo == '3') {
      final fechaActual = _dataBaseServices.obtenerFechaActual();
      setState(() {
        _cargarAbonos = true;
        _futureMovimientos = _mostrarClientes
            ? _dataBaseServices.consultarListadoReporteAbonosClientes(
                _rolSeleccionado ?? _pref.idUser, fechaActual)
            : _dataBaseServices.listaMovimientoscaja2(
                _rolSeleccionado ?? _pref.idUser, fechaActual);
      });
    } else if (_pref.cargo == '4') {
      if (_rolSeleccionado == null || _rolSeleccionado!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Seleccione un empleado antes de buscar.')),
        );
        return;
      }

      final fechaSeleccionada = _formKey.currentState?.fields['fecha']?.value;
      if (fechaSeleccionada == null || fechaSeleccionada.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor selecciona una fecha antes de buscar.')),
        );
        return;
      }

      setState(() {
        _cargarAbonos = true;
        _futureMovimientos = _mostrarClientes
            ? _dataBaseServices.consultarListadoReporteAbonosClientes(
                _rolSeleccionado!,
                fechaSeleccionada.toString().substring(0, 10))
            : _dataBaseServices.listaMovimientoscaja2(
                _rolSeleccionado!, fechaSeleccionada.toString());
      });
    }
  }

  Future<String> _calcularTotalRecaudado(BuildContext context) async {
    String dateValue;

    if (_pref.cargo == "4") {
      // Cargo 4: Toma la fecha del formulario
      String? formDate =
          _formKey.currentState?.fields['fecha']?.value?.toString();
      // Si el formulario no tiene valor, mostramos un Toast
      if (formDate == null || formDate.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SmartDialog.showToast('No se ha establecido fecha para el cálculo.');
        });
        return '0';
      }
      dateValue = formDate;
    } else {
      // Cualquier otro cargo: fecha actual
      dateValue = _dataBaseServices.obtenerFechaActual();
    }
    final fechaSolo = dateValue.substring(0, 10);
    final cargoEmpleado = _pref.cargo;
    // Si cargo es 3 o 4, usamos el empleado seleccionado; si no, usamos _pref.idUser
    final idEmpleado = (cargoEmpleado == "4" || cargoEmpleado == "3") &&
            _rolSeleccionado != null
        ? _rolSeleccionado!
        : _pref.idUser;

    return Databaseservices().totalCajaDia(idEmpleado, fechaSolo);
  }

  Future<List<Map<String, dynamic>>>
      _consultarListadoReporteAbonosClientes() async {
    var dateValue = _formKey.currentState?.fields['fecha']?.value;
    if (_pref.cargo != '4') {
      dateValue = _dataBaseServices.obtenerFechaActual();
    }
    if (dateValue == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SmartDialog.showToast('Seleccione una fecha');
      });
      return [];
    }
    final fecha = dateValue.toString().substring(0, 10);
    final cargoEmpleado = _pref.cargo;
    String id = ((cargoEmpleado == "4" || cargoEmpleado == "3") &&
            _rolSeleccionado != null)
        ? _rolSeleccionado!
        : _pref.idUser;

    return _mostrarClientes
        ? await _dataBaseServices.consultarListadoReporteAbonosClientes(
            id, fecha)
        : await _dataBaseServices.listaMovimientoscaja2(id, fecha);
  }

  bool get _puedeCerrarCaja {
    // Verifica que haya empleado seleccionado y fecha no vacía
    return _rolSeleccionado != null &&
        _rolSeleccionado!.isNotEmpty &&
        fecha.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaCaja;
    return Scaffold(
      floatingActionButton: _pref.cargo == '4'
          ? FloatingActionButton.extended(
              label: const Text('Cerrar Caja'),
              icon: const Icon(Icons.lock),
              onPressed: () async {
                if (!_puedeCerrarCaja) {
                  SmartDialog.showToast(
                      'Seleccione un empleado y fecha primero');
                  return;
                }
                final saldoCaja = await _futureCaja; // Obtener saldo de caja
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Cerrar Caja, verificar datos"),
                    content: Text(
                      "Empleado: ${_nombreEmpleadoSeleccionado ?? 'No seleccionado'}\n"
                      "ID Empleado: ${_rolSeleccionado ?? 'N/A'}\n"
                      "Saldo de Caja: \$$saldoCaja\n"
                      "¿Desea cerrar caja?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final data = await Databaseservices()
                              .cerrarCajaCobrador(_rolSeleccionado!, saldoCaja!,
                                  descripcion: "cierre caja vcjd");
                          if (data['success'] == true) {
                            SmartDialog.showToast("Caja cerrada con éxito");
                            Navigator.pop(context);
                          } else {
                            SmartDialog.showToast(
                                data['error'] ?? 'Error al insertar');
                          }
                        },
                        child: const Text("Si, Cerrar"),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
      backgroundColor: ColoresApp.blanco,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloCaja),
      ),
      drawer: const DrawerMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_pref.cargo == '4' || _pref.cargo == '3')
                SpinnerEmpleados(
                  valueid: "fk_roll",
                  nombreCompleto: "nombreCompleto",
                  empleados: _roles,
                  valorSeleccionado: _rolSeleccionado,
                  onChanged: _onEmpleadoChanged,
                ),
              const SizedBox(height: 16),
              // Campo fecha y botón de búsqueda
              if (_pref.cargo == '4')
                Row(
                  children: [
                    Expanded(flex: 6, child: _campoFecha(enabled: true)),
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _futureCaja = _calcularTotalRecaudado(context);
                          });
                          _buscarAbonos();
                        },
                      ),
                    ),
                  ],
                ),
              const Divider(height: 20),
              encabezaCaja(),
              filtro(),
              // Decidimos qué widget mostrar según el estado
              if (_mostrarPrestamos)
                // Mostrar la lista de préstamos
                Expanded(child: listaPrestamos())
              else if (_mostrarCancelados)
                // Mostrar la lista de cancelados
                Expanded(child: listaCancelados())
              else if (_cargarAbonos)
                // Mostrar clientes o movimientos
                _mostrarClientes
                    ? listadoReporteAbonosClientes()
                    : _movimientos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoFecha({required bool enabled}) {
    int ano = int.parse(_dataBaseServices.obtenerFechaActual().substring(0, 4));
    int mes = int.parse(_dataBaseServices.obtenerFechaActual().substring(5, 7));
    int dia =
        int.parse(_dataBaseServices.obtenerFechaActual().substring(8, 10));
    return FormBuilderDateTimePicker(
      name: 'fecha',
      controller: fecha,
      initialValue: DateTime(ano, mes, dia),
      inputType: InputType.date,
      format: DateFormat('yyyy-MM-dd'),
      enabled: enabled, // sólo habilitado si cargo == 4
      decoration: InputDecoration(
        labelText: 'Fecha',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget filtro() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 5.h, // Altura fija para los botones
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ColoresApp.grisClarito,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _mostrarClientes = true;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = false;
                  });
                  _buscarAbonos();
                },
                child: const Text("Clientes"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ColoresApp.grisClarito,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _mostrarClientes = false;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = false;
                  });
                  _buscarAbonos();
                },
                child: const Text("Gastos"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ColoresApp.grisClarito,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _mostrarClientes = false;
                    _mostrarPrestamos = true;
                    _mostrarCancelados = false;
                  });
                  _buscarAbonos();
                },
                child: const Text("Prestamos"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: ColoresApp.grisClarito,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _mostrarClientes = false;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = true;
                  });
                  _buscarAbonos();
                },
                child: const Text("Cancelados"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _movimientos() {
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
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          FormatoMiles()
                              .formatearCantidad(movimiento['movi_valor']),
                          style: TextStyle(
                            fontSize: 16,
                            color: colorValor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_pref.cargo == "4")
                          IconButton(
                              onPressed: () async {
                                final data = await Databaseservices()
                                    .eliminarMovimiento(
                                        movimiento['idmovimiento'].toString());
                                if (data) {
                                  SmartDialog.showToast(
                                      "Movimiento eliminado con éxito");
                                  // Refrescar la vista
                                  setState(() {
                                    _futureCaja =
                                        _calcularTotalRecaudado(context);
                                    _futureMovimientos =
                                        _consultarListadoReporteAbonosClientes();
                                  });
                                } else {
                                  SmartDialog.showToast(
                                      "No se pudo eliminar el movimiento");
                                }
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: ColoresApp.rojoLogo,
                              ))
                      ],
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

  Widget encabezaCaja() {
    return Container(
      width: double.infinity,
      height: 13.h,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: FutureBuilder<String>(
        future: _futureCaja,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('0'));
          } else {
            final totalCaja = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Saldo caja:",
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FormatoNumero(
                  numero: totalCaja,
                  color: ColoresApp.negro,
                  fontSize: 25,
                  fontSize2: 10,
                ),
                const Divider(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget listadoReporteAbonosClientes() {
    return Expanded(
      flex: 7,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _consultarListadoReporteAbonosClientes(),
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
                    int dividerIndex = abonos.indexWhere(
                        (abono) => abono['estado_abono'] == 'No Abonó');

                    double sumaDinero = abonos.fold(0.0, (sum, cliente) {
                      return sum +
                          (double.tryParse(
                                  cliente['monto_abonado'].toString()) ??
                              0.0);
                    });
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
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Recogio: ${FormatoMiles().formatearCantidad(sumaDinero.toString())}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
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
                              String montoAbonadoFormateado = NumberFormat(
                                      '#,###', 'es_CO')
                                  .format(double.tryParse(
                                          abono['monto_abonado'].toString()) ??
                                      0.0);
                              // Cálculo del índice donde empieza "No Abonó"
                              int dividerIndex = abonos.indexWhere(
                                (abono) => abono['estado_abono'] == 'No Abonó',
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
    );
  }

  Future<List<dynamic>> fetchListaPrestamos() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      // Lanza una excepción si no hay internet
      throw Exception('No tienes conexion a internet');
    }
    // Determina el ID y la fecha a usar
    String idConsultado;
    String fechaSeleccionada;

    if (_pref.cargo == '4') {
      // Usa el empleado seleccionado o, si no, _pref.idUser
      idConsultado = (_rolSeleccionado != null && _rolSeleccionado!.isNotEmpty)
          ? _rolSeleccionado!
          : _pref.idUser;

      // Usa la fecha del formulario o la fecha actual si está vacía
      final formDate =
          _formKey.currentState?.fields['fecha']?.value?.toString();
      if (formDate == null || formDate.isEmpty) {
        fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
      } else {
        fechaSeleccionada = formDate.substring(0, 10);
      }
    } else if (_pref.cargo == '3') {
      // Para cargo 3, usa el empleado seleccionado y la fecha actual
      idConsultado = (_rolSeleccionado != null && _rolSeleccionado!.isNotEmpty)
          ? _rolSeleccionado!
          : _pref.idUser;
      fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
    } else {
      // Para otros cargos, usa el ID pref.idUser y fecha actual
      idConsultado = _pref.idUser;
      fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
    }

    var url = Uri.parse(
        "${ApiConstants.listaPrestamosNuevos}$idConsultado&fc=$fechaSeleccionada");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  Future<List<dynamic>> fetchListaCancelados() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      // Lanza una excepción si no hay internet
      throw Exception('No tienes conexion a internet');
    }
    // Determina el ID y la fecha a usar
    String idConsultado;
    String fechaSeleccionada;

    if (_pref.cargo == '4') {
      // Usa el empleado seleccionado o, si no, _pref.idUser
      idConsultado = (_rolSeleccionado != null && _rolSeleccionado!.isNotEmpty)
          ? _rolSeleccionado!
          : _pref.idUser;

      // Usa la fecha del formulario o la fecha actual si está vacía
      final formDate =
          _formKey.currentState?.fields['fecha']?.value?.toString();
      if (formDate == null || formDate.isEmpty) {
        fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
      } else {
        fechaSeleccionada = formDate.substring(0, 10);
      }
    } else if (_pref.cargo == '3') {
      // Para cargo 3, usa el empleado seleccionado y la fecha actual
      idConsultado = (_rolSeleccionado != null && _rolSeleccionado!.isNotEmpty)
          ? _rolSeleccionado!
          : _pref.idUser;
      fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
    } else {
      // Para otros cargos, usa el ID pref.idUser y fecha actual
      idConsultado = _pref.idUser;
      fechaSeleccionada = _dataBaseServices.obtenerFechaActual();
    }

    var url = Uri.parse(
        "${ApiConstants.listaPrestamosCancelados}$idConsultado&fc=$fechaSeleccionada");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
      return [];
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  Widget listaPrestamos() {
    return FutureBuilder<List<dynamic>>(
      future: fetchListaPrestamos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text(
              textAlign: TextAlign.center,
              AppTextos.nohayInternetVC,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(AppTextos.nohayPrestamos),
          );
        } else {
          final clientes = snapshot.data!;
          int totalPrestamos = clientes.length;
          // Calcular la suma de los seguros
          double sumaSeguros = clientes.fold(0.0, (sum, cliente) {
            return sum +
                (double.tryParse(cliente['pres_seguro'].toString()) ?? 0.0);
          });
          double sumaDinero = clientes.fold(0.0, (sum, cliente) {
            return sum +
                (double.tryParse(cliente['pres_cantidad'].toString()) ?? 0.0);
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total prestamos: $totalPrestamos',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Prestado: ${FormatoMiles().formatearCantidad(sumaDinero.toString())}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Seguros: ${FormatoMiles().formatearCantidad(sumaSeguros.toString())}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ColoresApp.verde,
                            child: Text(
                              cliente['per_nombre'][0].toString().toUpperCase(),
                              style: const TextStyle(color: ColoresApp.blanco),
                            ),
                          ),
                          title: Text(
                            '${cliente['per_nombre'].toString().toUpperCase()} ${cliente['per_apellido'].toString().toUpperCase()}',
                            style: const TextStyle(color: ColoresApp.negro),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de prestamo: ${cliente['pres_fecha']}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Cantidad total: ${FormatoMiles().formatearCantidad(cliente['pres_cantidadTotal'])}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Valor Cuota: ${FormatoMiles().formatearCantidad(cliente['pres_valorCuota'])}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Valor seguro: ${FormatoMiles().formatearCantidad(cliente['pres_seguro'])}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                            ],
                          ),
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
    );
  }

  Widget listaCancelados() {
    return FutureBuilder<List<dynamic>>(
      future: fetchListaCancelados(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text(
              textAlign: TextAlign.center,
              AppTextos.nohayInternetVC,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(AppTextos.nohayPrestamosCancelados),
          );
        } else {
          final clientes = snapshot.data!;
          int totalPrestamos = clientes.length;
          // Calcular la suma de los seguros
          double sumaSeguros = clientes.fold(0.0, (sum, cliente) {
            return sum +
                (double.tryParse(cliente['pres_seguro'].toString()) ?? 0.0);
          });
          double sumaDinero = clientes.fold(0.0, (sum, cliente) {
            return sum +
                (double.tryParse(cliente['pres_cantidad'].toString()) ?? 0.0);
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total Cancelados: $totalPrestamos',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ColoresApp.verde,
                            child: Text(
                              cliente['per_nombre'][0].toString().toUpperCase(),
                              style: const TextStyle(color: ColoresApp.blanco),
                            ),
                          ),
                          title: Text(
                            '${cliente['per_nombre'].toString().toUpperCase()} ${cliente['per_apellido'].toString().toUpperCase()}',
                            style: const TextStyle(color: ColoresApp.negro),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha inicio: ${cliente['pres_fecha']}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Fecha fin: ${cliente['pre_fecha_finalizo']}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Cantidad total: ${FormatoMiles().formatearCantidad(cliente['pres_cantidadTotal'])}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                              Text(
                                'Suma ultimo abono: ${FormatoMiles().formatearCantidad(cliente['total_abonos'])}',
                                style: const TextStyle(color: ColoresApp.negro),
                              ),
                            ],
                          ),
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
    );
  }
}
