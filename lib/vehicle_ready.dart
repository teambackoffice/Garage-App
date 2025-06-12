import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/part_service.dart';
import 'package:garage_app/service_page.dart';
import 'package:garage_app/record_payment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  double tax = 0.0;
  bool _isLoading = false;
  String? _invoiceName;
  String? customerId;
  String? repairOrderId;

  // Getters for calculated values
  double get partsSubtotal =>
      selectedParts.isEmpty
          ? _toDouble(widget.customerData['calculated_parts_total'] ?? widget.customerData['parts_total'] ?? 0.0)
          : selectedParts.fold(0.0, (sum, item) => sum + ((item['rate'] ?? 0.0) * (item['qty'] ?? 0)));


  double get serviceTotalAmount =>
      selectedServices.isEmpty
          ? _toDouble(widget.customerData['calculated_service_total'] ?? widget.customerData['service_total'] ?? 0.0)
          : selectedServices.fold(0.0, (sum, item) => sum + ((item['rate'] ?? 0.0) * (item['qty'] ?? 0)));

  double get taxAmount => tax > 0 ? tax : _toDouble(widget.customerData['calculated_tax_amount'] ?? widget.customerData['tax_amount'] ?? 0.0);

  double get totalPartsValue => partsSubtotal + taxAmount;

  double get grandTotal => serviceTotalAmount + totalPartsValue;

  @override
  void initState() {
    print('grand total $grandTotal');
    print("the WIDGET.SERVICE TOTAL///////// ${widget.customerData['calculated_service_total']}");
    print("the WIDGET.PARTSS TOTAL====== ${widget.customerData['calculated_parts_total']}");
    super.initState();
    _customerName.text = widget.customerData['customer_name']?.toString() ?? '';
    _mobile.text = widget.customerData['mobile_number']?.toString() ?? '';
    _email.text = widget.customerData['email_id']?.toString() ?? '';
    customerId = widget.customerData['customer_id']?.toString();
    repairOrderId = widget.customerData['name']?.toString() ?? '';

    // Initialize tax amount
    tax = _toDouble(widget.customerData['calculated_tax_amount'] ?? widget.customerData['tax_amount'] ?? 0.0);

    // Initialize service items
    if (widget.customerData['service_items'] != null) {
      try {
        final serviceItems = widget.customerData['service_items'];
        if (serviceItems is List) {
          selectedServices = List<Map<String, dynamic>>.from(
            serviceItems.map((item) => item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item)),
          );
        }
      } catch (e) {
        _showMessage("Error loading service items: $e", Colors.red);
      }
    }

    // Initialize parts items
    if (widget.customerData['parts_items'] != null) {
      try {
        final partsItems = widget.customerData['parts_items'];
        if (partsItems is List) {
          selectedParts = List<Map<String, dynamic>>.from(
            partsItems.map((item) => item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item)),
          );
        }
      } catch (e) {
        _showMessage("Error loading parts items: $e", Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _customerName.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Converts a dynamic value to a double.
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Displays a snackbar with the given message and color.
  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Opens the parts selection page and updates selected parts and tax.
  Future<void> _openPartsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceAndParts()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedParts = List<Map<String, dynamic>>.from(result['items'] ?? []);
        tax = result['tax'] ?? 0.0;
      });
    }
  }

  /// Opens the services selection page and updates selected services.
  Future<void> _openServicesPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServicePage()),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() => selectedServices = result);
    }
  }

  /// Creates and submits the invoice to the API.
  Future<void> createInvoiceAndSubmit() async {

    if (_customerName.text.trim().isEmpty) {
      return _showMessage("⚠️ Customer name is required.", Colors.orange);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid') ?? '';
      if (sid.isEmpty) {
        _showMessage("❌ Your session has expired. Please log in again.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final items = [
        ...selectedServices,
        ...selectedParts,

      ].map((e) => {
        "item_code": e['item_code'] ?? e['item_name'],
        "item_name": e['item_name'],
        "qty": _toDouble(e['qty'] ?? 1).toInt(),
        "rate": _toDouble(e['rate'] ?? 0),
        "discount_amount": e['discount_amount'] ?? 0,
      }).toList();
      print('all ------items  ${jsonEncode(items)}');

      if (items.isEmpty) {
        _showMessage("⚠️ Please add at least one service or part to proceed.", Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      final payload = {
        "name": _customerName.text.trim(),
        "repair_order": repairOrderId ?? "",
        "items": items,
      };

      final response = await http.post(
        Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.c_salesinvoice'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200){
        print("===== the response is ===== ${response.body}");
      }

      if (response.statusCode >= 400) {
        print("the response of 400 ${response.body}");
        _showMessage("❌ Failed to submit invoice. Server returned status code ${response.statusCode}.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        _showMessage("❌ Failed to read server response. Please try again.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Handle known server-side error format
      if (body['message'] is Map && body['message']['status'] == 'error') {
        final errorMsg = body['message']['message'] ?? "An unknown error occurred.";
        _showMessage("❌ $errorMsg", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Handle _server_messages if present
      if (body['_server_messages'] != null) {
        try {
          final serverMsgs = jsonDecode(body['_server_messages']);
          if (serverMsgs is List && serverMsgs.isNotEmpty) {
            final firstMsg = jsonDecode(serverMsgs[0]);
            final errorMsg = firstMsg['message'] ?? "An unknown server error occurred.";
            _showMessage("❌ Server Error: $errorMsg", Colors.red);
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          _showMessage("❌ Failed to parse server error message.", Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      // Handle various success response formats
      if (body['message'] is Map && body['message']['status'] == 'success' && body['message']['data'] != null) {
        await _handleSuccessResponse(body['message']['data']);
        return;
      }

      if (body['message'] == "Sales Invoice Details" && body['data'] != null) {
        await _handleSuccessResponse(body['data']);
        return;
      }

      if (body['data'] != null && body['data']['invoice_id'] != null) {
        await _handleSuccessResponse(body['data']);
        return;
      }

      if (body['invoice_id'] != null) {
        await _handleSuccessResponse(body);
        return;
      }

      // Unrecognized structure
      _showMessage("⚠️ Unexpected server response. Please try again.", Colors.red);
      setState(() => _isLoading = false);

    } catch (e) {
      _showMessage("❌ Something went wrong while creating the invoice: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  /// Handles successful invoice creation and navigates to RecordPayment.
  Future<void> _handleSuccessResponse(Map<String, dynamic> data) async {
    final String invoiceId = data['invoice_id']?.toString() ?? '';
    if (invoiceId.isEmpty) {
      _showMessage("⚠️ Invoice created but no ID received.", Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    _showMessage("✅ Invoice created: $invoiceId", Colors.green);

    // Extract numeric part of invoice ID
    int invoiceIdInt = 0;
    try {
      final parts = invoiceId.split('-');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        invoiceIdInt = int.tryParse(lastPart) ?? 0;
      }
    } catch (e) {
      _showMessage("⚠️ Error parsing invoice ID: $e", Colors.orange);
    }

    // Small delay before navigation
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Navigate to RecordPayment and pass the grandTotal
    final paymentResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RecordPayment(
          id: invoiceIdInt,
          name: invoiceId,
          totalAmount: grandTotal, // Pass the grandTotal
        ),
      ),
    );

    // Return success to previous screen
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  /// Builds a list of items (services or parts) for display.
  Widget _buildItemList(
      String title,
      List<Map<String, dynamic>> items,
      void Function(int index) onDelete,
      ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          var e = entry.value;

          return ListTile(
            title: Text(e['item_name']?.toString() ?? 'Unknown Item'),
            subtitle: Text('Qty: ${e['qty'] ?? 1} × ₹${e['rate'] ?? 0}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${((e['rate'] ?? 0.0) * (e['qty'] ?? 1)).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Builds a row for displaying price details.
  Widget _buildPriceRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: bold ? TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Information Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customerName,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mobile,
                    decoration: const InputDecoration(
                      labelText: 'Mobile',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (repairOrderId != null && repairOrderId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Repair Order: $repairOrderId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Services and Parts Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openServicesPage,
                    icon: const Icon(Icons.build),
                    label: const Text('Add Services'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openPartsPage,
                    icon: const Icon(Icons.settings),
                    label: const Text('Add Parts'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Items Lists
            _buildItemList('Services', selectedServices, (index) {
              setState(() {
                selectedServices.removeAt(index);
              });
            }),
            if (selectedServices.isNotEmpty) const SizedBox(height: 16),
            _buildItemList('Parts', selectedParts, (index) {
              setState(() {
                selectedParts.removeAt(index);
              });
            }),


            // Price Summary Card
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Invoice Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildPriceRow('Service Total', serviceTotalAmount),
                  _buildPriceRow('Parts Subtotal', partsSubtotal),
                  _buildPriceRow('Tax', taxAmount),
                  _buildPriceRow('Total Parts Amount', totalPartsValue),
                  const Divider(),
                  _buildPriceRow('Grand Total', grandTotal, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : createInvoiceAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Create & Submit Invoice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}