import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/config/services/validacion_estado_usuario.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/vistas/ver_abonos_prestamo_cliente.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:cobrosapp/screen/widgets/spinner.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientesLista extends StatefulWidget {
  const ClientesLista({super.key});
  @override
  State<ClientesLista> createState() => _ClientesListaState();
}

class _ClientesListaState extends BaseScreen<ClientesLista> {
  final _pref = PreferenciasUsuario();
  final _dataBaseServices = Databaseservices();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _buscadorController = TextEditingController();

  // Aquí almacenamos el resultado de la futura consulta
  List<Map<String, dynamic>> _clientes = [];
  bool _isLoading = false;
  int _itemsToShow = 20;

  // Para el dropdown (empleado a consultar)
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;

  List<Map<String, dynamic>> _filtrarClientes(String query) {
    if (query.isEmpty) {
      // Ordenar por el campo 'orden' si existe
      final clientesOrdenados = List<Map<String, dynamic>>.from(_clientes);
      clientesOrdenados.sort((a, b) => (a['orden'] ?? double.infinity)
          .compareTo(b['orden'] ?? double.infinity));
      return clientesOrdenados;
    }

    final lowerQuery = query.toLowerCase();
    final clientesFiltrados = _clientes.where((cliente) {
      final nombreCompleto =
          '${cliente["per_nombre"] ?? ""} ${cliente["per_apellido"] ?? ""}'
              .toLowerCase();
      return nombreCompleto.contains(lowerQuery);
    }).toList();

    // Mantener el orden incluso en la búsqueda
    clientesFiltrados.sort((a, b) => (a['orden'] ?? double.infinity)
        .compareTo(b['orden'] ?? double.infinity));

    return clientesFiltrados;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cargoEmpleado = _pref.cargo;
    if (cargoEmpleado != '4' && cargoEmpleado != '3') {
      // Si no es cargo=4, cargamos directamente los clientes del usuario actual
      _loadClientes();
    } else {
      // cargo=4: Cargar lista de empleados para el dropdown
      _loadEmpleados();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes({String? empleadoId}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Primero obtener los clientes
      final newClientes = empleadoId != null && empleadoId.isNotEmpty
          ? await _dataBaseServices.fetchClientes(empleadoId)
          : await _dataBaseServices.fetchClientes(_pref.idUser);

      if (newClientes.isEmpty) {
        if (mounted) {
          setState(() {
            _clientes = [];
            _isLoading = false;
          });
        }
        return;
      }

      try {
        // Intentar obtener la ruta, pero no detener el proceso si falla
        final rutaBD =
            await _dataBaseServices.obtenerRuta(empleadoId ?? _pref.idUser);

        if (rutaBD.isNotEmpty) {
          // Crear un mapa de clientes basado en idpersona y idprestamos
          final Map<String, Map<String, dynamic>> clientesMap = {
            for (var cliente in newClientes)
              '${cliente['idpersona']}_${cliente['idprestamos']}': cliente
          };
          List<Map<String, dynamic>> clientesOrdenados = [];

          // Ordenar clientes según la ruta
          for (var rutaItem in rutaBD) {
            final idPersonaPrestamo =
                '${rutaItem['fk_cliente']}_${rutaItem['fk_prestamo']}';
            if (clientesMap.containsKey(idPersonaPrestamo)) {
              final cliente = clientesMap[idPersonaPrestamo];
              if (cliente != null) {
                clientesOrdenados.add({
                  ...cliente,
                  'orden': rutaItem['orden'],
                });
                clientesMap.remove(idPersonaPrestamo);
              }
            }
          }

          // Agregar los clientes que no están en la ruta al final
          clientesOrdenados.addAll(clientesMap.values.map((cliente) => {
                ...cliente,
                'orden': clientesOrdenados.length,
              }));

          if (mounted) {
            setState(() {
              _clientes = clientesOrdenados;
              _isLoading = false;
            });
          }
        } else {
          // Si no hay ruta, asignar orden secuencial a los clientes
          final clientesConOrden = newClientes
              .asMap()
              .map((index, cliente) => MapEntry(index, {
                    ...cliente,
                    'orden': index,
                  }))
              .values
              .toList();

          if (mounted) {
            setState(() {
              _clientes = clientesConOrden;
              _isLoading = false;
            });
          }
        }
      } catch (rutaError) {
        // Si falla la obtención de la ruta, mostrar los clientes sin orden específico
        debugPrint("Error al obtener ruta: $rutaError");
        if (mounted) {
          setState(() {
            _clientes = newClientes
                .map((cliente) => {
                      ...cliente,
                      'orden': 0,
                    })
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar clientes: $e");
      if (mounted) {
        setState(() {
          _clientes = [];
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {
        _itemsToShow += 20;
      });
    }
  }

  // Carga de empleados para dropdown (solo aplica si cargo=4)
  Future<void> _loadEmpleados() async {
    if (!mounted) {
      return; // Verificar si el widget está montado antes de continuar
    }
    try {
      final empleados =
          await _dataBaseServices.fetchEmpleados(_pref.cargo, _pref.cobro);
      if (mounted) {
        // Verificar nuevamente antes de llamar setState
        setState(() {
          _roles = empleados;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaCliente;
    final cargoEmpleado = _pref.cargo;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloClientes),
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          // Dropdown solo para cargo=4
          if (cargoEmpleado == '4' || cargoEmpleado == '3')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: SpinnerEmpleados(
                empleados: _roles,
                valorSeleccionado: _rolSeleccionado,
                valueid: "fk_roll",
                nombreCompleto: "nombreCompleto",
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value;
                    _clientes.clear();
                    _itemsToShow = 20;
                    _loadClientes(empleadoId: _rolSeleccionado);
                  });
                },
              ),
            ),
          // Buscador
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: TextField(
              controller: _buscadorController,
              decoration: InputDecoration(
                labelText: "Buscar cliente",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscadorController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _buscadorController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                setState(() {});
              },
            ),
          ),
          informacionPagos(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando clientes...'),
                      ],
                    ),
                  )
                : _clientes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay clientes disponibles.',
                          style: TextStyle(
                            fontSize: 16,
                            color: ColoresApp.negro,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _filtrarClientes(_buscadorController.text)
                                    .length <
                                _itemsToShow
                            ? _filtrarClientes(_buscadorController.text).length
                            : _itemsToShow,
                        itemBuilder: (context, index) {
                          final cliente =
                              _filtrarClientes(_buscadorController.text)[index];
                          return ClienteCard(
                            cliente: cliente,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Clientepagoabonos(
                                    idPrestamo: cliente['idprestamos'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget informacionPagos() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Estado de pagos de clientes: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _indicadorColor(
                color: ColoresApp.verde,
                texto: 'Al día',
              ),
              const SizedBox(width: 10),
              _indicadorColor(
                color: Colors.orange,
                texto: '3-5 días',
              ),
              const SizedBox(width: 10),
              _indicadorColor(
                color: ColoresApp.rojoLogo,
                texto: '+5 días',
              ),
              const SizedBox(width: 10),
              _indicadorColor(
                color: ColoresApp.morado,
                texto: 'Cliente nuevo',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicadorColor({required Color color, required String texto}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class ClienteCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onPressed;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onPressed,
  });

  Color _obtenerColorAvatar() {
    if (cliente['ultimo_abono'] == null) {
      // Verificar si es un préstamo nuevo (de hoy)
      final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
      final hoy = DateTime.now();

      // Comparar solo fecha sin hora
      final esMismoDia = fechaPrestamo.year == hoy.year &&
          fechaPrestamo.month == hoy.month &&
          fechaPrestamo.day == hoy.day;

      if (esMismoDia) {
        return ColoresApp.morado; // Préstamo nuevo de hoy
      }
      return ColoresApp.rojoLogo; // Préstamo sin pagos y no es de hoy
    }

    final ultimoAbono = DateTime.parse(cliente['ultimo_abono']);
    final hoy = DateTime.now();
    final diasTranscurridos = hoy.difference(ultimoAbono).inDays;
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    // Definir límites según tipo de préstamo
    int limiteModerado = 0;
    int limiteAlto = 0;

    switch (tipoPrestamo) {
      case 1: // Diario
        limiteModerado = 3;
        limiteAlto = 5;
        break;
      case 2: // Semanal
        limiteModerado = 8;
        limiteAlto = 10;
        break;
      case 3: // Quincenal
        limiteModerado = 15;
        limiteAlto = 17;
        break;
      default:
        limiteModerado = 3;
        limiteAlto = 5;
    }

    if (diasTranscurridos > limiteAlto) {
      return ColoresApp.rojoLogo;
    } else if (diasTranscurridos > limiteModerado) {
      return Colors.orange;
    }
    return ColoresApp.verde;
  }

  String _obtenerMensajeMora() {
    if (cliente['ultimo_abono'] == null) {
      final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
      final hoy = DateTime.now();

      final esMismoDia = fechaPrestamo.year == hoy.year &&
          fechaPrestamo.month == hoy.month &&
          fechaPrestamo.day == hoy.day;

      if (esMismoDia) {
        return 'Préstamo nuevo de hoy';
      }
      return 'Sin pagos registrados (desde ${cliente['pres_fecha']})';
    }

    final ultimoAbono = DateTime.parse(cliente['ultimo_abono']);
    final hoy = DateTime.now();
    final diasTranscurridos = hoy.difference(ultimoAbono).inDays;
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;

    // Determinar el período de pago según el tipo
    String periodoPago = '';
    int diasLimite = 0;

    switch (tipoPrestamo) {
      case 1:
        periodoPago = 'diario';
        diasLimite = 1;
        break;
      case 2:
        periodoPago = 'semanal';
        diasLimite = 8;
        break;
      case 3:
        periodoPago = 'quincenal';
        diasLimite = 15;
        break;
      default:
        periodoPago = 'diario';
        diasLimite = 1;
    }

    if (diasTranscurridos <= 0) {
      return 'Al día (pago $periodoPago)';
    }

    if (diasTranscurridos < diasLimite) {
      return 'Faltan ${diasLimite - diasTranscurridos} días para el próximo pago ($periodoPago)';
    }

    final diasMora = diasTranscurridos - diasLimite;
    if (diasMora == 1) {
      return '1 día de mora (pago $periodoPago)';
    }
    return '$diasMora días de mora (pago $periodoPago)';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: Tooltip(
          message: 'Estado de pagos',
          child: CircleAvatar(
            backgroundColor: _obtenerColorAvatar(),
            child: Text(
              cliente['per_nombre'][0].toString().toUpperCase(),
              style: const TextStyle(color: ColoresApp.blanco),
            ),
          ),
        ),
        title: Text(
          '${cliente['per_nombre'].toString().toUpperCase()} ${cliente['per_apellido'].toString().toUpperCase()}',
          style: const TextStyle(color: ColoresApp.negro),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  'Cedula: ${cliente['idpersona']}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                GestureDetector(
                  onTap: () async {
                    // Limpiamos el número de teléfono de espacios y caracteres especiales
                    final phoneNumber = cliente['per_telefono']
                        .toString()
                        .replaceAll(RegExp(r'[^\d+]'), '');

                    final Uri phoneUri = Uri.parse('tel:+57$phoneNumber');
                    try {
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No se pudo abrir el marcador telefónico'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    children: [
                      const Text(
                        'Teléfono: ',
                        style: TextStyle(color: ColoresApp.negro),
                      ),
                      // Espacio entre el número y el icono
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: ColoresApp.rojoLogo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${cliente['per_telefono']}',
                        style: const TextStyle(
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                          decorationColor: ColoresApp.rojoLogo,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Dirección: ${cliente['per_direccion']}'),
                const Divider(),
                Text(
                  'Fecha del préstamo: ${cliente['pres_fecha']}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                Text(
                  'Cuota: \$${FormatoMiles().formatearCantidad(cliente['pres_valorCuota'])}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                Text(
                  'Valor: \$${FormatoMiles().formatearCantidad(cliente['pres_cantidadTotal'])}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                Text(
                  'Abonos: \$${FormatoMiles().formatearCantidad(cliente['total_abonos'])}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                Text(
                  'Restante: \$${FormatoMiles().formatearCantidad(((int.tryParse(cliente['pres_cantidadTotal']?.toString() ?? '0') ?? 0) - (int.tryParse(cliente['total_abonos']?.toString() ?? '0') ?? 0)).toString())}',
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                const Divider(),
                Text(
                  _obtenerMensajeMora(),
                  style: const TextStyle(color: ColoresApp.negro),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_forward,
                        color: ColoresApp.rojoLogo),
                    label: const Text(
                      'Ver abonos',
                      style: TextStyle(color: ColoresApp.rojoLogo),
                    ),
                    onPressed: onPressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
