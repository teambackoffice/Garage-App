import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_app/part_service.dart';
import 'package:garage_app/service_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav.dart';
import 'login_page.dart';
import 'orders_page.dart';

class CreateRepairOrder extends StatefulWidget {
  final bool confirm;
  final Map<String, dynamic> ? appointmentData;
  const CreateRepairOrder({super.key, this.appointmentData,required this.confirm});

  @override
  State<CreateRepairOrder> createState() => _CreateRepairOrderState();
}

class _CreateRepairOrderState extends State<CreateRepairOrder> {
  // Controllers
  final TextEditingController _expectedDateController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();

  final Map<String, TextEditingController> _controllers = {};

  // State variables
  bool notifyCustomer = false;
  bool _isRefreshing = false;
  File? _selectedImage;
  List<Map<String, dynamic>> partsItems = [];
  double partsTotal = 0.0;
  double partsSubtotal = 0.0;
  double tax = 0.0;
  DateTime deliveryTime = DateTime.now();
  int? odometerReading;
  double fuelTankLevel = 0;
  double h = 0;

  bool isTyping = false;
  List<String> _tags = [];
  String? _selectedTag;
  File? customerRemarksImage;
  File? insuranceDocument;
  File? registrationCertificate;
  List<Map<String, dynamic>> serviceItems = [];
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _sessionId;
  bool _uploadingInsurance = false;

  List<String> _makes = [];
  List<String> _models = [];
  List<File> insuranceDocuments = []; // To store multiple files
  int? _uploadingInsuranceIndex;
  void _pickFile({required bool fromGallery}) async {
    File? pickedFile;

    if (fromGallery) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        pickedFile = File(picked.path);
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        pickedFile = File(result.files.single.path!);
      }
    }

    if (pickedFile != null) {
      setState(() {
        insuranceDocuments.add(pickedFile!);
      });
    }
  }
  List<File> customerRemarksImages = [];



  @override
  void initState() {
    super.initState();
    _loadSessionId();
    _fetchtags();
    _fetchMakes();
    _controllers['odometer'] = TextEditingController();
  }

  @override
  void dispose() {
    _expectedDateController.dispose();
    _tagController.dispose();
    _remarkController.dispose();
    _customerRemarksController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _purchaseDateController.dispose();
    _engineNumberController.dispose();
    _chassisNumberController.dispose();
    _registrationNumberController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Getters for totals
  double get serviceTotal =>
      serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get partsTotalAmount =>
      partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get grandTotal => serviceTotal + partsTotalAmount + tax;

  // Clear all form data
  void _clearAllFormData() {
    setState(() {
      // Clear text controllers
      _expectedDateController.clear();
      _tagController.clear();
      _remarkController.clear();
      _customerRemarksController.clear();
      _searchController.clear();
      _customerNameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _addressController.clear();
      _cityController.clear();
      _makeController.clear();
      _modelController.clear();
      _purchaseDateController.clear();
      _engineNumberController.clear();
      _chassisNumberController.clear();
      _registrationNumberController.clear();

      _controllers.forEach((_, controller) => controller.clear());

      // Reset variables
      _selectedTag = null;
      notifyCustomer = false;
      _selectedImage = null;
      customerRemarksImage = null;
      insuranceDocument = null;
      registrationCertificate = null;
      partsItems = [];
      serviceItems = [];
      partsTotal = 0.0;
      partsSubtotal = 0.0;
      tax = 0.0;
      deliveryTime = DateTime.now();
      odometerReading = null;
      fuelTankLevel = 0;
      _models = [];
      _uploadingInsurance = false;
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _refreshForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text("Are you sure you want to clear all fields and refresh the form?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Refresh"),
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllFormData();
                _showSnackBar("✅ Form has been refreshed");
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _submitFinalRepairOrder() async {
    if (!mounted) return false;

    setState(() {
      _isSubmitting = true;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("⚠️ Please fill all required fields.");
      setState(() => _isSubmitting = false);
      return false;
    }

    // Validate items
    if (serviceItems.isEmpty && partsItems.isEmpty) {
      _showSnackBar("⚠️ Add at least one service or part.");
      setState(() => _isSubmitting = false);
      return false;
    }

    // Get session
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid');

    if (sessionId == null || sessionId.isEmpty) {
      _showSnackBar("⚠️ Session expired. Please log in again.");
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
      return false;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Submitting order..."),
            ],
          ),
        ),
      );
    }

    try {
      final expectedDateFormatted = _expectedDateController.text.isNotEmpty
          ? _expectedDateController.text
          : DateFormat('yyyy-MM-dd').format(DateTime.now());

      final uri = Uri.parse(
        "https://garage.tbo365.cloud/api/method/garage.garage.auth.create_new_repairorder",
      );

      final request = http.MultipartRequest("POST", uri)
        ..headers['Cookie'] = 'sid=$sessionId';

      // Fields
      final fields = {
        "customer_name": _customerNameController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "make": _makeController.text.trim(),
        "model": _modelController.text.trim(),
        "purchase_date": _purchaseDateController.text.trim(),
        "engine_number": _engineNumberController.text.trim(),
        "chasis_number": _chassisNumberController.text.trim(),
        "registration_number": _registrationNumberController.text.trim(),
        "tags": _selectedTag ?? "",
        "remarks": _remarkController.text.trim(),
        "delivery_time": deliveryTime.toIso8601String(),
        "notify_customer": notifyCustomer.toString(),
        "odometer_reading": odometerReading?.toString() ?? "0",
        "expected_date": expectedDateFormatted,
        "customer_remarks": _customerRemarksController.text.trim(),
        "fuel_level": fuelTankLevel.toString(),
      };

      fields.forEach((key, value) {
        if (value.isNotEmpty) {
          request.fields[key] = value;
        }
      });

      request.fields['service_items'] = jsonEncode(serviceItems);
      request.fields['parts_items'] = jsonEncode(partsItems);

      // Attach files
      if (insuranceDocument != null && await insuranceDocument!.exists()) {
        request.files.add(await http.MultipartFile.fromPath('insurance', insuranceDocument!.path));
      }
      if (registrationCertificate != null && await registrationCertificate!.exists()) {
        request.files.add(await http.MultipartFile.fromPath('registration_certificate', registrationCertificate!.path));
      }
      if (customerRemarksImage != null && await customerRemarksImage!.exists()) {
        request.files.add(await http.MultipartFile.fromPath('image', customerRemarksImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      }

      if (!mounted) return false;

      final decoded = jsonDecode(response.body);
      final message = decoded['message'];

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Handle successful response
        if (message != null) {
          // Check if message is a Map (contains repair_order_id)
          if (message is Map<String, dynamic> && message.containsKey('repair_order_id')) {
            // Save repair order ID
            await prefs.setString('repair_order_id', message['repair_order_id']);

            // Save file paths if they exist
            if (insuranceDocument != null) {
              await prefs.setString('insurance_path', insuranceDocument!.path);
            }
            if (registrationCertificate != null) {
              await prefs.setString('rc_path', registrationCertificate!.path);
            }
            if (customerRemarksImage != null) {
              await prefs.setString('remarks_image_path', customerRemarksImage!.path);
            }

            final created = decoded['customer_created'] == true;
            final successMessage = created
                ? "✅ Customer created successfully!"
                : "✅ Repair Order Created Successfully!";

            // Show success dialog
            _showSuccessDialog(successMessage);
            return true;
          }
          // Check if message is a string indicating success
          else if (message is String) {
            // Common success messages from API
            if (message.toLowerCase().contains('success') ||
                message.toLowerCase().contains('created') ||
                message.toLowerCase().contains('saved')) {

              _showSuccessDialog("✅ Repair Order Created Successfully!");
              return true;
            } else {
              // If it's a string but not indicating success, show it as error
              _showSnackBar("❌ $message");
              return false;
            }
          }
          // If message exists but is neither Map with repair_order_id nor success string
          else {
            _showSuccessDialog("✅ Repair Order Created Successfully!");
            return true;
          }
        } else {
          // No message but successful status code
          _showSuccessDialog("✅ Repair Order Created Successfully!");
          return true;
        }
      } else {
        // Handle error response (status code >= 400)
        String errorMsg;

        try {
          if (decoded['exception'] != null) {
            errorMsg = "❌ ${decoded['exception']}";
          } else if (decoded['error'] != null) {
            errorMsg = "❌ ${decoded['error']}";
          } else if (decoded['message'] != null) {
            errorMsg = "❌ ${decoded['message']}";
          } else {
            errorMsg = "❌ Unknown error occurred. Please try again.";
          }
        } catch (e) {
          errorMsg = "❌ Error processing response. Please try again.";
        }

        _showSnackBar(errorMsg);
        return false;
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        _showSnackBar("❌ Network error: ${e.toString()}");
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text("Success!"),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear form data only when user chooses to create another order
                _clearAllFormData();
                _showSnackBar("✅ Form has been cleared for new order");
              },
              child: const Text("Create Another Order"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrdersListPage()),
                );
              },
              child: const Text("View Orders"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Stay on the current form without clearing
              },
              child: const Text("Stay Here"),
            ),
          ],
        );
      },
    );
  }

  // Service and Parts methods
  Future<void> _addService() async {
    try {
      final selected = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServicePage())
      );

      if (selected != null && selected is List) {
        setState(() {
          serviceItems = List<Map<String, dynamic>>.from(selected);
        });
      }
    } catch (e) {
      _showSnackBar("❌ Error selecting services: ${e.toString()}");
    }
  }

  Future<void> _addPart() async {
    try {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServiceAndParts())
      );

      if (result != null) {
        if (result is List) {
          setState(() {
            partsItems = List<Map<String, dynamic>>.from(result);
            partsSubtotal = partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));
          });
        } else if (result is Map<String, dynamic>) {
          setState(() {
            partsItems = List<Map<String, dynamic>>.from(result['items'] ?? []);
            partsSubtotal = result['subtotal'] ?? 0.0;
            tax = result['tax'] ?? 0.0;
            partsTotal = result['total'] ?? 0.0;
          });
        }
      }
    } catch (e) {
      _showSnackBar("❌ Error selecting parts: ${e.toString()}");
    }
  }

  // API methods
  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sid');
    if (_sessionId == null || _sessionId!.isEmpty) {
      _showError("Session not found. Please login again.");
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  Future<void> _fetchtags() async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_tags';
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
          'Cookie': 'sid=$sessionId',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null && data['message']['data'] != null) {
          var tagsData = data['message']['data'];
          if (tagsData is List) {
            setState(() {
              _tags = tagsData.map((tag) => tag['name'] as String).toList();
            });
          }
        }
      }
    } catch (e) {
      _showError("Failed to fetch tags. Please check your connection.");
    }
  }

  Future<void> _fetchMakes() async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_makes';
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
    final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(make)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _models = List<String>.from(data['message']['models'].map((m) => m['model']));
        });
      }
    } catch (e) {
      _showError("Failed to fetch models.");
    }
  }

  Future<void> _addTag(String tagName) async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.create_tags';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sid');

    if (sessionId == null) {
      _showError("⚠️ Your session has expired. Please log in again.");
      return;
    }

    final tagData = {'tag_name': tagName};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sessionId',
        },
        body: jsonEncode(tagData),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final message = decodedResponse['message']?.toString().toLowerCase();
        print("Response body: ${response.body}"); // for debugging

        if (message != null && (message.contains('success') || message.contains('created'))) {
          _showSnackBar("✅ Tag '$tagName' created successfully!");
          _fetchtags();
        } else {
          _showError("❌ Failed to create tag: ${decodedResponse['message'] ?? 'Unknown response'}");
        }
      } else {
        _showError("❌ Unable to create tag. Server responded with status code ${response.statusCode}.");
      }
    } catch (e) {
      _showError("❌ Network error occurred. Please check your connection and try again.");
    }
  }



  Future<void> _fetchVehicleDetails(String registrationNumber) async {
    if (registrationNumber.trim().isEmpty) {
      _showError("Please enter a registration number.");
      return;
    }

    final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.vregnum_search?vehicle_num=${Uri.encodeComponent(registrationNumber)}';

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'sid=$_sessionId',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (responseBody['message'] != null &&
          responseBody['message'] is Map &&
          responseBody['message'].containsKey('status') &&
          responseBody['message']['status'] == 'error') {
        _showError("❌ ${responseBody['message']['message']}");
        return;
      }

      final data = responseBody['message']?['data'];

      if (data != null && data is Map<String, dynamic>) {
        final vehicle = data['vehicle_details'];
        final customer = data['customer_details'];
        final address = data['customer_address'];

        if (customer != null) {
          _customerNameController.text = customer['customer_name'] ?? '';
        }

        if (address != null) {
          _mobileController.text = address['phone'] ?? '';
          _emailController.text = address['email_id'] ?? '';

          String addressText = '';
          if (address['address_line1'] != null && address['address_line1'].toString().isNotEmpty) {
            addressText = address['address_line1'];
          }
          if (address['address_line2'] != null && address['address_line2'].toString().isNotEmpty) {
            addressText += addressText.isEmpty ? address['address_line2'] : ', ${address['address_line2']}';
          }
          _addressController.text = addressText;
          _cityController.text = address['city'] ?? '';
        }

        if (vehicle != null) {
          _makeController.text = vehicle['make'] ?? '';
          _modelController.text = vehicle['model'] ?? '';
          _engineNumberController.text = vehicle['engine_number'] ?? '';
          _chassisNumberController.text = vehicle['chasis_number'] ?? '';
          _registrationNumberController.text = registrationNumber;

          if (vehicle['make'] != null && vehicle['make'].toString().isNotEmpty) {
            _fetchModels(vehicle['make']);
          }
        }

        _showSnackBar("✅ Vehicle details loaded successfully.");
      } else {
        _showError("❌ No data found for this registration number.");
      }
    } catch (e) {
      _showError("❌ Error fetching vehicle details: ${e.toString()}");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Image picker methods
  Future<void> _pickImage(bool isCustomerRemarks) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && isCustomerRemarks) {
      setState(() {
        customerRemarksImages.add(File(image.path)); // Add to the list
      });
    } else if (image != null) {
      setState(() {
        insuranceDocument = File(image.path);
        _showSnackBar("Insurance document selected");
      });
    }
  }


  Future<void> _pickRegistrationCertificateImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        registrationCertificate = File(image.path);
      });
    }
  }

  // UI Builder methods
  Widget _buildTextField(String key, String label, {TextInputType? inputType, IconData? icon}) {
    TextEditingController controller;

    switch (key) {
      case "customer_name":
        controller = _customerNameController;
        break;
      case "mobile":
        controller = _mobileController;
        break;
      case "email":
        controller = _emailController;
        break;
      case "address":
        controller = _addressController;
        break;
      case "city":
        controller = _cityController;
        break;
      case "engine_number":
        controller = _engineNumberController;
        break;
      case "chasis_number":
        controller = _chassisNumberController;
        break;
      case "registration_number":
        controller = _registrationNumberController;
        break;
      default:
        if (!_controllers.containsKey(key)) {
          _controllers[key] = TextEditingController();
        }
        controller = _controllers[key]!;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: controller,
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
      ),
    );
  }

  Widget _buildDropdown(String key, String label, List<String> items) {
    TextEditingController? controller;
    if (key == "make") {
      controller = _makeController;
    } else if (key == "model") {
      controller = _modelController;
    }

    String? currentValue;
    if (controller != null && controller.text.isNotEmpty) {
      currentValue = controller.text;
      if (!items.contains(currentValue)) {
        currentValue = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: currentValue,
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
            if (controller != null) {
              controller.text = value ?? '';
            }

            if (key == 'make') {
              _fetchModels(value ?? '');
              _modelController.text = '';
            }
          });
        },
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDateField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: _purchaseDateController,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(picked);
            });
          }
        },
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildTagsRemarks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          TextFormField(
            controller: _tagController,
            decoration: const InputDecoration(
              labelText: "Enter Tag Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              String tagName = _tagController.text.trim();
              if (tagName.isNotEmpty) {
                _addTag(tagName);
                _tagController.clear();
              } else {
                _showSnackBar("Please enter a tag name.");
              }
            },
            child: const Text("Add Tag"),
          ),
          const SizedBox(height: 16),
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
            decoration: const InputDecoration(
              labelText: "Tags",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _priceRow("Labor Total", serviceTotal),
            _priceRow("Parts Total", partsTotalAmount),
            _priceRow("Tax", tax),
            const Divider(),
            _priceRow("TOTAL", serviceTotal + partsTotalAmount + tax, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildImagePickerFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Document Uploads",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Insurance Document
          // Row for Insurance Document Upload Button
          Row(
            children: [
              const Text("Insurance Document"),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload"),
                onPressed: () {
                  _pickFile(fromGallery: true); // Directly open gallery
                },
              ),
            ],
          ),


// Show File List (Only Names)
          if (insuranceDocuments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: List.generate(insuranceDocuments.length, (index) {
                  final document = insuranceDocuments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.file(
                            document,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_uploadingInsuranceIndex == index)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              insuranceDocuments.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),




          const SizedBox(height: 16),

          // Registration Certificate
          Row(
            children: [
              const Text("Registration Certificate"),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload"),
                onPressed: _pickRegistrationCertificateImage,
              ),
            ],
          ),
          if (registrationCertificate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.file(
                      registrationCertificate!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10), // Space between image and delete button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        registrationCertificate = null;
                      });
                    },
                  ),
                ],
              ),
            ),


          const SizedBox(height: 16),

          // Customer Remarks Image
    // Add this to store multiple images

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("Customer Remarks Images"),
                  const SizedBox(width: 5),
                  Text("${customerRemarksImages.length}/3  "),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload"),
                    onPressed: customerRemarksImages.length < 3
                        ? () => _pickImage(true)
                        : null, // Disable button if 3 images selected
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              if (customerRemarksImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: customerRemarksImages.map((image) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10), // Space between image and delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  customerRemarksImages.remove(image);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          )

        ],
      ),
    );
  }

  Widget _buildExtraInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _expectedDateController,
            decoration: const InputDecoration(
              labelText: "Expected Delivery Date",
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              final DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: deliveryTime,
                firstDate: DateTime.now(),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerRemarksController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Customer Remarks",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExtraTextInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vehicle Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text("Fuel Level"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: fuelTankLevel,
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: "${fuelTankLevel.toStringAsFixed(0)}%",
                  onChanged: (double value) {
                    setState(() {
                      fuelTankLevel = value;
                    });
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Empty"),
                    Text("Half"),
                    Text("Full"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: _controllers['odometer'] ??= TextEditingController(),
            decoration: const InputDecoration(
              labelText: "Odometer Reading (in km)",
              border: OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {
                odometerReading = int.tryParse(value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, VoidCallback onAdd) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: onAdd,
          tooltip: "Add $title",
        ),
      ),
    );
  }

  Widget _buildItemList(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['item_name'] ?? 'Unknown Item'),
                  subtitle: Text('Qty: ${item['qty']} x ₹${item['rate']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Important to prevent Row from taking full width
                    children: [
                      Text('₹${((item['qty'] ?? 0) * (item['rate'] ?? 0)).toStringAsFixed(2)}'),
                      SizedBox(width: 30,),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Handle delete action
                          setState(() {
                            items.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );

  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Repair Order"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshForm,
            tooltip: "Refresh Form",
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
              );
            },
            tooltip: "Home",
          )
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search by Vehicle Number
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child:
                      TextFormField(
                        controller:
                          _searchController,

                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : () {
                        final regNum = _searchController.text.trim();
                        if (regNum.isNotEmpty) {
                          _fetchVehicleDetails(regNum);
                        } else {
                          _showError("Please enter a vehicle number.");
                        }
                      },
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Search"),
                    ),
                  ],
                ),
              ),

              // Customer Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Customer Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              _buildTextField("customer_name", "Customer Name", icon: Icons.person),
              _buildTextField("mobile", "Mobile", inputType: TextInputType.phone, icon: Icons.phone),
              _buildTextField("email", "Email", inputType: TextInputType.emailAddress, icon: Icons.email),
              _buildTextField("address", "Address", icon: Icons.home),
              _buildTextField("city", "City", icon: Icons.location_city),

              // Vehicle Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Vehicle Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              _buildDropdown("make", "Select Make", _makes),
              _buildDropdown("model", "Select Model", _models),
              _buildDateField("Purchase Date", "purchase_date"),
              _buildTextField("engine_number", "Engine Number", icon: Icons.engineering),
              _buildTextField("chasis_number", "Chassis Number", icon: Icons.directions_car),
              _buildTextField("registration_number", "Registration Number", icon: Icons.confirmation_number),

              // Services and Parts Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Services and Parts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              _buildSection("SERVICES", _addService),
              if (serviceItems.isNotEmpty)
                _buildItemList("SERVICES", serviceItems),

              _buildSection("PARTS", _addPart),
              if (partsItems.isNotEmpty)
                _buildItemList("PARTS", partsItems),

              _buildSummary(),

              // Additional Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  "Additional Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              _buildExtraInputs(),
              _buildTagsRemarks(),
              _buildImagePickerFields(),
              _buildExtraTextInputs(),

              // Submit Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: screenWidth,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFinalRepairOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        SizedBox(width: 16),
                        Text("Submitting...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                        : const Text(
                      "Submit Repair Order",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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