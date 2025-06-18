import 'package:cobrosapp/desing/coloresapp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cobrosapp/config/entitys/rendimiento_empleados_entity.dart';

class EmpleadosRendimientos extends StatelessWidget {
  final List<RedimientoEmpleadosEntity> lista;
  EmpleadosRendimientos({super.key, required this.lista});

  // ── helpers ──
  int _copToInt(String s) =>
      int.tryParse(s.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double? _percentToDouble(String s) =>
      s == 'N/A' ? null : double.tryParse(s.replaceAll('%', '').replaceAll(',', '.'));

  final _fmtCop = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final empleados = [...lista]
      ..sort((b, a) =>
          _copToInt(a.gananciaPrestamo).compareTo(_copToInt(b.gananciaPrestamo)));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: empleados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = empleados[i];

        // --- datos numéricos ---
        final ganancia   = _copToInt(e.gananciaPrestamo);
        final seguro     = _copToInt(e.dineroSeguro);
        final salidas    = _copToInt(e.salidas);

        // NUEVO cálculo solicitado
        final flujoNeto  = (ganancia + seguro) - salidas;

        final colorPosNeg =
        flujoNeto >= 0 ? Colors.green.shade700 : Colors.red.shade700;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

            // ---------- Título ----------
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorPosNeg.withOpacity(.15),
                  child: Text(e.perNombre.substring(0, 1),
                      style: TextStyle(color: colorPosNeg)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${e.perNombre} ${e.perApellido}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(_fmtCop.format(flujoNeto),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: colorPosNeg, fontWeight: FontWeight.w600)),
              ],
            ),

            // ---------- Sub-título ----------
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    e.rendimientoPrestamo == 'N/A'
                        ? '–'
                        : '${_percentToDouble(e.rendimientoPrestamo)!.toStringAsFixed(2)} %',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Text('Préstamos: ${e.cantidadPrestamos}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),

            // ---------- Detalle al expandir ----------
            children: [
              _fila('Presto:',   _fmtCop.format(_copToInt(e.dineroPrestado))),
              _fila('Recogió:',   _fmtCop.format(_copToInt(e.dineroRecogidoAbonos))),
              _fila('Seguros:',    _fmtCop.format(seguro)),
              const Divider(),
              _fila('Salidas (gastos):', _fmtCop.format(salidas),valorColor: ColoresApp.rojo),
              const Divider(),
              _fila('Flujo neto de caja:',
                  _fmtCop.format(flujoNeto),
                  valorColor: colorPosNeg),
            ],
          ),
        );
      },
    );
  }

  // Helper para cada línea de detalle
  Widget _fila(String label, String valor, {Color? valorColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(valor, style: TextStyle(color: valorColor)),
      ],
    ),
  );
}
