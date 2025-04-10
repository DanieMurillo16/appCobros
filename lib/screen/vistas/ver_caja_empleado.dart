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

import '../widgets/floatingboton_cajaempleado.dart';
import 'caja/car_movimientos.dart';

// Primero, agrega esta variable al inicio de la clase _CajaCuentasState
enum BotonActivo { ninguno, clientes, gastos, prestamos, cancelados }

class CajaCuentas extends StatefulWidget {
  const CajaCuentas({super.key});

  @override
  State<CajaCuentas> createState() => _CajaCuentasState();
}

class _CajaCuentasState extends BaseScreen<CajaCuentas> {
  BotonActivo _botonActivo = BotonActivo.ninguno;

  final _pref = PreferenciasUsuario();
  final _formKey = GlobalKey<FormBuilderState>();
  final _dataBaseServices = Databaseservices();
  final TextEditingController fecha = TextEditingController();
  Future<String>? _futureCaja;
  bool _mostrarClientes = true;
  bool _mostrarCancelados = false;
  bool _mostrarPrestamos = false;

  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  bool _cargarAbonos = false;
  bool _isLoading = false;

  // Variables para almacenar datos precargados
  List<Map<String, dynamic>> _datosClientes = [];
  List<dynamic> _datosPrestamos = [];
  List<dynamic> _datosCancelados = [];
  List<Map<String, dynamic>> _datosMovimientos = [];
  // Añadir esta variable para cachear el valor de caja
  Map<String, dynamic>? _ultimoDetallesCaja;

  // Método para cargar todos los datos
  Future<void> _cargarTodosDatos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool conectado = await Conexioninternet().isConnected();
      if (!conectado) {
        throw Exception('No hay conexión a internet');
      }

      // Cargar solo los datos necesarios según el filtro activo
      List<Future> futuros = [];

      if (_mostrarClientes || _botonActivo == BotonActivo.ninguno) {
        futuros.add(_cargarDatosConRetry(
            () => _consultarListadoReporteAbonosClientes()));
      }

      if (_mostrarPrestamos || _botonActivo == BotonActivo.ninguno) {
        futuros.add(_cargarDatosConRetry(() => fetchListaPrestamos()));
      }

      if (_mostrarCancelados || _botonActivo == BotonActivo.ninguno) {
        futuros.add(_cargarDatosConRetry(() => fetchListaCancelados()));
      }

      // Siempre cargar los movimientos para el cálculo de caja
      futuros.add(
          _cargarDatosConRetry(() => _dataBaseServices.listaMovimientoscaja2(
                _rolSeleccionado ?? _pref.idUser,
                fecha.text,
              )));

      final resultados = await Future.wait(futuros);

      if (mounted) {
        // En el setState dentro de _cargarTodosDatos()
        setState(() {
          int indice = 0;
          if (_mostrarClientes || _botonActivo == BotonActivo.ninguno) {
            // Asignar, no añadir
            _datosClientes = resultados[indice++] as List<Map<String, dynamic>>;
          }
          if (_mostrarPrestamos || _botonActivo == BotonActivo.ninguno) {
            // Asignar, no añadir
            _datosPrestamos = resultados[indice++];
          }
          if (_mostrarCancelados || _botonActivo == BotonActivo.ninguno) {
            // Asignar, no añadir
            _datosCancelados = resultados[indice++];
          }
          // Asignar, no añadir
          _datosMovimientos = resultados.last as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _cargarTodosDatos,
            ),
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// Función auxiliar para reintentos
  Future<T> _cargarDatosConRetry<T>(Future<T> Function() callback) async {
    for (int i = 0; i < 3; i++) {
      try {
        return await callback();
      } catch (e) {
        if (i == 2) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Error después de 3 intentos');
  }

  @override
  void initState() {
    super.initState();
    // Inicializar _ultimoDetallesCaja como vacío
    _ultimoDetallesCaja = null;

    if (_pref.cargo == '4' || _pref.cargo == '3') {
      // Cargar empleados
      _loadEmpleados();
      _futureCaja = Future.value("0");
    } else {
      // Otros cargos => sin Spinner, cargar datos del día
      fecha.text = _dataBaseServices.obtenerFechaActual();
      _cargarAbonos = true;

      // Cargar datos iniciales y LUEGO calcular el saldo
      _cargarTodosDatos().then((_) {
        if (mounted) {
          setState(() {
            _futureCaja = Future.value(calcularCaja());
          });
        }
      });

      _botonActivo = BotonActivo.clientes;
    }
  }

  Future<void> _loadEmpleados() async {
    if (!mounted) return;
    try {
      final empleados =
          await _dataBaseServices.fetchEmpleados(_pref.cargo, _pref.cobro);
      if (!mounted) return;

      setState(() {
        _roles = empleados.isNotEmpty ? empleados : [];
      });
    } catch (e) {
      if (!mounted) return;
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
    setState(() {
      _cargarAbonos = true;
    });
  }

  Future<String> _calcularTotalRecaudado(BuildContext context) async {
    String dateValue;
    if (!mounted) return '';

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaCaja;
    return Scaffold(
      floatingActionButton: _pref.cargo == '4'
          ? BotonFlotanteCierreCaja(
              rolSeleccionado: _rolSeleccionado,
              nombreEmpleadoSeleccionado: _nombreEmpleadoSeleccionado,
              fecha: fecha.text,
              cobro: _pref.cobro,
              cajaDetalles: _obtenerDetallesCaja(),
              futureCaja: _futureCaja,
              puedeCerrarCaja: _puedeCerrarCaja,
              onCajaCerrada: () {
                // Acción a realizar después de cerrar caja (opcional)
                setState(() {
                  _futureCaja = _calcularTotalRecaudado(context);
                  _cargarTodosDatos();
                });
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
                // En el widget _campoFecha (donde va el botón de búsqueda)
                // Modifica el botón de lupa en el widget Row
                Row(
                  children: [
                    Expanded(flex: 6, child: _campoFecha(enabled: true)),
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        color: ColoresApp.rojo,
                        icon: const Icon(Icons.search),
                        // Modifica el método onPressed del botón de lupa así:
                        onPressed: () async {
                          // Mostrar indicador de carga
                          SmartDialog.showLoading(msg: "Cargando datos...");

                          // IMPORTANTE: Invalidar el caché
                          setState(() {
                            _ultimoDetallesCaja = null;
                            _datosClientes = [];
                            _datosPrestamos = [];
                            _datosCancelados = [];
                            _datosMovimientos = [];
                            _isLoading = true;

                            // Reiniciar botones a estado inicial
                            _botonActivo = BotonActivo.clientes;
                            _mostrarClientes = true;
                            _mostrarPrestamos = false;
                            _mostrarCancelados = false;
                            _cargarAbonos = true;
                          });

                          try {
                            // Modificar _cargarTodosDatos para que cargue SIEMPRE todos los datos
                            await _cargarTodosDatosPorLupa();

                            // Calcular totales después de cargar datos
                            if (mounted) {
                              // Actualizar _futureCaja directamente con el valor calculado
                              String valorCalculado = calcularCaja();
                              setState(() {
                                _futureCaja = Future.value(valorCalculado);
                              });
                            }

                            SmartDialog.dismiss();
                            SmartDialog.showToast(
                              "Datos actualizados",
                              displayTime: const Duration(milliseconds: 1200),
                            );
                          } catch (error) {
                            SmartDialog.dismiss();
                            SmartDialog.showToast("Error al cargar: $error");
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
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
                    : _gastosmovimientos(),
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
        height: 5.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _botonActivo == BotonActivo.clientes
                      ? ColoresApp.rojo
                      : ColoresApp.verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_isLoading) return;
                  setState(() {
                    _botonActivo = BotonActivo.clientes;
                    _mostrarClientes = true;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = false;
                    _cargarAbonos = true;
                  });
                },
                child: const Text("Clientes",
                    style: TextStyle(color: ColoresApp.blanco)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _botonActivo == BotonActivo.gastos
                      ? ColoresApp.rojo
                      : ColoresApp.verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_isLoading) return;
                  setState(() {
                    _botonActivo = BotonActivo.gastos;
                    _mostrarClientes = false;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = false;
                    _cargarAbonos = true; // Añadir esto para mostrar los datos
                  });
                },
                child: const Text("Gastos",
                    style: TextStyle(color: ColoresApp.blanco)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _botonActivo == BotonActivo.prestamos
                      ? ColoresApp.rojo
                      : ColoresApp.verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_isLoading) return;

                  setState(() {
                    _botonActivo = BotonActivo.prestamos;
                    _mostrarClientes = false;
                    _mostrarPrestamos = true;
                    _mostrarCancelados = false;
                  });
                },
                child: const Text("Prestamos",
                    style: TextStyle(color: ColoresApp.blanco)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _botonActivo == BotonActivo.cancelados
                      ? ColoresApp.rojo
                      : ColoresApp.verde,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_isLoading) return;
                  setState(() {
                    _botonActivo = BotonActivo.cancelados;
                    _mostrarClientes = false;
                    _mostrarPrestamos = false;
                    _mostrarCancelados = true;
                  });
                },
                child: const Text("Cancelados",
                    style: TextStyle(color: ColoresApp.blanco)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gastosmovimientos() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_datosMovimientos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No hay movimientos registrados hoy.'),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _datosMovimientos.length,
        itemBuilder: (context, index) {
          final movimiento = _datosMovimientos[index];
          final tipoMovimiento =
              movimiento['tipoMovimiento'] == 1 ? 'Ingreso' : 'Gasto';
          final colorValor =
              tipoMovimiento == 'Ingreso' ? ColoresApp.verde : ColoresApp.rojo;

          return ListTile(
            title: Text(tipoMovimiento),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movimiento['movi_descripcion'].toString().toUpperCase()),
                Text(movimiento['movi_fecha']),
              ],
            ),
            trailing: SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    FormatoMiles().formatearCantidad(movimiento['movi_valor']),
                    style: TextStyle(
                      fontSize: 14,
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
                          setState(() {
                            _futureCaja = _calcularTotalRecaudado(context);
                            _cargarTodosDatos();
                          });
                        } else {
                          SmartDialog.showToast(
                              "No se pudo eliminar el movimiento");
                        }
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: ColoresApp.rojoLogo,
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget encabezaCaja() {
    return FutureBuilder<String>(
      future: _futureCaja,
      builder: (context, snapshot) {
        // Mostrar un valor predeterminado hasta que el Future se complete
        final saldoCaja =
            snapshot.connectionState == ConnectionState.done && snapshot.hasData
                ? snapshot.data!
                : "0";

        return Container(
          width: double.infinity,
          height: 15.h,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: ColoresApp.blanco,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Saldo caja:",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: ColoresApp.rojoLogo,
                      size: 24,
                    ),
                    // Modificar esta línea para obtener los detalles al momento de mostrar el diálogo
                    onPressed: () =>
                        _mostrarDialogoDetalleCaja(_obtenerDetallesCaja()),
                    tooltip: 'Detalles del cálculo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              FormatoNumero(
                numero: saldoCaja,
                color: ColoresApp.negro,
                fontSize: 25,
                fontSize2: 10,
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  // Método específico para cuando se presiona el botón de lupa
  Future<void> _cargarTodosDatosPorLupa() async {
    if (!mounted) return;

    try {
      final bool conectado = await Conexioninternet().isConnected();
      if (!conectado) {
        throw Exception('No hay conexión a internet');
      }

      // Siempre cargar TODOS los datos, independientemente del filtro
      List<Future> futuros = [];

      // Cargar clientes
      futuros.add(
          _cargarDatosConRetry(() => _consultarListadoReporteAbonosClientes()));

      // Cargar préstamos
      futuros.add(_cargarDatosConRetry(() => fetchListaPrestamos()));

      // Cargar cancelados
      futuros.add(_cargarDatosConRetry(() => fetchListaCancelados()));

      // Cargar movimientos
      futuros.add(
          _cargarDatosConRetry(() => _dataBaseServices.listaMovimientoscaja2(
                _rolSeleccionado ?? _pref.idUser,
                fecha.text,
              )));

      final resultados = await Future.wait(futuros);

      if (mounted) {
        setState(() {
          // Siempre asignar todos los valores, sin importar el filtro actual
          _datosClientes = resultados[0] as List<Map<String, dynamic>>;
          _datosPrestamos = resultados[1];
          _datosCancelados = resultados[2];
          _datosMovimientos = resultados[3] as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _cargarTodosDatosPorLupa,
            ),
          ),
        );
      }
      rethrow;
    }
  }

  Map<String, dynamic> _obtenerDetallesCaja() {
    // Si ya tenemos un valor calculado y no estamos cargando nuevos datos, devolverlo
    if (_ultimoDetallesCaja != null && !_isLoading) {
      return _ultimoDetallesCaja!;
    }

    // Comprobar si hay datos para calcular
    if (_datosClientes.isEmpty &&
        _datosMovimientos.isEmpty &&
        _datosPrestamos.isEmpty &&
        _datosCancelados.isEmpty) {
      // Devolver valores por defecto
      return {
        'abonosDiarios': 0.0,
        'cancelados': 0.0,
        'seguros': 0.0,
        'ingresos': 0.0,
        'totalEntradas': 0.0,
        'prestamos': 0.0,
        'gastos': 0.0,
        'totalSalidas': 0.0,
        'saldoCaja': 0.0,
      };
    }

    // Si no hay valor previo o estamos recargando, calcular
    // 1. Cálculos de entradas
    final abonos = _datosClientes;
    double totalAbonosDiario = abonos.fold(0.0, (sum, cliente) {
      return sum +
          (double.tryParse(cliente['monto_abonado'].toString()) ?? 0.0);
    });

    final clientesCancelados = _datosCancelados;
    double totalSumaCancelados = clientesCancelados.fold(0.0, (sum, cliente) {
      return sum + (double.tryParse(cliente['total_abonos'].toString()) ?? 0.0);
    });

    final datosPrestamo = _datosPrestamos;
    double totalSumaDineroPrestado = datosPrestamo.fold(0.0, (sum, cliente) {
      return sum +
          (double.tryParse(cliente['pres_cantidad'].toString()) ?? 0.0);
    });

    final clientesPrestamos = _datosPrestamos;
    double totalSumaSeguros = clientesPrestamos.fold(0.0, (sum, cliente) {
      double seguro = double.tryParse(cliente['pres_seguro'].toString()) ?? 0.0;
      return sum + seguro;
    });

    // 2. Cálculos de movimientos (ingresos y gastos)
    double totalIngresos = _datosMovimientos.fold(0.0, (sum, movimiento) {
      if (movimiento['tipoMovimiento'] == 1) {
        return sum +
            (double.tryParse(movimiento['movi_valor'].toString()) ?? 0.0);
      }
      return sum;
    });

    double totalGastos = _datosMovimientos.fold(0.0, (sum, movimiento) {
      if (movimiento['tipoMovimiento'] == 2) {
        return sum +
            (double.tryParse(movimiento['movi_valor'].toString()) ?? 0.0);
      }
      return sum;
    });

    // 3. Cálculo final del saldo de caja
    double totalEntradas = totalAbonosDiario +
        totalSumaCancelados +
        totalSumaSeguros +
        totalIngresos;
    double totalSalidas = totalSumaDineroPrestado + totalGastos;
    double saldoCaja = totalEntradas - totalSalidas;

    // Guardar el resultado para uso futuro
    _ultimoDetallesCaja = {
      'abonosDiarios': totalAbonosDiario,
      'cancelados': totalSumaCancelados,
      'seguros': totalSumaSeguros,
      'ingresos': totalIngresos,
      'totalEntradas': totalEntradas,
      'prestamos': totalSumaDineroPrestado,
      'gastos': totalGastos,
      'totalSalidas': totalSalidas,
      'saldoCaja': saldoCaja,
    };

    return _ultimoDetallesCaja!;
  }

// Método para mostrar el diálogo con detalles
  void _mostrarDialogoDetalleCaja(Map<String, dynamic> detalles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                const Text(
                  'Detalles del Saldo de Caja',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.rojoLogo,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Sección de Entradas
                _seccionDetalles(
                  'ENTRADAS',
                  ColoresApp.verde,
                  [
                    {
                      'concepto': 'Abonos diarios',
                      'valor': detalles['abonosDiarios']
                    },
                    {'concepto': 'Cancelados', 'valor': detalles['cancelados']},
                    {'concepto': 'Seguros', 'valor': detalles['seguros']},
                    {'concepto': 'Ingresos', 'valor': detalles['ingresos']},
                  ],
                  total: {
                    'concepto': 'Total Entradas',
                    'valor': detalles['totalEntradas']
                  },
                ),

                const SizedBox(height: 16),

                // Sección de Salidas
                _seccionDetalles(
                  'SALIDAS',
                  ColoresApp.rojo,
                  [
                    {'concepto': 'Préstamos', 'valor': detalles['prestamos']},
                    {'concepto': 'Gastos', 'valor': detalles['gastos']},
                  ],
                  total: {
                    'concepto': 'Total Salidas',
                    'valor': detalles['totalSalidas']
                  },
                ),

                const SizedBox(height: 16),

                // Saldo Final
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColoresApp.azulRey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SALDO FINAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.blanco,
                        ),
                      ),
                      Text(
                        FormatoMiles().formatearCantidad(
                            detalles['saldoCaja'].toString()),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColoresApp.blanco,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botón Cerrar
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: ColoresApp.rojoLogo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Widget auxiliar para crear secciones en el diálogo
  Widget _seccionDetalles(
      String titulo, Color color, List<Map<String, dynamic>> items,
      {required Map<String, dynamic> total}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Divider(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['concepto'],
                        style: const TextStyle(fontSize: 14)),
                    Text(
                      FormatoMiles()
                          .formatearCantidad(item['valor'].toString()),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total['concepto'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                FormatoMiles().formatearCantidad(total['valor'].toString()),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String calcularCaja() {
    // Verificar si existen datos para calcular
    if (_datosClientes.isEmpty &&
        _datosPrestamos.isEmpty &&
        _datosCancelados.isEmpty &&
        _datosMovimientos.isEmpty) {
      return "0"; // Valor por defecto cuando no hay datos
    }

    // Usar los valores ya almacenados sin recalcular
    final cajaDetalles = _obtenerDetallesCaja();
    return cajaDetalles['saldoCaja'].toString();
  }

  Widget listadoReporteAbonosClientes() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_datosClientes.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles'),
      );
    }

    final abonos = _datosClientes;
    int totalClientes = abonos.length;
    int clientesAbonaron =
        abonos.where((abono) => abono['estado_abono'] == 'Abonó').length;
    int clientesNoAbonaron = totalClientes - clientesAbonaron;

    // Encontrar el índice donde cambia de "Abonó" a "No Abonó"
    int dividerIndex = abonos.indexWhere(
      (abono) => abono['estado_abono'] == 'No Abonó',
    );

    double sumaDinero = abonos.fold(0.0, (sum, cliente) {
      return sum +
          (double.tryParse(cliente['monto_abonado'].toString()) ?? 0.0);
    });

    final clientes = _datosCancelados;
    int totalPrestamos = clientes.length;

    double totalsumaAbonos = clientes.fold(0.0, (sum, cliente) {
      return sum + (double.tryParse(cliente['total_abonos'].toString()) ?? 0.0);
    });

    final clientesPrestamos = _datosPrestamos;
    double totalSumaSeguros = clientesPrestamos.fold(0.0, (sum, cliente) {
      double seguro = double.tryParse(cliente['pres_seguro'].toString()) ?? 0.0;
      return sum + seguro;
    });

    double sumatotalDinero = totalsumaAbonos + sumaDinero + totalSumaSeguros;

    return Expanded(
      flex: 7,
      child: SizedBox(
        width: double.infinity,
        child: Column(
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
                    'Recogio: ${FormatoMiles().formatearCantidad(sumatotalDinero.toString())}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: abonos.length,
                itemBuilder: (context, index) {
                  final abono = abonos[index];
                  String montoAbonadoFormateado = NumberFormat('#,###', 'es_CO')
                      .format(
                          double.tryParse(abono['monto_abonado'].toString()) ??
                              0.0);

                  bool mostrarDivider =
                      dividerIndex > 0 && index == dividerIndex;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mostrarDivider)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No abonaron',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: ColoresApp.rojo,
                            ),
                          ),
                        ),
                      ListTile(
                        title: Text(abono['cliente'].toString().toUpperCase()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monto Abonado: $montoAbonadoFormateado'),
                            Text('Estado Abono: ${abono['estado_abono']}'),
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
    if (!mounted) return [];
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
        "${ApiConstants.listaPrestamosNuevos}$idConsultado&fc=$fechaSeleccionada&cobro=${_pref.cobro}");
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
    if (!mounted) return [];
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
        "${ApiConstants.listaPrestamosCancelados}$idConsultado&fc=$fechaSeleccionada&cobro=${_pref.cobro}");
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_datosPrestamos.isEmpty) {
      return const Center(
        child: Text(AppTextos.nohayPrestamos),
      );
    }

    final clientes = _datosPrestamos;
    int totalPrestamos = clientes.length;
    int conSeguro = 0;
    int sinSeguro = 0;
    double sumaSeguros = clientes.fold(0.0, (sum, cliente) {
      double seguro = double.tryParse(cliente['pres_seguro'].toString()) ?? 0.0;
      if (seguro > 0) {
        conSeguro++;
      } else {
        sinSeguro++;
      }
      return sum + seguro;
    });
    // Sumar la cantidad total de dinero prestado
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
                'Prestamos: $totalPrestamos',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Prestado: ${FormatoMiles().formatearCantidad(sumaDinero.toString())}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Con seguro: $conSeguro',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Text(' | ',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    'Sin seguro: $sinSeguro',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Seguros: ${FormatoMiles().formatearCantidad(sumaSeguros.toString())}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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

  Widget listaCancelados() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_datosCancelados.isEmpty) {
      return const Center(
        child: Text(AppTextos.nohayPrestamosCancelados),
      );
    }

    final clientes = _datosCancelados;
    int totalPrestamos = clientes.length;

    double totalsumaAbonos = clientes.fold(0.0, (sum, cliente) {
      return sum + (double.tryParse(cliente['total_abonos'].toString()) ?? 0.0);
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
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Suma: ${FormatoMiles().formatearCantidad(totalsumaAbonos.toString())}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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
}
