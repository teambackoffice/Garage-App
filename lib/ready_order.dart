import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:garage_app/create_invoice.dart';
import 'package:garage_app/vehicle_ready.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List<dynamic> repairOrders = [];
  List<dynamic> filteredOrders = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _customerDetails;
  bool _noCustomerFound = false;
  bool _showCustomerSection = false;

  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    fetchOpenRepairOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Retrieves the session ID from shared preferences.
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    return sid;
  }

  /// Displays a snackbar with the given message.
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Fetches open repair orders from the API.
  Future<void> fetchOpenRepairOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        isRefreshing = true;
        error = null;
      });
    } else {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    final sessionId = await _getSessionId();
    if (sessionId == null) {
      setState(() {
        error = 'No valid session. Please login again.';
        isLoading = false;
        isRefreshing = false;
      });
      _handleInvalidSession();
      return;
    }

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.repairorder_ready_orders_count',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (jsonResponse['message'] != null && jsonResponse['message']['data'] != null) {
          final data = jsonResponse['message']['data'];
          final orders = (data is List)
              ? data
              : (data is Map && data['orders'] != null)
              ? data['orders'] as List<dynamic>
              : [];

          if (orders.isNotEmpty) {
            for (final order in orders) {
              final invoiceData = await _checkExistingInvoice(order['name'], sessionId);
              order['existing_invoice'] = invoiceData?['invoice_id'];
            }
            setState(() {
              repairOrders = orders;
              filteredOrders = List.from(repairOrders);
              isLoading = false;
              isRefreshing = false;
            });
            if (isRefresh) {
              _showSnackBar('Orders refreshed successfully!');
            }
          } else {
            setState(() {
              error = 'No ready orders found.';
              isLoading = false;
              isRefreshing = false;
            });
            _showSnackBar('No ready orders found.');
          }
        } else {
          setState(() {
            error = 'Invalid response structure.';
            isLoading = false;
            isRefreshing = false;
          });
          _showSnackBar('Invalid response structure.');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          error = 'Unauthorized: Invalid or expired session.';
          isLoading = false;
          isRefreshing = false;
        });
        _handleInvalidSession();
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
          isRefreshing = false;
        });
        _showSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
        isRefreshing = false;
      });
      _showSnackBar('Network error: $e');
    }
  }

  /// Handles the refresh action.
  Future<void> _handleRefresh() async {
    await fetchOpenRepairOrders(isRefresh: true);
  }

  /// Handles invalid session by showing a dialog and redirecting to login.
  void _handleInvalidSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                        (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Login'),
              ),
            ],
          );
        },
      );
    });
  }

  /// Checks if an invoice exists for the given repair order.
  Future<Map<String, dynamic>?> _checkExistingInvoice(String repairOrderId, String sessionId) async {
    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_invoice_for_repair_order?repair_order=$repairOrderId',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['message'] != null) {
        final invoiceData = jsonResponse['message'];
        if (invoiceData['exists'] == true) {
          return {'invoice_id': invoiceData['invoice_id']};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Searches for a customer by name.
  Future<void> _searchCustomer(String query) async {
    if (query.trim().isEmpty) {
      _showSnackBar('Please enter a search term.');
      return;
    }

    setState(() {
      _isSearching = true;
      _customerDetails = null;
      _noCustomerFound = false;
    });

    final sessionId = await _getSessionId();
    if (sessionId == null) {
      _showSnackBar('No valid session. Please login again.');
      setState(() => _isSearching = false);
      _handleInvalidSession();
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

        if (data['message'] == null || data['message']['data'] == null) {
          setState(() {
            _isSearching = false;
            _noCustomerFound = true;
          });
          _showSnackBar('Invalid response structure.');
          return;
        }

        final customerData = data['message']['data'];

        if (customerData != null && customerData is Map<String, dynamic>) {
          setState(() {
            _customerDetails = customerData;
            _isSearching = false;
            _noCustomerFound = false;
            _showCustomerSection = true;
          });
          _showSnackBar('Customer data loaded.');
          _filterOrdersByCustomer(customerData['customer']?['name'] ?? '');
        } else {
          setState(() {
            _isSearching = false;
            _noCustomerFound = true;
          });
          _showSnackBar('No customer data found.');
        }
      } else {
        setState(() {
          _isSearching = false;
          _noCustomerFound = true;
        });
        _showSnackBar('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _noCustomerFound = true;
      });
      _showSnackBar('Error during search: $e');
    }
  }

  /// Filters orders based on the customer name.
  void _filterOrdersByCustomer(String customerName) {
    setState(() {
      filteredOrders = repairOrders.where((order) {
        final orderCustomerName = order['customer_name']?.toString().toLowerCase() ?? '';
        return orderCustomerName.contains(customerName.toLowerCase());
      }).toList();
    });
  }

  /// Clears the customer search results.
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _customerDetails = null;
      _noCustomerFound = false;
      _showCustomerSection = false;
      filteredOrders = List.from(repairOrders);
    });
  }

  /// Opens WhatsApp with a pre-filled message.
  Future<void> openWhatsApp(String phone, String message) async {
    final phoneNumber = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSnackBar('Redirecting to WhatsApp...');
    } else {
      _showSnackBar('Could not open WhatsApp');
    }
  }

  /// Converts a dynamic value to a double.
  double _toDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  /// Calculates the total cost of parts.
  double calculatePartsTotal(List<dynamic> partsItems) {
    if (partsItems.isEmpty) return 0.0;
    return partsItems.fold(0.0, (sum, part) {
      final rate = _toDouble(part['rate']);
      final qty = _toDouble(part['qty']);
      return sum + rate * qty;
    });
  }

  /// Calculates the total cost of services.
  double calculateServiceTotal(List<dynamic> serviceItems) {
    if (serviceItems.isEmpty) return 0.0;
    return serviceItems.fold(0.0, (sum, service) {
      final rate = _toDouble(service['rate']);
      final qty = _toDouble(service['qty']);
      return sum + rate * qty;
    });
  }

  /// Builds the customer search section.
  Widget _buildSearchSection(double w) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customer Search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                if (_showCustomerSection)
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Clear', style: TextStyle(color: Colors.red)),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer by name',
                prefixIcon: const Icon(Icons.person_search),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          ],
        ),
      ),
    );
  }

  /// Builds an order card for display.
  Widget _buildOrderCard(Map<String, dynamic> order, double w) {
    final vehicle = order['vehicle_details'] ?? {};
    final customerName = order['customer_name']?.toString() ?? 'N/A';
    final mobile = order['mobile_number']?.toString() ?? 'N/A';
    final email = order['email_id']?.toString() ?? 'N/A';
    final regNumber = order['registration_number']?.toString() ?? 'N/A';
    final status = order['status']?.toString() ?? 'N/A';
    final date = order['posting_date']?.toString() ?? 'N/A';
    final orderId = order['name']?.toString() ?? 'N/A';
    final existingInvoice = order['existing_invoice'];
    final serviceItems = order['service_items'] as List<dynamic>? ?? [];
    final partsItems = order['parts_items'] as List<dynamic>? ?? [];

    final serviceTotal = _toDouble(order['service_total'] ?? calculateServiceTotal(serviceItems));
    final partsTotal = _toDouble(order['parts_total'] ?? calculatePartsTotal(partsItems));
    final taxAmount = _toDouble(order['taxes_and_charges'] ?? order['tax_amount'] ?? 0.0);
    final totalPartsAmount = partsTotal + taxAmount;
    final grandTotal = _toDouble(order['grand_total'] ?? (serviceTotal + totalPartsAmount));

    final partsDetails = partsItems.isNotEmpty
        ? partsItems.map((part) => part['item_name']?.toString() ?? 'Unknown').join(', ')
        : 'None';

    final enhancedCustomerData = {
      ...order,
      'calculated_service_total': serviceTotal,
      'calculated_parts_total': partsTotal,
      'calculated_tax_amount': taxAmount,
      'calculated_total_parts_amount': totalPartsAmount,
      'calculated_grand_total': grandTotal,
    };

    return Card(
      margin: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '🛠️ Order ID: $orderId',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (existingInvoice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INVOICED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            if (existingInvoice != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📄 Invoice: $existingInvoice',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                Text('👤 Customer: $customerName'),
                Text('📞 Mobile: $mobile'),
                Text('📧 Email: $email'),
                Text('🚘 Make: ${vehicle['make']?.toString() ?? order['make']?.toString() ?? 'N/A'}'),
                Text('🚗 Model: ${vehicle['model']?.toString() ?? order['model']?.toString() ?? 'N/A'}'),
                Text('🔢 Reg No: $regNumber'),
                Text('📅 Date: $date'),
                Text('📌 Status: $status'),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _row('💰 Services Total:', formatter.format(serviceTotal), isBold: true),
                  _row('🔧 Parts Subtotal:', formatter.format(partsTotal)),
                  if (taxAmount > 0) _row('💲 Tax:', formatter.format(taxAmount)),
                  _row('📦 Parts Total:', formatter.format(totalPartsAmount), isBold: true),
                  const Divider(),
                  _row('💵 Grand Total:', formatter.format(grandTotal),
                      isBold: true, color: Colors.green[700]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🔧 Parts: $partsDetails',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final message =
                        'Hello $customerName, your vehicle with Reg. No. $regNumber is ready. - GarageHub';
                    openWhatsApp(mobile, message);
                  },
                  icon: const Icon(Icons.chat, color: Colors.green),
                  label: const Text('WhatsApp'),
                ),
                if (existingInvoice == null)
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Create(customerData: enhancedCustomerData)),
                      );
                      if (result == true) {
                        await fetchOpenRepairOrders(isRefresh: true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Invoice'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      _showSnackBar('Invoice $existingInvoice already exists.');
                    },
                    child: const Text('View Invoice', style: TextStyle(color: Colors.blue)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a row for displaying label-value pairs.
  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: isBold ? FontWeight.w500 : FontWeight.normal),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ready Orders (${filteredOrders.length})'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : _handleRefresh,
            icon: isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => fetchOpenRepairOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.blue[800],
        child: Column(
          children: [
            _buildSearchSection(w),
            Expanded(
              child: filteredOrders.isEmpty
                  ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ready orders found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(filteredOrders[index], w);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}