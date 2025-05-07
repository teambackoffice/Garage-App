import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav.dart';
import 'home_page.dart';
import 'main.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _appointmentTimeController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _chasisNumberController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();

  // Dropdown values
  List<String> _makes = [];
  List<String> _models = [];
  String? _selectedMake;
  String? _selectedModel;

  DateTime? _purchaseDate;
  DateTime? _appointmentDate;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMakes();
  }

  Future<void> _fetchMakes() async {
    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_makes';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final makes = data['message']['makes'] as List;
        setState(() {
          _makes = makes.map((m) => m['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching makes: $e');
    }
  }

  Future<void> _fetchModels(String make) async {
    final url =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(make)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['message']['models'] as List;
        setState(() {
          _models = models.map((m) => m['model'] as String).toList();
          _selectedModel = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching models: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _appointmentDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAppointment() async {
    if (_selectedMake == null || _selectedModel == null) {
      setState(() => _errorMessage = "Please select Make and Model!");
      return;
    }

    if (_appointmentDate == null) {
      setState(() => _errorMessage = "Please select Appointment date!");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.create_customer_vehicle_details';

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid');
    if (sessionId == null || sessionId.isEmpty) {
      setState(() => _errorMessage = "Session expired. Please login again.");
      return;
    }

    final payload = {
      "customer_name": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "email": _emailController.text.trim(),
      "address_line1": _addressController.text.trim(),
      "city": _cityController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "make": _selectedMake!,
      "model": _selectedModel!,
      "purchase_date": _formatDate(_purchaseDate),
      "appointment_date": _formatDate(_appointmentDate),
      "appointment_time": _appointmentTimeController.text.trim(),
      "engine_number": _engineNumberController.text.trim(),
      "chasis_number": _chasisNumberController.text.trim(),
      "registration": _registrationController.text.trim(),
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['message']['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment successfully booked!')),
        );
        _clearForm();
      } else {
        setState(() => _errorMessage = 'Failed to book appointment.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _cityController.clear();
    _pincodeController.clear();
    _appointmentTimeController.clear();
    _engineNumberController.clear();
    _chasisNumberController.clear();
    _registrationController.clear();

    setState(() {
      _selectedMake = null;
      _selectedModel = null;
      _purchaseDate = null;
      _appointmentDate = null;
      _errorMessage = null;
    });
  }

  Widget _buildFormField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLength: label == 'Phone' ? 10 : null,
        inputFormatters: label == 'Phone'
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '', // Hide character counter
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          if (label == 'Phone' && !RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter valid 10 digit phone';
          if (label == 'Email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) return 'Enter valid email';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>BottomNavBarScreen()));
            },
              child: Container(child: Icon(Icons.home,color: Colors.black,)))
        ],
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: h*0.01,),
                DropdownButtonFormField<String>(
                  value: _selectedMake,
                  hint: const Text("Tap to select"),
                  items: _makes.map((make) => DropdownMenuItem(value: make, child: Text(make))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMake = value;
                      _fetchModels(value!);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Make',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? 'Please select Make' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  hint: const Text("Tap to select"),
                  items: _models.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedModel = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Model',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? 'Please select Model' : null,
                ),
                const SizedBox(height: 20),
                _buildFormField('Customer Name', _nameController, icon: Icons.person),
                _buildFormField('Phone', _phoneController, inputType: TextInputType.phone, icon: Icons.phone),
                _buildFormField('Email', _emailController, inputType: TextInputType.emailAddress, icon: Icons.email),
                _buildFormField('Address', _addressController, icon: Icons.location_on),
                _buildFormField('City', _cityController, icon: Icons.location_city),
                _buildFormField('Pincode', _pincodeController, inputType: TextInputType.number, icon: Icons.pin),
                ListTile(
                  title: Text('Appointment Date: ${_formatDate(_appointmentDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
                _buildFormField('Appointment Time (HH:MM)', _appointmentTimeController, icon: Icons.access_time),
                _buildFormField('Engine Number', _engineNumberController, icon: Icons.engineering),
                _buildFormField('Chasis Number', _chasisNumberController, icon: Icons.directions_car),
                _buildFormField('Registration', _registrationController, icon: Icons.assignment),
                const SizedBox(height: 20),
                if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Submit Appointment',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
