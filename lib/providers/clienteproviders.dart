import 'package:flutter/foundation.dart';
import '../config/services/databaseservices.dart';
import '../config/shared/peferences.dart';

class ClienteProvider extends ChangeNotifier {
  final _db = Databaseservices();

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> get clientes => _clientes;

  Future<void> fetchClientesSpinnerFromPhp() async {
    try {
      final resultado = await _db.fetchClientesSpinnerFromPhp(PreferenciasUsuario().idUser);
      _clientes = resultado;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar providers clientes spinner: $e');
    }
  }

  Future<void> fetchClientesFromPhp(String idUser) async {
    try {
      final resultado = await _db.fetchClientes(idUser);
      _clientes = resultado; // Aquí estaba el error
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar providers clientes: $e');
    }
  }

  Future<void> loadAllData(String idUser) async {
    try {
    await fetchClientesSpinnerFromPhp();
    await fetchClientesFromPhp(idUser);
    } catch (e) {
      debugPrint('Error al cargar all data: $e');
    }
  }
}