import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReadyOrder extends StatefulWidget {
  final String repairOrderId;

  const ReadyOrder({super.key, required this.repairOrderId});

  @override
  State<ReadyOrder> createState() => _ReadyOrderState();
}

class _ReadyOrderState extends State<ReadyOrder> {
  String status = "Working In Progress";
  String company = "GARAGE COMPANY";

  Future<void> _updateRepairOrderStatus(String apiUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid') ?? '';

    final Uri url = Uri.parse(apiUrl);
    final Map<String, dynamic> body = {
      "repairorder_id": widget.repairOrderId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);
      debugPrint("📦 Response: $jsonResponse");

      if (response.statusCode == 200 &&
          jsonResponse['message'] != null &&
          jsonResponse['message']['success'] == true) {
        final message = jsonResponse['message']['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $message")),
        );
      } else {
        final error = jsonResponse['message']?['message'] ?? "Unknown error";
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // Improved alert box with better design
  void _showFullPageAlert(BuildContext context, String action) {
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevents dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,  // Adjusted width for better fitting
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,  // Makes the dialog fit the content size
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 70, // Slightly larger icon size
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                action == 'inprogress'
                    ? "Are you sure you want to mark this order as In Progress?"
                    : "Are you sure you want to mark this order as Ready?",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);  // Dismiss the alert
                    },
                    child: const Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,  // Gray button for cancel
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);  // Dismiss the alert
                      if (action == 'inprogress') {
                        _updateRepairOrderStatus(
                            'https://garage.teambackoffice.com/api/method/garage.garage.auth.repairorder_inprogress');
                      } else {
                        _updateRepairOrderStatus(
                            'https://garage.teambackoffice.com/api/method/garage.garage.auth.repairorder_ready_orders');
                      }
                    },
                    child: const Text("Confirm"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,  // Green button for confirm
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Repair Order Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSection("More", [
              buildField("Status", status),
              buildField("Company", company),
            ]),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _showFullPageAlert(context, 'inprogress'),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Mark In Progress"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showFullPageAlert(context, 'ready'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Mark Ready"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
