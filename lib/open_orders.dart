import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'open_view page.dart';

class OpenRepairOrderListPage extends StatefulWidget {
  const OpenRepairOrderListPage({super.key});

  @override
  State<OpenRepairOrderListPage> createState() => _OpenRepairOrderListPageState();
}

class _OpenRepairOrderListPageState extends State<OpenRepairOrderListPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sid');
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sid = await _getSessionId();
    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = "❌ Session expired. Please login again.";
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_repairorder_open_count',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final decoded = jsonDecode(response.body);
      debugPrint("📦 Orders Response: $decoded");

      if (response.statusCode == 200 && decoded['message']?['data'] != null) {
        final List<Map<String, dynamic>> dataList =
        List<Map<String, dynamic>>.from(decoded['message']['data']);

        setState(() {
          _orders = dataList;
        });
      } else {
        setState(() {
          _error = decoded['message']?.toString() ?? '❌ Unexpected response';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order['name'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Customer: ${order['customer_name'] ?? '-'}"),
          Text("Mobile: ${order['mobile_number'] ?? '-'}"),
          Text("Model: ${order['model'] ?? '-'}"),
          Text("Make: ${order['make'] ?? '-'}"),
          Text("Reg. No.: ${order['registration_number'] ?? '-'}"),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ₹${order['grand_total'] ?? 0}", style: const TextStyle(color: Colors.black)),
              Text("Status: ${order['status'] ?? '-'}", style: const TextStyle(color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Open Repair Orders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isLoading) return const Center(child: CircularProgressIndicator());
          if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
          if (_orders.isEmpty) return const Center(child: Text("No orders found."));

          return RefreshIndicator(
            onRefresh: _fetchOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final repairOrderId = _orders[index]['name'];
                return GestureDetector(
                  onTap: () async {
                    if (repairOrderId != null && repairOrderId.isNotEmpty) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenViewPage(repairOrderId: repairOrderId),
                        ),
                      );
                      _fetchOrders(); // Refresh on return
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ Invalid Repair Order ID")),
                      );
                    }
                  },
                  child: _buildOrderCard(_orders[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
