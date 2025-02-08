// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

import '../../config/routes/apis.dart';
import '../../config/routes/rutas.dart';
import '../../config/services/validacion_estado_usuario.dart';
import '../../config/shared/peferences.dart';
import '../../desing/app_medidas.dart';
import '../../desing/coloresapp.dart';
import '../../desing/textosapp.dart';
import '../widgets/appbar.dart';
import '../widgets/drawemenu.dart';
import '../widgets/textfield.dart';

class NuevoPrestamo extends StatefulWidget {
  const NuevoPrestamo({super.key});

  @override
  State<NuevoPrestamo> createState() => _NuevoPrestamoState();
}

class _NuevoPrestamoState extends BaseScreen<NuevoPrestamo> {
  final _pref = PreferenciasUsuario();
  final _formKey = GlobalKey<FormBuilderState>();

  //Controladores datos cliente
  final TextEditingController clienteIdentificacion = TextEditingController();
  final TextEditingController clienteNombre = TextEditingController();
  final TextEditingController clienteApellido = TextEditingController();
  final TextEditingController clientetelefono = TextEditingController();
  final TextEditingController clienteDireccion = TextEditingController();

  //Controladores datos prestamo
  final TextEditingController montoController = TextEditingController();
  final TextEditingController interesController = TextEditingController();
  final TextEditingController cuotasController = TextEditingController();

  // Controladores para los campos calculados
  final TextEditingController montoTotalController = TextEditingController();
  final TextEditingController cuotasDiariasController = TextEditingController();

  // Bandera para evitar bucles de formateo
  bool isFormatting = false;
  bool _isLoading = false;
  int resultado = 0;

  @override
  void initState() {
    super.initState();
    montoController.addListener(_onMontoChanged);
    interesController.addListener(_updateCampos);
    cuotasController.addListener(_updateCampos);

    // Recibir el argumento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final idCliente = args['idCliente'] as String?;
        if (idCliente != null) {
          clienteIdentificacion.text = idCliente;
        }
      }
    });
  }

  @override
  void dispose() {
    montoController.dispose();
    interesController.dispose();
    cuotasController.dispose();
    montoTotalController.dispose();
    cuotasDiariasController.dispose();
    super.dispose();
  }

  void _onMontoChanged() {
    if (isFormatting) return;
    String text = montoController.text;
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
      montoController.text = formatted;
      montoController.selection = TextSelection.fromPosition(
        TextPosition(offset: montoController.text.length),
      );
      isFormatting = false;
    }
    _updateCampos();
  }

  void _updateCampos() {
    String montoText = montoController.text.replaceAll(RegExp(r'[^\d.]'), '');
    String interesText =
        interesController.text.replaceAll(RegExp(r'[^\d.]'), '');
    String cuotasText = cuotasController.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Parsear los valores
    double monto = double.tryParse(montoText.replaceAll('.', '')) ?? 0.0;
    double interes = double.tryParse(interesText) ?? 0.0;
    int cuotas = int.tryParse(cuotasText) ?? 1;

    // Calcular el total a pagar y la cuota diaria
    double totalPagar = monto + (monto * interes / 100);
    double cuotaDiaria = totalPagar / cuotas;

    // Formatear los resultados
    final formatter = NumberFormat('#,###', 'es_CO');
    String montoTotalFormatted = formatter.format(totalPagar);
    String cuotasDiariasFormatted = formatter.format(cuotaDiaria);

    // Actualizar los campos calculados
    montoTotalController.text = montoTotalFormatted;
    cuotasDiariasController.text = cuotasDiariasFormatted;
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarPrestamos;
    return Scaffold(
      floatingActionButton: _botonFlotante(context),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child:
            TitulosAppBar(nombreRecibido: AppTextos.tituloNuevoAbonoPrestamo),
      ),
      drawer: const DrawerMenu(),
      body: _formulario(),
    );
  }

  Widget _formulario() {
    return FormBuilder(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          const Divider(),
          const Text(
            "Datos del cliente",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          WidgetTextField(
              identificador: "Identificación",
              hintText: "Numero de Documento del cliente",
              keyboardType: TextInputType.number,
              enabled: true,
              controller: clienteIdentificacion,
              suffixIcon: IconButton(
                  onPressed: () async {
                    final db = Databaseservices();
                    final idCliente = clienteIdentificacion.text.trim();

                    if (idCliente.isEmpty) {
                      SmartDialog.showToast("Identificación inválida");
                      return;
                    }
                    // datosCliente devuelve una List<Map<String, dynamic>>
                    final List<Map<String, dynamic>> listaDeClientes =
                        await db.datosCliente(idCliente);
                    if (listaDeClientes.isNotEmpty) {
                      final cliente =
                          listaDeClientes.first; // Toma el primer elemento
                      clienteNombre.text = cliente['per_nombre'] ?? '';
                      clienteApellido.text = cliente['per_apellido'] ?? '';
                      clientetelefono.text = cliente['per_telefono'] ?? '';
                      clienteDireccion.text = cliente['per_direccion'] ?? '';
                    } else {
                      SmartDialog.showToast("Cliente no encontrado");
                    }
                  },
                  icon: const Icon(Icons.search)),
              validador: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ])),
          Row(
            children: [
              Expanded(
                child: WidgetTextField(
                    identificador: "Nombre",
                    hintText: "Pepeito ",
                    keyboardType: TextInputType.name,
                    controller: clienteNombre,
                    enabled: true,
                    validador: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ])),
              ),
              Expanded(
                child: WidgetTextField(
                    identificador: "Apellido",
                    hintText: "Perez",
                    keyboardType: TextInputType.name,
                    controller: clienteApellido,
                    enabled: true,
                    validador: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ])),
              ),
            ],
          ),
          WidgetTextField(
            identificador: "Telefono",
            hintText: "311 123 4567",
            maxLength: 10,
            keyboardType: TextInputType.number,
            icono: const Icon(Icons.phone),
            controller: clientetelefono,
            validador: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            enabled: true,
          ),
          WidgetTextField(
            identificador: "Direccion",
            hintText: "Barrio, Calle, Carrera",
            keyboardType: TextInputType.streetAddress,
            icono: const Icon(Icons.location_city),
            controller: clienteDireccion,
            validador: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            enabled: true,
          ),
          const Divider(),
          const Text("Datos del prestamo",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: WidgetTextField(
                    identificador: "Monto",
                    hintText: "100.000",
                    icono: const Icon(Icons.attach_money),
                    keyboardType: TextInputType.number,
                    controller: montoController,
                    enabled: true,
                    validador: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ])),
              ),
              Expanded(
                child: WidgetTextField(
                    identificador: "Interes",
                    hintText: "5",
                    icono: const Icon(Icons.percent),
                    keyboardType: TextInputType.number,
                    controller: interesController,
                    enabled: true,
                    validador: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ])),
              ),
            ],
          ),
          WidgetTextField(
            identificador: "Cuotas",
            hintText: "30",
            maxLength: 3,
            keyboardType: TextInputType.number,
            icono: const Icon(Icons.format_list_numbered),
            controller: cuotasController,
            validador: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
            enabled: true,
          ),
          Row(
            children: [
              Expanded(
                child: WidgetTextField(
                  identificador: "Monto total",
                  hintText: "0.00",
                  valorPorDefecto: "0.00",
                  controller: montoTotalController,
                  icono: const Icon(Icons.calculate),
                  enabled: false, // Campo no editable
                ),
              ),
              Expanded(
                child: WidgetTextField(
                  identificador: "Cuotas diarias",
                  hintText: "0.00",
                  valorPorDefecto: "0.00",
                  icono: const Icon(Icons.calendar_today),
                  controller: cuotasDiariasController,
                  enabled: false, // Campo no editable
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: FormBuilderSwitch(
              activeColor: ColoresApp.verde,
              inactiveThumbColor: ColoresApp.rojo,
              name: 'seguro',
              initialValue: false,
              title: const Text('¿Agregar seguro?',
                  style: TextStyle(color: ColoresApp.negro, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _botonFlotante(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: ColoresApp.verde,
      foregroundColor: ColoresApp.blanco,
      onPressed: _isLoading
          ? null // Deshabilita el botón si ya está cargando
          : () async {
              if (_pref.cargo != "4") {
                final puedeInsertar = await verificarEstadoUsuarioCaja();
                if (puedeInsertar == "1") {
                  SmartDialog.showToast(
                      "¡Su caja ya cerró!... No puede insertar más movimientos por el día de hoy.");
                  return;
                }
              }
              if (_formKey.currentState?.saveAndValidate() ?? false) {
                final datosFormulario = _formKey.currentState!.value;
                final bool isSeguroSeleccionado =
                    datosFormulario['seguro'] == true;
                Map<String, dynamic> datosPrestamo = {
                  "identificacion": datosFormulario["Identificación"],
                  "nombre": datosFormulario["Nombre"],
                  "apellido": datosFormulario["Apellido"],
                  "Telefono": datosFormulario["Telefono"],
                  "Direccion": datosFormulario["Direccion"],
                  "FechaCreacion": Databaseservices().obtenerFechaActual(),
                  'Fecha': Databaseservices().obtenerFechaActual(),
                  'Monto':
                      datosFormulario['Monto'].toString().replaceAll(".", ""),
                  'Monto total': datosFormulario['Monto total']
                      .toString()
                      .replaceAll(".", ""),
                  'Cuotas diarias': datosFormulario['Cuotas diarias']
                      .toString()
                      .replaceAll(".", ""),
                  'Cuotas': datosFormulario['Cuotas'],
                  'Interes': datosFormulario['Interes'],
                  "seguro": isSeguroSeleccionado
                      ? (double.parse(datosFormulario['Monto']
                                  .toString()
                                  .replaceAll(".", "")) *
                              0.04)
                          .toStringAsFixed(0)
                      : "0",
                };
                await _mostrarDialogoConfirmacion(context, datosPrestamo);
              }
            },
      child: const Icon(Icons.add),
    );
  }

  Future<bool> insertarPrestamo(Map<String, dynamic> datos) async {
    // Ajusta la URL a tu dominio/IP y archivo PHP
    var url = Uri.parse(ApiConstants.insertarnuevoPrestamo2);
    var cobro = PreferenciasUsuario().cobro.toString();
    // Realiza la petición POST con los datos
    final response = await http.post(
      url,
      body: {
        //------------------- Insert persona (El php ya valida si ya existe el cliente para que no genere error y solo inserta el prestamo)
        'idpe': datos['identificacion'],
        'per_nom': datos['nombre'],
        'per_ape': datos['apellido'],
        'per_gen': "No definido",
        'per_tel': datos['Telefono'],
        'per_dir': datos['Direccion'],
        'per_fecha_creacion': datos['FechaCreacion'],
        'fk_roll': "1",
        'fk_cobro': cobro,
        'fk_em': _pref.idUser,
        //------------------- Inser prestamo
        'can': datos['Monto'],
        'cant': datos['Monto total'],
        'vac': datos['Cuotas diarias'],
        'cu': datos['Cuotas'],
        'int': datos['Interes'],
        'seg': datos['seguro'],
      },
    );

    final respuesta = jsonDecode(response.body);
    // Si todo salió bien, tu PHP devolverá un JSON con algún "success": true
    if (respuesta['success'] == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<Future<bool?>> _mostrarDialogoConfirmacion(
      BuildContext context, Map<String, dynamic> datosPrestamo) async {
    final formatter = NumberFormat('#,###', 'es_CO');

    String montoFormatted =
        formatter.format(double.parse(datosPrestamo["Monto"]));
    String montoTotalFormatted =
        formatter.format(double.parse(datosPrestamo["Monto total"]));
    String cuotasDiariasFormatted =
        formatter.format(double.parse(datosPrestamo["Cuotas diarias"]));
    String seguroFormatted =
        formatter.format(double.parse(datosPrestamo["seguro"]));

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // El usuario debe presionar un botón
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '¿La información es correcta?',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Persona:'),
                Text('Identificación: ${datosPrestamo["identificacion"]}'),
                Text(
                    'Nombre: ${datosPrestamo["nombre"]} ${datosPrestamo["apellido"]}'),
                Text('Teléfono: ${datosPrestamo["Telefono"]}'),
                Text('Dirección: ${datosPrestamo["Direccion"]}'),
                const Divider(),
                const Text('Préstamo:'),
                Text('Fecha: ${datosPrestamo["Fecha"]}'),
                Text('Cantidad: \$$montoFormatted'),
                Text('Cantidad con %: \$$montoTotalFormatted'),
                Text('Cuotas diarias: \$$cuotasDiariasFormatted'),
                Text('Seguro: \$$seguroFormatted'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No, corregir',
                  style: TextStyle(color: ColoresApp.rojo)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Sí, es correcta',
                  style: TextStyle(color: ColoresApp.verde)),
              onPressed: () async {
                // en lugar de pop aquí, primero ejecutamos la inserción
                bool exito = await _crearPrestamo(context, datosPrestamo);
                // si todo sale bien, cerramos el diálogo y luego navegamos
                if (exito && mounted) {
                  //Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, rutaNavBarPrestamos);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _crearPrestamo(
      BuildContext context, Map<String, dynamic> datosPrestamo) async {
    setState(() {
      _isLoading = true;
    });
    SmartDialog.showLoading(msg: "Creando Préstamo...");

    try {
      bool exito = await insertarPrestamo(datosPrestamo);
      if (exito) {
        SmartDialog.showToast("Préstamo registrado con éxito");
        SmartDialog.dismiss();
        limpiarCampos();
        return true;
      } else {
        resultado = 3;
        SmartDialog.dismiss();
        SmartDialog.showToast("Error al registrar nuevo Préstamo");
        return false;
      }
    } catch (e) {
      SmartDialog.dismiss();
      debugPrint("Vista insertarNuevoPrestamo - Error: $e");
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void limpiarCampos() {
    _formKey.currentState?.reset();
    clienteIdentificacion.text = "";
    clienteNombre.text = "";
    clienteApellido.text = "";
    clientetelefono.text = "";
    clienteDireccion.text = "";
    montoController.text = "0";
    interesController.text = "0";
    cuotasController.text = "0";
    montoTotalController.text = "0.00";
    cuotasDiariasController.text = "0.00";
  }
}
