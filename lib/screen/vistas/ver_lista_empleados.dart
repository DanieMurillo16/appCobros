// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/conexioninternet.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/validacion_estado_usuario.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:url_launcher/url_launcher.dart';

class EmpleadosLista extends StatefulWidget {
  const EmpleadosLista({super.key});

  @override
  State<EmpleadosLista> createState() => _EmpleadosListaState();
}

class _EmpleadosListaState extends BaseScreen<EmpleadosLista> {
  final _pref = PreferenciasUsuario();

  Future<List<dynamic>> fetchClientes() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      // Lanza una excepción si no hay internet
      throw Exception('No tienes conexion a internet');
    }

    var url = Uri.parse(ApiConstants.listaEmpleados);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarEstadoUsuario();
  }

  Future<void> _verificarEstadoUsuario() async {
    try {
      final nuevoEstado = await Databaseservices().fetchEstadoUsuario();
      if (nuevoEstado != "1") {
        Databaseservices().reiniciarDatos();
        Navigator.pushReplacementNamed(context, rutaLogin);
      }
    } catch (e) {
      debugPrint("Error al cargar : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarUsuarios;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloListaUsuarios),
      ),
      drawer: const DrawerMenu(),
      body: FutureBuilder<List<dynamic>>(
        future: fetchClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
                child: Text(
                    textAlign: TextAlign.center, AppTextos.nohayInternetVC));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text(AppTextos.nohayClientesVC));
          } else {
            final clientes = snapshot.data!;
            return ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Column(
                  children: [
                    Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ColoresApp.verde,
                          child: Text(
                            cliente['per_nombre'][0].toString().toUpperCase(),
                            style: const TextStyle(color: ColoresApp.blanco),
                          ),
                        ),
                        title: Text(
                          '${cliente['per_nombre']} ${cliente['per_apellido']}',
                          style: const TextStyle(color: ColoresApp.negro),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text(
                              'Estado: ${cliente['usu_estado'] == "1" ? "Activo" : "Inactivo"}',
                              style: const TextStyle(color: ColoresApp.negro),
                            ),
                            Text(
                              'Cargo: ${cliente['fk_roll'] == "2" ? "Cobrador" : cliente['fk_roll'] == '3' ? 'Supervisor' : cliente['fk_roll'] == '4' ? 'Administrador' : 'Otro'}',
                              style: const TextStyle(color: ColoresApp.negro),
                            ),
                            GestureDetector(
                              onTap: () async {
                                // Limpiamos el número de teléfono de espacios y caracteres especiales
                                final phoneNumber = cliente['per_telefono']
                                    .toString()
                                    .replaceAll(RegExp(r'[^\d+]'), '');

                                final Uri phoneUri =
                                    Uri.parse('tel:+57$phoneNumber');
                                try {
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'No se pudo abrir el marcador telefónico'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  const Text(
                                    'Teléfono: ',
                                    style: TextStyle(color: ColoresApp.negro),
                                  ),
                                  Text(
                                    '${cliente['per_telefono']}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      decoration: TextDecoration.underline,
                                      decorationColor: ColoresApp.rojoLogo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Fecha de registro: ${cliente['per_fecha_creacion']}',
                              style: const TextStyle(color: ColoresApp.negro),
                            ),
                            const Divider(),
                            Text(
                              'Usuario: ${cliente['usu_nombre']}',
                              style: const TextStyle(color: ColoresApp.negro),
                            ),
                            Text(
                              'Contra: ${cliente['us_contra']}',
                              style: const TextStyle(color: ColoresApp.negro),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: cliente['usu_estado'] == '1',
                              onChanged: (bool value) async {
                                final nuevoEstado = value ? '1' : '0';
                                try {
                                  await Databaseservices()
                                      .actualizarEstadoEmpleado(
                                    // Se envía el usuario y el nuevo estado
                                    cliente['usu_nombre'].toString(),
                                    nuevoEstado,
                                  );
                                  // Actualiza el estado localmente para reflejar cambios
                                  setState(() {
                                    cliente['usu_estado'] = nuevoEstado;
                                  });
                                  SmartDialog.showToast('Estado actualizado');
                                } catch (e) {
                                  SmartDialog.showToast(
                                      'Error al actualizar estado: $e');
                                  debugPrint('Error al actualizar estado: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
