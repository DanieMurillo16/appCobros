// ignore_for_file: unused_local_variable, prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../config/services/conexioninternet.dart';
import '../widgets/estado_cliente_ruta.dart';
import '../widgets/spinner.dart';

class RutaCobrador extends StatefulWidget {
  const RutaCobrador({super.key});

  @override
  State<RutaCobrador> createState() => _RutaCobradorState();
}

class _RutaCobradorState extends State<RutaCobrador> {
  final Databaseservices _databaseServices = Databaseservices();
  final PreferenciasUsuario _preferences = PreferenciasUsuario();
  List<Map<String, dynamic>> clientes = [];
  int? _draggingIndex;
  final ScrollController _scrollController = ScrollController();

  // Para el dropdown (empleado a consultar)
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    await _initializeRuta();
    final cargoEmpleado = _preferences.cargo;
    if (cargoEmpleado == '3' || cargoEmpleado == '4') {
      await _loadEmpleados();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEmpleados() async {
    if (!mounted) return;
    try {
      final empleados = await _databaseServices.fetchEmpleados(
          _preferences.cargo, _preferences.cobro);
      if (!mounted) return;
      setState(() {
        if (!mounted) return;
        _roles = empleados;
      });
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
    }
  }

  Future<void> _initializeRuta({String? empleadoId}) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Verificar conexión antes de hacer las llamadas
      final bool hasConnection = await Conexioninternet().isConnected();
      if (!hasConnection) {
        throw Exception('No hay conexión a internet');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      final rutaBD = await _databaseServices
          .obtenerRuta(empleadoId ?? _preferences.idUser);
      final fetchedClientes = await _databaseServices
          .fetchClientes(empleadoId ?? _preferences.idUser);

      List<Map<String, dynamic>> clientesOrdenados = [];
      if (!mounted) return;

      if (rutaBD.isNotEmpty) {
        // Crear un mapa de clientes basado en idpersona y idprestamos
        final Map<String, Map<String, dynamic>> clientesMap = {
          for (var cliente in fetchedClientes)
            '${cliente['idpersona']}_${cliente['idprestamos']}': cliente
        };

        // Procesar los clientes que ya están en la ruta
        for (var rutaItem in rutaBD) {
          final idPersonaPrestamo =
              '${rutaItem['fk_cliente']}_${rutaItem['fk_prestamo']}';
          if (clientesMap.containsKey(idPersonaPrestamo)) {
            final cliente = clientesMap[idPersonaPrestamo];
            if (cliente != null) {
              clientesOrdenados.add({
                ...cliente,
                'orden': rutaItem['orden'],
                'estado': rutaItem['estado'] == 1,
                'idprestamos': cliente[
                    'idprestamos'], // Use idprestamo from fetchedClientes
              });
              clientesMap.remove(idPersonaPrestamo);
            }
          }
        }
        // Agregar los clientes que no están en la ruta al final de la lista
        int ultimoOrden =
            clientesOrdenados.isNotEmpty ? clientesOrdenados.last['orden'] : 0;
        clientesOrdenados.addAll(clientesMap.values.map((cliente) {
          ultimoOrden += 1;
          return {
            ...cliente,
            'orden': ultimoOrden,
            'estado': false,
            'idprestamos':
                cliente['idprestamos'], // Use idprestamo from fetchedClientes
          };
        }));
      } else {
        // Si no hay ruta existente, usar todos los clientes con orden y estado predeterminados
        clientesOrdenados = fetchedClientes
            .map((cliente) => {
                  ...cliente,
                  'orden': fetchedClientes.indexOf(cliente),
                  'estado': false,
                  'idprestamos': cliente['idprestamos'],
                })
            .toList();
      }
      setState(() {
        clientes = clientesOrdenados;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error al inicializar ruta: $e");
      SmartDialog.showToast("Empleado sin ruta asignada...");
      try {
        final fetchedClientes = await _databaseServices
            .fetchClientes(empleadoId ?? _preferences.idUser);
        setState(() {
          clientes = fetchedClientes
              .map((cliente) => {
                    ...cliente,
                    'orden': fetchedClientes.indexOf(cliente),
                    'estado': false,
                    'idprestamos': cliente['idprestamo'],
                  })
              .toList();
        });
      } catch (fetchError) {
        debugPrint("Error al cargar clientes: $fetchError");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void actualizarPosicion(int viejaPosicion, int nuevaPosicion) {
    if (!mounted) return;
    if (viejaPosicion < nuevaPosicion) {
      nuevaPosicion -= 1;
    }

    setState(() {
      final cliente = clientes.removeAt(viejaPosicion);
      clientes.insert(nuevaPosicion, cliente);
    });
  }

// Agregar debounce para evitar múltiples guardados
  Timer? _saveDebouncer;

  Future<void> _guardarOrden() async {
    if (!mounted) return;

    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final List<Map<String, dynamic>> ruta = clientes.map((cliente) {
          return {
            'fk_cliente': int.tryParse(cliente['idpersona'].toString()) ?? 0,
            'orden': clientes.indexOf(cliente),
            'estado': (cliente['estado'] ?? false) ? 1 : 0,
            'idprestamos': int.tryParse(cliente['idprestamos'].toString()) ?? 0,
          };
        }).toList();

        if (!mounted) return;

        final bool exito = await _databaseServices.guardarRuta(
            _rolSeleccionado ?? _preferences.idUser, ruta);

        if (!mounted) return;

        if (exito) {
          // Usar un toast sutil en lugar de refrescar la pantalla
          SmartDialog.showToast(
            "Ruta guardada correctamente",
            displayTime: const Duration(milliseconds: 500),
          );
        } else {
          throw Exception('Error al guardar la ruta');
        }
      } catch (e) {
        debugPrint("Error al guardar la ruta: $e");
        SmartDialog.showToast("Error al guardar la ruta: ${e.toString()}");
      } finally {
        // Cerrar cualquier diálogo que se haya mostrado
        if (!_isLoading) {
          SmartDialog.dismiss();
        }
      }
    });
  }

  void _reiniciarEstados() {
    if (!mounted) return;
    setState(() {
      for (var cliente in clientes) {
        cliente['estado'] = false;
      }
    });
    _guardarOrden();
  }

  void _onReorderStart(int index) {
    if (!mounted) return;
    setState(() {
      _draggingIndex = index;
    });
  }

  void _onReorderEnd(int index) {
    if (!mounted) return;
    setState(() {
      _draggingIndex = null;
    });
  }

  void _navegarAInsertarAbono(Map<String, dynamic> cliente) {
    Navigator.pushNamed(
      context,
      rutanuevoAbono,
      arguments: {
        'idpersona': cliente['idprestamos'] + "-" + cliente['idpersona'],
        'nombre':
            '${cliente['per_nombre'].toString().toUpperCase()} ${cliente['per_apellido'].toString().toUpperCase()}',
        'fromRutaCobrador': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _preferences.ultimaPagina = rutaCobrador;
    final cargoEmpleado = _preferences.cargo;
    return Scaffold(
      backgroundColor: ColoresApp.blanco,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.rutaCobrador),
      ),
      drawer: const DrawerMenu(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando ruta...'),
                ],
              ),
            )
          : Column(
              children: [
                if (cargoEmpleado == '3' || cargoEmpleado == '4')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SpinnerEmpleados(
                      empleados: _roles,
                      valorSeleccionado: _rolSeleccionado,
                      valueid: "fk_roll",
                      nombreCompleto: "nombreCompleto",
                      onChanged: (value) {
                        setState(() {
                          _rolSeleccionado = value;
                          clientes.clear();
                          _initializeRuta(empleadoId: _rolSeleccionado);
                        });
                      },
                    ),
                  ),
                Expanded(
                    child: Listener(
                  onPointerMove: (PointerMoveEvent event) {
                    _autoScrollDuringDrag(event.position);
                  },
                  child: ReorderableListView(
                    scrollController: _scrollController,
                    onReorderStart: _onReorderStart,
                    onReorderEnd: _onReorderEnd,
                    children: [
                      for (int index = 0; index < clientes.length; index++)
                        ClienteListItem(
                          key: ValueKey(
                              '${clientes[index]['idpersona']}_$index'),
                          cliente: clientes[index],
                          index: index,
                          isDragging: _draggingIndex == index,
                          onEstadoChanged: (index, value) {
                            // Solo actualiza el valor en la lista sin llamar a setState
                            clientes[index]['estado'] = value;
                            // Opcionalmente, guarda en background sin mostrar indicadores
                            _guardarSinRefrescar(index, value);
                          },
                          onAbonoTap: _navegarAInsertarAbono,
                        ),
                    ],
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > clientes.length - 1) {
                        newIndex = clientes.length - 1;
                      } else if (newIndex < 0) {
                        newIndex = 0;
                      }
                      actualizarPosicion(oldIndex, newIndex);
                    },
                  ),
                )),
                Container(
                  color: ColoresApp.blanco,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(ColoresApp.rojo),
                          ),
                          onPressed: () => _guardarOrden(),
                          child: const Text('Guardar Orden',
                              style: TextStyle(color: ColoresApp.blanco)),
                        ),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(ColoresApp.rojo),
                          ),
                          onPressed: _reiniciarEstados,
                          child: const Text('Reiniciar Estados',
                              style: TextStyle(color: ColoresApp.blanco)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _autoScrollDuringDrag(Offset pointerPosition) {
    const scrollSpeed = 20.0; // Velocidad de desplazamiento
    const autoScrollThreshold =
        100.0; // Margen desde el borde para activar el desplazamiento

    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Desplazar hacia abajo si el puntero está cerca del borde inferior
    if (pointerPosition.dy >
            MediaQuery.of(context).size.height - autoScrollThreshold &&
        scrollOffset < maxScrollExtent) {
      _scrollController.animateTo(
        scrollOffset + scrollSpeed,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    }
    // Desplazar hacia arriba si el puntero está cerca del borde superior
    else if (pointerPosition.dy < autoScrollThreshold && scrollOffset > 0) {
      _scrollController.animateTo(
        scrollOffset - scrollSpeed,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    }
  }

  // Agrega este nuevo método para guardar sin refrescar la vista
  Future<void> _guardarSinRefrescar(int index, bool value) async {
    try {
      final cliente = clientes[index];
      final Map<String, dynamic> rutaItem = {
        'fk_cliente': int.tryParse(cliente['idpersona'].toString()) ?? 0,
        'orden': index,
        'estado': value ? 1 : 0,
        'idprestamos': int.tryParse(cliente['idprestamos'].toString()) ?? 0,
      };

      // Opcional: guardar solo este elemento en lugar de toda la ruta
      // await _databaseServices.guardarEstadoRutaItem(_rolSeleccionado ?? _preferences.idUser, rutaItem);

      // O usar el método existente pero sin refrescar UI
      _guardarOrden();
    } catch (e) {
      debugPrint("Error al actualizar estado: $e");
    }
  }
}
