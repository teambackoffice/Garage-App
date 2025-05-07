import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/create_invoice.dart';
import 'package:garage_app/vehicle_ready.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List<dynamic> repairOrders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchOpenRepairOrders();
  }

  Future<void> fetchOpenRepairOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid') ?? '';

    final url = Uri.parse(
      'https://garage.teambackoffice.com/api/method/garage.garage.auth.repairorder_ready_orders_count',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final jsonResponse = jsonDecode(response.body);
      debugPrint('🔄 Response: $jsonResponse');

      if (response.statusCode == 200 &&
          jsonResponse['message'] != null &&
          jsonResponse['message']['data'] != null) {
        setState(() {
          repairOrders = jsonResponse['message']['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Unexpected response format.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

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


  Widget _buildOrderCard(Map<String, dynamic> order, double w) {
    final vehicle = order['vehicle_details'] ?? {};
    final customerName = order['customer_name'] ?? 'N/A';
    final mobile = order['mobile_number'] ?? 'N/A';
    final email = order['email_id'] ?? 'N/A';
    final regNumber = order['registration_number'] ?? 'N/A';
    final serviceTotal = order['service_total'] ?? 0.0;
    final partsTotal = order['parts_total'] ?? 0.0;
    final grandTotal = order['grand_total'] ?? 0.0;
    final status = order['status'] ?? 'N/A';
    final date = order['posting_date'] ?? 'N/A';
    final orderId = order['name'] ?? 'N/A';

    final partsItems = order['parts_items'] ?? [];
    final partsDetails = partsItems.map((part) {
      return part['item_name'] ?? 'N/A';
    }).join(', ');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Create(
                customerData: order,


            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 10),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(w * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🛠️ Order ID: $orderId",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text("👤 Customer: $customerName"),
                  Text("📞 Mobile: $mobile"),
                  Text("📧 Email: $email"),
                  Text("🚘 Make: ${vehicle['make'] ?? 'N/A'}"),
                  Text("🚗 Model: ${vehicle['model'] ?? 'N/A'}"),
                  Text("🔢 Reg No: $regNumber"),
                  Text("📅 Date: $date"),
                  Text("📌 Status: $status"),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("💰 Services: ₹${serviceTotal.toStringAsFixed(2)}")),
                  Expanded(child: Text("🔧 Parts: ₹${partsTotal.toStringAsFixed(2)}")),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "💸 Total: ₹${grandTotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "🔧 Parts: $partsDetails",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final message =
                        "Hello $customerName, your vehicle with Reg. No. $regNumber is ready. Kindly collect it at your convenience. - GarageHub";
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
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        actions: const [Icon(Icons.home, color: Colors.black)],
        title: const Text(
          'Ready Repair Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
          : repairOrders.isEmpty
          ? const Center(child: Text('No ready orders found.'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: repairOrders.length,
        itemBuilder: (context, index) => _buildOrderCard(repairOrders[index], w),
      ),
    );
  }
}
