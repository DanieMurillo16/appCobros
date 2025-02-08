import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';

class DropdownSearchExample extends StatefulWidget {
  const DropdownSearchExample({super.key});

  @override
  State<DropdownSearchExample> createState() => _DropdownSearchExampleState();
}

class _DropdownSearchExampleState extends State<DropdownSearchExample> {
  // Simulación de datos del backend (lista de clientes)
  final List<Map<String, dynamic>> _roles = [
    {"id": "1", "nombreCompleto": "Juan Pérez", "email": "juan@example.com"},
    {"id": "2", "nombreCompleto": "Ana Gómez", "email": "ana@example.com"},
    {
      "id": "3",
      "nombreCompleto": "Carlos Rodríguez",
      "email": "carlos@example.com"
    },
    {
      "id": "4",
      "nombreCompleto": "Lucía Fernández",
      "email": "lucia@example.com"
    },
  ];

  // Método simulado para obtener sugerencias del "backend"
  Future<List<Map<String, dynamic>>> _getSuggestions(String pattern) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simula un retraso del servidor
    return _roles
        .where((cliente) => cliente["nombreCompleto"]!
        .toLowerCase()
        .contains(pattern.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Cliente")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selecciona un cliente:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropDownSearchField<Map<String, dynamic>>(
              textFieldConfiguration: const TextFieldConfiguration(
                autofocus: true,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Buscar cliente",
                  border: OutlineInputBorder(),
                ),
              ),
              displayAllSuggestionWhenTap:
              true, // Muestra todas las sugerencias al hacer clic
              isMultiSelectDropdown:
              false, // Indica que no es un selector múltiple
              suggestionsCallback: (pattern) async {
                return await _getSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(suggestion['nombreCompleto']),
                  subtitle: Text(suggestion['email']),
                );
              },
              onSuggestionSelected: (suggestion) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Cliente seleccionado: ${suggestion['nombreCompleto']}",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
