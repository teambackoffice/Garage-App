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
  String? _authToken;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('sid');

    if (_authToken != null && _authToken!.isNotEmpty) {
      await fetchAppointmentDetails();
    } else {
      setState(() {
        _error = "No auth token found. Please login again.";
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAppointmentDetails() async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_requested_appointments_count';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['message']?['data']?['requested_appointments'] is List) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(
              data['message']['data']['requested_appointments']);
        });
      } else {
        setState(() => _error = "Unexpected response format.");
      }
    } catch (e) {
      setState(() => _error = "Fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update Appointment Status (Confirmed or Rejected)
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.appointment_confirm';

    if (appointmentId.isEmpty) {
      _showError("Invalid appointment ID.");
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
        body: jsonEncode({
          "appointment_id": appointmentId,
          "status": status,
        }),
      );

      final responseData = jsonDecode(response.body);

      String msg = '';
      final dynamic message = responseData['message'];
      if (message is String) {
        msg = message;
      } else if (message is Map && message['message'] is String) {
        msg = message['message'];
      } else {
        msg = "Appointment status updated.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: status == "Confirmed"
              ? Colors.green
              : status == "Rejected"
              ? Colors.red
              : Colors.orange,
        ),
      );

      if (status == "Confirmed") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConfirmPage()),
        );
      } else {
        await fetchAppointmentDetails();
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // Cancel Appointment
  Future<void> cancelAppointment(String appointmentId) async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.appointment_cancel';

    if (appointmentId.isEmpty) {
      _showError("Invalid appointment ID.");
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$_authToken',  // Ensure this contains the valid session ID
        },
        body: jsonEncode({
          "appointment_id": appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the API response has a success message
        String msg = '';
        final dynamic message = responseData['message'];

        // If the response has a message, use it
        if (message is String) {
          msg = message;
        } else if (message is Map && message['message'] is String) {
          msg = message['message'];
        } else {
          msg = "Appointment cancelled successfully."; // Default success message
        }

        // Show a snackbar with the success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,  // Green background for success
          ),
        );

        // Update the appointment status locally if necessary (if you store this information locally)
        await fetchAppointmentDetails(); // Refresh the appointment list or status

      } else {
        // Show an error message if the API response is not successful
        _showError("Failed to cancel the appointment.");
      }
    } catch (e) {
      // Show an error message if the network request fails
      _showError("Error: $e");
    } finally {
      // Reset the loading state after the operation completes
      setState(() => _isUpdating = false);
    }
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,  // Red background for error
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Appointment Requests'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : appointments.isEmpty
          ? const Center(child: Text("No appointment requests found."))
          : ListView.builder(
        itemCount: appointments.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) {
          final a = appointments[index];
          final appointmentId =
              a['name'] ?? a['appointment_id'] ?? a['docname'] ?? '';

          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['customer_name'] ?? 'No Name',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text("Model: ${a['model'] ?? 'N/A'}"),
                  Text("Make: ${a['make'] ?? 'N/A'}"),
                  Text("Date: ${a['date'] ?? 'N/A'}"),
                  Text("Time: ${a['time'] ?? 'N/A'}"),
                  const SizedBox(height: 6),
                  Text(
                    "Status: ${a['status'] ?? 'Pending'}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: a['status'] == 'Confirmed'
                          ? Colors.green
                          : a['status'] == 'Rejected'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isUpdating
                            ? null
                            : () => updateAppointmentStatus(
                            appointmentId, "Confirmed"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(w * 0.35, 40),
                        ),
                        icon: const Icon(Icons.check),
                        label: _isUpdating
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                            : const Text("Confirm"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUpdating
                            ? null
                            : () => cancelAppointment(appointmentId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: Size(w * 0.35, 40),
                        ),
                        icon: const Icon(Icons.cancel),
                        label: _isUpdating
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                            : const Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : fetchAppointmentDetails,  // Disable when loading
        backgroundColor: Colors.blue,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)  // Show a spinner when loading
            : const Icon(Icons.refresh),  // Show the refresh icon otherwise
      ),
    );
  }
}
