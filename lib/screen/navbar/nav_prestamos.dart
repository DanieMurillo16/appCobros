import 'package:cobrosapp/screen/vistas/ver_lista_prestamos.dart';
import 'package:flutter/material.dart';

import '../../config/routes/rutas.dart';
import '../../config/shared/peferences.dart';
import '../../desing/coloresapp.dart';
import '../../desing/textosapp.dart';
import '../vistas/insertar_nuevo_prestamo.dart';

class NavBarPrestamo extends StatefulWidget {
  const NavBarPrestamo({super.key});

  @override
  State<NavBarPrestamo> createState() => _NavBarPrestamoState();
}

class _NavBarPrestamoState extends State<NavBarPrestamo> {
  int _selectedIndex = 0;
  final _pref = PreferenciasUsuario();

  // Lista de vistas que se mostrarán
  final List<Widget> _widgetOptions = const [
    VerListaPrestamos(),
    NuevoPrestamo()
  ];

  // Método para cambiar el índice seleccionado
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarPrestamos;
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // Muestra la vista seleccionada
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ColoresApp.rojo, // Fondo rojo para el Navbar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Ícono más representativo para nuevo préstamo
            label: AppTextos.tituloAbonoPrestamo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), // Ícono de pagos para abonos
            label: AppTextos.tituloNuevoAbonoPrestamo,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: ColoresApp.blanco, // Color seleccionado
        unselectedItemColor: ColoresApp.grisOscuro,  // Color para opciones no seleccionadas
        onTap: _onItemTapped, // Llama al método de cambio de vista
      ),
    );
  }
}

