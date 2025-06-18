import 'package:cobrosapp/config/entitys/rendimiento_empleados_entity.dart';
import 'package:cobrosapp/config/routes/rutas.dart';
import 'package:cobrosapp/config/services/databaseservices.dart';
import 'package:cobrosapp/config/shared/peferences.dart';
import 'package:cobrosapp/desing/app_medidas.dart';
import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:cobrosapp/desing/textosapp.dart';
import 'package:cobrosapp/screen/widgets/appbar.dart';
import 'package:cobrosapp/screen/widgets/drawemenu.dart';
import 'package:cobrosapp/screen/widgets/empleadosRendimientos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';

class VerRendimientoEmpleados extends StatefulWidget {
  const VerRendimientoEmpleados({super.key});

  @override
  State<VerRendimientoEmpleados> createState() =>
      _VerRendimientoEmpleadosState();
}

class _VerRendimientoEmpleadosState extends State<VerRendimientoEmpleados> {
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _inicioCtrl = TextEditingController();
  final TextEditingController _finCtrl = TextEditingController();

  List<RedimientoEmpleadosEntity> rendimientos = [];

  Future<void> _consultarDatos() async {
    if (_inicioCtrl.text.isEmpty || _finCtrl.text.isEmpty) {
      SmartDialog.showToast('Seleccione fechas');
      return;
    }

    SmartDialog.showLoading(msg: 'Consultando información');
    rendimientos = await Databaseservices().listaRendimientoEmpleados(
      _inicioCtrl.text,
      _finCtrl.text,
    );
    SmartDialog.dismiss();
    SmartDialog.showToast(
      rendimientos.isNotEmpty ? 'Datos encontrados' : 'No se encontraron datos',
    );
    setState(() {}); // refresca la lista Empleadosrendimientos()
  }

  Widget _campoFecha({
    required String name,
    required String label,
    required TextEditingController ctrl,
  }) {
    final hoy = DateTime.now();
    return FormBuilderDateTimePicker(
      name: name,
      locale: const Locale('es', 'CO'),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialValue: hoy,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      inputType: InputType.date,
      format: DateFormat('yyyy-MM-dd', 'es_CO'),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (dt) {
        if (dt != null) {
          ctrl.text = DateFormat('yyyy-MM-dd').format(dt);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _inicioCtrl.dispose();
    _finCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PreferenciasUsuario().ultimaPagina = rutaRendimiento;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(AppMedidas.medidaAppBarLargo),
        child: TitulosAppBar(nombreRecibido: AppTextos.tituloRendimiento),
      ),
      drawer: const DrawerMenu(),
      body: FormBuilder(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Para ver el rendimiento de sus empleados seleccione una fecha inicio y una fecha fin',
                style: TextStyle(fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _campoFecha(
                name: 'fechaInicio',
                label: 'Fecha inicio',
                ctrl: _inicioCtrl,
              ),
              const SizedBox(height: 12),
              _campoFecha(
                name: 'fechaFin',
                label: 'Fecha fin',
                ctrl: _finCtrl,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColoresApp.rojo,
                    foregroundColor: ColoresApp.blanco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _consultarDatos,
                  child: const Text('Buscar'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: EmpleadosRendimientos(lista: rendimientos),),
            ],
          ),
        ),
      ),
    );
  }
}
