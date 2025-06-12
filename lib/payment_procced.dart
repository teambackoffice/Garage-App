import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav.dart';

class PaymentProceedPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentProceedPage({Key? key, required this.paymentData}) : super(key: key);

  @override
  State<PaymentProceedPage> createState() => _PaymentProceedPageState();
}

class _PaymentProceedPageState extends State<PaymentProceedPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String selectedPaymentMethod = 'Credit Card';
  bool isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {'value': 'Cash', 'label': 'Cash', 'icon': Icons.money},
    {'value': 'Credit Card', 'label': 'Credit Card', 'icon': Icons.credit_card},
    {'value': 'Debit Card', 'label': 'Debit Card', 'icon': Icons.credit_card},
    {'value': 'UPI', 'label': 'UPI', 'icon': Icons.qr_code},
    {'value': 'Bank Transfer', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
    {'value': 'Cheque', 'label': 'Cheque', 'icon': Icons.receipt_long},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = '';

    // Debug: Print payment data to verify what's being passed
    print("=== PAYMENT DATA DEBUG ===");
    print("Full payment data: ${widget.paymentData}");
    print("Invoice name: '${widget.paymentData['invoice_name']}'");
    print("Customer name: '${widget.paymentData['customer_name']}'");
    print("Due amount: '${widget.paymentData['due_amount']}'");
    print("========================");
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('sid');
    } catch (e) {
      return null;
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0.0;
    final dueAmount = double.tryParse(widget.paymentData['due_amount']?.toString() ?? '0') ?? 0.0;

    if (paymentAmount <= 0) {
      _showErrorSnackBar('Please enter a valid payment amount');
      return;
    }

    // Warn if payment amount exceeds due amount
    if (paymentAmount > dueAmount && dueAmount > 0) {
      final shouldContinue = await _showOverpaymentDialog(paymentAmount, dueAmount);
      if (!shouldContinue) return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final sessionId = await _getSessionId();
      if (sessionId == null) {
        _showErrorSnackBar('Session expired. Please login again.');
        Navigator.of(context).pop();
        return;
      }

      final success = await _processPaymentAPI(sessionId, paymentAmount);

      if (success) {
        await _showSuccessDialog();
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Payment processing failed. Please try again.');
      }

    } on TimeoutException catch (e) {
      _showErrorSnackBar('Request timeout. Please check your connection.');
    } on SocketException catch (e) {
      _showErrorSnackBar('Network error. Please check your connection.');
    } catch (e) {
      print("Payment Error: $e");
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<bool> _processPaymentAPI(String sessionId, double paymentAmount) async {
    // Validate required fields before sending
    final invoiceName = widget.paymentData['invoice_name']?.toString().trim();
    if (invoiceName == null || invoiceName.isEmpty) {
      print("❌ Invoice name is missing or empty");
      _showErrorSnackBar('Invoice name is required');
      return false;
    }

    if (paymentAmount <= 0) {
      print("❌ Payment amount is invalid: $paymentAmount");
      _showErrorSnackBar('Valid payment amount is required');
      return false;
    }

    // Generate reference number (you can customize this logic)
    final referenceNo = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final referenceDate = DateTime.now().toIso8601String().split('T')[0]; // Current date in YYYY-MM-DD format

    // Prepare payment data with correct API format
    final paymentPayload = {
      'invoice_name': invoiceName,
      'payment_amount': paymentAmount, // Use payment_amount instead of amount
      'mode_of_payment': selectedPaymentMethod, // Use mode_of_payment instead of payment_method
      'reference_no': referenceNo,
      'reference_date': referenceDate,
    };

    print("=== PAYMENT PROCESSING ===");
    print("Invoice Name: '$invoiceName'");
    print("Payment Amount: $paymentAmount");
    print("Mode of Payment: $selectedPaymentMethod");
    print("Reference No: $referenceNo");
    print("Reference Date: $referenceDate");
    print("Payment Data: ${json.encode(paymentPayload)}");

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'sid=$sessionId',
      'Accept': 'application/json',
      'User-Agent': 'FlutterApp/1.0',
    };

    try {
      final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.pay_sales_invoice';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(paymentPayload),
      ).timeout(const Duration(seconds: 30));

      print("=== PAYMENT RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check for success in different response formats
        if (responseData['success'] == true) {
          print("✅ Payment successful - Direct success");
          return true;
        } else if (responseData['message'] != null) {
          final message = responseData['message'];
          if (message['status'] == 'success' || message['success'] == true) {
            print("✅ Payment successful - Message success");
            return true;
          } else if (message['status'] == 'error') {
            final errorMsg = message['message'] ?? 'Payment failed';
            print("❌ Payment failed: $errorMsg");
            _showErrorSnackBar(errorMsg);
            return false;
          }
        }

        // If no clear success indicator, check for error messages
        if (responseData['message'] != null && responseData['message']['message'] != null) {
          _showErrorSnackBar(responseData['message']['message']);
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      print("❌ Payment API failed: $e");
      return false;
    }
  }

  Future<bool> _showOverpaymentDialog(double paymentAmount, double dueAmount) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Overpayment Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You are paying more than the due amount:'),
              const SizedBox(height: 8),
              Text('Due Amount: ₹${dueAmount.toStringAsFixed(2)}'),
              Text('Payment Amount: ₹${paymentAmount.toStringAsFixed(2)}'),
              Text('Excess: ₹${(paymentAmount - dueAmount).toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              const Text('Do you want to continue?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹${_amountController.text}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Method: $selectedPaymentMethod',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invoice: ${widget.paymentData['invoice_name']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.paymentData['customer_name'] ?? 'Unknown Customer';
    final invoiceName = widget.paymentData['invoice_name'] ?? 'Unknown Invoice';
    final regNumber = widget.paymentData['registration_number'] ?? '';
    final dueAmount = double.tryParse(widget.paymentData['due_amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(widget.paymentData['invoice_total']?.toString() ?? '0') ?? 0.0;
    final paidAmount = double.tryParse(widget.paymentData['paid_amount']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder:(context)=>BottomNavBarScreen()));
            },
              child: Container(child: Container(child: Icon(Icons.home))))
        ],
        title: const Text('Payment'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Customer & Invoice Info Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Invoice: $invoiceName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (regNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            regNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Invoice Amount Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: ₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Paid: ₹${paidAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Due Amount',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${dueAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payment Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Amount Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Enter Payment Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Payment Amount',
                                hintText: 'Enter amount to pay',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.green[600]!),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter payment amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Quick amount buttons
                            if (dueAmount > 0) ...[
                              const Text(
                                'Quick Select:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _buildQuickAmountButton(dueAmount, 'Full Due'),
                                  if (dueAmount > 1000) _buildQuickAmountButton(dueAmount / 2, 'Half'),
                                  if (dueAmount >= 1000) _buildQuickAmountButton(1000, '₹1000'),
                                  if (dueAmount >= 500) _buildQuickAmountButton(500, '₹500'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment Method Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...paymentMethods.map((method) =>
                                RadioListTile<String>(
                                  value: method['value'],
                                  groupValue: selectedPaymentMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPaymentMethod = value!;
                                    });
                                  },
                                  title: Row(
                                    children: [
                                      Icon(method['icon'], size: 20, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(method['label']),
                                    ],
                                  ),
                                  activeColor: Colors.green[600],
                                  contentPadding: EdgeInsets.zero,
                                ),
                            ).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_add, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notes (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add payment notes...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.green[600]!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Payment Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : _processPayment,
                    icon: isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.payment, size: 24),
                    label: Text(
                      isProcessing
                          ? 'Processing...'
                          : _amountController.text.isEmpty
                          ? 'Enter Amount to Pay'
                          : 'Process Payment ₹${_amountController.text}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(2);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.green[700],
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}