import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../desing/coloresapp.dart';

class TitulosAppBar extends StatefulWidget {
  final String? nombreRecibido;
  const TitulosAppBar({super.key, this.nombreRecibido});

  @override
  State<TitulosAppBar> createState() => _TitulosAppBarState();
}

class _TitulosAppBarState extends State<TitulosAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      toolbarHeight: 30.w,
      leading: Builder(
        builder: (context) =>
            IconButton(
              icon: const Icon(Icons.menu, color: ColoresApp.blanco),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Abre el Drawer de la vista actual
              },
            ),
      ),
      backgroundColor: ColoresApp.
      rojo,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                " ${widget.nombreRecibido}",
                style: const TextStyle(color: ColoresApp.blanco),
              ),
            ),
            const SizedBox(width: 10),

          ],
        ),
      ),
    );
  }
}

class ContainerHeaderIcon extends StatelessWidget {
  final IconButton iconButton;
  final EdgeInsets? configMargin;
  final Color? color;
  const ContainerHeaderIcon(
      {super.key, required this.iconButton, this.configMargin, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      margin: configMargin,
      decoration: BoxDecoration(
        color: color?? ColoresApp.blanco,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: iconButton,
    );
  }
}
