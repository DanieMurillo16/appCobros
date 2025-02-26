import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:cobrosapp/config/routes/apis.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/desing/coloresapp.dart';

import '../../config/services/databaseservices.dart';
import '../../config/services/validacion_estado_usuario.dart';
import '../../config/shared/peferences.dart';

class Clientepagoabonos extends StatefulWidget {
  final String idPrestamo;

  const Clientepagoabonos({super.key, required this.idPrestamo});

  @override
  State<Clientepagoabonos> createState() => _ClientepagoabonosState();
}

class _ClientepagoabonosState extends BaseScreen<Clientepagoabonos> {
  final _pref = PreferenciasUsuario();

  Future<List<dynamic>> consultaAbonos() async {
    if (!mounted) return[];
    var url =
        Uri.parse(ApiConstants.verAbonoPrestamoEspecifico + widget.idPrestamo);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['abonos'] ?? []; // Extraer solo la lista de abonos
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
            double sumaDinero = abonos.fold(0.0, (sum, cliente) {
            return sum +
                (double.tryParse(cliente['abo_cantidad'].toString()) ?? 0.0);
          });
            return Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                    "Estos son los abonos que se han hecho del prestamo"),
                const SizedBox(height: 20),
                Text(
                    "Total recogido: ${FormatoMiles().formatearCantidad(sumaDinero.toString())}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Divider(),
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
                          trailing: _pref.cargo == "4"
                              ? IconButton(
                                  onPressed: () async {
                                    final data = await Databaseservices()
                                        .eliminarAbono(abono['idabonos']);
                                    if (data) {
                                      SmartDialog.showToast(
                                          "Abono eliminado con éxito");
                                      // Refrescar la vista
                                      setState(() {
                                        consultaAbonos();
                                      });
                                    } else {
                                      SmartDialog.showToast(
                                          "No se pudo eliminar el abono");
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: ColoresApp.rojoLogo,
                                  ),
                                )
                              : null,
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
