// ignore_for_file: unused_element, unused_field, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sizer/sizer.dart';
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/validacion_estado_usuario.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:cobrosapp/screen/widgets/textfield.dart';
import 'package:http/http.dart' as http;

class RegistrarUsuario extends StatefulWidget {
  const RegistrarUsuario({super.key});

  @override
  State<RegistrarUsuario> createState() => _RegistrarUsuarioState();
}

class _RegistrarUsuarioState extends BaseScreen<RegistrarUsuario> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dataBaseServices = Databaseservices();
  final _pref = PreferenciasUsuario();

  //Controladores datos cliente
  final TextEditingController clienteIdentificacion = TextEditingController();
  final TextEditingController clienteNombre = TextEditingController();
  final TextEditingController clienteApellido = TextEditingController();
  final TextEditingController clientetelefono = TextEditingController();
  final TextEditingController clienteDireccion = TextEditingController();

  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRolesFromPhp();
  }

  void _limpiarCampos() {
    setState(() {
      _formKey.currentState?.reset();
    });
  }

  // 1. Cargar clientes desde PHP
  Future<void> _fetchRolesFromPhp() async {
    try {
      final empleados = await _dataBaseServices.fetchRolesSpinnerFromPhp();
      setState(() {
        _roles = empleados;
      });
    } catch (e) {
      debugPrint("Error al cargar: $e");
    }
  }

  FormBuilderDropdown<String> botonListaClientes() {
    return FormBuilderDropdown<String>(
      name: "rol",
      decoration: InputDecoration(
        hintText: "Seleccione el Rol",
        labelText: "Rol usuario",
        labelStyle: const TextStyle(color: ColoresApp.negro),
        focusColor: ColoresApp.rojoLogo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColoresApp.rojoLogo,
            width: 2.0,
          ),
        ),
        floatingLabelStyle: const TextStyle(color: ColoresApp.rojoLogo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
      items: _roles
          .map<DropdownMenuItem<String>>((cliente) => DropdownMenuItem<String>(
                value: cliente['idrol'], // Almacena idrol como valor
                child:
                    Text(cliente['nombreCompleto']), // Muestra nombre del rol
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _rolSeleccionado = value;
        });
      },
    );
  }

  Future<bool> insertarUsuarioNuevo(Map<String, dynamic> datos) async {
    try {
      var url = Uri.parse(ApiConstants.insertarnuevoEmpleado);

      // Crear usuario de forma segura
      var nombre = datos['nombre'].toString();
      var usuario =
          nombre.length >= 3 ? nombre.substring(0, 3) : nombre.padRight(3, 'x');

      usuario += Databaseservices().aleatorio().toString().substring(0, 5);
      var contra = Databaseservices().aleatorio().toString();
      var fecha = Databaseservices().obtenerFechaActual().toString();
      var cobro = PreferenciasUsuario().cobro.toString();

      final response = await http.post(
        url,
        body: {
          'idpe': datos['identificacion'],
          'per_nom': datos['nombre'],
          'per_ape': datos['apellido'],
          'per_gen': "No definido",
          'per_tel': datos['Telefono'],
          'per_dir': datos['Direccion'],
          'per_fecha_creacion': fecha,
          'fk_roll': datos['rol'],
          'fk_cobro': cobro,
          'usu_nom': usuario,
          'usu_con': contra,
        },
      );

      final respuesta = jsonDecode(response.body);
      return respuesta['success'] == true;
    } catch (e) {
      debugPrint("Error al insertar usuario: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarUsuarios;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Crear empleado'),
        backgroundColor: ColoresApp.verde,
        foregroundColor: ColoresApp.blanco,
        onPressed: _isLoading
            ? null // Deshabilita el botón si ya está cargando
            : () async {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  setState(() {
                    _isLoading = true;
                  });
                  SmartDialog.showLoading(msg: "Creando Usuario");
                  final datosFormulario = _formKey.currentState!.value;
                  debugPrint(datosFormulario.toString());
                  Map<String, dynamic> datosPrestamo = {
                    "rol": _rolSeleccionado.toString(),
                    "identificacion": datosFormulario["Identificacion"],
                    "nombre": datosFormulario["Nombre"],
                    "apellido": datosFormulario["Apellido"],
                    "Telefono": datosFormulario["Telefono"],
                    "Direccion": datosFormulario["Direccion"],
                  };
                  try {
                    bool exito = await insertarUsuarioNuevo(datosPrestamo);
                    if (exito) {
                      SmartDialog.showToast("Usuario Registrado");
                      SmartDialog.dismiss();
                      _limpiarCampos();
                      Navigator.pushReplacementNamed(
                          context, rutaNavBarUsuarios);
                    } else {
                      SmartDialog.dismiss();
                      SmartDialog.showToast("Error al registrar");
                    }
                  } catch (e) {
                    SmartDialog.dismiss();
                    debugPrint("Vista insertarnuevoEmpleado - Error: $e");
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
      ),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.usuarioRegistrar),
      ),
      drawer: const DrawerMenu(),
      body: SingleChildScrollView(
        child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 2.h,
                ),
                const Text(
                  "Datos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: botonListaClientes(),
                ),
                WidgetTextField(
                    identificador: "Identificacion",
                    hintText: "Numero de Documento",
                    maxLength: 10,
                    keyboardType: TextInputType.number,
                    controller: clienteIdentificacion,
                    icono: const Icon(Icons.badge),
                    validador: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ])),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 10.w,
                        height: 10.h,
                        child: WidgetTextField(
                            identificador: "Nombre",
                            hintText: "Pepeito ",
                            icono: const Icon(Icons.person),
                            keyboardType: TextInputType.name,
                            controller: clienteNombre,
                            enabled: true,
                            validador: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ])),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: 10.w,
                        height: 10.h,
                        child: WidgetTextField(
                            identificador: "Apellido",
                            hintText: "Perez",
                            icono: const Icon(Icons.person_2_outlined),
                            keyboardType: TextInputType.name,
                            controller: clienteApellido,
                            enabled: true,
                            validador: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ])),
                      ),
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
                  maxLength: 35,
                  keyboardType: TextInputType.streetAddress,
                  icono: const Icon(Icons.location_city),
                  controller: clienteDireccion,
                  validador: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  enabled: true,
                ),
              ],
            )),
      ),
    );
  }
}
