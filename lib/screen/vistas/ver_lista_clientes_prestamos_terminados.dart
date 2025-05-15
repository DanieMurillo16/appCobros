import 'package:cobrosapp/config/entitys/clientes_cancelados_entity.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/services/formatomiles.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/vistas/ver_abonos_prestamo_cliente.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:cobrosapp/screen/widgets/spinner.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class VerListaClientesPrestamosTerminados extends StatefulWidget {
  const VerListaClientesPrestamosTerminados({super.key});

  @override
  State<VerListaClientesPrestamosTerminados> createState() =>
      _VerListaClientesPrestamosTerminadosState();
}

class _VerListaClientesPrestamosTerminadosState
    extends State<VerListaClientesPrestamosTerminados> {
  // Variables para la lista de clientes cancelados
  List<ClientesCanceladosEntity> listaClientes = [];
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionado;
  bool _isLoading = false;
  final pref = PreferenciasUsuario();

  Future<void> obtenerListaClientes({String? idUsuario}) async {
    setState(() {
      _isLoading = true; // Iniciar carga
    });

    try {
      idUsuario ??= pref.idUser;
      List<ClientesCanceladosEntity> clientes =
          await Databaseservices().listaClientesCreditosTerminados(idUsuario);

      if (mounted) {
        setState(() {
          listaClientes = clientes;
          _isLoading = false; // Finalizar carga
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _loadEmpleados() async {
    if (!mounted) {
      return; // Verificar si el widget está montado antes de continuar
    }
    try {
      final empleados =
          await Databaseservices().fetchEmpleados(pref.cargo, pref.cobro);
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
  void initState() {
    super.initState();
    obtenerListaClientes();
    _loadEmpleados();
  }

  @override
  Widget build(BuildContext context) {
    pref.ultimaPagina = rutaNavBarClientes;
    final cargoEmpleado = pref.cargo;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child:
            TitulosAppBar(nombreRecibido: AppTextos.tituloClientesTerminados),
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          const SizedBox(height: 10),
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
                    listaClientes.clear();
                    obtenerListaClientes(idUsuario: value);
                  });
                },
              ),
            ),
          const Text('Prestamos terminados del ultimo mes.'),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando datos...'),
                      ],
                    ),
                  )
                : Center(
                    child: listaClientes.isEmpty
                        ? const Center(
                            child: Text(
                                'No hay clientes con prestamos terminados.'))
                        : ListView.builder(
                            itemCount: listaClientes.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ExpansionTile(
                                  leading: Tooltip(
                                    message: 'Estado de pagos',
                                    child: CircleAvatar(
                                      backgroundColor: ColoresApp.verde,
                                      child: Text(
                                        listaClientes[index]
                                            .nombre
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: ColoresApp.blanco),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${listaClientes[index].nombre.toString().toUpperCase()} ${listaClientes[index].apellido.toString().toUpperCase()}',
                                    style: const TextStyle(
                                        color: ColoresApp.negro),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SelectableText(
                                            'Cedula: ${listaClientes[index].cedulaPersona}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              // Limpiamos el número de teléfono de espacios y caracteres especiales
                                              final phoneNumber =
                                                  listaClientes[index]
                                                      .telefono
                                                      .toString()
                                                      .replaceAll(
                                                          RegExp(r'[^\d+]'),
                                                          '');

                                              final Uri phoneUri = Uri.parse(
                                                  'tel:+57$phoneNumber');
                                              try {
                                                if (await canLaunchUrl(
                                                    phoneUri)) {
                                                  await launchUrl(phoneUri,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                } else {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'No se pudo abrir el marcador telefónico'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Error: ${e.toString()}'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Teléfono: ',
                                                  style: TextStyle(
                                                      color: ColoresApp.negro),
                                                ),
                                                // Espacio entre el número y el icono
                                                const Icon(
                                                  Icons.phone,
                                                  size: 16,
                                                  color: ColoresApp.rojoLogo,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  listaClientes[index].telefono,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        ColoresApp.rojoLogo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                              'Dirección: ${listaClientes[index].direccion}'),
                                          const Divider(),
                                          Text(
                                            'Fecha inicio: ${listaClientes[index].fechaPrestamo.toString().substring(0, 10)}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          Text(
                                            'Fecha fin: ${listaClientes[index].fechaFinalizo.toString().substring(0, 10)}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          Text(
                                            'Cuota: \$${FormatoMiles().formatearCantidad(listaClientes[index].valorCuota)}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          Text(
                                            'Valor: \$${FormatoMiles().formatearCantidad(listaClientes[index].cantidadPrestamo)}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          Text(
                                            'Abonos: \$${FormatoMiles().formatearCantidad(listaClientes[index].totalAbonos)}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          Text(
                                            'Restante: \$${FormatoMiles().formatearCantidad(((int.tryParse(listaClientes[index].cantidadPrestamo.toString()) ?? 0) - (int.tryParse(listaClientes[index].totalAbonos) ?? 0)).toString())}',
                                            style: const TextStyle(
                                                color: ColoresApp.negro),
                                          ),
                                          const Divider(),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: const Icon(
                                                  Icons.arrow_forward,
                                                  color: ColoresApp.rojoLogo),
                                              label: const Text(
                                                'Ver abonos',
                                                style: TextStyle(
                                                    color: ColoresApp.rojoLogo),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Clientepagoabonos(
                                                      idPrestamo:
                                                          listaClientes[index]
                                                              .idPrestamo,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
