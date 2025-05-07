import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenViewPage extends StatefulWidget {
  final String repairOrderId;

  const OpenViewPage({super.key, required this.repairOrderId});

  @override
  State<OpenViewPage> createState() => _OpenViewPageState();
}

class _OpenViewPageState extends State<OpenViewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.repairOrderId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Invalid Repair Order ID")),
        );
      }
    });
  }

  Future<void> _updateRepairOrderStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid') ?? '';

    final String repairOrderId = widget.repairOrderId.trim();
    if (repairOrderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invalid Repair Order ID")),
      );
      return;
    }

    if (sid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Session expired. Please log in again.")),
      );
      return;
    }

    // Choose the correct endpoint based on the status
    late final Uri url;
    if (status == "working_progress") {
      url = Uri.parse('https://garage.teambackoffice.com/api/method/garage.garage.auth.repairorder_inprogress');
    } else if (status == "ready_order") {
      url = Uri.parse('https://garage.teambackoffice.com/api/method/garage.garage.auth.repairorder_ready_orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Invalid status type")),
      );
      return;
    }

    final Map<String, dynamic> body = {
      "repairorder_id": repairOrderId,
    };

    debugPrint("🔄 Sending Request → $body");
    debugPrint("🔐 SID: $sid");
    debugPrint("🌐 URL: $url");

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
          (jsonResponse['message']['success'] == true || jsonResponse['message'] is String)) {
        final message = jsonResponse['message'] is String
            ? jsonResponse['message']
            : jsonResponse['message']['message'] ?? "Status updated successfully";
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Order Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repair Order ID:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              widget.repairOrderId,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: width * 0.8,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateRepairOrderStatus("working_progress"),
                      icon: const Icon(Icons.work_outline),
                      label: const Text("Mark as Working Progress"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: width * 0.8,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateRepairOrderStatus("ready_order"),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Mark as Ready Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
