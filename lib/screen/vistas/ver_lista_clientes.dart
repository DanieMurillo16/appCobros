import 'package:cobrosapp/screen/vistas/dialogo_modificar_prestamo_screen.dart';
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
    _initializeData();
  }

  Future<void> refreshData() async {
    // Simplemente reaplicas tu inicialización
    await _initializeData();
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

  // Nuevo método para inicializar datos
  Future<void> _initializeData() async {
    final cargoEmpleado = _pref.cargo;

    setState(() {
      _isLoading = true;
    });

    try {
      if (cargoEmpleado == '4' || cargoEmpleado == '3') {
        // Cargar empleados primero
        await _loadEmpleados();
        _rolSeleccionado = null;
      } else {
        // Cargar directamente los clientes del usuario actual
        await _loadClientes();
      }
    } catch (e) {
      debugPrint("Error en inicialización: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Carga de empleados para dropdown (solo aplica si cargo=4)
  Future<void> _loadEmpleados() async {
    if (!mounted) return;

    try {
      final empleados = await _dataBaseServices.fetcListaEmpleadosSpinner(
          _pref.cargo, _pref.cobro);

      if (mounted) {
        setState(() {
          _roles = empleados;
          // Si no hay empleado seleccionado y hay empleados disponibles
          if (_rolSeleccionado == null && empleados.isNotEmpty) {
            _rolSeleccionado = empleados[0]['fk_roll'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Error al cargar empleados: $e");
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empleados: $e'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _loadEmpleados,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaNavBarClientes;
    final cargoEmpleado = _pref.cargo;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloClientes),
      ),
      drawer: const DrawerMenu(),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            // Dropdown solo para cargo=4
            if (cargoEmpleado == '4' || cargoEmpleado == '3')
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: _roles.isEmpty
                    ? const Center(
                        child: Text('Cargando empleados...'),
                      )
                    : SpinnerEmpleados(
                        empleados: _roles,
                        valorSeleccionado: _rolSeleccionado,
                        valueid: "fk_roll",
                        hintText: 'Seleccione empleado',
                        nombreCompleto: "nombreCompleto",
                        onChanged: (value) async {
                          setState(() {
                            _rolSeleccionado = value;
                            _clientes.clear();
                            _itemsToShow = 20;
                            _isLoading = true;
                          });
                          await _loadClientes(empleadoId: _rolSeleccionado);
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
                              ? _filtrarClientes(_buscadorController.text)
                                  .length
                              : _itemsToShow,
                          itemBuilder: (context, index) {
                            final cliente = _filtrarClientes(
                                _buscadorController.text)[index];
                            return ClienteCard(
                              cliente: cliente,
                              cargoEmpleado: cargoEmpleado,
                              onPrestamoModificado: () async {
                                if (_rolSeleccionado != null) {
                                  await _loadClientes(
                                      empleadoId: _rolSeleccionado);
                                } else {
                                  await _loadClientes();
                                }
                              },
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
      ),
    );
  }

  Widget informacionPagos() {
    // Calcular el progreso
    double calcularProgresoClientes() {
      if (_clientes.isEmpty) return 0.0;
      int clientesAlDia = _clientes.where((cliente) {
        final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
        final hoy = DateTime.now();
        final tipoPrestamo =
            int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
        final valorCuota =
            double.tryParse(cliente['pres_valorCuota'].toString()) ?? 0;
        final totalAbonado =
            double.tryParse(cliente['total_abonos'].toString()) ?? 0;

        // Calcular días laborables y cuotas
        final diasLaborablesTranscurridos =
            _calcularDiasLaborables(fechaPrestamo, hoy);
        final intervaloPago =
            tipoPrestamo == 1 ? 1 : (tipoPrestamo == 2 ? 6 : 13);
        final cuotasEquivalentes = (totalAbonado / valorCuota).floor();
        final cuotasEsperadas =
            (diasLaborablesTranscurridos / intervaloPago).ceil();
        final cuotasFaltantes = cuotasEsperadas - cuotasEquivalentes;

        // Cliente al día si no debe cuotas o debe 4 o menos
        return cuotasFaltantes <= 4;
      }).length;

      return clientesAlDia / _clientes.length;
    }

    final progreso = calcularProgresoClientes();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estado general de clientes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.negro,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${(progreso * 100).round()}%',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: progreso < 0.3
                                ? Colors.red
                                : progreso < 0.7
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: ColoresApp.rojoLogo,
                          ),
                          onPressed: () =>
                              _mostrarDialogoInformacionColores(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: progreso,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progreso < 0.3
                        ? Colors.red
                        : progreso < 0.7
                            ? Colors.orange
                            : Colors.green,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_clientes.where((c) => _estaAlDia(c)).length} de ${_clientes.length} clientes al día',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _mostrarDialogoInformacionColores(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Estado de pagos de los clientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.negro,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'El estado general de los clientes se calcula con los clientes que esten al dia.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                // Primera fila con 3 indicadores en Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _indicadorColor(
                      color: ColoresApp.morado,
                      texto: 'Nuevo hoy',
                    ),
                    _indicadorColor(
                      color: ColoresApp.verde,
                      texto: '0-4 cuotas',
                    ),
                    _indicadorColor(
                      color: Colors.orange,
                      texto: '5-7 cuotas',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Segunda fila con 2 indicadores en Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _indicadorColor(
                      color: ColoresApp.rojoLogo,
                      texto: '+8 cuotas',
                    ),
                    const SizedBox(width: 16),
                    _indicadorColor(
                      color: Colors.brown,
                      texto: 'Vencido',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(ColoresApp.verde),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(color: ColoresApp.blanco),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _calcularDiasLaborables(DateTime inicio, DateTime fin) {
    // Comenzar desde el día siguiente al préstamo
    DateTime actual = DateTime(inicio.year, inicio.month, inicio.day)
        .add(const Duration(days: 1));
    int dias = 0;

    while (actual.isBefore(fin) || actual.isAtSameMomentAs(fin)) {
      // No contar domingos (weekday 7)
      if (actual.weekday != 7) {
        dias++;
      }
      actual = actual.add(const Duration(days: 1));
    }
    return dias;
  }

// Agregar este metodo auxiliar
  bool _estaAlDia(Map<String, dynamic> cliente) {
    final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
    final hoy = DateTime.now();
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    final valorCuota =
        double.tryParse(cliente['pres_valorCuota'].toString()) ?? 0;
    final totalAbonado =
        double.tryParse(cliente['total_abonos'].toString()) ?? 0;

    final diasLaborablesTranscurridos =
        _calcularDiasLaborables(fechaPrestamo, hoy);
    final intervaloPago = tipoPrestamo == 1 ? 1 : (tipoPrestamo == 2 ? 6 : 13);
    final cuotasEquivalentes = (totalAbonado / valorCuota).floor();
    final cuotasEsperadas =
        (diasLaborablesTranscurridos / intervaloPago).ceil();
    final cuotasFaltantes = cuotasEsperadas - cuotasEquivalentes;

    return cuotasFaltantes <= 4;
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
  final String cargoEmpleado;
  final VoidCallback? onPrestamoModificado;

  const ClienteCard(
      {super.key,
      required this.cliente,
      required this.onPressed,
      required this.cargoEmpleado,
      this.onPrestamoModificado});

  int calcularDiasLaborables(DateTime inicio, DateTime fin) {
    DateTime actual = DateTime(inicio.year, inicio.month, inicio.day)
        .add(const Duration(days: 1));
    int dias = 0;

    while (actual.isBefore(fin) || actual.isAtSameMomentAs(fin)) {
      if (actual.weekday != 7) {
        dias++;
      }
      actual = actual.add(const Duration(days: 1));
    }
    return dias;
  }

  Color _obtenerColorAvatar() {
    final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
    final hoy = DateTime.now();
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    final valorCuota =
        double.tryParse(cliente['pres_valorCuota'].toString()) ?? 0;
    final totalAbonado =
        double.tryParse(cliente['total_abonos'].toString()) ?? 0;

    // Verificaciones básicas
    final esMismoDia = fechaPrestamo.year == hoy.year &&
        fechaPrestamo.month == hoy.month &&
        fechaPrestamo.day == hoy.day;
    if (esMismoDia) return ColoresApp.morado;

    final esDiaAnterior = fechaPrestamo.difference(hoy).inDays == -1;
    if (esDiaAnterior && hoy.weekday == 7) return ColoresApp.verde;

    // Calcular días laborables
    final diasLaborablesTranscurridos =
        calcularDiasLaborables(fechaPrestamo, hoy);
    if (diasLaborablesTranscurridos == 0) return ColoresApp.verde;

    // Calcular cuotas equivalentes basadas en el monto total abonado
    final cuotasEquivalentes = (totalAbonado / valorCuota).floor();

    // Definir intervalo según tipo de préstamo
    int intervaloPago;
    switch (tipoPrestamo) {
      case 1: // Diario
        intervaloPago = 1;
        break;
      case 2: // Semanal
        intervaloPago = 6;
        break;
      case 3: // Quincenal
        intervaloPago = 13;
        break;
      default:
        intervaloPago = 1;
    }

    // Calcular cuotas esperadas y faltantes
    int cuotasEsperadas = (diasLaborablesTranscurridos / intervaloPago).ceil();
    int cuotasFaltantes = cuotasEsperadas - cuotasEquivalentes;

    // Determinar color basado en cuotas faltantes
    if (cuotasFaltantes <= 0) {
      return ColoresApp.verde;
    } else if (cuotasFaltantes <= 4) {
      return ColoresApp.verde;
    } else if (cuotasFaltantes <= 7) {
      return Colors.orange;
    } else if (cuotasFaltantes > 7 && cuotasFaltantes <= 50) {
      return ColoresApp.rojo;
    } else {
      return ColoresApp.cafe;
    }
  }

  String _obtenerMensajeMora() {
    // Obtener datos del cliente
    final fechaPrestamo = DateTime.parse(cliente['pres_fecha']);
    final hoy = DateTime.now();
    final tipoPrestamo =
        int.tryParse(cliente['fk_tipo_prestamo'].toString()) ?? 1;
    final valorCuota =
        double.tryParse(cliente['pres_valorCuota'].toString()) ?? 0;
    final totalAbonado =
        double.tryParse(cliente['total_abonos'].toString()) ?? 0;

    // Verificaciones básicas
    final esMismoDia = fechaPrestamo.year == hoy.year &&
        fechaPrestamo.month == hoy.month &&
        fechaPrestamo.day == hoy.day;
    if (esMismoDia) return 'Préstamo nuevo de hoy';

    // Calcular días laborables
    final diasLaborablesTranscurridos =
        calcularDiasLaborables(fechaPrestamo, hoy);
    final intervaloPago = tipoPrestamo == 1 ? 1 : (tipoPrestamo == 2 ? 6 : 13);
    final periodoPago = tipoPrestamo == 1
        ? 'diario'
        : (tipoPrestamo == 2 ? 'semanal' : 'quincenal');

    // Calcular cuotas equivalentes y esperadas
    final cuotasEquivalentes = (totalAbonado / valorCuota).floor();
    final cuotasEsperadas =
        (diasLaborablesTranscurridos / intervaloPago).ceil();
    final cuotasFaltantes = cuotasEsperadas - cuotasEquivalentes;

    // Mensaje simplificado
    if (cuotasFaltantes <= 0) {
      return 'Cliente al día';
    } else if (cuotasFaltantes > 50) {
      return 'Cliente en mora extrema';
    }
    return 'Debe $cuotasFaltantes cuota${cuotasFaltantes != 1 ? 's' : ''} - pago $periodoPago';
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
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor: \$${FormatoMiles().formatearCantidad(cliente['pres_cantidadTotal'])}',
                          style: const TextStyle(color: ColoresApp.negro),
                        ),
                        Text(
                          'Cuota: \$${FormatoMiles().formatearCantidad(cliente['pres_valorCuota'])}',
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
                      ],
                    ),
                    const Spacer(),
                    if (cargoEmpleado == '4')
                      Expanded(
                          child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: ColoresApp.rojo,
                        ),
                        onPressed: () async {
                          final resultado = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                DialogoModificarPrestamoScreen(
                              idPrestamo: cliente['idprestamos'],
                              montoActual: cliente['pres_cantidadTotal'],
                              valorCuotas: cliente['pres_valorCuota'],
                              cantidadCuotas: cliente['pres_cuotas'],
                              onSuccess: onPrestamoModificado,
                            ),
                          );
                          if (resultado == true &&
                              onPrestamoModificado != null) {
                            onPrestamoModificado!(); // dispara el callback
                          }
                        },
                      ))
                  ],
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
