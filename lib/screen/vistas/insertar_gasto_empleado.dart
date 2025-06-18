// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/services/conexioninternet.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:cobrosapp/screen/widgets/textfield.dart';

import 'package:http/http.dart' as http;

import '../../config/services/validacion_estado_usuario.dart';

class GastosState extends StatefulWidget {
  const GastosState({super.key});

  @override
  State<GastosState> createState() => _GastosStateState();
}

class _GastosStateState extends BaseScreen<GastosState> {
  final _formKey = GlobalKey<FormBuilderState>();

  final _pref = PreferenciasUsuario();
  final _dataBaseServices = Databaseservices();

  final TextEditingController identificacionController =
      TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  bool isFormatting = false;
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _futureMovimientos;

  // Opciones para el tipo de movimiento
  final List<String> _tiposMovimiento = [
    "Ingreso",
    "Gasto",
  ];

  // Opciones para el tipo de caja
  final List<String> _tiposCaja = [
    "Caja General",
    "Caja Diaria",
  ];

  // Lista de empleados para el dropdown
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;

  @override
  void initState() {
    super.initState();
    // Escucha cambios para formatear monto
    valorController.addListener(_onMontoChanged);
    _futureMovimientos = listaMovimientoscaja(_pref.idUser);

    // Cargar empleados si el cargo es 4
    if (_pref.cargo == '4') {
      _loadEmpleados();
    }
  }

  @override
  void dispose() {
    super.dispose();
    valorController.dispose();
    descripcionController.dispose();
    identificacionController.dispose();
  }

  Future<List<Map<String, dynamic>>> listaMovimientoscaja(
      String idConsultado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    final fecha = Databaseservices().obtenerFechaActual();
    var url = Uri.parse(
        "${ApiConstants.listaMovimientosCaja}$idConsultado&fc=$fecha");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Error en la respuesta del servidor');
      }
    } else {
      throw Exception('Error al cargar los movimientos');
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final empleados = await _dataBaseServices.fetcListaEmpleadosSpinner(_pref.cargo, _pref.cobro);
      setState(() {
        _roles = empleados;
      });
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
    }
  }

  void _onMontoChanged() {
    if (isFormatting) return;
    String text = valorController.text;
    String cleanedText = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanedText.isEmpty) return;
    double value = double.tryParse(cleanedText.replaceAll('.', '')) ?? 0.0;
    final formatter = NumberFormat('#,###', 'es_CO');
    String formatted = formatter.format(value);
    if (formatted != text) {
      isFormatting = true;
      valorController.text = formatted;
      valorController.selection = TextSelection.fromPosition(
        TextPosition(offset: valorController.text.length),
      );
      isFormatting = false;
    }
  }

  Future<bool> insertarNuevoMovimiento(Map<String, dynamic> datos) async {
    try {
      bool respuesta = await Databaseservices().insertarNuevoMovimiento(
        datos['tipo'],
        datos['valor'],
        datos['descripcion'],
        _pref.cobro,
        datos['fk'],
      );

      final bool data = respuesta;

      if (data == true) {
        SmartDialog.showToast("Movimiento registrado correctamente");
        return true;
      } else {
        SmartDialog.showToast("Error al registrar el movimiento");
        return false;
      }
    } catch (e) {
      SmartDialog.showToast("Error al registrar el movimiento");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaGastos;
    var formBuilder = FormBuilder(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          if (_pref.cargo == '4')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FormBuilderDropdown<String>(
                name: 'empleado',
                decoration: InputDecoration(
                  floatingLabelStyle: const TextStyle(color: ColoresApp.rojo),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ColoresApp.rojo,
                      width: 2.0,
                    ),
                  ),
                  labelText: 'Empleado',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: ColoresApp.rojo,
                    ),
                  ),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                items: _roles
                    .map(
                      (empleado) => DropdownMenuItem(
                        value: empleado['fk_roll'].toString(),
                        child: Text(empleado['nombreCompleto']),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value;
                  });
                },
              ),
            ),
          // Spinner para tipo de movimiento
          FormBuilderDropdown<String>(
            name: 'tipoMovimiento',
            focusColor: ColoresApp.rojo,
            decoration: InputDecoration(
              hintText: 'Seleccione tipo de movimiento',
              floatingLabelStyle: const TextStyle(color: ColoresApp.rojo),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColoresApp.rojo,
                  width: 2.0,
                ),
              ),
              labelText: 'Tipo de Movimiento',
              hint: const Text('Seleccione tipo de movimiento'),
              border: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: ColoresApp.rojo,
                ),
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            items: _tiposMovimiento
                .map(
                  (tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          // Spinner para tipo de caja (solo para cargo 4)
          if (_pref.cargo == '4')
            FormBuilderDropdown<String>(
              name: 'tipoCaja',
              focusColor: ColoresApp.rojo,
              decoration: InputDecoration(
                floatingLabelStyle: const TextStyle(color: ColoresApp.rojo),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColoresApp.rojo,
                    width: 2.0,
                  ),
                ),
                labelText: 'Tipo de Caja',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: ColoresApp.rojo,
                  ),
                ),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
              items: _tiposCaja
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 10),
          // Campo para valor del gasto/ingreso
          WidgetTextField(
            identificador: "Valor",
            hintText: "Valor del movimiento",
            keyboardType: TextInputType.number,
            controller: valorController,
            icono: const Icon(Icons.attach_money),
            validador: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 10),
          // Campo para descripción
          WidgetTextField(
            identificador: "Descripción",
            hintText: "Descripción del gasto/ingreso",
            maxLength: 30,
            keyboardType: TextInputType.text,
            controller: descripcionController,
            icono: const Icon(Icons.description),
            validador: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColoresApp.rojo,
              ),
              onPressed: _isLoading
                  ? null // Deshabilita el botón si ya está cargando
                  : () async {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        setState(() {
                          _isLoading = true;
                        });

                        if (_pref.cargo != "4") {
                          final puedeInsertar =
                              await verificarEstadoUsuarioCaja();
                          if (puedeInsertar == "1") {
                            SmartDialog.showToast(
                                "¡Su caja ya cerró!... No puede insertar más movimientos por el día de hoy.");
                            return;
                          }
                        }
                        SmartDialog.showLoading(
                            msg: "Insertando movimiento...");
                        final formData = _formKey.currentState!.value;
                        // Obtener el valor y ajustarlo según el tipo de movimiento
                        String valor =
                            valorController.text.trim().replaceAll(".", "");
                        if (formData['tipoMovimiento'] == "Gasto") {
                          valor =
                              "-$valor"; // Convertir a negativo si es un gasto
                        }
                        if (_pref.cargo == '4') {
                          if (formData['tipoCaja'] == "Caja General") {
                            final data = await Databaseservices()
                                .cerrarCajaCobrador(
                                  formData['empleado'],
                                   valor,
                                   _pref.cobro,
                                    descripcion:
                                        descripcionController.text.trim());
                            if (data['success'] == true) {
                              limpiarCampos();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Movimiento registrado en caja general')),
                              );
                              setState(() {
                                _isLoading = false;
                              });
                              SmartDialog.dismiss();
                              return;
                            } else {
                              SmartDialog.showToast(
                                  data['error'] ?? 'Error al insertar');
                              setState(() {
                                _isLoading = false;
                              });
                              SmartDialog.dismiss();

                              return;
                            }
                          }
                        }
                        final info = {
                          "tipo": formData['tipoMovimiento'] == "Ingreso"
                              ? "1"
                              : "2",
                          "valor":
                              valorController.text.trim().replaceAll(".", ""),
                          "descripcion": descripcionController.text.trim(),
                          "fk": _pref.idUser,
                        };
                        // Agregar empleado seleccionado si el cargo es 4
                        if (_pref.cargo == '4' && _rolSeleccionado != null) {
                          info['fk'] = _rolSeleccionado!;
                        }
                        final bool registrado =
                            await insertarNuevoMovimiento(info);
                        SmartDialog.dismiss();
                        if (registrado) {
                          limpiarCampos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Movimiento registrado')),
                          );
                          setState(() {
                            _futureMovimientos =
                                listaMovimientoscaja(_pref.idUser);

                            _isLoading = false;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Error al registrar el movimiento')),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              child: const Text('Registrar',
                  style: TextStyle(fontSize: 15, color: ColoresApp.blanco))),
          const SizedBox(height: 20),
          const Divider(),
          // FutureBuilder para mostrar la lista de movimientos
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureMovimientos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text('Error al cargar los movimientos'));
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
                          FormatoMiles()
                              .formatearCantidad(movimiento['movi_valor']),
                          style: const TextStyle(
                            fontSize: 16,
                            color: ColoresApp.rojo,
                            fontWeight: FontWeight.bold,
                          )),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.gastosTitulo),
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          Expanded(
            child: formBuilder,
          )
        ],
      ),
    );
  }

  void limpiarCampos() {
    _formKey.currentState?.reset();
    valorController.clear();
    descripcionController.clear();
  }
}
