// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../routes/rutas.dart';
import 'databaseservices.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  final _dataBaseServices = Databaseservices();

  @override
  void initState() {
    super.initState();
    _verificarEstadoUsuario();
    verificarEstadoUsuarioCaja();
  }

  Future<void> _verificarEstadoUsuario() async {
    try {
      final nuevoEstado = await _dataBaseServices.fetchEstadoUsuario();
      if (nuevoEstado != '1') {
        Databaseservices().reiniciarDatos();
        Navigator.pushReplacementNamed(context, rutaLogin);
        SmartDialog.showToast("Usuario inactivo, contacte al administrador");
      } else {}
    } catch (e) {
      // Manejo de error
      debugPrint("Error al cargar : $e");
    }
  }

  Future<String> verificarEstadoUsuarioCaja() async {
    try {
      final nuevoEstado = await _dataBaseServices.estadoUsuarioCaja();
      if (nuevoEstado == '0') {
        return "0";
      } else {
        return "1";
      }
    } catch (e) {
      debugPrint("Error al cargar : $e");
      return "0";
    }
  }
}
