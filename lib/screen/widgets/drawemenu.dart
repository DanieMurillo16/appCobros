import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../../config/routes/rutas.dart';
import '../../config/shared/peferences.dart';
import '../../desing/coloresapp.dart';
import '../../desing/textosapp.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final _pref = PreferenciasUsuario();

  String nombre = "";
  String cargo = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  void _cargarDatosUsuario() {
    setState(() {
      cargo = _pref.cargo;
      nombre = _pref.nombre;
    });
  }

// ...existing code...
  @override
  Widget build(BuildContext context) {
    final cargoEmpleado =
        _pref.cargo; // '2' Cobrador, '3' Supervisor, '4' Admin

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado
            EncabezaDrawer(nombre: nombre, correo: cargo),
            // 1) ruta para cualquier rol
            menuItem(
              context,
              "Rutas del Cobrador",
              Icons.route,
              rutaCobrador,
              ColoresApp.rojo,
            ),
            const LineasDivisoras(),
            // 2) Abono Prestamo => accesible para 2, 3, 4 (usa if necesario si quieres filtrar)
            menuItem(
              context,
              AppTextos.abonoPrestamoVD,
              Icons.add_box,
              rutanuevoAbono,
              ColoresApp.verde,
            ),
            const LineasDivisoras(),
            // 3) Nuevo Prestamo => accesible para 2, 3, 4
            menuItem(
              context,
              AppTextos.nuevoPrestamoVD,
              Icons.person_add,
              rutaNavBarPrestamos,
              ColoresApp.rojo,
            ),
            const LineasDivisoras(),
            // 4) Clientes => accesible para 2, 3, 4
            menuItem(
              context,
              AppTextos.clienteVD,
              Icons.groups,
              rutaNavBarClientes,
              ColoresApp.verde,
            ),
            const LineasDivisoras(),

            // 5) Caja => accesible para 2, 3, 4
            menuItem(
              context,
              AppTextos.cajaVD,
              Icons.event_note,
              rutaCaja,
              ColoresApp.rojo,
            ),
            // 7) Usuarios => solo para cargo 4
            if (cargoEmpleado == '4') ...[
              const LineasDivisoras(),
              menuItem(
                context,
                AppTextos.usuariosVD,
                Icons.engineering,
                rutaNavBarUsuarios,
                ColoresApp.verde,
              ),
              const LineasDivisoras(),
              menuItem(
                context,
                "Rendimiento",
                Icons.currency_exchange,
                rutaRendimiento,
                ColoresApp.verde,
              ),
            ],
            const LineasDivisoras(),
            menuItem(
              context,
              "Gastos",
              Icons.money_off,
              rutaGastos,
              ColoresApp.rojo,
            ),
            const LineasDivisoras(),
            // Cerrar sesión, siempre visible
            menuItem(
              context,
              "Cerrar Sesion",
              Icons.logout_outlined,
              rutaLogin,
              ColoresApp.rojo,
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(
    BuildContext context,
    String nombre,
    IconData icono,
    String vista,
    Color iconColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (vista == rutaLogin) {
            SmartDialog.showToast(AppTextos.cerradoSesionVD);
            _pref.ultimaPagina = rutaLogin;
            _pref.nombre = "";
            _pref.telefono = "";
            _pref.idUser = "";
            _pref.cargo = "";
            _pref.estado = "";
            _pref.cobro = "";
            Navigator.pushReplacementNamed(context, rutaLogin);
          } else {
            Navigator.pushReplacementNamed(context, vista);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(
                icono,
                size: 28,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EncabezaDrawer extends StatelessWidget {
  final String nombre;
  final String correo;
  const EncabezaDrawer({
    super.key,
    required this.nombre,
    required this.correo,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColoresApp.rojo, ColoresApp.rojo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage:
                AssetImage('assets/perfil.jpg'), // Cambia según tu imagen
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColoresApp.blanco,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correo == "4"
                    ? "Administrador"
                    : correo == "3"
                        ? "Supervisor"
                        : "Cobrador",
                style: const TextStyle(
                  fontSize: 14,
                  color: ColoresApp.blanco,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LineasDivisoras extends StatelessWidget {
  const LineasDivisoras({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Divider(
        color: ColoresApp.grisClarito,
      ),
    );
  }
}
