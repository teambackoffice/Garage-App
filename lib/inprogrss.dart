import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:garage_app/workin_progress_details.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bottom_nav.dart';

class InProgressRepairOrdersPage extends StatefulWidget {
  const InProgressRepairOrdersPage({super.key});

  @override
  State<InProgressRepairOrdersPage> createState() =>
      _InProgressRepairOrdersPageState();
}

class _InProgressRepairOrdersPageState extends State<InProgressRepairOrdersPage> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _orders = [];

  Future<void> openWhatsApp(String phone, String message) async {
    final phoneNumber = phone.replaceAll(RegExp(r'\D'), ''); // Clean the phone number
    final uri = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

    try {
      // Use the new launchUrl method
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


  Future<void> _fetchInProgressOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');

    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = '❌ Session expired. Please login again.';
        _isLoading = false;
      });
      return;
    }
    final url = Uri.parse(
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_repairorder_inprogress_count');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final jsonResponse = json.decode(response.body);
      debugPrint("📦 In-Progress Orders Response: $jsonResponse");

      if (response.statusCode == 200 &&
          jsonResponse['message']?['data'] is List) {
        setState(() {
          _orders = jsonResponse['message']['data'];
        });
      } else {
        setState(() {
          _error = '❌ Failed to load orders.';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String customerName = order['customer_name'] ?? 'N/A';
    final String mobile = order['mobile_number'] ?? '';
    final String regNumber = order['registration_number'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkInProgress(),
              settings: RouteSettings(arguments: order['name']), // ✅ Pass order ID
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text("Customer: ${order['customer_name'] ?? '-'}"),
              Text("Mobile: ${order['mobile_number'] ?? '-'}"),
              Text("Vehicle: ${order['make'] ?? ''} ${order['model'] ?? ''}"),
              Text("Reg No: ${order['registration_number'] ?? '-'}"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: ₹${order['grand_total'] ?? 0}"),
                  Text("Status: ${order['status'] ?? ''}", style: const TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              // WhatsApp Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final message = '''
Hello $customerName, your vehicle with Reg. No. $regNumber is ready. Kindly collect it at your convenience. - GarageHub
''';
                    openWhatsApp(mobile, message);
                  },
                  icon: const Icon(Icons.chat, color: Colors.green),
                  label: const Text("WhatsApp Customer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchInProgressOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In-Progress Repair Orders"),
        actions: [
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>BottomNavBarScreen()));
            },
              child: Container(child: Container(child: Icon(Icons.home,color: Colors.black,))))
        ],),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _orders.isEmpty
          ? const Center(child: Text("No orders found."))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }
}
