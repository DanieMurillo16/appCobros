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
                texto: '+3 días',
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

// Función para contar días laborables (sin domingos)
int _calcularDiasLaborables(DateTime inicio, DateTime fin) {
  int dias = 0;
  DateTime actual = DateTime(inicio.year, inicio.month, inicio.day);

  while (actual.isBefore(fin) || actual.isAtSameMomentAs(fin)) {
    // Domingo = 7 en DateTime weekday
    if (actual.weekday != 7) {
      dias++;
    }
    actual = actual.add(const Duration(days: 1));
  }

  return dias;
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
    // Obtener fechas y datos básicos
    final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
    final hoy = DateTime.now();
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    final totalAbonosRealizados =
        int.tryParse(cliente['cantidad_cuotas'].toString()) ?? 0;

    // Verificar si es un préstamo nuevo (de hoy)
    final esMismoDia = fechaPrestamo.year == hoy.year &&
        fechaPrestamo.month == hoy.month &&
        fechaPrestamo.day == hoy.day;

    // Si es préstamo de hoy, siempre es morado (nuevo)
    if (esMismoDia) {
      return ColoresApp.morado; // Préstamo nuevo de hoy
    }

    // Calcular días laborables transcurridos (excluyendo domingos)
    final diasLaborablesTranscurridos =
        _calcularDiasLaborables(fechaPrestamo, hoy);

    // Definir intervalo según tipo de préstamo
    int intervaloPago;

    switch (tipoPrestamo) {
      case 1: // Diario (pago de lunes a sábado)
        intervaloPago = 1;
        break;
      case 2: // Semanal
        intervaloPago =
            6; // 7 días normales - 1 domingo = 6 días laborables por semana
        break;
      case 3: // Quincenal
        intervaloPago =
            13; // 15 días normales - 2 domingos = 13 días laborables
        break;
      default:
        intervaloPago = 1;
    }

    // Calcular cuántos pagos debería haber realizado ya (basado en días laborables)
    int abonosEsperados = (diasLaborablesTranscurridos / intervaloPago).ceil();

    // Ajuste para préstamos nuevos (1-2 días laborables)
    if (cliente['ultimo_abono'] == null &&
        diasLaborablesTranscurridos <= 2 &&
        abonosEsperados <= 1) {
      return ColoresApp.verde; // verde para préstamos recientes sin abonos aún
    }

    // Si no hay pagos registrados y debería haber al menos uno (caso general)
    if (cliente['ultimo_abono'] == null && abonosEsperados > 0) {
      // Graduamos el color según los días laborables transcurridos
      if (abonosEsperados <= 3) {
        return Colors.orange; // 1-3 cuotas sin pagar
      } else {
        return ColoresApp.rojoLogo; // 4+ cuotas sin pagar
      }
    }

    // Calcular cuántos pagos faltan
    int abonosFaltantes = abonosEsperados - totalAbonosRealizados;

    // Lógica de colores según los umbrales de abonosFaltantes
    if (abonosFaltantes < 2) {
      return ColoresApp.verde; // Al día, adelantado o solo debe 1 cuota
    } else if (abonosFaltantes >= 2 && abonosFaltantes <= 3) {
      return Colors.orange; // 2-3 cuotas atrasadas (amarillo-naranja)
    } else if (abonosFaltantes >= 4 && abonosFaltantes <= 6) {
      return ColoresApp.rojo; // 4-6 cuotas atrasadas (rojo)
    } else {
      return ColoresApp.rojoLogo; // Más de 6 cuotas
    }
  }

  String _obtenerMensajeMora() {
    // Obtener fechas y datos básicos
    final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
    final hoy = DateTime.now();
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    final totalAbonosRealizados =
        int.tryParse(cliente['cantidad_cuotas'].toString()) ?? 0;

    // Verificar si es un préstamo nuevo (de hoy)
    final esMismoDia = fechaPrestamo.year == hoy.year &&
        fechaPrestamo.month == hoy.month &&
        fechaPrestamo.day == hoy.day;

    if (esMismoDia) {
      return 'Préstamo nuevo de hoy';
    }

    // Determinar el período de pago según el tipo
    String periodoPago = '';
    int intervaloPago = 0;

    switch (tipoPrestamo) {
      case 1:
        periodoPago = 'diario';
        intervaloPago = 1;
        break;
      case 2:
        periodoPago = 'semanal';
        intervaloPago = 6;
        break;
      case 3:
        periodoPago = 'quincenal';
        intervaloPago = 13;
        break;
      default:
        periodoPago = 'diario';
        intervaloPago = 1;
    }

    // Calcular cuántos días han pasado desde que se otorgó el préstamo
    final diasTranscurridos = _calcularDiasLaborables(fechaPrestamo, hoy);

    // Calcular cuántos pagos debería haber realizado ya
    int abonosEsperados = (diasTranscurridos / intervaloPago).ceil();

    // *** NUEVA VALIDACIÓN: Préstamo reciente (1-2 días) sin abonos ***
    if (cliente['ultimo_abono'] == null &&
        diasTranscurridos <= 2 &&
        abonosEsperados <= 1) {
      return 'Préstamo reciente ($diasTranscurridos día${diasTranscurridos > 1 ? "s" : ""}): Debe 1 cuota (pago $periodoPago)';
    }

    // Si no hay abonos registrados
    if (cliente['ultimo_abono'] == null) {
      return 'Sin pagos registrados: debe $abonosEsperados cuota${abonosEsperados > 1 ? "s" : ""} (pago $periodoPago)';
    }

    // Calcular cuántos pagos faltan
    int abonosFaltantes = abonosEsperados - totalAbonosRealizados;

    if (abonosFaltantes <= 0) {
      if (abonosFaltantes < 0) {
        // Adelantado en pagos
        return 'Cliente adelantado en ${-abonosFaltantes} cuota${-abonosFaltantes > 1 ? "s" : ""} (pago $periodoPago)';
      }
      return 'Al día (pago $periodoPago)';
    } else if (abonosFaltantes == 1) {
      return 'Debe 1 cuota (pago $periodoPago)';
    } else {
      return 'Debe $abonosFaltantes cuotas (pago $periodoPago)';
    }
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
