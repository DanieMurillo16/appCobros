// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/conexioninternet.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/services/validacion_estado_usuario.dart';
import '../widgets/spinner.dart';

class VerListaPrestamos extends StatefulWidget {
  const VerListaPrestamos({super.key});

  @override
  State<VerListaPrestamos> createState() => _VerListaPrestamosState();
}

class _VerListaPrestamosState extends BaseScreen<VerListaPrestamos> {
  final _pref = PreferenciasUsuario();
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;

  Future<List<dynamic>> fetchListaPrestamos() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexion a internet');
    }
    final idConsultado =
        (_pref.cargo == '4' || _pref.cargo == '3') && _rolSeleccionado != null
            ? _rolSeleccionado!
            : _pref.idUser;
    final fecha = Databaseservices().obtenerFechaActual();
    var url = Uri.parse(
        "${ApiConstants.listaPrestamosNuevos}$idConsultado&fc=$fecha");
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
    if (_pref.cargo == '4' || _pref.cargo == '3') {
      _loadEmpleados();
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final empleados = await Databaseservices().fetchEmpleados(_pref.cargo);
      setState(() {
        _roles = empleados;
      });
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
    }
  }

@override
Widget build(BuildContext context) {
  _pref.ultimaPagina = rutaNavBarPrestamos;
  final cargoEmpleado = _pref.cargo;
  return Scaffold(
    appBar: const PreferredSize(
      preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
      child: TitulosAppBar(nombreRecibido: AppTextos.tituloAbonoPrestamo),
    ),
    drawer: const DrawerMenu(),
    body: Column(
      children: [
        if (cargoEmpleado == '4' || cargoEmpleado == '3')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SpinnerEmpleados(
              empleados: _roles,
              valorSeleccionado: _rolSeleccionado,
              valueid: "fk_roll",
              nombreCompleto: "nombreCompleto",
              onChanged: (value) {
                setState(() {
                  _rolSeleccionado = value;
                  fetchListaPrestamos();
                });
              },
            ),
          ),
        Expanded(child: listaPrestamos()),
      ],
    ),
  );
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
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Column(
                children: [
                  Card(
                    elevation: 5,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
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
                          const Divider(),
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
                          const Divider(),
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
    );
  }
}
