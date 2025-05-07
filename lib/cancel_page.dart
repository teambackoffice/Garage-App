import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Cancel extends StatefulWidget {
  const Cancel({super.key});

  @override
  State<Cancel> createState() => _CancelState();
}

class _CancelState extends State<Cancel> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCancelledAppointments();
  }

  Future<void> _fetchCancelledAppointments() async {
    const String apiUrl =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_cancelled_appointments_count';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');

      if (sid == null) {
        setState(() => _errorMessage = "User not logged in.");
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final appointments = json['message']['data']['requested_appointments'] as List<dynamic>;

        setState(() {
          _appointments = appointments;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data. Status Code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adding "Cancelled" text inside each card
            Text(
              "Cancelled", // Text indicating the appointment was cancelled
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text("Appointment ID: ${appointment['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Customer: ${appointment['customer_name']}"),
            Text("Date: ${appointment['date']}"),
            Text("Time: ${appointment['time']}"),
            Text("Vehicle ID: ${appointment['vehicle_id']}"),
            Text("Model: ${appointment['model']}"),
            Text("Make: ${appointment['make']}"),
            Text("Registration: ${appointment['registration_number']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
        ),
        title: const Text("Cancelled Appointments"),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : _appointments.isEmpty
          ? const Center(child: Text("No cancelled appointments found."))
          : ListView.builder(
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(_appointments[index]);
        },
      ),
    );
  }
}
