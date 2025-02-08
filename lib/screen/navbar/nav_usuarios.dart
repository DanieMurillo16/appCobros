import 'package:flutter/material.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/vistas/insertar_nuevo_empleado.dart';
import 'package:cobrosapp/screen/vistas/ver_lista_empleados.dart';

class NavBarUsuarios extends StatefulWidget {
  const NavBarUsuarios({super.key});

  @override
  State<NavBarUsuarios> createState() => _NavBarUsuariosState();
}

class _NavBarUsuariosState extends State<NavBarUsuarios> {
  int _selectedIndex = 0;
  final _pref = PreferenciasUsuario();

  // Lista de vistas que se mostrarán
  final List<Widget> _widgetOptions = const [
    EmpleadosLista(),
    RegistrarUsuario(),
  ];

  // Método para cambiar el índice seleccionado
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarUsuarios;
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // Muestra la vista seleccionada
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ColoresApp.rojo, // Fondo rojo para el Navbar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Ícono más representativo para nuevo préstamo
            label: AppTextos.tituloListaUsuarios,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), // Ícono de pagos para abonos
            label: AppTextos.tituloRegistrarUsuario,
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

