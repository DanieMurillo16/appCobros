import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/vistas/ver_lista_clientes.dart';
import 'package:cobrosapp/screen/vistas/ver_lista_clientes_prestamos_terminados.dart';
import 'package:flutter/material.dart';


class NavClientes extends StatefulWidget {
  const NavClientes({super.key});

  @override
  State<NavClientes> createState() => _NavClientesState();
}

class _NavClientesState extends State<NavClientes> {
    int _selectedIndex = 0;
  final _pref = PreferenciasUsuario();

  // Lista de vistas que se mostrarán
  final List<Widget> _widgetOptions = const [
    ClientesLista(),
    VerListaClientesPrestamosTerminados(),
  ];

  // Método para cambiar el índice seleccionado
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {

    _pref.ultimaPagina = rutaNavBarClientes;
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // Muestra la vista seleccionada
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ColoresApp.rojo, // Fondo rojo para el Navbar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Ícono más representativo para nuevo préstamo
            label: AppTextos.tituloClientes,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add_check_rounded), // Ícono de pagos para abonos
            label: AppTextos.tituloClientesTerminados,
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