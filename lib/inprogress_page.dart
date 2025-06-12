import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key});

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _data;
  final TextEditingController _repairOrderController = TextEditingController(text: "RO250047");

  Future<void> _fetchRepairOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });

    final repairOrderId = _repairOrderController.text.trim();
    final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.repairorder_inprogress');

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');

      if (sid == null || sid.isEmpty) {
        setState(() {
          _error = 'Session expired. Please login again.';
        });
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode({"repairorder_id": repairOrderId}),
      );

      final jsonResponse = json.decode(response.body);
      final message = jsonResponse['message'];

      if (response.statusCode == 200 && message is Map<String, dynamic>) {
        setState(() => _data = message);
      } else {
        setState(() => _error = 'Failed to fetch data');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAmountRow(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("₹$value", style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildStepper(String currentStatus) {
    final steps = ["CREATED", "IN PROGRESS", "VEHICLE READY", "PAYMENT DUE", "PAYMENT DONE"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: steps.map((step) {
        final isActive = steps.indexOf(step) <= steps.indexOf(currentStatus.toUpperCase());
        return Column(
          children: [
            Icon(Icons.circle, size: 12, color: isActive ? Colors.green : Colors.grey),
            const SizedBox(height: 4),
            Text(step, style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.grey)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildServiceOrPartList(String title, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...items.map((item) => ListTile(
          title: Text(item['item_name'] ?? ''),
          trailing: const Icon(Icons.edit, size: 18, color: Colors.green),
        )),
        const Divider(thickness: 1),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchRepairOrder);
  }

  @override
  Widget build(BuildContext context) {
    final car = _data?['vehicle_model'] ?? '';
    final customer = _data?['customer_name'] ?? '';
    final mobile = _data?['mobile'] ?? '';
    final total = _data?['grand_total']?.toString() ?? '0';
    final received = _data?['paid_amount']?.toString() ?? '0';
    final due = _data?['balance_amount']?.toString() ?? '0';
    final discount = _data?['discount_amount']?.toString() ?? '0';
    final status = _data?['status'] ?? 'CREATED';

    final services = List<Map<String, dynamic>>.from(_data?['services'] ?? []);
    final parts = List<Map<String, dynamic>>.from(_data?['parts'] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('Repair Order In Progress')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _data == null
          ? const Center(child: Text("No data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepper(status),
            const SizedBox(height: 16),
            Text(customer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(mobile, style: const TextStyle(color: Colors.grey)),
            Text(car, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAmountRow("Total", total, Colors.black),
                _buildAmountRow("Received", received, Colors.green),
                _buildAmountRow("Due", due, Colors.red),
                _buildAmountRow("Discount", discount, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            _buildServiceOrPartList("SERVICES", services),
            _buildServiceOrPartList("PARTS", parts),
          ],
        ),
      ),
    );
  }
}
