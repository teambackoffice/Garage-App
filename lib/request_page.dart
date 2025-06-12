import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'confirm_page.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  List<Map<String, dynamic>> appointments = [];
  String? _errorMessage;
  bool _isLoading = true;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    debugPrint('Loaded Auth Token: $_authToken');

    if (_authToken != null) {
      fetchAppointmentDetails();
    } else {
      setState(() {
        _errorMessage = 'Authentication token not found. Please log in again.';
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAppointmentDetails() async {
    const String baseUrl =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_requested_appointments_count';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
      );

      debugPrint('📥 API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🧬 Parsed Data: $data');

        if (data['message'] != null &&
            data['message']['data'] != null &&
            data['message']['data']['requested_appointments'] is List) {
          setState(() {
            appointments = List<Map<String, dynamic>>.from(
                data['message']['data']['requested_appointments']);
            _errorMessage = null;
          });
        } else {
          _showError('Invalid response format or no appointments found.');
          debugPrint('❌ Invalid response structure: ${response.body}');
        }
      } else {
        _showError('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Appointment Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        )
            : appointments.isEmpty
            ? const Text(
          'No appointments found.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                title: Text(
                  appointment['customer_name'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model: ${appointment['model'] ?? 'N/A'}'),
                    Text('Make: ${appointment['make'] ?? 'N/A'}'),
                    Text('Date: ${appointment['date'] ?? 'N/A'}'),
                    Text('Time: ${appointment['time'] ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => const Confirm()),
                        // );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('View Confirmed Appointments'),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchAppointmentDetails,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}