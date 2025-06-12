import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/part_service.dart';
import 'package:garage_app/service_page.dart';
import 'package:garage_app/record_payment.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Vehicle extends StatefulWidget {
  final Map<String, dynamic>? order;
  const Vehicle({Key? key, this.order}) : super(key: key);

  @override
  State<Vehicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vehicle> {
  final _customerName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> selectedParts = [];
  List<Map<String, dynamic>> selectedServices = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  double tax = 0.0;

  // Search functionality state variables
  Map<String, dynamic>? _customerDetails;
  String? _customerGroup;
  bool _noCustomerFound = false;
  List<dynamic>? _customerVehicles;

  // Getters for calculated totals
  double get partsSubtotal =>
      selectedParts.fold(0.0, (sum, e) => sum + (_toDouble(e['rate']) * _toDouble(e['qty'])));
  double get serviceTotal =>
      selectedServices.fold(0.0, (sum, e) => sum + (_toDouble(e['rate']) * _toDouble(e['qty'])));
  double get grandTotal => partsSubtotal + serviceTotal + tax;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      final o = widget.order!;
      _customerName.text = o['customer_name']?.toString() ?? '';
      _mobile.text = o['mobile']?.toString() ?? '';
      _email.text = o['email']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _customerName.dispose();
    _mobile.dispose();
    _email.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Converts a dynamic value to a double.
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// Displays a snackbar with the given message and color.
  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Retrieves the session ID from shared preferences.
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sid');
  }

  /// Searches for a customer by name using the API.
  Future<void> _searchCustomer(String query) async {
    if (query.trim().isEmpty) {
      _showMessage('⚠️ Please enter a search term.', Colors.orange);
      return;
    }

    setState(() {
      _isSearching = true;
      _customerDetails = null;
      _customerGroup = null;
      _noCustomerFound = false;
      _customerVehicles = null;
    });

    final sessionId = await _getSessionId();
    if (sessionId == null) {
      _showMessage('❌ No valid session. Please login again.', Colors.red);
      setState(() => _isSearching = false);
      return;
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.customer_name_search?customer_name=$encodedQuery',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);

        if (data['message'] == null ||
            data['message']['status'] != 'success' ||
            data['message']['data'] == null ||
            data['message']['data']['customer'] == null) {
          setState(() {
            _isSearching = false;
            _noCustomerFound = true;
          });
          _showMessage('⚠️ No customer found.', Colors.orange);
          return;
        }

        final customerData = data['message']['data']['customer'];
        final vehicles = data['message']['data']['vehicles'] ?? [];

        if (customerData != null && customerData is Map<String, dynamic>) {
          setState(() {
            _customerDetails = customerData;
            _customerVehicles = vehicles;
            _isSearching = false;
            _noCustomerFound = false;
          });
          _showMessage('✅ Customer data loaded.', Colors.green);

          _customerName.text = customerData['customer_name'] ?? '';
          if (customerData['mobile_no'] != null) {
            _mobile.text = customerData['mobile_no'].toString();
          }
          if (customerData['email_id'] != null) {
            _email.text = customerData['email_id'].toString();
          }
          if (customerData['customer_type'] != null) {
            _customerGroup = customerData['customer_type'];
          }
        } else {
          setState(() {
            _isSearching = false;
            _noCustomerFound = true;
          });
          _showMessage('⚠️ Invalid customer data format.', Colors.orange);
        }
      } else {
        setState(() {
          _isSearching = false;
          _noCustomerFound = true;
        });
        _showMessage('❌ Search failed with status: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _noCustomerFound = true;
      });
      _showMessage('❌ Error during search: $e', Colors.red);
    }
  }

  /// Clears the customer data and resets the form.
  void _clearCustomerData() {
    setState(() {
      _customerDetails = null;
      _customerVehicles = null;
      _customerGroup = null;
      _noCustomerFound = false;
      _customerName.text = '';
      _mobile.text = '';
      _email.text = '';
    });
    _showMessage('✅ Customer data cleared.', Colors.green);
  }

  /// Shows a confirmation dialog before deleting customer data.
  void _showDeleteConfirmation() {
    if (_customerDetails == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to remove ${_customerDetails!['customer_name']} from this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCustomerData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Builds the customer card to display search results.
  Widget _buildCustomerCard() {
    final customer = _customerDetails;
    if (customer == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Found:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${customer['customer_name'] ?? 'N/A'}'),
                      if (customer['mobile_no'] != null) Text('Mobile: ${customer['mobile_no']}'),
                      if (customer['email_id'] != null) Text('Email: ${customer['email_id']}'),
                      if (customer['customer_type'] != null) Text('Type: ${customer['customer_type']}'),
                      if (customer['territory'] != null) Text('Territory: ${customer['territory']}'),
                      if (_customerVehicles != null && _customerVehicles!.isNotEmpty)
                        Text('Vehicles: ${_customerVehicles!.length}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the services page to select services.
  Future<void> _openServicesPage() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (_) => const ServicePage()),
    );
    if (result != null) {
      setState(() => selectedServices = result);
      _showMessage('✅ Services added.', Colors.green);
    }
  }

  /// Opens the parts page to select parts and tax.
  Future<void> _openPartsPage() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceAndParts()),
    );
    if (result == null) return;

    final rawItems = result['items'];
    final newTax = _toDouble(result['tax']);

    final parts = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (var e in rawItems) {
        if (e is Map<String, dynamic>) parts.add(e);
      }
    }

    setState(() {
      selectedParts = parts;
      tax = newTax;
    });
    _showMessage('✅ Parts added.', Colors.green);
  }

  /// Submits the invoice to the API and navigates to RecordPayment.
  Future<void> _submitInvoice() async {
    if (_customerName.text.trim().isEmpty) {
      return _showMessage("⚠️ Customer name is required.", Colors.orange);
    }

    if (selectedServices.isEmpty && selectedParts.isEmpty) {
      return _showMessage("⚠️ Add at least one service or part.", Colors.orange);
    }

    setState(() {
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid') ?? '';
    if (sid.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      return _showMessage("❌ Session expired. Please login again.", Colors.red);
    }

    final items = [
      ...selectedServices,
      ...selectedParts,
    ].map((e) => {
      "item_code": e['item_code'] ?? e['item_name'],
      "item_name": e['item_name'],
      "item_qty": (_toDouble(e['qty']).toInt()).toString(),
    }).toList();

    final payload = {
      "params": {
        "customer": _customerName.text.trim(),
        "mobile": _mobile.text.trim(),
        "items": items,
      },
    };

    try {
      final res = await http.post(
        Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.c_salesinvoice_without_repairorder'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _showMessage("❌ API Error: Status code ${res.statusCode}", Colors.red);
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final body = jsonDecode(res.body);

      if (body['message'] == "Sales Invoice Details" && body['data'] != null) {
        final data = body['data'];
        final invoiceId = data['invoice_id'] as String;
        final totalAmount = _toDouble(data['grand_total']);

        _showMessage("✅ Invoice created: $invoiceId", Colors.green);

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

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // Navigate to RecordPayment with grandTotal
        final paymentResult = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => RecordPayment(
              id: invoiceIdInt,
              name: invoiceId,
              totalAmount: grandTotal, // Fixed: Pass the calculated grandTotal
            ),
          ),
        );

        // Return success to previous screen if payment was recorded
        if (mounted && paymentResult == true) {
          Navigator.pop(context, true);
        }
      } else {
        String errorMessage = "❌ Failed to create invoice.";
        if (body['error'] != null) {
          errorMessage = "❌ ${body['error'].toString()}";
        } else if (body['_server_messages'] != null) {
          try {
            final serverMsgs = jsonDecode(body['_server_messages']);
            if (serverMsgs is List && serverMsgs.isNotEmpty) {
              final firstMsg = jsonDecode(serverMsgs[0]);
              errorMessage = "❌ ${firstMsg['message'] ?? 'Unknown server error.'}";
            }
          } catch (e) {
            errorMessage = "❌ Failed to parse server error.";
          }
        }
        _showMessage(errorMessage, Colors.red);
      }
    } catch (e) {
      _showMessage("❌ Error: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Builds a text field with the specified properties.
  Widget _buildTextField(
      TextEditingController ctrl,
      String label,
      double w, {
        TextInputType type = TextInputType.text,
        VoidCallback? onSubmitted,
      }) =>
      Padding(
        padding: EdgeInsets.only(top: w * 0.025),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.02)),
            suffixIcon: ctrl == _searchController
                ? IconButton(icon: const Icon(Icons.search), onPressed: onSubmitted)
                : null,
          ),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
      );

  /// Builds the search field for customer search.
  Widget _buildSearchField(double w) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Customer',
                hintText: 'Enter customer name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.02)),
                suffixIcon: IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.search),
                  onPressed: _isSearching ? null : () => _searchCustomer(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => _searchCustomer(value.trim()),
            ),
            if (_noCustomerFound)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No customer found. Try a different search term.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_customerDetails != null) _buildCustomerCard(),
          ],
        ),
      ),
    );
  }

  /// Builds a list tile for displaying an item (service or part).
  Widget _buildItemTile(Map<String, dynamic> item) {
    return ListTile(
      title: Text(item['item_name']?.toString() ?? 'Unknown Item'),
      subtitle: Text('Qty: ${_toDouble(item['qty'])} × ₹${_toDouble(item['rate'])}'),
      trailing: Text('₹${(_toDouble(item['qty']) * _toDouble(item['rate'])).toStringAsFixed(2)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final currentTime = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(currentTime); // e.g., 02:41 PM
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(currentTime); // e.g., Tuesday, May 27, 2025

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Current Time: $formattedTime IST, $formattedDate",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchField(w),
            const SizedBox(height: 16),
            _buildTextField(_customerName, "Customer Name", w),
            const SizedBox(height: 12),
            _buildTextField(_mobile, "Mobile Number", w, type: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(_email, "Email", w, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openServicesPage,
                    icon: const Icon(Icons.room_service),
                    label: const Text("Add Services"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openPartsPage,
                    icon: const Icon(Icons.build),
                    label: const Text("Add Parts"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedServices.isNotEmpty) ...[
              const Text(
                "Services",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...selectedServices.map((e) => _buildItemTile(e)),
            ],
            if (selectedParts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Parts",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...selectedParts.map((e) => _buildItemTile(e)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  const Text(
                    "Invoice Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  _buildSummaryRow("Parts Subtotal", partsSubtotal),
                  _buildSummaryRow("Tax", tax),
                  _buildSummaryRow("Service Total", serviceTotal),
                  const Divider(),
                  _buildSummaryRow("Grand Total", grandTotal, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Create Invoice",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a summary row for the invoice summary section.
  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}