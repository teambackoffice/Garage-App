import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentDuePage extends StatefulWidget {
  const PaymentDuePage({super.key});

  @override
  State<PaymentDuePage> createState() => _PaymentDuePageState();
}

class _PaymentDuePageState extends State<PaymentDuePage> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentDueOrders();
  }

  Future<void> _fetchPaymentDueOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');

      if (sid == null || sid.isEmpty) {
        setState(() {
          _error = '❌ Session expired. Please login again.';
          _isLoading = false;
          _orders = []; // Clear orders if session is invalid
        });
        return;
      }

      final url = Uri.parse(
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_paymentdue_repair_orders_with_count',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      print("🔍 Payment Due Status: ${response.statusCode}");
      print("📩 Raw Response: ${response.body}");

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final message = jsonResponse['message'];

        if (message != null && message['data'] is List) {
          setState(() {
            _orders = List<Map<String, dynamic>>.from(message['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = '❌ No orders found or invalid data format.';
            _orders = [];
            _isLoading = false;
          });
        }
      } else {
        final errorMsg = jsonResponse['message'] ?? 'Unknown error occurred.';
        setState(() {
          _error = '❌ Server Error: $errorMsg';
          _orders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Exception: ${e.toString()}';
        _orders = [];
        _isLoading = false;
      });
    }
  }


  Widget _buildOrderCard(Map<String, dynamic> order, double fontSize) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order['name'] ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize + 2,
              ),
            ),
            const SizedBox(height: 4),
            Text("Customer: ${order['customer_name'] ?? '-'}",
                style: TextStyle(fontSize: fontSize)),
            Text("Mobile: ${order['mobile_number'] ?? '-'}",
                style: TextStyle(fontSize: fontSize)),
            Text("Vehicle: ${order['make'] ?? ''} ${order['model'] ?? ''}",
                style: TextStyle(fontSize: fontSize)),
            Text("Reg No: ${order['registration_number'] ?? '-'}",
                style: TextStyle(fontSize: fontSize)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: ₹${order['grand_total'] ?? 0}",
                    style: TextStyle(fontSize: fontSize)),
                Text("Status: ${order['status'] ?? 'Payment Due'}",
                    style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.038; // Adaptive font size

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Payment Due',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPaymentDueOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
          ),
        )
            : _orders.isEmpty
            ? const Center(child: Text("No payment due orders found."))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(_orders[index], fontSize);
          },
        ),
      ),
    );
  }
}
