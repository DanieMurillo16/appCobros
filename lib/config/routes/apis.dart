// api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://www.cobros.shop/prestamos';
  
  //-----------------Consultas
  static const String loginEndpoint = '$baseUrl/Login.php';
  static const String verificarEstadoUsuario = '$baseUrl/getEstadoUsuario.php?id=';
  static const String verificarEstadoUsuarioCaja = '$baseUrl/verificarEstadoUsuarioCaja.php?id=';
  static const String buscarDatosCliente = '$baseUrl/verDatosCliente.php?id=';
  static const String listaEmpleados = '$baseUrl/verListaEmpleados.php';
  static const String listaCajaCobradores = '$baseUrl/verlistaCajaCobradores.php';
  static const String historialCierres = '$baseUrl/historialCierreCajaCobradores.php?id=';
  static const String guardarRuta = '$baseUrl/InsertarguardarRuta.php';
  static const String guardarRuta2 = '$baseUrl/InsertarguardarRuta2.php';
  static const String consultarRuta = '$baseUrl/ver_rutas_cobro.php?fk_empleado=';
  static const String consultarRuta2 = '$baseUrl/ver_rutas_cobro2.php?fk_empleado=';
  static const String listaEmpleadosSpinner = '$baseUrl/VerEmpleadoSpinnner.php';
  static const String listaEmpleadosSpinner2 = '$baseUrl/verListaEmpleadosRol.php?rol=';
  static const String verNombrePersonaPrestamos = '$baseUrl/verNombrePersonaPrestamos.php?id=';
  static const String verListadoReporteAbonosClientes = '$baseUrl/verReporteRecuadosClientes.php';
  static const String verRecaudosEmpleado = '$baseUrl/verRecaudosEmpleado.php?id=';
  static const String verCajaEmpleado = '$baseUrl/verCajaEmpleado.php?id=';
  static const String verRolesPersona = '$baseUrl/VerRolesPersona.php';
  static const String listaClientesConPrestamos =
      '$baseUrl/getUsuariosConPrestamos.php?id=';
  static const String listaMovimientosCaja =
      '$baseUrl/listaMovimientosCaja.php?id=';
  static const String sumaMovimientosCajaIngresos =
      '$baseUrl/verSumaMovimientosIngresos.php?id=';
  static const String listaPrestamosNuevos =
      '$baseUrl/listaPrestamos.php?id=';
  static const String listaPrestamosCancelados =
      '$baseUrl/listaPrestamosCancelados.php?id=';
  static const String verAbonoPrestamoEspecifico =
      '$baseUrl/VerAbonoPrestamoEspecifico.php?id_prestamo=';

  //-----------------Inserciones
  static const String insertarAbonoPrestamoCliente =
      '$baseUrl/InsertarAbonoPrestamoCliente.php';
  static const String insertarnuevoPrestamo =
      '$baseUrl/InsertarNuevoPrestamo.php';
  static const String insertarnuevoPrestamo2 =
      '$baseUrl/InsertarNuevoPrestamo2.php';
  static const String insertarnuevoEmpleado =
      '$baseUrl/InsertarNuevaPersona.php';
  static const String insertarMovimientoCaja =
      '$baseUrl/insertarMovimientoCaja.php';
  static const String insertarCajaGeneral =
      '$baseUrl/insertarCajaGeneral.php';
  //-----------------Actualizaciones
  static const String actualizarEstadoUsuario =
      '$baseUrl/actualizarEstadoUsuario.php?id=';
  static const String eliminarAbono =
      '$baseUrl/eliminarAbono.php?id=';
}
