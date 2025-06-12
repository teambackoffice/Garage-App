import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:garage_app/payment_procced.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentDuePage extends StatefulWidget {
  const PaymentDuePage({Key? key}) : super(key: key);

  @override
  State<PaymentDuePage> createState() => _PaymentDuePageState();
}

class _PaymentDuePageState extends State<PaymentDuePage> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    final isValidSession = await _validateSession();
    if (isValidSession) {
      fetchPaymentDueOrders();
    } else {
      _handleInvalidSession();
    }
  }

  Future<bool> _validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('sid');
      final sessionExpiry = prefs.getString('session_expiry');

      if (sessionId == null || sessionId.isEmpty) {
        return false;
      }

      if (sessionExpiry != null) {
        final expiryDate = DateTime.tryParse(sessionExpiry);
        if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
          await _clearSession();
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('sid');

      if (sessionId != null && sessionId.isNotEmpty && sessionId.length >= 10) {
        return sessionId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sid');
      await prefs.remove('session_expiry');
      await prefs.remove('user_data');
      await prefs.remove('username');
    } catch (e) {
      print("Error clearing session: $e");
    }
  }

  void _handleInvalidSession() {
    setState(() {
      errorMessage = "Your session has expired. Please login again.";
      isLoading = false;
      isRefreshing = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginDialog();
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please login again to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (Route<dynamic> route) => false,
    );
  }

  Future<double> _fetchOutstandingAmount(String invoiceId, String sessionId) async {
    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/resource/Sales Invoice/$invoiceId?fields=["outstanding_amount"]',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
      );

      if (response.statusCode == 200) {

        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return double.tryParse(jsonResponse['data']['outstanding_amount']?.toString() ?? '0') ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      print('Error fetching outstanding amount for $invoiceId: $e');
      return 0.0;
    }
  }

  Future<void> fetchPaymentDueOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        isRefreshing = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    final sessionId = await _getSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      _handleInvalidSession();
      return;
    }

    try {
      final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_paymentdue_repair_orders_with_count';
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
        'Accept': 'application/json',
        'User-Agent': 'FlutterApp/1.0',
      };

      print("=== FETCHING PAYMENT DUE ORDERS ===");
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      // print("=== API RESPONSE ===");
      // print("Status Code: ${response.statusCode}");
      // print("Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        print("======RESPONSEEEEEE +++++++ ${response.body}");

        try {
          final data = json.decode(response.body);
          List<dynamic> extractedOrders = [];
          final tt = data['grand_total'];

          print("=== PARSING RESPONSE ===");
          print('extracted 1 = $extractedOrders');
          print('order 1 = $orders');


          if (data is Map<String, dynamic>) {
            if (data.containsKey('message')) {
              final message = data['message'];

              if (message is Map<String, dynamic>) {
                if (message.containsKey('success') && message['success'] == true) {
                  if (message.containsKey('data')) {
                    extractedOrders = List<dynamic>.from(message['data'] ?? []);
                  }
                } else if (message.containsKey('data')) {
                  extractedOrders = List<dynamic>.from(message['data'] ?? []);
                }
              } else if (message is List) {
                extractedOrders = List<dynamic>.from(message);
              }
            }

            if (extractedOrders.isEmpty && data.containsKey('data')) {
              final dataField = data['data'];
              if (dataField is List) {
                extractedOrders = List<dynamic>.from(dataField);
              }
            }

            if (extractedOrders.isEmpty && data.containsKey('customer_name')) {
              extractedOrders = [data];
            }
          } else if (data is List) {
            extractedOrders = List<dynamic>.from(data);
          }

          // Fetch outstanding amount if it's 0 or missing
          for (var order in extractedOrders) {
            final invoices = order['sales_invoices'] as List<dynamic>? ?? [];
            for (var invoice in invoices) {
              var outstandingAmount = double.tryParse(invoice['outstanding_amount']?.toString() ?? '0') ?? 0.0;
              if (outstandingAmount == 0.0) {
                outstandingAmount = await _fetchOutstandingAmount(invoice['name'], sessionId);
                invoice['outstanding_amount'] = outstandingAmount;
              }
            }
          }

          print("=== FINAL RESULT ===");
          print("Total orders: ${extractedOrders.length}");
          print('extected 2=$extractedOrders');
          print('orders 2=$orders');
          if (extractedOrders.isNotEmpty) {
            print("Sample order data:");
            print("Customer: ${extractedOrders[0]['customer_name']}");
            print("Order: ${extractedOrders[0]['name']}");
            final invoices = extractedOrders[0]['sales_invoices'] as List<dynamic>? ?? [];
            print("Invoices in first order: ${invoices.length}");
            for (int i = 0; i < invoices.length; i++) {
              print("  Invoice $i: ${invoices[i]['name']} - Due: ₹${invoices[i]['outstanding_amount']}");
              print("  Invoice $i: ${invoices[i]['name']} - Due: ₹${invoices[i]['grand_total']}");
            }
          }

          setState(() {
            orders = extractedOrders;
            isLoading = false;
            isRefreshing = false;
            errorMessage = null;
          });

        } catch (jsonError) {
          print("❌ JSON Parsing Error: $jsonError");
          setState(() {
            errorMessage = "Invalid response format from server.";
            isLoading = false;
            isRefreshing = false;
          });
        }
      } else if (response.statusCode == 401) {
        print("❌ Authentication Error (401)");
        await _clearSession();
        _handleInvalidSession();
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
          isRefreshing = false;
        });
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout Error: $e");
      setState(() {
        errorMessage = "Request timeout. Please check your internet connection.";
        isLoading = false;
        isRefreshing = false;
      });
    } on SocketException catch (e) {
      print("❌ Network Error: $e");
      setState(() {
        errorMessage = "Network error. Please check your internet connection.";
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      print("❌ Unexpected Error: $e");
      setState(() {
        errorMessage = "An unexpected error occurred: $e";
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    final isValidSession = await _validateSession();
    if (isValidSession) {
      await fetchPaymentDueOrders(isRefresh: true);
    } else {
      _handleInvalidSession();
    }
  }

  Future<void> _proceedToPayment(dynamic order, dynamic invoice) async {
    final invoiceName = invoice['name'] ?? 'Unknown';
    final dueAmount = double.tryParse(invoice['outstanding_amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(order['grand_total']?.toString() ?? '0') ?? 0.0;
    final paidAmount = double.tryParse(invoice['paid_amount']?.toString() ?? '0') ?? 0.0;

    print("=== PROCEEDING TO PAYMENT ===");
    print("Customer: ${order['customer_name']}");
    print("Order: ${order['name']}");
    print("Invoice Name: $invoiceName");
    print("Due Amount: ₹$dueAmount");
    print("===Total Amount====: ₹$totalAmount");
    print("Paid Amount: ₹$paidAmount");

    if (invoiceName == 'Unknown' || dueAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid invoice data. Please refresh and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentData = {
      'invoice_name': invoiceName,
      'customer_name': order['customer_name'] ?? 'Unknown Customer',
      'mobile_number': order['mobile_number'] ?? '',
      'due_amount': dueAmount,
      'order_name': order['name'] ?? 'Unknown',
      'registration_number': order['registration_number'] ?? '',
      'invoice_total': order['grand_total'],
      'paid_amount': paidAmount,
    };

    print("Payment data being passed:");
    print(json.encode(paymentData));

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentProceedPage(paymentData: paymentData),
      ),
    );

    if (result == true) {
      await fetchPaymentDueOrders(isRefresh: true);
    }
  }

  double _calculateTotalBalance() {
    double total = 0;
    for (var order in orders) {
      final invoices = order['sales_invoices'] as List<dynamic>? ?? [];
      for (var invoice in invoices) {
        final balance = double.tryParse(invoice['outstanding_amount']?.toString() ?? '0') ?? 0;
        total += balance;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Due'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: _onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isLoading && orders.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem(
                    'Total Due',
                    '₹${_calculateTotalBalance().toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildSummaryItem(
                    'Orders',
                    orders.length.toString(),
                    Icons.receipt_long,
                  ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Colors.blue[600],
              child: isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payments...'),
                  ],
                ),
              )
                  : errorMessage != null
                  ? _buildErrorWidget()
                  : orders.isNotEmpty

                  ? _buildPaymentList()
              :_buildEmptyWidget()
                   ,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorMessage?.contains("session") == true
                  ? Icons.lock_outline
                  : Icons.error_outline,
              size: 64,
              color: errorMessage?.contains("session") == true
                  ? Colors.orange[300]
                  : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? "An error occurred",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: errorMessage?.contains("session") == true
                  ? _navigateToLogin
                  : () => fetchPaymentDueOrders(),
              icon: Icon(errorMessage?.contains("session") == true
                  ? Icons.login
                  : Icons.refresh),
              label: Text(errorMessage?.contains("session") == true
                  ? "Login"
                  : "Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorMessage?.contains("session") == true
                    ? Colors.orange
                    : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'All Payments Up to Date!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending payments found',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final customer = order['customer_name'] ?? 'Unknown Customer';
        final orderName = order['name'] ?? 'Unknown';
        final vehicle = '${order['make'] ?? ''} ${order['model'] ?? ''}'.trim();
        final regNumber = order['registration_number'] ?? '';
        final invoices = order['sales_invoices'] as List<dynamic>? ?? [];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Order: $orderName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (vehicle.isNotEmpty)
                            Text(
                              vehicle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (regNumber.isNotEmpty)
                            Text(
                              regNumber,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${invoices.length} Due',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ...invoices.asMap().entries.map((entry) {
                  final invoiceIndex = entry.key;
                  final invoice = entry.value;
                  return _buildPaymentItem(order, invoice, invoiceIndex);
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(dynamic order, dynamic invoice, int invoiceIndex) {
    final invoiceName = invoice['name'] ?? 'Unknown';
    final dueAmount = double.tryParse(invoice['outstanding_amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(invoice['grand_total']?.toString() ?? '0') ?? 0.0;
    final paidAmount = double.tryParse(invoice['paid_amount']?.toString() ?? '0') ?? 0.0;
    final dueDate = invoice['due_date'];

    print("Building payment item: $invoiceName - Index: $invoiceIndex");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (dueDate != null)
                      Text(
                        'Due: $dueDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                    Text(
                      'Total: ₹${totalAmount.toStringAsFixed(2)} | Paid: ₹${paidAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${dueAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                print("Pay button clicked for invoice: $invoiceName at index: $invoiceIndex");
                _proceedToPayment(order, invoice);
              },
              icon: const Icon(Icons.payment, size: 20),
              label: Text('Pay ₹${dueAmount.toStringAsFixed(2)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}