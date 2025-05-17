import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../desing/coloresapp.dart';

class SpinnerEmpleados extends StatelessWidget {
  final String? valueid,nombreCompleto,hintText,labelText;
  final List<Map<String, dynamic>> empleados; // Lista de empleados
  final String? valorSeleccionado; // Valor seleccionado actual
  final void Function(String?)? onChanged; // Callback al cambiar valor

  const SpinnerEmpleados({
    super.key,
    required this.empleados,
    this.valorSeleccionado,
    this.onChanged,
    this.valueid,
    this.nombreCompleto,
    this.hintText = 'Seleccione empleado', this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<String>(
      name: "empleado",
      decoration: InputDecoration(
        hintText: hintText ?? "Seleccione un empleado",
        labelText: labelText ?? "Empleado",
        labelStyle: const TextStyle(color: Colors.black),
        focusColor: ColoresApp.rojo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColoresApp.rojo,
            width: 2.0,
          ),
        ),
        floatingLabelStyle: const TextStyle(color: ColoresApp.rojo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ColoresApp.rojo,
          ),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
      items: empleados.map<DropdownMenuItem<String>>((empleado) {
        return DropdownMenuItem<String>(
          value: empleado[valueid].toString(),
          child: Text(empleado[nombreCompleto] ?? "Sin datos"),
        );
      }).toList(),
      initialValue: valorSeleccionado,
      onChanged: onChanged,
      hint: Text(hintText ?? "Seleccione un empleado"),
    );
  }
}
