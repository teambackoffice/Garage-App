import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:garage_app/workin_progress_details.dart';
import 'bottom_nav.dart';

class InProgressRepairOrdersPage extends StatefulWidget {
  const InProgressRepairOrdersPage({super.key});

  @override
  State<InProgressRepairOrdersPage> createState() =>
      _InProgressRepairOrdersPageState();
}

class _InProgressRepairOrdersPageState
    extends State<InProgressRepairOrdersPage> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _customerDetails;
  bool _noCustomerFound = false;

  // Open WhatsApp
  Future<void> openWhatsApp(String phone, String message) async {
    final phoneNumber = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar("Redirecting to WhatsApp...");
      } else {
        _showSnackBar("Could not open WhatsApp");
      }
    } catch (e) {
      _showSnackBar("Error: Could not open WhatsApp. $e");
    }
  }

  // Get session ID
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sid');
  }

  // Show snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Local search function for filtering orders
  void _performLocalSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredOrders = List.from(_orders);
      } else {
        _filteredOrders = _orders.where((order) {
          final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
          final mobile = (order['mobile_number'] ?? '').toString().toLowerCase();
          final regNumber = (order['registration_number'] ?? '').toString().toLowerCase();
          final orderName = (order['name'] ?? '').toString().toLowerCase();
          final make = (order['make'] ?? '').toString().toLowerCase();
          final model = (order['model'] ?? '').toString().toLowerCase();
          // final services = (order['service_items'] ?? []);

          final searchQuery = query.toLowerCase();

          return customerName.contains(searchQuery) ||
              mobile.contains(searchQuery) ||
              regNumber.contains(searchQuery) ||
              orderName.contains(searchQuery) ||
              make.contains(searchQuery) ||
              model.contains(searchQuery);
        }).toList();
      }
    });
  }

  // Enhanced API search for customers
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
    if (sessionId == null || sessionId.isEmpty) {
      _showSnackBar('No valid session. Please login again.');
      setState(() => _isSearching = false);
      return;
    }

    List<String> searchEndpoints = [
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.customer_name_search?customer_name=${Uri.encodeComponent(query)}',
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.customer_search?query=${Uri.encodeComponent(query)}',
      'https://garage.tbo365.cloud/api/method/garage.garage.auth.search_customer?search=${Uri.encodeComponent(query)}',
    ];

    bool searchSuccessful = false;

    for (String endpoint in searchEndpoints) {
      if (searchSuccessful) break;

      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': 'sid=$sessionId',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          dynamic customerList;

          if (data['message'] != null) {
            if (data['message']['data'] != null) {
              customerList = data['message']['data'];
            } else if (data['message'] is List) {
              customerList = data['message'];
            } else if (data['message'] is Map) {
              customerList = [data['message']];
            }
          }

          if (customerList != null && customerList is List && customerList.isNotEmpty) {
            setState(() {
              _customerDetails = customerList.first;
              _isSearching = false;
              _noCustomerFound = false;
            });
            searchSuccessful = true;
            _showSnackBar("Customer found!");
            break;
          }
        }
      } catch (e) {
        continue;
      }
    }

    if (!searchSuccessful) {
      setState(() {
        _isSearching = false;
        _noCustomerFound = true;
      });
      _showSnackBar('No customer found with that search term.');
    }
  }

  // Fetch In-progress Orders
  Future<void> _fetchInProgressOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sid = await _getSessionId();
    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = '❌ Session expired. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_repairorder_inprogress_count');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': 'sid=$sid',
      });

      print("Orders API Response: ${response.body}"); // Debug log

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['message'] == null) {
          setState(() {
            _error = '❌ Invalid API response: No message field';
            _isLoading = false;
          });
          return;
        }

        List<dynamic> ordersData = [];

        if (jsonResponse['message']['data'] is List) {
          ordersData = jsonResponse['message']['data'];
        } else if (jsonResponse['message'] is List) {
          ordersData = jsonResponse['message'];
        }

        // Log parsed orders for debugging
        print("Parsed ordersData: $ordersData");

        setState(() {
          _orders = ordersData;
          _filteredOrders = List.from(_orders);
          _error = null;
        });

        if (_orders.isEmpty) {
          _showSnackBar("No in-progress orders found.");
        }
      } else {
        setState(() {
          _error = '❌ Failed to load orders. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Network error: $e';
      });
      print("Error fetching orders: $e"); // Debug log
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Order card UI
  Widget _buildOrderCard(Map<String, dynamic> order, double screenWidth) {
    print("Order data: $order"); // Debug log
    final String customerName = order['customer_name'] ?? 'N/A';
    final String mobile = order['mobile_number'] ?? order['mobile'] ?? '';
    final String regNumber = order['registration_number'] ?? order['vehicle_number'] ?? 'N/A';
    final String orderName = order['name'] ?? 'N/A';
    final String make = order['make'] ?? '';
    final String model = order['model'] ?? '';
    final String status = order['status'] ?? 'In Progress';
    final dynamic grandTotalRaw = order['grand_total'] ?? order['total_amount'] ?? order['total'] ?? 0;
    final double grandTotal = double.tryParse(grandTotalRaw.toString()) ?? 0.0;
    final List<dynamic> services = order['service_items'] ?? [];
    final List serviceNames = services.map((service) => service['item_name'] ?? '').toList();
    final String servicesString = serviceNames.join(', ');
    final List<dynamic> parts = order['parts_items'] ?? [];
    final List partNames = parts.map((part) => part['item_name'] ?? '').toList();
    final String partsString = partNames.join(', ');

    // Responsive font sizes and padding
    final double fontSizeTitle = screenWidth < 400 ? 14 : 16;
    final double fontSizeBody = screenWidth < 400 ? 12 : 14;
    final double padding = screenWidth < 400 ? 12 : 16;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: screenWidth * 0.03),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>  WorkInProgress( services : servicesString, parts : partsString),
              settings: RouteSettings(arguments: orderName),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      orderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSizeTitle,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: screenWidth < 400 ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Row(
                children: [
                  Icon(Icons.person, size: fontSizeBody, color: Colors.grey),
                  SizedBox(width: screenWidth * 0.015),
                  Expanded(
                    child: Text(
                      "Customer: $customerName",
                      style: TextStyle(fontSize: fontSizeBody),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.01),
              if (mobile.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone, size: fontSizeBody, color: Colors.grey),
                    SizedBox(width: screenWidth * 0.015),
                    Expanded(
                      child: Text(
                        "Mobile: $mobile",
                        style: TextStyle(fontSize: fontSizeBody),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: screenWidth * 0.01),
              Row(
                children: [
                  Icon(Icons.directions_car, size: fontSizeBody, color: Colors.grey),
                  SizedBox(width: screenWidth * 0.015),
                  Expanded(
                    child: Text(
                      "Vehicle: ${make.isNotEmpty ? '$make ' : ''}${model.isNotEmpty ? model : 'N/A'}",
                      style: TextStyle(fontSize: fontSizeBody),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.01),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: fontSizeBody, color: Colors.grey),
                  SizedBox(width: screenWidth * 0.015),
                  Expanded(
                    child: Text(
                      "Reg No: $regNumber",
                      style: TextStyle(fontSize: fontSizeBody),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    grandTotal == 0
                        ? "Total: Not Available"
                        : "Total: ₹${grandTotal.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                      fontSize: fontSizeBody,
                    ),
                  ),
                  if (mobile.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        final message =
                        '''Hello $customerName, your vehicle with Reg. No. $regNumber is ready for collection. Please visit us at your convenience. Thank you! - GarageHub''';
                        openWhatsApp(mobile, message);
                      },
                      icon: Icon(Icons.chat, size: fontSizeBody),
                      label: Text("WhatsApp", style: TextStyle(fontSize: fontSizeBody - 2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customer search result
  Widget _buildCustomerSearchResult(double screenWidth) {
    final double fontSizeBody = screenWidth < 400 ? 12 : 14;

    if (_isSearching) {
      return Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_noCustomerFound) {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
        child: Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red, size: fontSizeBody),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    "No customer found with that search term.",
                    style: TextStyle(fontSize: fontSizeBody),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_customerDetails != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
        child: Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: Icon(Icons.person, color: Colors.green, size: fontSizeBody),
            title: Text(
              _customerDetails!['name'] ?? _customerDetails!['customer_name'] ?? 'No Name',
              style: TextStyle(fontSize: fontSizeBody),
            ),
            subtitle: Text(
              _customerDetails!['mobile'] ?? _customerDetails!['mobile_number'] ?? 'No Mobile',
              style: TextStyle(fontSize: fontSizeBody - 2),
            ),
            trailing: IconButton(
              icon: Icon(Icons.close, size: fontSizeBody),
              onPressed: () {
                setState(() {
                  _customerDetails = null;
                  _noCustomerFound = false;
                });
              },
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInProgressOrders();
    _searchController.addListener(() {
      _performLocalSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "In-Progress Repair Orders",
              style: TextStyle(fontSize: screenWidth < 400 ? 16 : 20),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, size: screenWidth < 400 ? 20 : 24),
                onPressed: _fetchInProgressOrders,
                tooltip: "Refresh Orders",
              ),
              IconButton(
                icon: Icon(Icons.home, size: screenWidth < 400 ? 20 : 24),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
                  );
                },
                tooltip: "Home",
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.grey.shade50,
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search orders by customer, mobile, reg no...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                            ),
                            style: TextStyle(fontSize: screenWidth < 400 ? 12 : 14),
                            onSubmitted: (value) => _searchCustomer(value),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        ElevatedButton.icon(
                          onPressed: () => _searchCustomer(_searchController.text),
                          icon: Icon(Icons.person_search, size: screenWidth < 400 ? 14 : 16),
                          label: Text(
                            "Find Customer",
                            style: TextStyle(fontSize: screenWidth < 400 ? 12 : 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenWidth * 0.03),
                          ),
                        ),
                      ],
                    ),
                    if (_searchController.text.isNotEmpty && _orders.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.02),
                        child: Row(
                          children: [
                            Text(
                              "Showing ${_filteredOrders.length} of ${_orders.length} orders",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: screenWidth < 400 ? 10 : 12,
                              ),
                            ),
                            const Spacer(),
                            if (_searchController.text.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  _performLocalSearch('');
                                  setState(() {
                                    _customerDetails = null;
                                    _noCustomerFound = false;
                                  });
                                },
                                icon: Icon(Icons.clear, size: screenWidth < 400 ? 14 : 16),
                                label: Text(
                                  "Clear",
                                  style: TextStyle(fontSize: screenWidth < 400 ? 10 : 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _buildCustomerSearchResult(screenWidth),
              Expanded(
                child: _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        "Loading in-progress orders...",
                        style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
                      ),
                    ],
                  ),
                )
                    : _error != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: screenWidth < 400 ? 48 : 64,
                        color: Colors.red.shade300,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenWidth < 400 ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      ElevatedButton.icon(
                        onPressed: _fetchInProgressOrders,
                        icon: Icon(Icons.refresh, size: screenWidth < 400 ? 14 : 16),
                        label: Text(
                          "Retry",
                          style: TextStyle(fontSize: screenWidth < 400 ? 12 : 14),
                        ),
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
                        Icons.inbox_outlined,
                        size: screenWidth < 400 ? 48 : 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        _searchController.text.isNotEmpty
                            ? "No orders found matching your search."
                            : "No in-progress orders found.",
                        style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchController.text.isNotEmpty) ...[
                        SizedBox(height: screenWidth * 0.02),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _performLocalSearch('');
                          },
                          child: Text(
                            "Clear search",
                            style: TextStyle(fontSize: screenWidth < 400 ? 12 : 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_filteredOrders[index], screenWidth);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}