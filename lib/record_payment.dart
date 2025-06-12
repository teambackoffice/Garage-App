import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'bottom_nav.dart';

class RecordPayment extends StatefulWidget {
  final int id;
  final String name;
  final double totalAmount;

  const RecordPayment({
    Key? key,
    required this.id,
    required this.name,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<RecordPayment> createState() => _RecordPaymentState();
}

class _RecordPaymentState extends State<RecordPayment> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _referenceNumberController = TextEditingController();

  String _paymentMode = 'Cash';
  bool _isSubmitting = false;
  double _outstandingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _outstandingAmount = widget.totalAmount;
    _paidAmountController.addListener(_updateOutstandingAmount);
  }

  @override
  void dispose() {
    _paidAmountController.removeListener(_updateOutstandingAmount);
    _paidAmountController.dispose();
    _dateController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  /// Updates the outstanding amount as the user types the paid amount.
  void _updateOutstandingAmount() {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    setState(() {
      _outstandingAmount = widget.totalAmount - paid;
      if (_outstandingAmount < 0) _outstandingAmount = 0.0;
    });
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

  /// Opens a date picker and updates the date field.
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Prevent future dates
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  /// Validates the reference number based on the payment mode.
  String? _validateReferenceNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a reference number';
    }
    if (_paymentMode == 'UPI' && !value.contains('@')) {
      return 'UPI reference should contain "@" (e.g., user@upi)';
    }
    if (_paymentMode == 'Cheque' && value.length < 6) {
      return 'Cheque number should be at least 6 digits';
    }
    return null;
  }

  /// Shows a confirmation dialog before submitting the payment.
  Future<bool> _showConfirmationDialog() async {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${widget.name}'),
            Text('Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}'),
            Text('Paid Amount: ₹${paid.toStringAsFixed(2)}'),
            Text('Outstanding: ₹${_outstandingAmount.toStringAsFixed(2)}'),
            Text('Payment Mode: $_paymentMode'),
            Text('Reference: ${_referenceNumberController.text}'),
            Text('Date: ${_dateController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    ) ??
        false;
  }

  /// Submits the payment to the API.
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid') ?? '';
    if (sid.isEmpty) {
      _showMessage('❌ Session expired. Please log in again.', Colors.red);
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final payload = {
        "invoice_name": widget.name,
        "payment_amount": paid,
        "reference_no": _referenceNumberController.text,
        "reference_date": _dateController.text,
        "mode_of_payment": _paymentMode,
      };

      final res = await http.post(
        Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.pay_sales_invoice'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: jsonEncode(payload),
      );

      final resp = jsonDecode(res.body);
      print("=== the response is === $resp");

      if (resp['message']?['status'] == 'success' || resp['success'] == true) {
        _showMessage('✅ Payment of ₹${paid.toStringAsFixed(2)} recorded successfully!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        String err = 'Unknown error';
        if (resp['message'] is Map && resp['message']['message'] != null) {
          err = resp['message']['message'];
        } else if (resp['message'] is String) {
          err = resp['message'];
        } else if (resp['error'] != null) {
          err = resp['error'];
        } else if (resp['_server_messages'] != null) {
          try {
            final serverMsgs = jsonDecode(resp['_server_messages']);
            if (serverMsgs is List && serverMsgs.isNotEmpty) {
              final firstMsg = jsonDecode(serverMsgs[0]);
              err = firstMsg['message'] ?? 'Unknown server error';
            }
          } catch (e) {
            err = 'Failed to parse server error';
          }
        }
        _showMessage('❌ Payment failed: $err', Colors.red);
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      print("error is /.,/,/./ $e");
      _showMessage('❌ Error: $e', Colors.red);
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final currentTime = DateTime.now();
    final formattedTime = DateFormat('hh:mm a').format(currentTime); // e.g., 02:39 PM
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(currentTime); // e.g., Tuesday, May 27, 2025

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BottomNavBarScreen()));
            },
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Invoice Details and Timestamp
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invoice: ${widget.name}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Current Time: $formattedTime IST, $formattedDate",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Paid Amount Field
              TextFormField(
                controller: _paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Paid Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the paid amount';
                  }
                  final paid = double.tryParse(value) ?? 0.0;
                  if (paid <= 0) {
                    return 'Paid amount must be greater than 0';
                  }
                  if (paid > widget.totalAmount) {
                    return 'Paid amount cannot exceed total amount (₹${widget.totalAmount.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Payment Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    _buildSummaryRow('Total Amount', widget.totalAmount),
                    _buildSummaryRow('Paid Amount',
                        double.tryParse(_paidAmountController.text) ?? 0.0),
                    _buildSummaryRow('Outstanding Amount', _outstandingAmount,
                        color: _outstandingAmount > 0 ? Colors.red[700] : Colors.green[700]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment Mode Dropdown
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _paymentMode = v!),
              ),

              const SizedBox(height: 20),

              // Reference Number Field
              TextFormField(
                controller: _referenceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                  border: OutlineInputBorder(),
                  hintText: 'Transaction ID / Receipt Number',
                ),
                validator: _validateReferenceNumber,
              ),

              const SizedBox(height: 20),

              // Payment Date Field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Payment Date",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  final selectedDate = DateTime.parse(value);
                  final now = DateTime.now();
                  if (selectedDate.isAfter(now)) {
                    return 'Payment date cannot be in the future';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Submit Payment',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a summary row for the payment summary section.
  Widget _buildSummaryRow(String label, double value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}