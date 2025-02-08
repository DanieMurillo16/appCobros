import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/desing/coloresapp.dart';

import '../../config/services/validacion_estado_usuario.dart';

class HistorialCierres extends StatefulWidget {
  final String idPersona;

  const HistorialCierres({super.key, required this.idPersona});

  @override
  State<HistorialCierres> createState() => _HistorialCierresState();
}

class _HistorialCierresState extends BaseScreen<HistorialCierres> {
  Future<List<dynamic>> consultarCierresCaja() async {
    var url = Uri.parse(ApiConstants.historialCierres + widget.idPersona);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los cierres de caja');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColoresApp.blanco,
        backgroundColor: ColoresApp.rojo,
        title: const Text('Historial de cierres de caja'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: consultarCierresCaja(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay historial en el momento.'));
          } else {
            final abonos = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 20),
                const Text("Estos son los cierres que se han hecho."),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: abonos.length,
                    itemBuilder: (context, index) {
                      final abono = abonos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            foregroundColor: ColoresApp.blanco,
                            backgroundColor: ColoresApp.verde,
                            child: Text((index + 1).toString()),
                          ),
                          title: Text(
                              'Cantidad: \$${FormatoMiles().formatearCantidad(abono['caja_cantidad'])}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${abono['caja_fecha']}'),
                              Text('Descripción: ${abono['caja_descripcion']}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
