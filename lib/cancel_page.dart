import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_cancelled_appointments_count';

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

  Future<void> openWhatsApp(String phone, String message) async {
    final phoneNumber = phone.replaceAll(RegExp(r'\D'), ''); // Clean the phone number
    final uri = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Redirecting to WhatsApp...")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")),
        );
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Could not open WhatsApp. $e")),
      );
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
            Text(
              "Cancelled",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text("Appointment ID: ${appointment['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Customer: ${appointment['customer_name']}"),
            Text("Date: ${appointment['date']}"),
            Text("Time: ${appointment['time']}"),
            Text("Vehicle ID: ${appointment['vehicle_id']}"),
            Text("Model: ${appointment['model']}"),
            Text("Make: ${appointment['make']}"),
            Text("Registration: ${appointment['registration_number']}"),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: () {
                  final phone = appointment['mobile'] ?? '';
                  final message = "Hello ${appointment['customer_name']}, your appointment on ${appointment['date']} at ${appointment['time']} was cancelled. Please contact us for rescheduling.";
                  openWhatsApp(phone, message);
                },
              ),
            ),
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
        title: const Text("Cancelled Appointments", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
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
