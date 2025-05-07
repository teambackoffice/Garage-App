import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Service extends StatefulWidget {
  const Service({super.key});

  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
  List<dynamic> services = [];
  String? selectedService;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    final url = Uri.parse(
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_services');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          services = data['message'] ?? [];
        });
      } else {
        print("Failed to load services: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

  void onSelect() {
    if (selectedService != null) {
      print("Selected Service: $selectedService");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: $selectedService')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Service')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose a service',
                border: OutlineInputBorder(),
              ),
              value: selectedService,
              items: services.map<DropdownMenuItem<String>>((service) {
                return DropdownMenuItem<String>(
                  value: service['service'], // Adjust key if needed
                  child: Text(service['service']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedService = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSelect,
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
