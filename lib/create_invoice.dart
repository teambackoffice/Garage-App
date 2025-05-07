import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/service_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:garage_app/part_service.dart';
import 'package:garage_app/record_payment.dart';

class Vehicle extends StatefulWidget {
  final Map<String, dynamic>? order;

  const Vehicle({super.key, this.order});

  @override
  State<Vehicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vehicle> {
  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> selectedParts = [];
  List<Map<String, dynamic>> selectedServices = [];

  double get partsSubtotal => selectedParts.fold(
      0.0, (sum, item) => sum + (item['rate'] ?? 0.0) * (item['qty'] ?? 0));
  double get serviceTotal => selectedServices.fold(
      0.0, (sum, item) => sum + (item['rate'] ?? 0.0) * (item['qty'] ?? 0));
  double get grandTotal => serviceTotal + partsSubtotal;

  @override
  void initState() {
    super.initState();
    final orderData = widget.order;
    if (orderData != null) {
      _customerName.text = orderData['customer_name'] ?? '';
      _mobile.text = orderData['mobile_number'] ?? '';
      _email.text = orderData['email'] ?? orderData['email_id'] ?? '';
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  Future<void> createInvoiceWithoutRepairOrder() async {
    final name = _customerName.text.trim();

    if (name.isEmpty) {
      _showMessage("Customer name is required", Colors.orange);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid');

    if (sessionId == null || sessionId.isEmpty) {
      _showMessage("Session expired. Please log in again.", Colors.red);
      return;
    }

    final items = [...selectedServices, ...selectedParts].map((item) {
      return {
        "item_code": item['item_code'] ?? item['item_name'] ?? '',
        "item_name": item['item_name'] ?? '',
        "item_qty": item['qty'] ?? 0,
      };
    }).toList();

    if (items.isEmpty) {
      _showMessage("Please add at least one service or part.", Colors.orange);
      return;
    }

    final invoicePayload = {
      "name": name,
      "items": items,
    };

    try {
      final invoiceRes = await http.post(
        Uri.parse(
            'https://garage.teambackoffice.com/api/method/garage.garage.auth.c_salesinvoice_without_repairorder'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
        body: jsonEncode(invoicePayload),
      );

      final invoiceBody = jsonDecode(invoiceRes.body);
      print("🧾 Invoice Response: $invoiceBody");

      if (invoiceRes.statusCode == 200 &&
          invoiceBody['message']?['status'] == 'success') {
        final invoiceName = invoiceBody['message']['invoice_name'];
        _showMessage("Invoice $invoiceName created successfully", Colors.green);

        setState(() {
          _searchController.clear();
          _customerName.clear();
          _mobile.clear();
          _email.clear();
          selectedServices.clear();
          selectedParts.clear();
        });

        // Navigate to Record Payment page if needed:
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => RecordPayment(invoiceName: invoiceName),
        // ));
      } else {
        final msg = invoiceBody['message'] is String
            ? invoiceBody['message']
            : invoiceBody['message']?['message'] ?? "Invoice creation failed.";
        _showMessage("Error: $msg", Colors.red);
      }
    } catch (e) {
      _showMessage("Exception: $e", Colors.red);
    }
  }

  Future<void> _openPartsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceAndParts()),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        selectedParts = result;
      });
    }
  }

  Future<void> _openServicesPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServicePage()),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        selectedServices = result;
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, double w,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.only(top: w * 0.03),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.025)),
        ),
      ),
    );
  }

  Widget _buildSectionTile(String title, VoidCallback onTap, double w) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: w * 0.02),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildItemList(String title, List<Map<String, dynamic>> items, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) => Card(
          child: ListTile(
            title: Text(item['item_name'] ?? 'Item'),
            subtitle: Text(
                'Qty: ${item['qty'] ?? 1} × ₹${item['rate']?.toStringAsFixed(2) ?? '0.00'}'),
            trailing: Text(
                '₹${((item['rate'] ?? 0.0) * (item['qty'] ?? 1)).toStringAsFixed(2)}'),
          ),
        )),
      ],
    );
  }

  Widget _buildPriceRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double w) {
    return Container(
      margin: EdgeInsets.only(top: w * 0.03),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.025),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          _buildPriceRow("Service Total", serviceTotal),
          _buildPriceRow("Parts", partsSubtotal),
          const Divider(),
          _buildPriceRow("Grand Total", grandTotal, bold: true),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(double w, double h) {
    return Center(
      child: ElevatedButton(
        onPressed: createInvoiceWithoutRepairOrder,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: w * 0.3, vertical: h * 0.02),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Submit", style: TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Create Invoice", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_customerName, "Customer Name", w),
            _buildTextField(_mobile, "Mobile Number", w, keyboard: TextInputType.phone),
            _buildTextField(_email, "Email", w, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildSectionTile("Select Services", _openServicesPage, w),
            if (selectedServices.isNotEmpty) _buildItemList("Services", selectedServices, w),
            const SizedBox(height: 12),
            _buildSectionTile("Select Parts", _openPartsPage, w),
            if (selectedParts.isNotEmpty) _buildItemList("Parts", selectedParts, w),
            _buildSummaryCard(w),
            const SizedBox(height: 20),
            _buildSubmitButton(w, h),
          ],
        ),
      ),
    );
  }
}
