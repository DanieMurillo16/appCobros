import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../desing/coloresapp.dart';

class EmpleadoListItem extends StatefulWidget {
  final Map<String, dynamic> empleado;
  final Function(Map<String, dynamic>, String) onEstadoChanged;

  const EmpleadoListItem({
    Key? key,
    required this.empleado,
    required this.onEstadoChanged,
  }) : super(key: key);

  @override
  State<EmpleadoListItem> createState() => _EmpleadoListItemState();
}

class _EmpleadoListItemState extends State<EmpleadoListItem> {
  late bool _estadoActivo;

  @override
  void initState() {
    super.initState();
    _estadoActivo = widget.empleado['usu_estado'].toString() == "1";
  }

  @override
  void didUpdateWidget(EmpleadoListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empleado['usu_estado'] != widget.empleado['usu_estado']) {
      _estadoActivo = widget.empleado['usu_estado'].toString() == "1";
    }
  }

  String _obtenerNombreCargo(dynamic roll) {
    final rolNumero = int.tryParse(roll.toString());
    switch (rolNumero) {
      case 2:
        return "Cobrador";
      case 3:
        return "Supervisor";
      case 4:
        return "Administrador";
      default:
        return "Otro (Rol: $roll)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleado = widget.empleado;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ColoresApp.verde,
          child: Text(
            empleado['per_nombre'][0].toString().toUpperCase(),
            style: const TextStyle(color: ColoresApp.blanco),
          ),
        ),
        title: Text(
          '${empleado['per_nombre']} ${empleado['per_apellido']}',
          style: const TextStyle(color: ColoresApp.negro),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Text(
              'Estado: ${_estadoActivo ? "Activo" : "Inactivo"}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
            Text(
              'Cedula: ${empleado['idpersona']}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
            Text(
              'Cargo: ${_obtenerNombreCargo(empleado['fk_roll'])}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
            GestureDetector(
              onTap: () async {
                final phoneNumber = empleado['per_telefono']
                    .toString()
                    .replaceAll(RegExp(r'[^\d+]'), '');

                final Uri phoneUri = Uri.parse('tel:+57$phoneNumber');
                try {
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri,
                        mode: LaunchMode.externalApplication);
                  } else {
                    SmartDialog.showToast(
                        'No se pudo abrir el marcador telefónico');
                  }
                } catch (e) {
                  SmartDialog.showToast('Error: ${e.toString()}');
                }
              },
              child: Row(
                children: [
                  const Text(
                    'Teléfono: ',
                    style: TextStyle(color: ColoresApp.negro),
                  ),
                  // Espacio entre el número y el icono
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: ColoresApp.rojoLogo,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${empleado['per_telefono']}',
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
              'Fecha de registro: ${empleado['per_fecha_creacion']}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
            const Divider(),
            Text(
              'Usuario: ${empleado['usu_nombre']}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
            Text(
              'Contra: ${empleado['us_contra']}',
              style: const TextStyle(color: ColoresApp.negro),
            ),
          ],
        ),
        trailing: Switch(
          value: _estadoActivo,
          onChanged: (bool value) async {
            final nuevoEstado = value ? '1' : '0';

            // Actualizar estado local inmediatamente para mejor UX
            setState(() {
              _estadoActivo = value;
            });

            try {
              // Llamar al callback para actualizar datos
              widget.onEstadoChanged(empleado, nuevoEstado);
            } catch (e) {
              // Si hay error, revertir al estado anterior
              setState(() {
                _estadoActivo = !value;
              });
              SmartDialog.showToast('Error al actualizar estado: $e');
            }
          },
        ),
      ),
    );
  }
}
