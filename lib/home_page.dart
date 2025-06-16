import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/payment_procced.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import your other pages here - adjust paths if needed
import 'Ready.dart';
import 'complited_orders.dart';
import 'create_invoice.dart';
import 'create_repair order.dart';
import 'details_page.dart';
import 'inprogress_page.dart';
import 'inprogrss.dart';
import 'main.dart';
import 'open_orders.dart';
import 'payment_due.dart';
import 'ready_order.dart';

class GarageHomePage extends StatefulWidget {
  const GarageHomePage({Key? key}) : super(key: key);

  @override
  _GarageHomePageState createState() => _GarageHomePageState();
}

class _GarageHomePageState extends State<GarageHomePage> {
  final Color primaryColor = const Color(0xFF00796B);
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _customerDetails;
  Map<String, dynamic>? _customerGroup;
  Map<String, dynamic>? _defaultCompany;

  bool _isSearching = false;
  bool _isLoading = true;
  bool _noCustomerFound = false;
  bool _showCustomerSection = false;

  int _openOrdersCount = 0;
  int _completedOrdersCount = 0;
  int _inProgressCount = 0;
  int _readyOrdersCount = 0;
  int _paymentDueCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    debugPrint('Retrieved session ID: $sid');
    return sid;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchDefaultCompany(),
        _fetchOpenOrdersCount(),
        _fetchCompletedOrdersCount(),
        _fetchInProgressCount(),
        _fetchReadyOrdersCount(),
        _fetchPaymentDueCount(),
      ]);
    } catch (e) {
      debugPrint('Error in _loadInitialData: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDefaultCompany() async {
    final sessionId = await _getSessionId();
    if (sessionId == null) {
      debugPrint('Session ID is null, cannot fetch company data');
      return;
    }

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_default_company',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _defaultCompany = data['message'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching default company: $e');
    }
  }

  Future<void> _fetchOpenOrdersCount() async {
    final sessionId = await _getSessionId();
    if (sessionId == null) return;

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_repairorder_open_count',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _openOrdersCount = data['message']['count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching open orders count: $e');
    }
  }

  Future<void> _fetchCompletedOrdersCount() async {
    final sessionId = await _getSessionId();

    if (sessionId == null) {
      debugPrint('Session ID is null. User may not be logged in.');
      return;
    }

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_completed_repair_orders_with_count',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
      );

      debugPrint('Completed Orders Response Status: ${response.statusCode}');
      debugPrint('Completed Orders Response Body: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final count = data['message']['completed_count'];

        setState(() {
          _completedOrdersCount = count ?? 0;
        });

        debugPrint('Updated completed orders count: $_completedOrdersCount');
      } else {
        debugPrint('Failed to load completed orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching completed orders count: $e');
    }
  }

  Future<void> _fetchInProgressCount() async {
    final sessionId = await _getSessionId();
    if (sessionId == null) return;

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_repairorder_inprogress_count',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _inProgressCount = data['message']['count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching in-progress count: $e');
    }
  }

  Future<void> _fetchReadyOrdersCount() async {
    final sessionId = await _getSessionId();
    if (sessionId == null) return;

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.repairorder_ready_orders_count',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['message'] != null) {
            if (data['message']['count'] != null) {
              _readyOrdersCount = data['message']['count'];
            } else if (data['message']['data'] != null) {
              _readyOrdersCount = (data['message']['data'] as List).length;
            } else {
              _readyOrdersCount = 0;
            }
          } else {
            _readyOrdersCount = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching ready orders count: $e');
    }
  }

  Future<void> _fetchPaymentDueCount() async {
    final sessionId = await _getSessionId();
    if (sessionId == null) return;

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_paymentdue_repair_orders_with_count',
    );

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': 'sid=$sessionId',
      });

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['message'] != null) {
            if (data['message']['count'] != null) {
              _paymentDueCount = data['message']['count'];
            } else if (data['message']['data'] != null && data['message']['data'] is List) {
              _paymentDueCount = (data['message']['data'] as List).length;
            } else {
              _paymentDueCount = 0;
            }
          } else {
            _paymentDueCount = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching payment due count: $e');
    }
  }

  Future<void> _searchCustomer(String query) async {
    if (query.trim().isEmpty) {
      _showSnackBar('Please enter a search term.');
      return;
    }

    setState(() {
      _isSearching = true;
      _customerDetails = null;
      _customerGroup = null;
      _noCustomerFound = false;
    });

    final sessionId = await _getSessionId();
    if (sessionId == null) {
      _showSnackBar('No valid session. Please login again.');
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

  void _removeCustomer() {
    setState(() {
      _customerDetails = null;
      _customerGroup = null;
      _searchController.clear();
      _noCustomerFound = false;
      _showCustomerSection = false;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Customer Search",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                if (_showCustomerSection)
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Clear"),
                    onPressed: _removeCustomer,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
           SizedBox(height: h*0.01),
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
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Icon(Icons.search),
                  onPressed: _isSearching
                      ? null
                      : () => _searchCustomer(_searchController.text.trim()),
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

  Widget _buildCustomerCard() {
    final customer = _customerDetails!['customer'] ?? {};
    final address = _customerDetails!['address'] ?? {};
    final vehicles = _customerDetails!['vehicles'] as List? ?? [];

    final name = customer['customer_name'] ?? customer['name'] ?? 'Unknown';
    final type = customer['customer_type'] ?? 'Unknown';
    final phone = address['phone'] ?? customer['mobile_no'] ?? 'Not available';
    final email = address['email_id'] ?? customer['email_id'] ?? 'Not available';

    String vehicleInfo = 'No vehicles';
    if (vehicles.isNotEmpty) {
      final vehicle = vehicles[0];
      vehicleInfo = '${vehicle['make'] ?? 'Unknown'} ${vehicle['model'] ?? ''} (${vehicle['registration_number'] ?? 'No reg'})';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  radius: 24,
                  child: Icon(Icons.person, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.phone, 'Phone', phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'Email', email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.directions_car, 'Vehicle', vehicleInfo),
             SizedBox(height:h*0.01),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Stack buttons vertically on small screens
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        // child: _buildActionButton(
                        //   'Create Order',
                        //   Icons.add_circle,
                        //       () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(builder: (_) => const CreateRepairOrder()),
                        //     ).then((_) => _loadInitialData());
                        //   },
                        // ),
                      ),
                      SizedBox(height: h*0.01),
                      SizedBox(
                        width: double.infinity,
                        // child: _buildActionButton(
                        //   'Create Invoice',
                        //   Icons.receipt,
                        //       () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(builder: (_) => const Vehicle()),
                        //     ).then((_) => _loadInitialData());
                        //   },
                        // ),
                      ),
                    ],
                  );
                } else {
                  // Use row layout for larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Create Order',
                          Icons.add_circle,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateRepairOrder(confirm: false,)),
                            ).then((_) => _loadInitialData());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          'Create Invoice',
                          Icons.receipt,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const Vehicle()),
                            ).then((_) => _loadInitialData());
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardTitle('Order Status'),
             SizedBox(height: h*0.01),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Open',
                    _openOrdersCount,
                    Icons.folder_open,
                    Colors.blue,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OpenRepairOrderListPage()),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    'In Progress',
                    _inProgressCount,
                    Icons.build_circle,
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InProgressRepairOrdersPage()),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
              ],
            ),
          SizedBox(height: h*0.01),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Ready',
                    _readyOrdersCount,
                    Icons.check_circle_outline,
                    Colors.green,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Order()),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    'Completed',
                    _completedOrdersCount,
                    Icons.done_all,
                    Colors.purple,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CompliteOrders()),
                      ).then((_) {
                        debugPrint('Returned from CompliteOrders screen');
                        _loadInitialData();
                      });
                    },
                  ),
                ),
              ],
            ),
             SizedBox(height: h*0.01),
            _buildStatusCard(
              'Payment Due',
              _paymentDueCount,
              Icons.payment,
              Colors.red,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentDuePage()),
                ).then((_) => _loadInitialData());
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(
      String title,
      int count,
      IconData icon,
      Color color,
      VoidCallback onTap
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.1,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Create Repair Order',
                    Icons.add_circle_outline,
                    'New order',
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateRepairOrder(confirm: false,)),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionCard(
                    'Create Invoice',
                    Icons.receipt_long,
                    'New invoice',
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Vehicle()),
                      ).then((_) => _loadInitialData());
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.15,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
             SizedBox(height: h*0.01),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _defaultCompany?['default_company'] ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          companyName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh dashboard',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Loading dashboard.....',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(),
              if (_showCustomerSection) _buildCustomerCard(),
              _buildOrdersSection(),
              SizedBox(height: h*0.01),
              _buildQuickActions(),
             SizedBox(height: h*0.01),
            
            ],
            
          ),
        ),
      ),
    );
  }
}