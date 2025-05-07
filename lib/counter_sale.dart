import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_invoice.dart';
import 'record_payment.dart';
import 'service_page.dart';
import 'part_service.dart';

class CounterSale extends StatefulWidget {
  const CounterSale({super.key});

  @override
  State<CounterSale> createState() => _CounterSaleState();
}

class _CounterSaleState extends State<CounterSale> {
  final _searchController = TextEditingController();
  final _customerName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _repairOrder = TextEditingController(); // FIXED: Added this line

  bool isLoadingCustomer = false;
  bool isSubmittingInvoice = false;

  Map<String, dynamic>? customerDetails;
  List<Map<String, dynamic>> selectedServices = [];
  List<Map<String, dynamic>> selectedParts = [];

  double get serviceSubtotal =>
      selectedServices.fold(0.0, (sum, item) => sum + (item['rate'] ?? 0) * (item['qty'] ?? 0));

  double get partsSubtotal =>
      selectedParts.fold(0.0, (sum, item) => sum + (item['rate'] ?? 0) * (item['qty'] ?? 0));

  double get grandTotal => serviceSubtotal + partsSubtotal;

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> searchCustomer() async {
    final name = Uri.encodeComponent(_searchController.text.trim());
    if (name.isEmpty) {
      _showMessage("Enter customer name to search", Colors.orange);
      return;
    }

    setState(() => isLoadingCustomer = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid') ?? '';

      final url =
          'https://garage.teambackoffice.com/api/method/garage.garage.auth.customer_name_search?customer_name=$name';
      final res = await http.get(Uri.parse(url), headers: {'Cookie': 'sid=$sid'});
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['message']['status'] == 'success') {
        final customer = data['message']['data'];
        _customerName.text = customer['customer_name'] ?? '';
        _mobile.text = customer['mobile_no'] ?? '';
        _email.text = customer['email_id'] ?? '';
        setState(() => customerDetails = customer);
        _showMessage("Customer loaded", Colors.green);
      } else {
        _clearCustomerFields();
        _showMessage("Customer not found", Colors.red);
      }
    } catch (e) {
      _showMessage("Error: $e", Colors.red);
    } finally {
      setState(() => isLoadingCustomer = false);
    }
  }

  void _clearCustomerFields() {
    _customerName.clear();
    _mobile.clear();
    _email.clear();
    _repairOrder.clear();
    customerDetails = null;
  }

  void _resetForm() {
    _searchController.clear();
    _clearCustomerFields();
    selectedServices.clear();
    selectedParts.clear();
  }

  Future<void> _openServicePage() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicePage()));
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() => selectedServices = result);
    }
  }

  Future<void> _openPartsPage() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceAndParts()));
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() => selectedParts = result);
    }
  }
  Future<void> submitInvoice() async {
    if (_customerName.text.trim().isEmpty) {
      _showMessage("Customer name required", Colors.red);
      return;
    }
    if (_repairOrder.text.trim().isEmpty) {
      _showMessage("Repair order required", Colors.red);
      return;
    }
    if (selectedServices.isEmpty && selectedParts.isEmpty) {
      _showMessage("Add at least one service or part", Colors.red);
      return;
    }

    final items = [
      ...selectedServices.map((e) => {
        "item_code": e['item_name'],
        "item_name": e['item_name'],
        "item_qty": e['qty']
      }),
      ...selectedParts.map((e) => {
        "item_code": e['item_name'],
        "item_name": e['item_name'],
        "item_qty": e['qty']
      }),
    ];

    final payload = {
      "name": _customerName.text.trim(),
      "repair_order": _repairOrder.text.trim(),
      "items": items,
    };

    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.c_salesinvoice';

    setState(() => isSubmittingInvoice = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid') ?? '';

      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(payload),
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          decoded['message'] is Map &&
          decoded['message']['invoice_name'] != null) {
        final invoiceName = decoded['message']['invoice_name'];

        _showMessage("✅ Invoice created", Colors.green);
        _resetForm();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Vehicle()),
        );
      } else {
        _showMessage("❌ Failed to create invoice", Colors.red);
      }
    } catch (e) {
      _showMessage("🚫 Error: $e", Colors.red);
    } finally {
      setState(() => isSubmittingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Counter Sale'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Customer Info"),
            _buildSearchField(),
            if (isLoadingCustomer) const Center(child: CircularProgressIndicator()),
            _buildCustomerDetailsCard(),
            _buildTextField(_customerName, "Customer Name"),
            const SizedBox(height: 8),
            _buildTextField(_mobile, "Mobile", keyboard: TextInputType.phone),
            const SizedBox(height: 8),
            _buildTextField(_email, "Email", keyboard: TextInputType.emailAddress),
            const SizedBox(height: 8),
            _buildTextField(_repairOrder, "Repair Order"), // FIXED: Added repair order input
            const SizedBox(height: 20),
            _sectionTitle("Add Services"),
            _addButton("Add Services", Icons.home_repair_service, _openServicePage),
            if (selectedServices.isNotEmpty) _buildItemList("Selected Services", selectedServices),
            const SizedBox(height: 20),
            _sectionTitle("Add Parts"),
            _addButton("Add Parts", Icons.build_circle, _openPartsPage),
            if (selectedParts.isNotEmpty) _buildItemList("Selected Parts", selectedParts),
            const SizedBox(height: 20),
            _sectionTitle("Invoice Summary"),
            _buildSummaryCard(),
            const SizedBox(height: 18),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildSearchField() => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: _searchController,
      onFieldSubmitted: (_) => searchCustomer(),
      decoration: const InputDecoration(
        hintText: "Search Customer Name",
        prefixIcon: Icon(Icons.search),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );

  Widget _buildCustomerDetailsCard() {
    if (customerDetails == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(customerDetails?['customer_name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerDetails?['mobile_no'] ?? ''),
            Text(customerDetails?['email_id'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _addButton(String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildItemList(String title, List<Map<String, dynamic>> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: items
            .map((e) => ListTile(
          title: Text("${e['item_name']} (x${e['qty']})"),
          trailing: Text("\u20B9${(e['rate'] * e['qty']).toStringAsFixed(2)}"),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildSummaryCard() => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      title: const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text("\u20B9${grandTotal.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton.icon(
      onPressed:
      (isSubmittingInvoice || (selectedServices.isEmpty && selectedParts.isEmpty)) ? null : submitInvoice,
      icon: const Icon(Icons.receipt_long),
      label: isSubmittingInvoice
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Prepare Invoice"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),
  );
}
