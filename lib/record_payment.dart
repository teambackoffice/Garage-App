import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecordPayment extends StatefulWidget {
  final String invoiceName;
  final double totalAmount;

  const RecordPayment({super.key, required this.invoiceName, required this.totalAmount});

  @override
  State<RecordPayment> createState() => _RecordPaymentState();
}

class _RecordPaymentState extends State<RecordPayment> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refNoController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedPaymentMethod;
  DateTime? _selectedDate;
  bool isLoading = false;

  final List<String> _paymentMethods = [
    'Cash', 'Credit Card', 'Debit Card', 'UPI', 'Net Banking'
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid') ?? '';

    if (sessionId.isEmpty) {
      _showMessage("⚠️ Session expired. Please login again.", Colors.red);
      return;
    }

    if (_amountController.text.trim().isEmpty || double.tryParse(_amountController.text.trim()) == null) {
      _showMessage("⚠️ Please enter a valid amount.", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    final payload = {
      "invoice_name": widget.invoiceName.trim(),
      "payment_amount": double.parse(_amountController.text.trim()),
      "mode_of_payment": _selectedPaymentMethod,
      "reference_no": _refNoController.text.trim(),
      "reference_date": _dateController.text.trim(),
    };

    try {
      final res = await http.post(
        Uri.parse('https://garage.teambackoffice.com/api/method/garage.garage.auth.pay_sales_invoice'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
        body: jsonEncode(payload),
      );

      final resBody = jsonDecode(res.body);

      if (res.statusCode == 200 && resBody['message']?['status'] == 'success') {
        _showMessage("✅ Payment recorded successfully!", Colors.green);
      } else {
        _showMessage("❌ Payment failed. Please try again later.", Colors.red);
      }
    } catch (e) {
      _showMessage("❌ Error: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record Payment for ${widget.invoiceName}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Amount is required.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                hint: const Text("Select Payment Method"),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                },
                items: _paymentMethods
                    .map((method) => DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _refNoController,
                decoration: const InputDecoration(labelText: "Reference Number"),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: "Payment Date"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Payment date is required.";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPayment,
                child: const Text("Submit Payment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
