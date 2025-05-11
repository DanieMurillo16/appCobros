// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cobrosapp/desing/textosapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../routes/rutas.dart';
import '../services/conexioninternet.dart';
import '../shared/peferences.dart';
import '../routes/apis.dart';

class Databaseservices {
  final _pref = PreferenciasUsuario();

  Future<List> loginIni(String correo, String pass) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    if (correo.isNotEmpty && pass.isNotEmpty) {
      var url = Uri.parse(ApiConstants.loginEndpoint);
      final respuesta = await http.post(url, body: {
        "usu_nombre": correo,
        "us_contra": pass,
      });
      var data = jsonDecode(respuesta.body);
      if (data.isEmpty) {
        return [];
      }
      if (respuesta.statusCode != 200) {
        SmartDialog.showToast("Error al conectar al servidor");
        return [];
      }

      if (data[0]['usu_estado'] == "0") {
        SmartDialog.showToast("Usuario inactivo");
        return [];
      }
      if (data == "error" || data.isEmpty) {
        SmartDialog.showToast("Usuario o contraseña incorrectos");
      } else {
        _pref.nombre = (data[0]['per_nombre'] ?? AppTextos.sinTexto) +
            ' ' +
            (data[0]['per_apellido'] ?? AppTextos.sinTexto);
        _pref.idUser = data[0]['idpersona'] ?? AppTextos.sinTexto;
        _pref.cargo = data[0]['fk_roll'] ?? AppTextos.sinTexto;
        _pref.cobro = data[0]['fk_cobro'] ?? AppTextos.sinTexto;
        _pref.telefono = data[0]['per_telefono'] ?? AppTextos.sinTexto;
      }
      return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> cerrarCajaCobrador(
      String empleado, String saldo, String cobro,
      {String? descripcion}) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }

    if (empleado.isNotEmpty && saldo.isNotEmpty) {
      var url = Uri.parse(ApiConstants.insertarCajaGeneral);

      // Construir el cuerpo de la solicitud
      Map<String, String> body = {
        "fk": empleado,
        "cantidad": saldo,
        "cobro": cobro,
      };
      // Agregar `caja_descripcion` al cuerpo si no es nulo ni vacío
      if (descripcion != null && descripcion.isNotEmpty) {
        body["caja_descripcion"] = descripcion;
      }
      // Enviar la solicitud POST
      final respuesta = await http.post(url, body: body);
      final data = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (data['success'] == true) {
      } else {
        SmartDialog.showToast(data['error'] ?? "Error al insertar");
      }
      return data;
    } else {
      return {"success": false, "error": "Empleado o saldo vacío"};
    }
  }

  Future<List<Map<String, dynamic>>> consultarListadoReporteAbonosClientes(
      String idUser, String fecha) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    try {
      var url = Uri.parse(ApiConstants.verListadoReporteAbonosClientes);
      debugPrint('Consutal Clientes');
      final respuesta = await http.post(url, body: {
        "idempleado": idUser,
        "fecha": fecha,
      });

      var data = jsonDecode(respuesta.body);
      if (data['success'] == true) {
        final List<dynamic> dataList = data['data'];
        return dataList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error en la consulta: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error al cargar: $e');
    }
  }

  Future<bool> insertarNuevoMovimiento(String tipo, String valor,
      String descripcion, String cobro, String fkUser) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    try {
      var url = Uri.parse(ApiConstants.insertarMovimientoCaja);

      final respuesta = await http.post(url, body: {
        "tipo": tipo,
        "valor": valor,
        "desc": descripcion,
        "cobro": cobro,
        "fk": fkUser,
      });

      if (respuesta.statusCode != 200) {
        throw Exception('Error en el servidor: ${respuesta.statusCode}');
      }
      final Map<String, dynamic> data = jsonDecode(respuesta.body);
      if (data['success'] == true) {
        // Si el JSON trae success:true, retornamos true.
        return true;
      } else {
        // Si success:false, lanzamos excepción con el mensaje recibido.
        throw Exception(
            'Error en la consulta: ${data['message'] ?? 'Respuesta inesperada.'}');
      }
    } catch (e) {
      throw Exception('Error al insertar movimiento: $e');
    }
  }

  Future<String> fetchEstadoUsuario() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    String idEmpleado = _pref.idUser.toString();
    try {
      var url = Uri.parse(ApiConstants.verificarEstadoUsuario + idEmpleado);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('usu_estado')) {
          // Caso 1: La respuesta es un objeto JSON
          return data['usu_estado'].toString();
        } else if (data is List && data.isNotEmpty) {
          // Caso 2: La respuesta es una lista de objetos
          return data[0]['usu_estado'].toString();
        } else {
          debugPrint("Formato inesperado: $data");
          return '0';
        }
      } else {
        debugPrint("Error en la API. Código de estado: ${response.statusCode}");
        return "";
      }
    } catch (e) {
      debugPrint("Error en la consulta: $e");
      SmartDialog.showToast('Error en la consulta');
      return "0";
    }
  }

  Future<String> estadoUsuarioCaja() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    String idEmpleado = _pref.idUser.toString();
    try {
      var url = Uri.parse(ApiConstants.verificarEstadoUsuarioCaja + idEmpleado);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('ca_estado')) {
          // Caso 1: La respuesta es un objeto JSON
          return data['ca_estado'].toString();
        } else if (data is List) {
          // Caso 2: La respuesta es una lista de objetos
          if (data.isNotEmpty) {
            return data[0]['ca_estado'].toString();
          } else {
            // Lista vacía
            return '0';
          }
        } else {
          debugPrint("Formato inesperado: $data");
          return '0';
        }
      } else {
        debugPrint("Error en la API. Código de estado: ${response.statusCode}");
        return "0";
      }
    } catch (e) {
      debugPrint("Error en la consulta: $e");
      SmartDialog.showToast('Error en la consulta');
      return "0";
    }
  }

  Future<List<Map<String, dynamic>>> fetchClientesSpinnerFromPhp(
      String fkempleado) async {
    try {
      bool conectado = await Conexioninternet().isConnected();
      if (!conectado) {
        throw Exception('No tienes conexión a internet');
      }
      var url = Uri.parse(ApiConstants.verNombrePersonaPrestamos + fkempleado);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'idprestamos': '${item['idprestamos']}-${item['idpersona']}',
            'nombreCompleto':
                '${item['per_nombre'].toString().toUpperCase()} ${item['per_apellido'].toString().toUpperCase()}',
          };
        }).toList();
      } else {
        SmartDialog.showToast(
            'Error al cargar empleados: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      SmartDialog.showToast('Error al cargar: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRolesSpinnerFromPhp() async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    try {
      var url = Uri.parse(ApiConstants.verRolesPersona);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'idrol': item['idrol'],
            'nombreCompleto': item['rol_nombre'],
          };
        }).toList();
      } else {
        SmartDialog.showToast('Error al cargar: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      SmartDialog.showToast('Error al cargar: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchEmpleados(
      String rol, String cobro) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    try {
      var url = Uri.parse(
          ApiConstants.listaEmpleadosSpinner2 + rol + "&cobro=" + cobro);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'fk_roll': item['idpersona'],
            'nombreCompleto': item['per_nombre'] + ' ' + item['per_apellido'],
          };
        }).toList();
      } else {
        SmartDialog.showToast(
            'Error al cargar empleados: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      SmartDialog.showToast('Error al cargar: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchClientes(String idConsultado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(ApiConstants.listaClientesConPrestamos +
        idConsultado +
        '&cobro=' +
        _pref.cobro);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  Future<List<Map<String, dynamic>>> listaCajaCobradores(String cobro) async {
    try {
      bool conectado = await Conexioninternet().isConnected();
      if (!conectado) {
        throw Exception('No tienes conexión a internet');
      }

      var url = Uri.parse("${ApiConstants.listaCajaCobradores}$cobro");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        debugPrint('JSON decodificado: $jsonResponse');

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Verificar si data es una lista
          final List<dynamic> dataList = jsonResponse['data'] as List<dynamic>;
          debugPrint('Data como lista: $dataList');

          // Convertir cada elemento a Map<String, dynamic>
          final List<Map<String, dynamic>> resultado = dataList.map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();

          debugPrint('Resultado final: $resultado');
          return resultado;
        } else {
          debugPrint('Error: data es null o success es false');
          return [];
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en listaCajaCobradores: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listaMovimientoscaja(
      String idConsultado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(ApiConstants.listaMovimientosCaja + idConsultado);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  Future<List<Map<String, dynamic>>> datosCliente(String idConsultado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(ApiConstants.buscarDatosCliente + idConsultado);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

//--------------------------------------------------------------------------Rutas
  Future<bool> guardarRuta(
      String idEmpleado, List<Map<String, dynamic>> ruta) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }

    var url = Uri.parse(ApiConstants.guardarRuta2);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idempleado': idEmpleado,
        'ruta': ruta,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return true;
      } else {
        SmartDialog.showToast(data['error'] ?? 'Error al guardar la ruta');
        return false;
      }
    } else {
      throw Exception('Error en el servidor: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerRuta(String idEmpleado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }

    var url = Uri.parse('${ApiConstants.consultarRuta2}$idEmpleado');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseData['success'] == true) {
        // Aquí sí hay datos, extrae la lista de 'rutas'
        final List<dynamic> data = responseData['rutas'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        // No hay datos; lanza una excepción o retorna una lista vacía
        throw Exception(responseData['error'] ?? 'No se encontraron rutas');
      }
    } else {
      throw Exception('Error al obtener la ruta');
    }
  }

//--------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listaMovimientoscaja2(
      String idConsultado, String fecha) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(
        "${ApiConstants.listaMovimientosCaja}$idConsultado&fc=$fecha&cobro=${_pref.cobro}");
    final response = await http.get(url);
    debugPrint('Consutal Gastos');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Error en la respuesta del servidor');
      }
    } else {
      throw Exception('Error al cargar los movimientos...');
    }
  }

  Future<String> sumaMovimientosCajaIngresos(
      String idConsultado, String fecha, String tipoMovimiento) async {
    // Verificar la conexión a internet
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    // Construir la URL
    var url = Uri.parse(
        "${ApiConstants.sumaMovimientosCajaIngresos}$idConsultado&fecha=$fecha&tipo=$tipoMovimiento");
    // Realizar la solicitud HTTP GET
    final response = await http.get(url);
    // Verificar el código de estado de la respuesta
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Validar si la respuesta fue exitosa
      if (data['success'] == true) {
        // Devolver el valor de 'total' como un número
        return data['total'] ?? "0.0";
      } else {
        // Manejar el error del servidor
        throw Exception(data['error'] ?? 'Error en la respuesta del servidor');
      }
    } else {
      // Manejar errores HTTP
      throw Exception('Error al traer la suma de movimientos...');
    }
  }

  Future<String> totalCajaDia(String idConsultado, String fecha) async {
    // Verificar la conexión a internet
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    final url = Uri.parse(
        '${ApiConstants.verCajaEmpleado}$idConsultado&fecha=$fecha&cobro=${_pref.cobro}');
    // Realizar la solicitud HTTP GET
    final response = await http.get(url);
    // Verificar el código de estado de la respuesta
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Validar si la respuesta fue exitosa
      if (data['success'] == true) {
        // Devolver el valor de 'total' como un número
        return data['total'] ?? "0.0";
      } else {
        return "0.0";
        // Manejar el error del servidor
      }
    } else {
      // Manejar errores HTTP
      throw Exception('Error al traer datos caja...');
    }
  }

  Future<List<Map<String, dynamic>>> listaDePrestamos(
      String idConsultado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(ApiConstants.listaClientesConPrestamos + idConsultado);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al cargar los clientes');
    }
  }

  Future<List<dynamic>> consultaAbonosClientes(idPrestamo) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(ApiConstants.verAbonoPrestamoEspecifico + idPrestamo);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los abonos');
    }
  }

  Future<Map<String, dynamic>> actualizarEstadoEmpleado(
      String idEmpleado, String nuevoEstado) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }
    var url = Uri.parse(
        "${ApiConstants.actualizarEstadoUsuario}$idEmpleado&estado=$nuevoEstado");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // El servidor regresa un objeto, no una lista
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al cargar estado');
    }
  }

  Future<bool> eliminarAbono(String id) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }

    var url = Uri.parse(ApiConstants.eliminarAbono + id);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return true;
      } else {
        SmartDialog.showToast(data['error'] ?? 'Error al eliminar Abono');
        return false;
      }
    } else {
      throw Exception('Error en el servidor: ${response.statusCode}');
    }
  }

  Future<bool> eliminarMovimiento(String id) async {
    bool conectado = await Conexioninternet().isConnected();
    if (!conectado) {
      throw Exception('No tienes conexión a internet');
    }

    var url = Uri.parse(ApiConstants.eliminarMovimiento + id);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return true;
      } else {
        SmartDialog.showToast(data['error'] ?? 'Error al eliminar Movimiento');
        return false;
      }
    } else {
      throw Exception('Error en el servidor: ${response.statusCode}');
    }
  }

  //--------------------------------------------------------------------------------------

  String obtenerFechaActual() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = formatter.format(now);
    return formatted;
  }

  int aleatorio() {
    const min = 100000;
    const max = 999999;
    return min + DateTime.now().microsecond % (max - min + 1);
  }

  void reiniciarDatos() {
    _pref.ultimaPagina = rutaLogin;
    _pref.nombre = "";
    _pref.telefono = "";
    _pref.idUser = "";
    _pref.cargo = "";
    _pref.cobro = "";
  }
}
