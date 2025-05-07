// settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cancel.dart';
import 'insurence_due.dart';
import 'login_page.dart';
import 'main.dart';
import 'my_customers.dart';
import 'my_vendor.dart';
import 'reports.dart';
import 'search_orders.dart';
import 'service_remainder.dart';
import 'settings.dart';
import 'Tally_exports.dart';
import 'vehicle_search_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = "";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text("Welcome: $_username", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: h*0.03,),
          buildDivider(),
          buildNavTile(Icons.person, 'My Customers', MyCustomersPage()),
          buildDivider(),
          buildNavTile(Icons.group, 'My Vendors', MyVendorsPage()),
          buildDivider(),
          buildNavTile(Icons.receipt_long, 'Order Search', SearchOrdersPage()),
          buildDivider(),
          buildNavTile(Icons.settings, 'Settings', GarageSettingsPage()),
          buildDivider(),
          buildNavTile(Icons.palette, 'Service Reminders', const ServiceRemindersPage()),
          buildDivider(),
          buildNavTile(Icons.star, 'Service Feedbacks', const ServiceRemindersPage()), // Placeholder
          buildDivider(),
          buildNavTile(Icons.directions_car, 'Vehicle Search', const VehicleSearchPage()),
          buildDivider(),
          buildNavTile(Icons.timer, 'Insurance Due', const InsuranceDuePage()),
          buildDivider(),
          buildNavTile(Icons.bar_chart, 'Reports', const ReportsPage()),
          buildDivider(),
          buildNavTile(Icons.insert_drive_file, 'Tally Export', const TallyExportPage()),
          buildDivider(),
          buildNavTile(Icons.cancel, 'Cancel Orders', const CancelledOrdersPage()),
          buildDivider(),
          buildSimpleTile(Icons.group_add, 'Refer'), // No action
          buildDivider(),
          const SizedBox(height: 20),
          buildSimpleTile(Icons.logout, 'Logout', onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    child: const Text("No"),
                    onPressed: () => Navigator.pop(context), // dismiss dialog
                  ),
                  TextButton(
                    child: const Text("Yes"),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear(); // clear login info
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login'); // navigate to login
                      }
                    },
                  ),
                ],
              ),
            );
          }),

          buildDivider(),
        ],
      ),
    );
  }

  Widget buildNavTile(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  Widget buildSimpleTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget buildDivider() => const Divider(height: 0.5, thickness: 0.5);

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
