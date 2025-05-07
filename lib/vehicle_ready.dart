import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/part_service.dart';
import 'package:garage_app/service_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav.dart';
import 'main.dart';
import 'record_payment.dart';

class Create extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const Create({Key? key, required this.customerData}) : super(key: key);

  @override
  State<Create> createState() => _CreateState();
}

class _CreateState extends State<Create> {
  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();

  List<Map<String, dynamic>> selectedServices = [];
  List<Map<String, dynamic>> selectedParts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerName.text = widget.customerData['customer_name'] ?? '';
    _mobile.text = widget.customerData['mobile_number'] ?? '';
    _email.text = widget.customerData['email_id'] ?? '';
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

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final qty = item['qty'] ?? 1;
      final rate = item['rate'] ?? 0;
      return sum + (qty * rate);
    });
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
      setState(() => _isLoading = true);

      final invoiceRes = await http.post(
        Uri.parse('https://garage.teambackoffice.com/api/method/garage.garage.auth.c_salesinvoice_without_repairorder'),
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
        final serviceTotal = calculateTotal(selectedServices);
        final partsTotal = calculateTotal(selectedParts);
        final grandTotal = serviceTotal + partsTotal;

        _showMessage("Invoice $invoiceName created successfully", Colors.green);

        setState(() {
          _customerName.clear();
          _mobile.clear();
          _email.clear();
          selectedServices.clear();
          selectedParts.clear();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordPayment(
              invoiceName: invoiceName,
              totalAmount: grandTotal, // Pass the grand total
            ),
          ),
        );
      } else {
        final msg = invoiceBody['message'] is String
            ? invoiceBody['message']
            : invoiceBody['message']?['message'] ?? "Invoice creation failed.";
        _showMessage("Error: $msg", Colors.red);
      }
    } catch (e) {
      _showMessage("Exception: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPriceRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
          Text("₹${value.toStringAsFixed(2)}",
              style: bold
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceTotal = calculateTotal(selectedServices);
    final partsTotal = calculateTotal(selectedParts);
    final grandTotal = serviceTotal + partsTotal;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>BottomNavBarScreen()));
            },
              child: Container(child: Icon(Icons.home,color: Colors.black,)))
        ],
        title: const Text('Create Invoice'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Customer Info
                  TextFormField(
                    controller: _customerName,
                    decoration: const InputDecoration(
                      labelText: '👤 Customer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobile,
                    decoration: const InputDecoration(
                      labelText: '📞 Mobile',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: '📧 Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      InkWell(
                        onTap: _openServicesPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.miscellaneous_services, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Add Services", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _openPartsPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.settings, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Add Parts", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildPriceRow("Service Total", serviceTotal),
                  _buildPriceRow("Parts Total", partsTotal),
                  const Divider(),
                  _buildPriceRow("Grand Total", grandTotal, bold: true),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : InkWell(
                    onTap: createInvoiceWithoutRepairOrder,
                    child: Container(
                      width: screenWidth * 0.6,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Create Invoice",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
