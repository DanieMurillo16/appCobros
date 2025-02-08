// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/providers/clienteproviders.dart';
import 'package:cobrosapp/screen/widgets/textfield.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _pref = PreferenciasUsuario();
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  TextEditingController controllerUser = TextEditingController();
  TextEditingController controllerPass = TextEditingController();

  @override
  void dispose() {
    controllerUser.dispose();
    controllerPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaLogin;
    final clienteProvider =
        Provider.of<ClienteProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                color: ColoresApp.blanco,
                padding: const EdgeInsets.all(24),
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Prestamos",
                            style: TextStyle(
                              color: ColoresApp.rojoLogo,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "JS",
                            style: TextStyle(
                              color: ColoresApp.verde,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Imagen del logo
                      const ImagenLogo(),
                      const SizedBox(height: 20),
                      // Campos de texto con estilo
                      WidgetTextField(
                        identificador: "Usuario",
                        hintText: "Usuario",
                        controller: controllerUser,
                        icono: const Icon(Icons.email),
                        validador: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                      const SizedBox(height: 15),
                      WidgetTextField(
                        identificador: "Contraseña",
                        hintText: "******",
                        controller: controllerPass,
                        campoContrasena: true,
                        keyboardType: TextInputType.number,
                        icono: const Icon(Icons.lock_outline),
                        validador: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      // Botón de iniciar sesión
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          backgroundColor: ColoresApp.rojo,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                        ),
                        onPressed: _isLoading
                            ? null // Deshabilita el botón si ya está cargando
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                if (_formKey.currentState?.saveAndValidate() ??
                                    false) {
                                  SmartDialog.showLoading(
                                      msg: "Validando credenciales...");
                                  final correo = controllerUser.text;
                                  final pass = controllerPass.text;
                                  final data = await Databaseservices()
                                      .loginIni(correo, pass);
                                  try {
                                    if (data.isNotEmpty && data != "Error") {
                                      await clienteProvider
                                          .loadAllData(_pref.idUser);
                                      Navigator.pushReplacementNamed(
                                          context, rutanuevoAbono);
                                    } else {
                                      SmartDialog.showToast(
                                          "Usuario o contraseña incorrectos");
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  } catch (e) {
                                    SmartDialog.dismiss();
                                    debugPrint("Vista login -Error: $e");
                                  } finally {
                                    SmartDialog.dismiss();
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                        child: const Text(
                          "INICIAR SESIÓN",
                          style:
                              TextStyle(fontSize: 16, color: ColoresApp.blanco),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImagenLogo extends StatelessWidget {
  const ImagenLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.w,
      width: 50.w,
      margin: const EdgeInsets.only(top: 100),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(300),
          child: Image.asset("assets/cobros.png")),
    );
  }
}
