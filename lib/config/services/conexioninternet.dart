

import 'package:connectivity_plus/connectivity_plus.dart';

class Conexioninternet {

  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // ignore: unrelated_type_equality_checks
    return connectivityResult != ConnectivityResult.none;
  }
}