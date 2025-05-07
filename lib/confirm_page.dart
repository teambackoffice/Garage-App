import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmPage extends StatefulWidget {
  const ConfirmPage({super.key});

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  List<Map<String, dynamic>> confirmedAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAuthTokenAndFetch();
  }

  Future<void> _loadAuthTokenAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('sid');

    if (_authToken == null || _authToken!.isEmpty) {
      setState(() {
        _errorMessage = "Authentication token not found. Please login again.";
        _isLoading = false;
      });
    } else {
      await fetchConfirmedAppointments();
    }
  }

  Future<void> fetchConfirmedAppointments() async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_confirmed_appointments_count';

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message']?['data'];

        if (message != null) {
          setState(() {
            confirmedAppointments = List<Map<String, dynamic>>.from(message['requested_appointments'] ?? []);
            totalCount = message['requested_appointments_count'] ?? 0;
            _errorMessage = null;
          });
        } else {
          _showError("Invalid response structure.");
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      _showError("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
    if (appointmentId.isEmpty) {
      _showError("Invalid appointment ID.");
      return;
    }

    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.appointment_confirm';

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'sid=$_authToken',
        },
        body: jsonEncode({"appointment_id": appointmentId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final msg = responseData['message'] ?? 'Appointment confirmed.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        await fetchConfirmedAppointments();
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      _showError("Error confirming appointment: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded['_server_messages'] != null) {
        final serverMsgList = jsonDecode(decoded['_server_messages']);
        final firstMsg = jsonDecode(serverMsgList[0]);
        _showError("Server: ${firstMsg['message']}");
      } else {
        _showError(decoded['message'] ?? "Unknown error occurred");
      }
    } catch (e) {
      _showError("Failed to parse error response: $e");
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback to a home or dashboard page if no previous route exists
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Placeholder()), // Replace Placeholder with your HomePage
              );
            }
          },
          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
        ),
        title: const Text("Confirmed Appointments"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : confirmedAppointments.isEmpty
          ? const Center(child: Text("No confirmed appointments."))
          : Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Text(
              "Total Confirmed: $totalCount",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: confirmedAppointments.length,
              itemBuilder: (context, index) {
                final a = confirmedAppointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a['customer_name'] ?? 'No Name',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.check_circle_outline, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              "Confirmed",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Model: ${a['model'] ?? 'N/A'}"),
                        Text("Make: ${a['make'] ?? 'N/A'}"),
                        Text("Date: ${a['date'] ?? 'N/A'}"),
                        Text("Time: ${a['time'] ?? 'N/A'}"),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchConfirmedAppointments,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
