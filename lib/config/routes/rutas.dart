
import 'package:cobrosapp/screen/navbar/nav_prestamos.dart';
import 'package:cobrosapp/screen/navbar/nav_usuarios.dart';
import 'package:cobrosapp/screen/vistas/insertar_abono_prestamo_cliente.dart';
import 'package:cobrosapp/screen/vistas/insertar_gasto_empleado.dart';
import 'package:cobrosapp/screen/vistas/ruta_cobrar_clientes.dart';
import 'package:cobrosapp/screen/vistas/ver_caja_empleado.dart';
import 'package:cobrosapp/screen/vistas/ver_caja_general.dart';
import 'package:cobrosapp/screen/vistas/ver_lista_clientes.dart';
import 'package:cobrosapp/screen/vistas/insertar_nuevo_prestamo.dart';
import 'package:cobrosapp/screen/login/login.dart';
import 'package:cobrosapp/screen/vistas/insertar_nuevo_empleado.dart';


const String rutaLogin ="/login";
const String rutaRegistrarUsuario ="/registrar_usuario";
const String rutaDashboard ="/nuevo_prestamo";
const String rutaNavBarPrestamos ="/navbar_prestamos";
const String rutaNavBarUsuarios ="/navbar_usuarios";
const String rutaCliente ="/cliente";
const String rutanuevoPrestamo ="/nuevoPrestamo";
const String rutanuevoAbono ="/nuevoAbono";
const String rutaCaja ="/caja";
const String rutaCajaGeneral ="/cajaGeneral";
const String rutaGastos ="/gastos";
const String rutaClienteHistorialPagos ="/cliente_historial_pagos";
const String rutaCobrador ="/pruebas";

final rutas = {
  rutaLogin: (context) => const Login(),
  rutaRegistrarUsuario: (context) => const RegistrarUsuario(),
  rutaDashboard: (context) => const NuevoPrestamo(),
  rutaNavBarPrestamos: (context) => const NavBarPrestamo(),
  rutaCliente: (context) => const ClientesLista(),
  rutaCaja: (context) => const CajaCuentas(),
  rutaCajaGeneral: (context) => const VerCajaGeneral(),
  rutaNavBarUsuarios: (context) => const NavBarUsuarios(),
  rutanuevoPrestamo: (context) => const NuevoPrestamo(),
  rutanuevoAbono: (context) => const Abonoprestamo(),
  rutaCobrador: (context) => const RutaCobrador(),
  rutaGastos: (context) => const GastosState(),
};