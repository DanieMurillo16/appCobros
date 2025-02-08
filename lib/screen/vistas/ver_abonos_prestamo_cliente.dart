import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/desing/coloresapp.dart';

import '../../config/services/validacion_estado_usuario.dart';

class Clientepagoabonos extends StatefulWidget {
  final String idPrestamo;

  const Clientepagoabonos({super.key, required this.idPrestamo});

  @override
  State<Clientepagoabonos> createState() => _ClientepagoabonosState();
}

class _ClientepagoabonosState extends BaseScreen<Clientepagoabonos> {
  
  Future<List<dynamic>> consultaAbonos() async {
    var url =
        Uri.parse(ApiConstants.verAbonoPrestamoEspecifico + widget.idPrestamo);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los abonos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColoresApp.blanco,
        backgroundColor: ColoresApp.rojo,
        title: const Text('Abonos del prestamo'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: consultaAbonos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay abonos en el momento.'));
          } else {
            final abonos = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 20),
                const Text("Estos son los abonos que se han hecho del prestamo"),
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
                              'Cantidad: \$${FormatoMiles().formatearCantidad(abono['abo_cantidad'])}'),
                          subtitle: Text('Fecha: ${abono['abo_fecha']}'),
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
