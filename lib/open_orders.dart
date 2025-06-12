import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'open_view page.dart';
// import 'open_view_page.dart';

class OpenRepairOrderListPage extends StatefulWidget {
  const OpenRepairOrderListPage({super.key});

  @override
  State<OpenRepairOrderListPage> createState() => _OpenRepairOrderListPageState();
}

class _OpenRepairOrderListPageState extends State<OpenRepairOrderListPage> {
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];

  // Search related variables
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _customerDetails;
  String? _customerGroup;
  bool _noCustomerFound = false;
  bool _showCustomerSection = false;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _filteredOrders = _orders;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get session ID from SharedPreferences
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sid');
  }

  // Show snackbar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Fetch all open repair orders
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sid = await _getSessionId();
    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = "❌ Session expired. Please login again.";
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_repairorder_open_count',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final decoded = jsonDecode(response.body);
      debugPrint("📦 Orders Response: $decoded");

      if (response.statusCode == 200 && decoded['message']?['data'] != null) {
        final List<Map<String, dynamic>> dataList =
        List<Map<String, dynamic>>.from(decoded['message']['data']);

        setState(() {
          _orders = dataList;
          _filteredOrders = dataList;
        });
      } else {
        setState(() {
          _error = decoded['message']?.toString() ?? '❌ Unexpected response';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Search customer by name (API call)
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

      debugPrint("🔍 Customer Search Response: ${response.body}");

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

          // Filter orders by this customer
          _filterOrdersByCustomer(customerData['name'] ?? '');
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
      debugPrint("❌ Search Error: $e");
    }
  }

  // Filter orders by customer name
  void _filterOrdersByCustomer(String customerName) {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final orderCustomer = order['customer_name']?.toString().toLowerCase() ?? '';
        return orderCustomer.contains(customerName.toLowerCase());
      }).toList();
      _isSearchMode = true;
    });
  }

  // Local search in existing orders
  void _performLocalSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredOrders = _orders;
        _isSearchMode = false;
        _showCustomerSection = false;
      });
      return;
    }

    setState(() {
      _filteredOrders = _orders.where((order) {
        final searchQuery = query.toLowerCase();
        final customerName = order['customer_name']?.toString().toLowerCase() ?? '';
        final mobile = order['mobile_number']?.toString().toLowerCase() ?? '';
        final regNumber = order['registration_number']?.toString().toLowerCase() ?? '';
        final orderName = order['name']?.toString().toLowerCase() ?? '';
        final make = order['make']?.toString().toLowerCase() ?? '';
        final model = order['model']?.toString().toLowerCase() ?? '';
        final vehicleMake =
            order['vehicle_details']?['make']?.toString().toLowerCase() ?? '';
        final vehicleModel =
            order['vehicle_details']?['model']?.toString().toLowerCase() ?? '';
        final engineNumber =
            order['vehicle_details']?['engine_number']?.toString().toLowerCase() ?? '';
        final chassisNumber =
            order['vehicle_details']?['chasis_number']?.toString().toLowerCase() ?? '';

        // Search in service items
        final serviceItems = (order['service_items'] as List<dynamic>?) ?? [];
        final serviceItemMatch = serviceItems.any((item) =>
        item['item_name']?.toString().toLowerCase().contains(searchQuery) ?? false);

        // Search in parts items
        final partsItems = (order['parts_items'] as List<dynamic>?) ?? [];
        final partsItemMatch = partsItems.any((item) =>
        item['item_name']?.toString().toLowerCase().contains(searchQuery) ?? false);

        return customerName.contains(searchQuery) ||
            mobile.contains(searchQuery) ||
            regNumber.contains(searchQuery) ||
            orderName.contains(searchQuery) ||
            make.contains(searchQuery) ||
            model.contains(searchQuery) ||
            vehicleMake.contains(searchQuery) ||
            vehicleModel.contains(searchQuery) ||
            engineNumber.contains(searchQuery) ||
            chassisNumber.contains(searchQuery) ||
            serviceItemMatch ||
            partsItemMatch;
      }).toList();
      _isSearchMode = true;
    });
  }

  // Clear search and reset
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredOrders = _orders;
      _isSearchMode = false;
      _showCustomerSection = false;
      _customerDetails = null;
      _noCustomerFound = false;
    });
  }

  // Build customer details section
  Widget _buildCustomerSection() {
    if (!_showCustomerSection || _customerDetails == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: 'Clear search',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Name: ${_customerDetails!['customer_name'] ?? '-'}'),
          Text('Mobile: ${_customerDetails!['mobile_no'] ?? '-'}'),
          Text('Email: ${_customerDetails!['email_id'] ?? '-'}'),
          if (_customerDetails!['address'] != null)
            Text('Address: ${_customerDetails!['address']}'),
        ],
      ),
    );
  }

  // Build search bar
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by customer, mobile, reg number, vehicle, items...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _performLocalSearch,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
            ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          // IconButton(
          //   onPressed: () => _searchCustomer(_searchController.text),
          //   // icon: const Icon(Icons.cloud_search),
          //   tooltip: 'Search customer in database',
          // ),
        ],
      ),
    );
  }

  // Build individual order card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final vehicleDetails = order['vehicle_details'] as Map<String, dynamic>?;
    final serviceItems = (order['service_items'] as List<dynamic>?) ?? [];
    final partsItems = (order['parts_items'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['name'] ?? '-',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'] ?? '-',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("${order['customer_name'] ?? '-'}")),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("${order['mobile_number'] ?? '-'}")),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("${order['email_id'] ?? '-'}")),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.directions_car, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "${vehicleDetails?['make'] ?? order['make'] ?? '-'} ${vehicleDetails?['model'] ?? order['model'] ?? '-'}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("${order['registration_number'] ?? '-'}")),
            ],
          ),
          const SizedBox(height: 4),
          if (vehicleDetails != null) ...[
            Row(
              children: [
                const Icon(Icons.build, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Engine: ${vehicleDetails['engine_number'] ?? '-'}")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.car_repair, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Chassis: ${vehicleDetails['chasis_number'] ?? '-'}")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Purchase: ${vehicleDetails['purchase_date'] ?? '-'}")),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("Posted: ${order['posting_date'] ?? '-'}")),
            ],
          ),
          const Divider(height: 16),
          Text(
            "Services: ${serviceItems.isNotEmpty ? serviceItems.map((item) => item['item_name']).join(', ') : '-'}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            "Parts: ${partsItems.isNotEmpty ? partsItems.map((item) => item['item_name']).join(', ') : '-'}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service: ₹${order['service_total']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    "Parts: ₹${order['parts_total']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    "Total: ₹${order['grand_total']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(_isSearchMode ? "Search Results" : "Open Repair Orders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isSearchMode)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCustomerSection(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearchMode ? Icons.search_off : Icons.inbox,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearchMode ? "No matching orders found." : "No orders found.",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final repairOrder = _filteredOrders[index];
                      final repairOrderId = repairOrder['name'];
                      return GestureDetector(
                        onTap: () async {
                          if (repairOrderId != null && repairOrderId.isNotEmpty) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OpenViewPage(
                                  repairOrderId: repairOrderId,
                                  // repairOrderData: repairOrder,
                                ),
                              ),
                            );
                            _fetchOrders(); // Refresh on return
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("❌ Invalid Repair Order ID")),
                            );
                          }
                        },
                        child: _buildOrderCard(repairOrder),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}