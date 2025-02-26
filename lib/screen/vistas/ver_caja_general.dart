import 'package:cobrosapp/config/services/validacion_estado_usuario.dart';
import 'package:flutter/material.dart';
import '../../config/routes/rutas.dart';
import '../../config/services/databaseservices.dart';
import '../../config/services/formatomiles.dart';
import '../../config/shared/peferences.dart';
import '../../desing/app_medidas.dart';
import '../../desing/coloresapp.dart';
import '../../desing/textosapp.dart';
import '../widgets/appbar.dart';
import '../widgets/drawemenu.dart';
import 'ver_cierres_caja_empleado.dart';

class VerCajaGeneral extends StatefulWidget {
  const VerCajaGeneral({super.key});

  @override
  State<VerCajaGeneral> createState() => _VerCajaGeneralState();
}

class _VerCajaGeneralState extends BaseScreen<VerCajaGeneral> {
  final _pref = PreferenciasUsuario();
  final _dataBaseServices = Databaseservices();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _buscadorController = TextEditingController();

  // Aquí almacenamos el resultado de la futura consulta
  late Future<List<Map<String, dynamic>>> _futureDatosCajaGeneral;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _futureDatosCajaGeneral = _loadDatosCajaGeneral();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buscadorController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadDatosCajaGeneral() async {

    if (!mounted) return[];
    try {
      return await _dataBaseServices.listaCajaCobradores();
    } catch (e) {
      debugPrint("Error al cargar caja: $e");
      return [];
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _pref.ultimaPagina = rutaCajaGeneral;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.cajaGeneral),
      ),
      drawer: const DrawerMenu(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureDatosCajaGeneral,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos disponibles'));
          } else {
            final clientes = snapshot.data!;
            return ListView.builder(
              controller: _scrollController,
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return ClienteCard(
                  cliente: cliente,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistorialCierres(
                          idPersona: cliente['idpersona'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class ClienteCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onPressed;

  const ClienteCard({
    required this.cliente,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: ColoresApp.verde,
          child: Text(
            cliente['per_nombre'][0].toString().toUpperCase(),
            style: const TextStyle(color: ColoresApp.blanco),
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
                Text(
                  'Total: \$${FormatoMiles().formatearCantidad(cliente['total_caja_cantidad'])}',
                  style: const TextStyle(color: ColoresApp.negro, fontSize: 20),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_forward,
                        color: ColoresApp.rojoLogo),
                    label: const Text(
                      'Ver registros',
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
