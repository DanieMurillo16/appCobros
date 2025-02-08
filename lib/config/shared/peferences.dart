import 'package:shared_preferences/shared_preferences.dart';
import '../routes/rutas.dart';

class PreferenciasUsuario {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Getter y setter para la última página visitada
  String get ultimaPagina {
    return _preferences.getString("ultimaPagina") ?? rutaLogin;
  }

  set ultimaPagina(String value) {
    _preferences.setString("ultimaPagina", value);
  }

  // ID del usuario
  String get idUser {
    return _preferences.getString("uid") ?? "";
  }

  set idUser(String value) {
    _preferences.setString("uid", value);
  }

  // Nombre del usuario
  String get nombre {
    return _preferences.getString("nombre") ?? "";
  }

  set nombre(String value) {
    _preferences.setString("nombre", value);
  }

  // Teléfono del usuario
  String get telefono {
    return _preferences.getString("telefono") ?? "";
  }

  set telefono(String value) {
    _preferences.setString("telefono", value);
  }

  // Cargo del usuario
  String get cargo {
    return _preferences.getString("cargo") ?? "";
  }

  set cargo(String value) {
    _preferences.setString("cargo", value);
  }

  // Cobro asociado al usuario
  String get cobro {
    return _preferences.getString("cobro") ?? "";
  }

  set cobro(String value) {
    _preferences.setString("cobro", value);
  }

  // Estado del usuario
  String get estado {
    return _preferences.getString("estado") ?? "";
  }

  set estado(String value) {
    _preferences.setString("estado", value);
  }

  void setString(String key, String value) {
    _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }
}
