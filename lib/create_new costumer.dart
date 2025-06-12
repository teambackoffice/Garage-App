import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Customer extends StatefulWidget {
  const Customer({super.key});

  @override
  State<Customer> createState() => _CustomerState();
}

class _CustomerState extends State<Customer> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool isLoading = false;

  Future<void> _createCustomer() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();

    // Check if any field is empty
    if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty || city.isEmpty) {
      _showMessage("Please fill all fields", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    // Final payload, exactly like Postman
    final payload = {
      "name": name,
      "email": email,
      "phone": phone,
      "address": address,
      "city": city,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final sid = prefs.getString('sid');

      if (sid == null || sid.isEmpty) {
        _showMessage("Session expired. Please log in again.", Colors.red);
        setState(() => isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse("https://garage.tbo365.cloud/api/method/garage.garage.auth.create_new_user"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "sid=$sid",
        },
        body: jsonEncode(payload), // ✅ Send raw JSON payload
      );

      final data = jsonDecode(response.body);
      print("🧾 Create Customer Response: $data");

      if (response.statusCode == 200 && data['message']?['status'] == 'success') {
        _showMessage("Customer created successfully", Colors.green);
        _clearFields(); // Optional: Clear form after success
      } else {
        final error = data['message'] is String
            ? data['message']
            : data['message']?['message'] ?? "Customer creation failed.";
        _showMessage("Error: $error", Colors.red);
      }
    } catch (e) {
      _showMessage("Exception: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Customer"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.03),
        child: Column(
          children: [
            _buildTextField(_nameController, "Name", w, icon: Icons.person),
            _buildTextField(_emailController, "Email", w, keyboard: TextInputType.emailAddress, icon: Icons.email),
            _buildTextField(_phoneController, "Phone", w, keyboard: TextInputType.phone, icon: Icons.phone),
            _buildTextField(_addressController, "Address", w, icon: Icons.location_on),
            _buildTextField(_cityController, "City", w, icon: Icons.location_city),
            SizedBox(height: h * 0.03),
            SizedBox(
              width: double.infinity,
              height: h * 0.06,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _createCustomer,
                icon: const Icon(Icons.save),
                label: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Submit", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.025),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, double w,
      {TextInputType keyboard = TextInputType.text, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.025),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(w * 0.025),
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        ),
      ),
    );
  }
}
