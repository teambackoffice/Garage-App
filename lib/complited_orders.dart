import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CompliteOrders extends StatefulWidget {
  const CompliteOrders({super.key});

  @override
  State<CompliteOrders> createState() => _CompliteOrdersState();
}

class _CompliteOrdersState extends State<CompliteOrders> {
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];

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
    _fetchCompletedOrders();
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

  // Fetch completed orders
  Future<void> _fetchCompletedOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');

    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = '❌ Session expired. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_completed_repair_orders_with_count');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid',
        },
      );

      final jsonResponse = jsonDecode(response.body);
      debugPrint("📦 Completed Orders Response: $jsonResponse");

      if (response.statusCode == 200 && jsonResponse['message']?['data'] is List) {
        print(' ====== ${response.body}');

        print('response.data of completed = ${response.body}');
        setState(() {
          _orders = jsonResponse['message']['data'];
          _filteredOrders = jsonResponse['message']['data'];
        });
      } else {
        setState(() {
          _error = '❌ Failed to load completed orders.';
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
          _filterOrdersByCustomer(customerData['customer_name'] ?? customerData['name'] ?? '');
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
        final String customerName = order['customer_name'] ?? 'N/A';
        final String mobile = order['mobile_number'] ?? order['mobile'] ?? '';
        final String regNumber = order['registration_number'] ?? order['vehicle_number'] ?? 'N/A';
        final String orderName = order['name'] ?? 'N/A';
        final String make = order['make'] ?? '';
        final String model = order['model'] ?? '';
        final String status = order['status'] ?? 'Working In Progress';
        final String email = order['email_id'] ?? 'N/A';
        final String postingDate = order['posting_date'] ?? 'N/A';
        final dynamic serviceTotal = order['service_total'] ?? 0.0;
        final dynamic partsTotal = order['parts_total'] ?? 0.0;
        final dynamic grandTotal = order['grand_total'] ?? order['total_amount'] ?? 0.0;
        final List<dynamic> serviceItems = order['service_items'] ?? [];

        return customerName.contains(searchQuery) ||
            mobile.contains(searchQuery) ||
            regNumber.contains(searchQuery) ||
            orderName.contains(searchQuery) ||
            make.contains(searchQuery) ||
            model.contains(searchQuery);
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
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
          Text('Name: ${_customerDetails!['customer_name'] ?? _customerDetails!['name'] ?? '-'}'),
          Text('Mobile: ${_customerDetails!['mobile_no'] ?? _customerDetails!['mobile_number'] ?? '-'}'),
          Text('Email: ${_customerDetails!['email_id'] ?? _customerDetails!['email'] ?? '-'}'),
          if (_customerDetails!['address'] != null && _customerDetails!['address'].toString().isNotEmpty)
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
                hintText: 'Search completed orders...',
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
          //   icon: const Icon(Icons.cloud_search),
          //   tooltip: 'Search customer in database',
          // ),
        ],
      ),
    );
  }

  // Build individual order card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order['name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order['status'] ?? 'Completed',
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
                Expanded(child: Text("Customer: ${order['customer_name'] ?? '-'}")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Mobile: ${order['mobile_number'] ?? '-'}")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Vehicle: ${order['make'] ?? ''} ${order['model'] ?? ''}")),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text("Reg No: ${order['registration_number'] ?? '-'}")),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ₹${order['grand_total'] ?? 0}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                if (order['completion_date'] != null)
                  Text(
                    "Completed: ${order['completion_date']}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isSearchMode ? 'Search Results' : 'Completed Orders',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCompletedOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _filteredOrders.isEmpty
                ? Center(
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
                    _isSearchMode
                        ? "No matching completed orders found."
                        : "No completed orders found.",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchCompletedOrders,
              child: ListView.builder(
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(_filteredOrders[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Alternative method for token-based authentication (if needed)
  Future<Map<String, dynamic>?> fetchCompletedRepairOrdersCount(String token) async {
    final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.get_completed_repair_orders_with_count');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint('Failed to fetch completed repair orders. Status: ${response.statusCode}');
      return null;
    }
  }
}