import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Ready.dart';
import 'complited_orders.dart';
import 'create_invoice.dart';
import 'create_repair order.dart';
// import 'create_repair_order.dart';
import 'details_page.dart';
import 'inprogrss.dart';
import 'main.dart';
import 'open_orders.dart';
import 'payment_due.dart';
import 'ready_order.dart';

class GarageHomePage extends StatefulWidget {
  const GarageHomePage({super.key});

  @override
  State<GarageHomePage> createState() => _GarageHomePageState();
}

class _GarageHomePageState extends State<GarageHomePage> {
  final Color primaryColor = const Color(0xFF00796B);
  final Color secondaryColor = const Color(0xFF004D40);
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _customerDetails;
  bool _isSearching = false;

  // Store default company data
  Map<String, dynamic>? _defaultCompany;

  // API URLs
  static const String baseUrl = 'https://garage.teambackoffice.com/api/method/garage.garage.auth';
  int? openOrderCount;
  int? inProgressOrderCount;
  int? readyOrderCount;

  @override
  void initState() {
    super.initState();
    fetchDefaultCompany(); // Call API on page load
  }

  // Fetch default company data using the API
  Future<void> fetchDefaultCompany() async {
    final url = Uri.parse('https://garage.teambackoffice.com/api/method/garage.garage.auth.get_default_company');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Company Data: $data');

        if (data['message'] != null) {
          setState(() {
            _defaultCompany = data['message'];
          });
        }
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching company data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double itemWidth = (MediaQuery.of(context).size.width - 48) / 2;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: _defaultCompany == null
            ? const CircularProgressIndicator() // Show a loading indicator while the company name is being fetched
            : Text(
          _defaultCompany?['name'] ?? 'Garage Hub', // Use company name or fallback to default
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(),
              SizedBox(height: screenWidth * 0.02),
              if (_isSearching) const Center(child: CircularProgressIndicator()),
              if (_customerDetails != null) ...[
                _buildCustomerDetailsCard(_customerDetails!),
                SizedBox(height: screenWidth * 0.02),
              ],
              _buildMenuCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRepairOrder())),
                colorStart: Colors.blue.shade300,
                colorEnd: Colors.green.shade300,
                icon: Icons.build_circle_outlined,
                iconColor: primaryColor,
                title: "Create Repair Order",
                subtitle: "Click to open a new job",
              ),
              SizedBox(height: screenWidth * 0.01),
              _buildMenuCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Vehicle())),
                colorStart: Colors.orange.shade200,
                colorEnd: Colors.orange.shade600,
                icon: Icons.receipt_long,
                iconColor: Colors.orange.shade800,
                title: "Create Invoice",
                subtitle: "Parts or service billing",
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                "Quick Access",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: secondaryColor),
              ),
              SizedBox(height: screenWidth * 0.01),
              _quickAccessGrid(itemWidth),
              SizedBox(height: screenWidth * 0.03),
              _buildMenuCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompliteOrders())),
                colorStart: Colors.green.shade300,
                colorEnd: Colors.teal.shade200,
                icon: Icons.history,
                iconColor: Colors.green.shade800,
                title: "Completed Orders",
                subtitle: "View your previous jobs",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextFormField(
      controller: _searchController,
      onFieldSubmitted: _searchCustomerByName,
      decoration: InputDecoration(
        hintText: "Search by Customer Name",
        labelText: "Search",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Future<void> _searchCustomerByName(String name) async {
    if (name.isEmpty) {
      setState(() => _customerDetails = null);
      return;
    }

    setState(() => _isSearching = true);
    final encodedName = Uri.encodeComponent(name);
    final url = Uri.parse('$baseUrl.customer_name_search?customer_name=$encodedName');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'];
        if (message is Map && message['status'] == 'success') {
          setState(() => _customerDetails = Map<String, dynamic>.from(message['data']));
        } else {
          setState(() => _customerDetails = null);
        }
      } else {
        setState(() => _customerDetails = null);
      }
    } catch (e) {
      print("Search error: $e");
      setState(() => _customerDetails = null);
    }

    setState(() => _isSearching = false);
  }

  Widget _buildCustomerDetailsCard(Map<String, dynamic> customer) {
    return InkWell(
      onTap: () {
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoText("Customer Name", customer['customer_name']),
              _infoText("Type", customer['customer_type']),
              _infoText("Group", customer['customer_group']),
              _infoText("Territory", customer['territory']),
              _infoText("Language", customer['language']),
              _infoText("Created On", customer['creation']),
              if (customer['email_id'] != null) _infoText("Email", customer['email_id']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildMenuCard({
    required VoidCallback onTap,
    required Color colorStart,
    required Color colorEnd,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colorStart, colorEnd]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor,
                radius: 18,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAccessGrid(double itemWidth) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _gridButton("Open Orders", Icons.folder_open, [Colors.blue, Colors.purple], itemWidth, openOrderCount, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenRepairOrderListPage()));
            }),
            _gridButton("In Progress", Icons.pending_actions, [Colors.deepOrange, Colors.red], itemWidth, inProgressOrderCount, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InProgressRepairOrdersPage()));
            }),
          ],
        ),
        SizedBox(height: itemWidth * 0.05),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _gridButton("Ready Orders", Icons.check, [Colors.green, Colors.teal], itemWidth, readyOrderCount, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) =>  Order()));
            }),
            _gridButton("Due Payments", Icons.payment, [Colors.pinkAccent, Colors.purple], itemWidth, null, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentDuePage()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _gridButton(String label, IconData icon, List<Color> gradientColors, double itemWidth, int? count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: itemWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (count != null) ...[
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}
