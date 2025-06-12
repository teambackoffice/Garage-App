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
import 'main.dart';
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
  List<String> _tags = []; //
  File? _selectedImage;
  String? _selectedTag;// List for tags
  List<Map<String, dynamic>> partsItems = [];
  DateTime deliveryTime = DateTime.now();
  bool notifyCustomer = false;
  double fuelTankLevel = 0;
  int? odometerReading;

  bool isTyping = false;
   File? customerRemarksImage; // To store the image
  File? registrationCertificate;
  File? insuranceDocument;
  final Map<String, TextEditingController> _controllers = {};

  Future<void> _addTag(String tagName) async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.create_tags';

    // Retrieve session ID from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sid');

    if (sessionId == null) {
      _showError("Session expired. Please log in again.");
      return;
    }

    final tagData = {
      'tag_name': tagName,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',  // Ensure 'sid' is being sent properly
        },
        body: jsonEncode(tagData),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print('Decoded Response: $decodedResponse');  // Add this line to debug the response

        if (decodedResponse.containsKey('message') && decodedResponse['message'] == 'Success') {
          _showSnackBar("Tag '$tagName' created successfully!");
          // Refresh the tags after adding a new one
          _fetchtags();
        } else {
          String errorMessage = decodedResponse['message'] ?? 'Unknown error';
          print("API Error: $errorMessage");  // Debugging line to print the error
          _showError("Failed to create tag: $errorMessage");
        }
      } else {
        print("Failed to create tag. Status code: ${response.statusCode}");
        _showError("Failed to create tag. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');  // Log the exception for debugging
      _showError("Failed to create tag. Please try again.");
    }
  }
  Future<void> _pickImage(bool fromGallery) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  Future<void> _pickInsuranceImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        insuranceDocument = File(pickedFile.path);
      });
    }
  }
  Future<void> _uploadInsurance() async {
    if (insuranceDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an insurance image first.'),
      ));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sid') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User is not logged in or token is missing.'),
      ));
      return;
    }

    // Read the file as bytes (binary data)
    final fileBytes = await File(insuranceDocument!.path).readAsBytes();
    final fileName = insuranceDocument!.path.split('/').last;

    print('Insurance file path: ${insuranceDocument!.path}');
    print('File bytes length: ${fileBytes.length}');

    final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.upload_insurance');

    // Prepare the multipart request
    final request = http.MultipartRequest('POST', url)
      ..headers['Cookie'] = 'sid=$token'
      ..fields['repair_order_name'] = 'REPAIR_ORDER_123'  // Ensure this is dynamic if needed
      ..files.add(http.MultipartFile.fromBytes(
        'file',  // Ensure this field name matches what the backend expects
        fileBytes,
        filename: fileName,
      ));
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        print('Upload successful: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Insurance uploaded successfully!'),
          ));
        }
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error uploading insurance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _expectedDateController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchtags();
  }

  double get serviceTotal => serviceItems.fold(0.0, (sum, item) => sum + item['qty'] * item['rate']);
  double get partsTotal => partsItems.fold(0.0, (sum, item) => sum + item['qty'] * item['rate']);



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

  // Fetch tags from the API
  Future<void> _fetchtags() async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_tags';

    // Retrieve session ID from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sid');

    if (sessionId == null) {
      _showError("Session expired. Please log in again.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId', // Pass the session ID here
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tags = List<String>.from(data['message']['data'].map((m) => m['name']));
        });
      } else {
        // Log response details for debugging
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // Check if session expired
        if (response.body.contains('session_expired')) {
          _showError("Session expired. Please log in again.");
        } else {
          _showError("Failed to fetch tags: ${response.statusCode}");
        }
      }
    } catch (e) {
      print('Error: $e');
      _showError("Failed to fetch tags.");
    }
  }




  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
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
        "tags": _selectedTag, // Use the selected tag here
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

    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.create_new_repairorder';

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

  Widget _buildTagsRemarks() {
    return Column(
      children: [
        TextFormField(
          controller: _tagController,
          decoration: const InputDecoration(
            labelText: "Enter Tag Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),  // Adds some space between the text field and button
        ElevatedButton(
          onPressed: () {
            String tagName = _tagController.text.trim();
            if (tagName.isNotEmpty) {
              _addTag(tagName); // Add the tag
              _tagController.clear(); // Clear the input field after submitting
            } else {
              _showSnackBar("Please enter a tag name.");
            }
          },
          child: const Text("Add Tag"),
        ),
        const SizedBox(height: 16),  // Adds some space after the button
        DropdownButtonFormField<String>(
          value: _selectedTag,
          hint: const Text("Choose a tag"),
          onChanged: (String? newValue) {
            setState(() {
              _selectedTag = newValue;
            });
          },
          items: _tags.map((String tag) {
            return DropdownMenuItem<String>(
              value: tag,
              child: Text(tag),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: "Tags",
            border: OutlineInputBorder(),
          ),
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
    if (insuranceDocument != null)
    Image.file(insuranceDocument!, width: 200, height: 200),
    const SizedBox(height: 10),
    ElevatedButton(
    onPressed: _pickInsuranceImage,
    child: const Text('Pick Insurance Image'),
    ),
    const SizedBox(height: 20),
    ElevatedButton(
    onPressed: _uploadInsurance,
    child: const Text('Upload Insurance'),
    )
      ],

    );
  }
  Widget _buildAddTagField() {
    final TextEditingController _tagNameController = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: _tagNameController,
          decoration: const InputDecoration(
            labelText: "Add a New Tag",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final tagName = _tagNameController.text.trim();
            if (tagName.isNotEmpty) {
              _addTag(tagName);
              _tagNameController.clear();
            } else {
              _showSnackBar("Please enter a tag name.");
            }
          },
          child: const Text("Add Tag"),
        ),
      ],
    );
  }
  Widget _buildExtraInputs() {
    return Column(
      children: [
        SizedBox(height: h*0.03,),
        TextField(
          controller: _expectedDateController,
          decoration: const InputDecoration(labelText: "Expected Delivery Date",border: OutlineInputBorder()),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: deliveryTime,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (selectedDate != null && selectedDate != deliveryTime) {
              setState(() {
                deliveryTime = selectedDate;
                _expectedDateController.text = DateFormat('yyyy-MM-dd').format(deliveryTime);
              });
            }
          },
        ),
        SizedBox(height: h*0.03,),
        Row(
          children: [
            const Text("Customer Remarks"),
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload Image',
              onPressed: () => _pickImage(true),
            ),
          ],
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.file(
              _selectedImage!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
  Widget _buildExtraTextInputs() {
    return Column(
      children: [
        ListTile(
          title: const Text("Fuel Level"),
          subtitle: Slider(
            value: fuelTankLevel,
            min: 0,
            max: 100,
            divisions: 10,
            label: fuelTankLevel.toStringAsFixed(1),
            onChanged: (double value) {
              setState(() {
                fuelTankLevel = value;
              });
            },
          ),
        ),
        TextField(
          keyboardType: TextInputType.number,
          controller: _controllers['odometer'] ??= TextEditingController(),
          decoration: const InputDecoration(labelText: "Odometer Reading (in km)"),
          onChanged: (value) {
            // Update the odometerReading value
            setState(() {
              odometerReading = int.tryParse(value);
            });
          },
        ),

      ],
    );
  }
}




