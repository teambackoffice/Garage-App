import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_app/repair_order.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav.dart';

class CreateRepairOrder extends StatefulWidget {
  const CreateRepairOrder({super.key});
  @override
  State<CreateRepairOrder> createState() => _CreateRepairOrderState();
}

class _CreateRepairOrderState extends State<CreateRepairOrder> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _sessionId;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, dynamic> _formData = {
    "customer_name": "",
    "mobile": "",
    "email": "",
    "address": "",
    "city": "",
    "make": "",
    "model": "",
    "purchase_date": "",
    "engine_number": "",
    "chasis_number": "",
    "registration_number": "",
  };

  final Map<String, TextEditingController> _controllers = {};
  List<String> _makes = [];
  List<String> _models = [];

  @override
  void initState() {
    super.initState();
    _loadSessionId();
    _fetchMakes();
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sid');
    if (_sessionId == null || _sessionId!.isEmpty) {
      _showError("Session not found. Please login again.");
    }
  }

  Future<void> _fetchMakes() async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_makes';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _makes = List<String>.from(data['message']['makes'].map((m) => m['name']));
        });
      }
    } catch (e) {
      _showError("Failed to fetch makes.");
    }
  }

  Future<void> _fetchModels(String make) async {
    final url =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(make)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _models = List<String>.from(data['message']['models'].map((m) => m['model']));
          _formData['model'] = ''; // clear model if make changes
        });
      }
    } catch (e) {
      _showError("Failed to fetch models.");
    }
  }

  Future<void> _fetchVehicleDetails(String registrationNumber) async {
    if (registrationNumber.trim().isEmpty) {
      _showError("Please enter a registration number.");
      return;
    }

    final url =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.vregnum_search?vehicle_num=${Uri.encodeComponent(registrationNumber)}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'sid=$_sessionId',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);
      final data = responseBody['message']?['data'];

      if (data != null && data is Map<String, dynamic>) {
        final vehicle = data['vehicle_details'];
        final customer = data['customer_details'];
        final address = data['customer_address'];

        setState(() {
          _formData['customer_name'] = customer?['customer_name'] ?? '';
          _formData['mobile'] = address?['phone'] ?? '';
          _formData['email'] = address?['email_id'] ?? '';
          _formData['address'] = address?['address_line1'] ?? '';
          _formData['city'] = address?['city'] ?? '';
          _formData['make'] = vehicle?['make'] ?? '';
          _formData['model'] = vehicle?['model'] ?? '';
          _formData['engine_number'] = vehicle?['engine_number'] ?? '';
          _formData['chasis_number'] = vehicle?['chasis_number'] ?? '';
          _formData['registration_number'] = registrationNumber;

          _controllers.forEach((key, controller) {
            controller.text = _formData[key] ?? '';
          });

          if (_formData['make'].isNotEmpty) {
            _fetchModels(_formData['make']);
          }
        });
      } else {
        _showError("No data found for this vehicle.");
      }
    } catch (e) {
      _showError("An error occurred while fetching vehicle details.");
    }
  }

  Widget _buildTextField(String key, String label, {TextInputType? inputType, IconData? icon}) {
    _controllers.putIfAbsent(key, () => TextEditingController(text: _formData[key]));
    _controllers[key]!.text = _formData[key];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: key == 'mobile' ? TextInputType.number : inputType,
        inputFormatters: key == 'mobile'
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (key == 'mobile' && v.length != 10) return 'Enter 10-digit mobile number';
          if (key == 'email' && v.isNotEmpty) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
            if (!emailRegex.hasMatch(v)) return 'Enter valid email';
          }
          return null;
        },
        onChanged: (value) => _formData[key] = value.trim(),
      ),
    );
  }

  Widget _buildDropdown(String key, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: _formData[key].isNotEmpty ? _formData[key] : null,
        items: items.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _formData[key] = value ?? '';
            if (key == 'make') {
              _fetchModels(value ?? '');
            }
          });
        },
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDateField(String key, String label) {
    _controllers.putIfAbsent(key, () => TextEditingController(text: _formData[key]));
    _controllers[key]!.text = _formData[key];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextFormField(
            controller: _controllers[key],
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today),
              prefixIcon: const Icon(Icons.date_range),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_formData['purchase_date'].isNotEmpty) {
      initialDate = DateTime.tryParse(_formData['purchase_date']) ?? DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final formattedDate = picked.toIso8601String().split('T').first;
      setState(() {
        _formData['purchase_date'] = formattedDate;
        _controllers['purchase_date']?.text = formattedDate;
      });
    }
  }

  void _goToOrdersPage() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepairOrderFullPage(formData: _formData),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>BottomNavBarScreen()));
            },
              child: Container(child: Icon(Icons.home,color: Colors.black,)))
        ],
        title: const Text("Create Repair Order"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final regNum = _searchController.text.trim();
                        if (regNum.isNotEmpty) {
                          _fetchVehicleDetails(regNum);
                        } else {
                          _showError("Please enter a vehicle number.");
                        }
                      },
                      child: const Text("Search"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField("customer_name", "Customer Name", icon: Icons.person),
              _buildTextField("mobile", "Mobile", inputType: TextInputType.phone, icon: Icons.phone),
              _buildTextField("email", "Email", inputType: TextInputType.emailAddress, icon: Icons.email),
              _buildTextField("address", "Address", icon: Icons.home),
              _buildTextField("city", "City", icon: Icons.location_city),
              _buildDropdown("make", "Select Make", _makes),
              _buildDropdown("model", "Select Model", _models),
              _buildDateField("purchase_date", "Purchase Date"),
              _buildTextField("engine_number", "Engine Number", icon: Icons.engineering),
              _buildTextField("chasis_number", "Chassis Number", icon: Icons.directions_car),
              _buildTextField("registration_number", "Registration Number", icon: Icons.confirmation_number),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: screenWidth * 0.9,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _goToOrdersPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Next", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
