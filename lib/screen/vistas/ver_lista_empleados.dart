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
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';

import '../widgets/estado_empleado.dart';

class EmpleadosLista extends StatefulWidget {
  const EmpleadosLista({super.key});

  @override
  State<EmpleadosLista> createState() => _EmpleadosListaState();
}

class _EmpleadosListaState extends BaseScreen<EmpleadosLista> {
  final _pref = PreferenciasUsuario();

  Future<List<dynamic>> listaEmpleados() async {
    if (!mounted) return [];
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      // Lanza una excepción si no hay internet
      throw Exception('No tienes conexion a internet');
    }
    var url = Uri.parse('${ApiConstants.listaEmpleados}${_pref.cobro}');
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
        future: listaEmpleados(),
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
                return EmpleadoListItem(
                  empleado: cliente,
                  onEstadoChanged: (empleado, nuevoEstado) async {
                    try {
                      // Actualizar en la base de datos sin actualizar toda la vista
                      await _actualizarEstadoEmpleado(
                        empleado['usu_nombre'].toString(),
                        nuevoEstado,
                      );
                      // Actualizar la lista local sin llamar a setState
                      empleado['usu_estado'] = nuevoEstado;
                      SmartDialog.showToast('Estado actualizado');
                    } catch (e) {
                      SmartDialog.showToast('Error al actualizar estado: $e');
                      debugPrint('Error al actualizar estado: $e');
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _actualizarEstadoEmpleado(
      String nombreUsuario, String nuevoEstado) async {
    if (!mounted) return;
    await Databaseservices().actualizarEstadoEmpleado(
      nombreUsuario,
      nuevoEstado,
    );
  }
}
