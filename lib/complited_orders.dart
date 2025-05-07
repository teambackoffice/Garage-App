import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CompliteOrders extends StatefulWidget {
  const CompliteOrders({super.key});

  @override
  State<CompliteOrders> createState() => _CompliteOrdersState();
}

class _CompliteOrdersState extends State<CompliteOrders> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedOrders();
  }

  Future<void> _fetchCompletedOrders() async {
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
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_completed_repair_orders_with_count');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final jsonResponse = jsonDecode(response.body);
      debugPrint("📦 Completed Orders Response: $jsonResponse");

      if (response.statusCode == 200 && jsonResponse['message']?['data'] is List) {
        setState(() {
          _orders = jsonResponse['message']['data'];
        });
      } else {
        setState(() {
          _error = '❌ Failed to load completed orders.';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("Customer: ${order['customer_name'] ?? '-'}"),
            Text("Mobile: ${order['mobile_number'] ?? '-'}"),
            Text("Vehicle: ${order['make'] ?? ''} ${order['model'] ?? ''}"),
            Text("Reg No: ${order['registration_number'] ?? '-'}"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: ₹${order['grand_total'] ?? 0}"),
                Text("Status: ${order['status'] ?? 'Completed'}",
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Completed Orders',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _orders.isEmpty
          ? const Center(child: Text("No completed orders found."))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }
}
