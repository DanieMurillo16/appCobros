import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:sizer/sizer.dart';
import '../../desing/coloresapp.dart';

class WidgetTextField extends StatelessWidget {
  final String identificador;
  final String? hintText;
  final String? valorPorDefecto;
  final int? maxLength;
  final Widget? icono,suffixIcon;

  final bool? campoContrasena;
  final String? Function(String?)? validador;
  final TextEditingController? controller;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final TextInputType? keyboardType;

  const WidgetTextField({
    super.key,
    required this.identificador,
    this.hintText,
    this.icono,
    this.suffixIcon,
    this.campoContrasena,
    this.validador,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.valorPorDefecto,
  });

  @override
  Widget build(BuildContext context) {

    if (valorPorDefecto != null && controller != null && controller!.text.isEmpty) {
      controller!.text = valorPorDefecto!;
    }
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: FormBuilderTextField(
        maxLength: maxLength,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autofocus: false,
        name: identificador,
        controller: controller,
        obscureText: campoContrasena ?? false,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: identificador,
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(color: ColoresApp.negro),
          focusColor: ColoresApp.rojoLogo,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: ColoresApp.rojoLogo,
              width: 2.0,
            ),
          ),
          floatingLabelStyle: const TextStyle(color: ColoresApp.rojoLogo),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          prefixIcon: icono,
        ),
        validator: validador,
      ),
    );
  }
}