// repair_order_full_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:garage_app/part_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'service_page.dart';

class RepairOrderFullPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  const RepairOrderFullPage({super.key, required this.formData});

  @override
  State<RepairOrderFullPage> createState() => _RepairOrderFullPageState();
}

class _RepairOrderFullPageState extends State<RepairOrderFullPage> {
  List<Map<String, dynamic>> serviceItems = [];
  List<Map<String, dynamic>> partsItems = [];
  DateTime deliveryTime = DateTime.now();
  bool notifyCustomer = false;
  double fuelTankLevel = 100.0;
  int odometerReading = 1;
  bool isTyping = false;

  File? registrationCertificate;
  File? insuranceDocument;

  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _expectedDateController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();

  double get serviceTotal => serviceItems.fold(0.0, (sum, item) => sum + item['qty'] * item['rate']);
  double get partsTotal => partsItems.fold(0.0, (sum, item) => sum + item['qty'] * item['rate']);

  Future<void> _pickImage(bool isForRegistrationCertificate) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isForRegistrationCertificate) {
          registrationCertificate = File(pickedFile.path);
        } else {
          insuranceDocument = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _addService() async {
    final selected = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicePage()));
    if (selected != null && selected is List) {
      setState(() => serviceItems = List<Map<String, dynamic>>.from(selected));
    }
  }

  Future<void> _addPart() async {
    final selected = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceAndParts()));
    if (selected != null && selected is List) {
      setState(() => partsItems = List<Map<String, dynamic>>.from(selected));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.black87));
  }

  Future<bool> _submitFinalRepairOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid');

    if (sessionId == null || sessionId.isEmpty) {
      _showSnackBar("⚠️ Session expired. Please log in again.");
      Navigator.of(context).pop();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return false;
    }

    if (serviceItems.isEmpty && partsItems.isEmpty) {
      _showSnackBar("⚠️ Please add at least one service or part.");
      return false;
    }

    final fullData = {
      "data": {
        ...widget.formData,
        "service_items": serviceItems,
        "parts_items": partsItems,
        "tags": _tagController.text.trim(),
        "remarks": _remarkController.text.trim(),
        "delivery_time": deliveryTime.toIso8601String(),
        "notify_customer": notifyCustomer,
        "odometer_reading": odometerReading.toString(),
        "expected_date": _expectedDateController.text.trim(),
        "customer_remarks": _customerRemarksController.text.trim(),
        "fuel_level": fuelTankLevel.toStringAsFixed(2),
        "registration_certificate": registrationCertificate != null ? base64Encode(await registrationCertificate!.readAsBytes()) : null,
        "insurance_document": insuranceDocument != null ? base64Encode(await insuranceDocument!.readAsBytes()) : null,
      }
    };

    const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.create_new_repairorder';

    if (!mounted) return false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
        body: jsonEncode(fullData),
      );

      if (!mounted) return false;
      Navigator.of(context).pop();

      final decoded = jsonDecode(response.body);
      final message = decoded['message'];

      if (message is Map && message.containsKey('repair_order_id')) {
        await prefs.setString('repair_order_id', message['repair_order_id']);
      }

      _showSnackBar("✅ Repair Order Submitted Successfully");

      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersListPage()));
      }

      return true;
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print("Repair Order Error: $e");
      _showSnackBar("❌ Network error. Please try again later.");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Review Repair Order'),
        actions: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BottomNavBarScreen())),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.home),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCustomerCard(widget.formData),
                  _buildSection("SERVICES", _addService),
                  _buildSection("PARTS", _addPart),
                  _buildSummary(),
                  _buildExtraInputs(),
                  _buildTagsRemarks(),
                  _buildImagePickerFields(),
                  _buildExtraTextInputs(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitFinalRepairOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: isWide ? const Size(200, 50) : const Size(150, 50),
                    ),
                    child: Text("Submit Repair Order", style: TextStyle(fontSize: isWide ? 18 : 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['customer_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data['mobile'] ?? ''),
            Text(data['email'] ?? ''),
            const Divider(),
            Text("${data['make'] ?? ''} ${data['model'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(data['registration_number'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, VoidCallback onAdd) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.green.shade100,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(icon: const Icon(Icons.add_circle), onPressed: onAdd),
      ),
    );
  }

  Widget _summaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("₹${value.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _summaryRow("Labor Total", serviceTotal),
          _summaryRow("Parts Total", partsTotal),
          const Divider(),
          _summaryRow("TOTAL", serviceTotal + partsTotal),
        ]),
      ),
    );
  }

  Widget _buildExtraInputs() {
    return Column(
      children: [
        ListTile(
          title: const Text("Delivery Time"),
          subtitle: Text(DateFormat('yyyy-MM-dd – hh:mm a').format(deliveryTime)),
          trailing: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: deliveryTime,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(deliveryTime),
                );
                if (pickedTime != null) {
                  setState(() {
                    deliveryTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                }
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Odometer Reading", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16), // Space between label and field
            SizedBox(
              width: 100, // You can adjust the width as per your design
              child: TextFormField(
                controller: TextEditingController(text: odometerReading.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                onChanged: (value) {
                  final newValue = int.tryParse(value);
                  if (newValue != null) {
                    setState(() {
                      odometerReading = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        const Text("Fuel Tank Level", style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: fuelTankLevel,
          min: 0,
          max: 100,
          divisions: 10,
          label: '${fuelTankLevel.toStringAsFixed(0)}%',
          onChanged: (val) => setState(() => fuelTankLevel = val),
        ),
      ],
    );
  }

  Widget _buildTagsRemarks() {
    return Column(
      children: [
        TextField(
          controller: _tagController,
          decoration: const InputDecoration(labelText: "Tags"),
        ),
        TextField(
          controller: _remarkController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Remarks"),
        ),
      ],
    );
  }

  Widget _buildImagePickerFields() {
    return Column(
      children: [
        ListTile(
          title: const Text("Registration Certificate"),
          trailing: IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pickImage(true),
          ),
        ),
        if (registrationCertificate != null) ...[
          const Text("Selected: Registration Certificate"),
          Image.file(registrationCertificate!),
        ],
        ListTile(
          title: const Text("Insurance Document"),
          trailing: IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pickImage(false),
          ),
        ),
        if (insuranceDocument != null) ...[
          const Text("Selected: Insurance Document"),
          Image.file(insuranceDocument!),
        ],
      ],
    );
  }

  Widget _buildExtraTextInputs() {
    return Column(
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _expectedDateController,
          decoration: const InputDecoration(
            labelText: "Expected Delivery Date (optional)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerRemarksController,
          decoration: const InputDecoration(
            labelText: "Customer Remarks (optional)",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
