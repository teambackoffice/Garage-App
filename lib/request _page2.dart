// ... existing imports ...
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Request extends StatefulWidget {
  const Request({super.key});

  @override
  State<Request> createState() => _RequestState();
}

class _RequestState extends State<Request> {
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
          data['message']?['data']?['requested_appointments'] != null) {
        final rawList = data['message']['data']['requested_appointments'];

        if (rawList is String) {
          try {
            final decodedList = jsonDecode(rawList);
            if (decodedList is List) {
              setState(() {
                appointments = List<Map<String, dynamic>>.from(decodedList);
              });
            } else {
              setState(() {
                _error = "Invalid appointment data format.";
              });
            }
          } catch (e) {
            setState(() {
              _error = "Failed to parse appointment list from string: $e";
            });
          }
        } else if (rawList is List) {
          setState(() {
            appointments = List<Map<String, dynamic>>.from(rawList);
          });
        } else {
          setState(() {
            _error = "Unexpected format of requested appointments.";
          });
        }
      } else {
        setState(() => _error = "Unexpected response format.");
      }
    } catch (e) {
      setState(() => _error = "Fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
          'Accept': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
        body: jsonEncode({
          "appointment_id": appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String msg = '';

        final dynamic message = responseData['message'];
        if (message is String) {
          msg = message;
        } else if (message is Map && message['message'] is String) {
          msg = message['message'];
        } else {
          msg = "Appointment cancelled successfully.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        await fetchAppointmentDetails();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['_server_messages'] != null) {
            final serverMsgList = jsonDecode(errorData['_server_messages']);
            final firstMsg = jsonDecode(serverMsgList[0]);
            _showError("Server: ${firstMsg['message']}");
          } else {
            _showError(errorData['message'] ?? "Failed to cancel appointment.");
          }
        } catch (e) {
          _showError("Unexpected error: $e");
        }
      }
    } catch (e) {
      _showError("Network error: $e");
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
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
          'Accept': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
        body: jsonEncode({
          "appointment_id": appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String msg = '';

        final dynamic message = responseData['message'];
        if (message is String) {
          msg = message;
        } else if (message is Map && message['message'] is String) {
          msg = message['message'];
        } else {
          msg = "Appointment confirmed successfully.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        await fetchAppointmentDetails();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['_server_messages'] != null) {
            final serverMsgList = jsonDecode(errorData['_server_messages']);
            final firstMsg = jsonDecode(serverMsgList[0]);
            _showError("Server: ${firstMsg['message']}");
          } else {
            _showError(errorData['message'] ?? "Failed to confirm appointment.");
          }
        } catch (e) {
          _showError("Unexpected error: $e");
        }
      }
    } catch (e) {
      _showError("Network error: $e");
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDialog(String title, String content, VoidCallback onYes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onYes();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.05),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: w * 0.05, color: Colors.red),
          ),
        ),
      )
          : appointments.isEmpty
          ? const Center(child: Text("No appointment requests found."))
          : ListView.builder(
        itemCount: appointments.length,
        padding: EdgeInsets.all(w * 0.02),
        itemBuilder: (context, index) {
          final a = appointments[index];
          final appointmentId =
              a['name'] ?? a['appointment_id'] ?? a['docname'] ?? '';

          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.symmetric(vertical: h * 0.01),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(w * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['customer_name'] ?? 'No Name',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: w * 0.05),
                  ),
                  SizedBox(height: h * 0.01),
                  Text("Model: ${a['model'] ?? 'N/A'}"),
                  Text("Make: ${a['make'] ?? 'N/A'}"),
                  Text("Date: ${a['date'] ?? 'N/A'}"),
                  Text("Time: ${a['time'] ?? 'N/A'}"),
                  SizedBox(height: h * 0.01),
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
                  SizedBox(height: h * 0.02),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _isUpdating
                            ? null
                            : () => _confirmDialog(
                          "Cancel Appointment",
                          "Are you sure you want to cancel this appointment?",
                              () => cancelAppointment(appointmentId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(w * 0.35, h * 0.05),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                            : const Text("Cancel",
                            style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _isUpdating
                            ? null
                            : () => _confirmDialog(
                          "Confirm Appointment",
                          "Are you sure you want to confirm this appointment?",
                              () => confirmAppointment(appointmentId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(w * 0.35, h * 0.05),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                            : const Text("Confirm",
                            style: TextStyle(color: Colors.white)),
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
        onPressed: _isUpdating ? null : () => fetchAppointmentDetails(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
