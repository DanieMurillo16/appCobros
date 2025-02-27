// ignore_for_file: unused_element, avoid_print, unnecessary_brace_in_string_interps, unrelated_type_equality_checks, unused_field, use_build_context_synchronously
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/routes/apis.dart';
import '../../config/routes/rutas.dart';
import '../../config/services/conexioninternet.dart';
import '../../config/services/databaseservices.dart';
import '../../config/services/formatomiles.dart';
import '../../config/services/validacion_estado_usuario.dart';
import '../../config/shared/peferences.dart';
import '../../desing/app_medidas.dart';
import '../../desing/coloresapp.dart';
import '../../desing/textosapp.dart';
import '../widgets/appbar.dart';
import '../widgets/drawemenu.dart';
import '../widgets/spinner.dart';
import '../widgets/textfield.dart';

class Abonoprestamo extends StatefulWidget {
  const Abonoprestamo({super.key});

  @override
  // ignore: library_private_types_in_public_api
  __AbonoprestamoState createState() => __AbonoprestamoState();
}

class __AbonoprestamoState extends BaseScreen<Abonoprestamo> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _pref = PreferenciasUsuario();
  final _dataBaseServices = Databaseservices();

  String? _idPersona;
  String? _nombre;
  bool _fromRutaCobrador = false;

  String? _clienteSeleccionado;
  final TextEditingController _controladorMonto = TextEditingController();
  final TextEditingController _clienteController = TextEditingController();

  List<Map<String, dynamic>> _clientes = [];
  bool isFormatting = false;
  bool _cargarAbonos = false;

  // Lista de empleados (si el cargo es 3 o 4)
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  late Future<Map<String, dynamic>> _futureCalcularTotal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _idPersona = args['idpersona'];
      _nombre = args['nombre'];
      _fromRutaCobrador = args['fromRutaCobrador'] ?? false;

      // Si vienes desde la ruta y ya tienes _idPersona, asigna y carga abonos
      if (_fromRutaCobrador && _idPersona != null) {
        _clienteSeleccionado = _idPersona;
        _clienteController.text = _nombre ?? '';
        _buscarAbonos(); // Esto dispara la llamada a _calcularTotalRecaudado()
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _futureCalcularTotal = Future.value(
        {'prestamo': {}, 'abonos': []}); // Valor inicial para evitar error
    final cargoEmpleado = _pref.cargo;
    if (cargoEmpleado == '3' || cargoEmpleado == '4') {
      _loadEmpleados();
    } else {
      _fetchClientesFromPhp(_pref.idUser);
    }
    // Si _fromRutaCobrador todavía no está configurado, no pasa nada
    // Se reasignará en didChangeDependencies cuando lleguen los argumentos
    _controladorMonto.addListener(_onMontoChanged);
  }

  // Cargar empleados (sólo si cargo = 3 o 4)
  Future<void> _loadEmpleados() async {
    try {
      final empleados = await _dataBaseServices.fetchEmpleados(_pref.cargo,_pref.cobro);
      setState(() {
        _roles = empleados;
      });
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
    }
  }

  @override
  void dispose() {
    _controladorMonto.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  // Cargar clientes desde PHP (tomando como parámetro el id del empleado)
  Future<void> _fetchClientesFromPhp(String idEmpleado) async {
    try {
      final clientes =
          await _dataBaseServices.fetchClientesSpinnerFromPhp(idEmpleado);
      setState(() {
        _clientes = clientes;
      });
    } catch (e) {
      debugPrint("Error al cargar clientes: $e");
    }
  }

  void _onMontoChanged() {
    if (isFormatting) return;
    String text = _controladorMonto.text;
    // Eliminar cualquier carácter que no sea dígito o separador decimal
    String cleanedText = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanedText.isEmpty) return;
    // Parsear el texto limpio a un número
    double value = double.tryParse(cleanedText.replaceAll('.', '')) ?? 0.0;
    // Formatear el número como pesos colombianos
    final formatter = NumberFormat('#,###', 'es_CO');
    String formatted = formatter.format(value);
    // Actualizar el controlador si el texto formateado cambió
    if (formatted != text) {
      isFormatting = true;
      _controladorMonto.text = formatted;
      _controladorMonto.selection = TextSelection.fromPosition(
        TextPosition(offset: _controladorMonto.text.length),
      );
      isFormatting = false;
    }
  }

  void _buscarAbonos() {
    setState(() {
      _cargarAbonos = true;
      _futureCalcularTotal = _calcularTotalRecaudado();
    });
  }

  Future<List<Map<String, dynamic>>> _getSuggestions(String pattern) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (pattern.isEmpty) {
      return _clientes;
    }
    return _clientes
        .where((cliente) => (cliente["nombreCompleto"] ?? '')
            .toLowerCase()
            .contains(pattern.toLowerCase()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _buscarClientes(String pattern) async {
    if (_fromRutaCobrador && _idPersona != null) {
      return _clientes
          .where((cliente) => cliente['idpersona'] == _idPersona)
          .toList();
    }
    return _clientes
        .where((cliente) => (cliente["nombreCompleto"] ?? '')
            .toLowerCase()
            .contains(pattern.toLowerCase()))
        .toList();
  }

  double restateFinal = 0.0;

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutanuevoAbono;
    final cargoEmpleado = _pref.cargo;
    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      appBar: _fromRutaCobrador
          ? PreferredSize(
              preferredSize:
                  const Size.fromHeight(AppMedidas.medidaAppBarLargo),
              child: AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                toolbarHeight: 30.w,
                backgroundColor: ColoresApp.rojo,
                title: const Text(
                  AppTextos.abonoPrestamoVD,
                  style: TextStyle(color: ColoresApp.blanco),
                ),
                leading: IconButton(
                  color: ColoresApp.blanco,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            )
          : const PreferredSize(
              preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
              child: TitulosAppBar(nombreRecibido: AppTextos.abonoPrestamoVD),
            ),
      drawer: _fromRutaCobrador ? null : const DrawerMenu(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Si cargo es 3 o 4 => Spinner para empleados
                if ((cargoEmpleado == '3' || cargoEmpleado == '4') &&
                    !_fromRutaCobrador)
                  SpinnerEmpleados(
                    empleados: _roles, // lista de empleados
                    valorSeleccionado: _rolSeleccionado,
                    valueid: "fk_roll", // campo id
                    nombreCompleto: "nombreCompleto", // campo a mostrar
                    onChanged: (value) {
                      // Al seleccionar empleado, cargamos sus clientes
                      setState(() {
                        _rolSeleccionado = value;
                        if (_rolSeleccionado != null &&
                            _rolSeleccionado!.isNotEmpty) {
                          _fetchClientesFromPhp(_rolSeleccionado!);
                          _clienteController.clear();
                          _cargarAbonos = false;
                        }
                      });
                    },
                  ),
                const SizedBox(height: 8),
                if (_fromRutaCobrador && _nombre != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Cliente: $_nombre',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                // DropDownSearchField para clientes
                if (!_fromRutaCobrador)
                  Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: DropDownSearchField<Map<String, dynamic>>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: _clienteController,
                            autofocus: false,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: "Buscar cliente",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          suggestionsCallback: (pattern) =>
                              _getSuggestions(pattern),
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(suggestion['nombreCompleto'] ?? ''),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            setState(() {
                              _clienteSeleccionado = suggestion['idprestamos'];
                              _clienteController.text =
                                  suggestion['nombreCompleto'] ?? '';
                            });
                            if (_clienteSeleccionado != null &&
                                _clienteSeleccionado!.isNotEmpty) {
                              _buscarAbonos();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Cliente seleccionado: ${suggestion['nombreCompleto']}"),
                              ),
                            );
                          },
                          noItemsFoundBuilder: (context) => const Center(
                            child: Text("No se encontraron resultados"),
                          ),
                          displayAllSuggestionWhenTap: true,
                          isMultiSelectDropdown: false,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: WidgetTextField(
                          identificador: AppTextos.monto,
                          hintText: "10.000",
                          icono: const Icon(Icons.attach_money),
                          keyboardType: TextInputType.number,
                          controller: _controladorMonto,
                          enabled: true,
                          validador: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                          ])),
                    ),
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        color: ColoresApp.verde,
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          if (_pref.cargo != "4") {
                            final puedeInsertar =
                                await verificarEstadoUsuarioCaja();
                            if (puedeInsertar == "1") {
                              SmartDialog.showToast(
                                  "¡Su caja ya cerró!... No puede insertar más movimientos por el día de hoy.");
                              return;
                            }
                          }
                          if (_formKey.currentState?.saveAndValidate() ??
                              false) {
                            final datosFormulario =
                                _formKey.currentState!.value;
                            datosFormulario['Monto'].toString();
                            debugPrint(restateFinal.toString());
                            _dialogoPreguntaAbono(
                                context, restateFinal, _clienteSeleccionado!);
                          } else {
                            SmartDialog.showToast(
                                "Por favor digite el Monto a abonar");
                            return;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                //-----------------------------------------
                if (_cargarAbonos)
                  SizedBox(
                    height: 60.h,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 2.h,
                            ),
                            Expanded(
                                child: FutureBuilder<Map<String, dynamic>>(
                              future: _futureCalcularTotal,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData) {
                                  return const Center(
                                      child: Text('No hay datos disponibles'));
                                } else {
                                  final data = snapshot.data!;
                                  final prestamo = data['prestamo'];
                                  final abonos = data['abonos'] as List;

                                  // Calcular total abonos
                                  double totalMonto =
                                      abonos.fold(0.0, (sum, item) {
                                    return sum +
                                        (double.tryParse(item['abo_cantidad']
                                                .toString()
                                                .replaceAll(".", "")) ??
                                            0.0);
                                  });

                                  // Obtener datos del préstamo
                                  double valorcuota = double.tryParse(
                                          prestamo['pres_valorCuota']
                                              .toString()
                                              .replaceAll(".", "")) ??
                                      0.0;

                                  double valorPrestamo = double.tryParse(
                                          prestamo['pres_cantidadTotal']
                                              .toString()
                                              .replaceAll(".", "")) ??
                                      0.0;

                                  String fechaPrestamo = prestamo['pres_fecha'];

                                  restateFinal = valorPrestamo - totalMonto;

                                  final NumberFormat numberFormat =
                                      NumberFormat('#,###', 'es_CO');

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Fecha prestamo: $fechaPrestamo',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Prestamo: \$${numberFormat.format(valorPrestamo)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Cuota: \$${numberFormat.format(valorcuota)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Abonos: \$${numberFormat.format(totalMonto)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Restante: \$${numberFormat.format(restateFinal)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Divider(),
                                      if (abonos.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                                'No hay abonos registrados para este préstamo.'),
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: abonos.length,
                                            itemBuilder: (context, index) {
                                              var abono = abonos[index]
                                                  as Map<String, dynamic>;
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    flex: 8,
                                                    child: ListTile(
                                                      leading:
                                                          Text('${index + 1}'),
                                                      title: Text(
                                                          'Monto: \$${FormatoMiles().formatearCantidad(abono['abo_cantidad'])}'),
                                                      subtitle: Text(
                                                          'Fecha: ${abono['abo_fecha']}'),
                                                      onTap: () {},
                                                    ),
                                                  ),
                                                  if (_pref.cargo == "4")
                                                    Expanded(
                                                        flex: 2,
                                                        child: IconButton(
                                                            onPressed:
                                                                () async {
                                                              final data =
                                                                  await Databaseservices()
                                                                      .eliminarAbono(
                                                                          abono[
                                                                              'idabonos']);
                                                              if (data) {
                                                                SmartDialog
                                                                    .showToast(
                                                                        "Abono eliminado con éxito");
                                                                setState(() {
                                                                  _futureCalcularTotal =
                                                                      _calcularTotalRecaudado();
                                                                });
                                                              } else {
                                                                SmartDialog
                                                                    .showToast(
                                                                        "No se pudo eliminar el abono");
                                                              }
                                                            },
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color: ColoresApp
                                                                  .rojoLogo,
                                                            )))
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                }
                              },
                            ))
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> _dialogoPreguntaAbono(
      BuildContext context, double restante, String idConcatenado) {
    final double montoAbono =
        double.tryParse(_controladorMonto.text.replaceAll('.', '')) ?? 0.0;

    // Separar idprestamos y idpersona
    final partes = idConcatenado.split('-');
    final idPrestamo = partes[0];
    final idPersona = partes[1];

    return showDialog(
      context: context,
      builder: (ctx) {
        final bool esAbonoCompleto = (montoAbono == restante && restante > 0);

        return AlertDialog(
          title: Text(
            esAbonoCompleto
                ? '¿Abonar y crear nuevo préstamo?'
                : 'Confirmar abono',
          ),
          content: Text(
            esAbonoCompleto
                ? 'El abono de \$${_controladorMonto.text} dejará la deuda en 0. ¿Deseas crear un nuevo préstamo de inmediato?'
                : '¿Quieres abonar \$${_controladorMonto.text}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                SmartDialog.showToast('Abono no insertado');

                Navigator.of(ctx).pop(); // Solo cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            if (esAbonoCompleto)
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  SmartDialog.showLoading(msg: 'Procesando...');
                  final exito = await _insertarAbonoPhp(idPrestamo);
                  SmartDialog.dismiss();
                  if (exito) {
                    SmartDialog.showToast('Abono registrado con éxito');
                    _resetFormulario();
                  } else {
                    SmartDialog.showToast('Error al registrar el abono');
                  }
                },
                child: const Text('Solo abonar'),
              ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                SmartDialog.showLoading(msg: 'Procesando...');
                final exito = await _insertarAbonoPhp(idPrestamo);
                SmartDialog.dismiss();
                if (exito) {
                  SmartDialog.showToast('Abono registrado con éxito');
                  if (esAbonoCompleto) {
                    Navigator.pushNamed(
                      context,
                      rutanuevoPrestamo,
                      arguments: {'idCliente': idPersona},
                    );
                  } else {
                    _resetFormulario();
                  }
                } else {
                  SmartDialog.showToast('Error al registrar el abono');
                }
              },
              child: Text(esAbonoCompleto ? 'Abonar y prestar' : 'Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _insertarAbonoPhp(String idPrestamo) async {
    try {
      String idEmpleadoSeleccionado = _pref.idUser; // Valor por defecto
      if (_pref.cargo == '3' || _pref.cargo == '4') {
        // Si hay un empleado seleccionado en el spinner y no está vacío, usarlo
        if (_rolSeleccionado != null && _rolSeleccionado!.isNotEmpty) {
          idEmpleadoSeleccionado = _rolSeleccionado!;
        }
      }
      final montoSinFormato = _controladorMonto.text.replaceAll('.', '');
      var url = Uri.parse(ApiConstants.insertarAbonoPrestamoCliente);
      final response = await http.post(url, body: {
        'idprestamo': idPrestamo,
        'idempleado': idEmpleadoSeleccionado,
        'monto': montoSinFormato,
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      SmartDialog.showToast('Error al insertar abono: $e');
      return false;
    }
  }

  void _resetFormulario() {
    setState(() {
      _formKey.currentState?.reset();
      _controladorMonto.text = '';
      _clienteController.clear();
    });
  }

  Future<Map<String, dynamic>> _calcularTotalRecaudado() async {
    if (!await Conexioninternet().isConnected()) {
      SmartDialog.showToast('No hay conexión a internet');
      return {'prestamo': {}, 'abonos': []};
    }

    if (_clienteSeleccionado == null || _clienteSeleccionado!.isEmpty) {
      return {'prestamo': {}, 'abonos': []};
    }

    List<String> partes = _clienteSeleccionado!.split('-');
    String? idPrestamo;

    try {
      if (partes.length >= 2) {
        // Formato "idPrestamo-idPersona"
        idPrestamo = partes[0];
      } else {
        // Solo tenemos idPersona
        final idPersona = partes[0];
        var urlPersona =
            Uri.parse(ApiConstants.verAbonoPrestamoEspecifico + idPersona);
        final responsePersona = await http.get(urlPersona);

        if (responsePersona.statusCode == 200) {
          final data = jsonDecode(responsePersona.body);
          if (data == null || data.isEmpty) {
            return {'prestamo': {}, 'abonos': []};
          }
          return data;
        } else {
          throw Exception('Error al cargar abonos por persona');
        }
      }

      // Consulta por idPrestamo
      var url = Uri.parse(
          ApiConstants.verAbonoPrestamoEspecifico + idPrestamo.toString());
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          return {'prestamo': {}, 'abonos': []};
        }
        return data;
      } else {
        throw Exception('Error al cargar los abonos');
      }
    } catch (e) {
      debugPrint('Error en _calcularTotalRecaudado: $e');
      return {'prestamo': {}, 'abonos': []};
    }
  }
}
