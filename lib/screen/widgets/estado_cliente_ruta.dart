import 'package:flutter/material.dart';

import '../../desing/coloresapp.dart';

class ClienteListItem extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final int index;
  final Function(int, bool) onEstadoChanged;
  final Function(Map<String, dynamic>) onAbonoTap;
  final bool isDragging;

  const ClienteListItem({
    super.key,
    required this.cliente,
    required this.index,
    required this.onEstadoChanged,
    required this.onAbonoTap,
    this.isDragging = false,
  });

  @override
  State<ClienteListItem> createState() => _ClienteListItemState();
}

class _ClienteListItemState extends State<ClienteListItem> {
  bool _estado = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.cliente['estado'] ?? false;
  }

  @override
  void didUpdateWidget(ClienteListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Esta línea es crucial: actualiza el estado local cuando cambia desde fuera
    if (oldWidget.cliente['estado'] != widget.cliente['estado']) {
      setState(() {
        _estado = widget.cliente['estado'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: widget.isDragging ? ColoresApp.azulRey : ColoresApp.blanco,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.grisClarito,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        selectedColor: ColoresApp.azulRey,
        leading: Switch(
          activeColor: ColoresApp.verde,
          inactiveThumbColor: ColoresApp.rojo,
          value: _estado,
          onChanged: (value) {
            setState(() {
              _estado = value;
            });
            widget.onEstadoChanged(widget.index, value);
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        title: Text(
          '${widget.cliente['per_nombre'].toString().toUpperCase()} ${widget.cliente['per_apellido'].toString().toUpperCase()}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              color: ColoresApp.verde,
              icon: const Icon(Icons.add_box),
              onPressed: () => widget.onAbonoTap(widget.cliente),
            ),
          ],
        ),
      ),
    );
  }
}