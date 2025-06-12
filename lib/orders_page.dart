import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Ready.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({Key? key}) : super(key: key);

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid') ?? '';

      if (sid.isEmpty) {
        setState(() {
          _error = 'Session ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_created_repairorder_list',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          decoded['message'] != null &&
          decoded['message']['data'] is List) {
        setState(() {
          _orders = decoded['message']['data'];
          _isLoading = false;
        });
      } else {
        final msg = decoded['message']?['message'] ?? 'Unexpected server response.';
        setState(() {
          _error = 'Error: $msg';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching orders: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['name'] ?? 'N/A';
    final customer = order['customer_name'] ?? 'N/A';
    final make = order['make'] ?? 'N/A';
    final model = order['model'] ?? 'N/A';
    final regNo = order['registration_number'] ?? 'N/A';
    final grandTotal = (order['grand_total'] ?? 0).toStringAsFixed(2);
    final status = order['status'] ?? 'CREATED';
    final services = order['service_items'] ?? [];
    final parts = order['parts_items'] ?? [];

// Extract only the service names
    final serviceNames = services.map((item) => item['item_name'] ?? 'Unnamed Service').toList();
    final partNames = parts.map((item) => item['item_name'] ?? '').toList();

// If you want to display as a comma-separated string
    final serviceNamesString = serviceNames.join(', ');
    final partNamesString = partNames.join(', ');


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text("Order ID: $orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: $customer"),
            Text("Make/Model: $make / $model"),
            Text("Reg No: $regNo"),
            Text("Total: ₹$grandTotal"),
            Text("Status: $status"),


          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReadyOrder(repairOrderId: orderId,service_items: serviceNamesString,parts_items: partNamesString,status : status),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Repair Orders")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _orders.isEmpty
          ? const Center(child: Text("No repair orders found."))
          : RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(_orders[index]);
          },
        ),
      ),
    );
  }
}
