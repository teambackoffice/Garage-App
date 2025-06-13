import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_app/service_parts_adding/service_parts_adding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bottom_nav.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'part_service.dart';
import 'service_page.dart';

class CreateRepair extends StatefulWidget {
  final Map<String, dynamic> appointmentData;

  const CreateRepair({super.key, required this.appointmentData});

  @override
  State<CreateRepair> createState() => _CreateRepairOrderState();
}

class _CreateRepairOrderState extends State<CreateRepair> {
  // Controllers for form fields
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
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();

  final Map<String, TextEditingController> _controllers = {};
  bool notifyCustomer = false;
  bool isInspectionNeeded = false;
  List<File> _customerRemarksImages = []; // Support for multiple images (max 3)
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


  @override
  void initState() {
    super.initState();
    _loadSessionId();
    _fetchtags();
    _fetchMakes();
    _controllers['odometer'] = TextEditingController();
    _populateFromAppointmentData();
    print("Appointment data received: ${widget.appointmentData}");
  }

  void _populateFromAppointmentData() {
    try {
      final requiredKeys = [
        'customer_name',
        'phone',
        'email_id',
        'make',
        'model',
        'registration_number',
        'engine_number',
        'chasis_number',
        'date',
        'address_line1',
        'city',
      ];
      final missingKeys = requiredKeys.where((key) => !widget.appointmentData.containsKey(key) || widget.appointmentData[key] == null).toList();
      if (missingKeys.isNotEmpty) {
        print("Missing keys in appointmentData: $missingKeys");
        _showSnackBar("⚠️ Some appointment data is missing: ${missingKeys.join(', ')}");
      }

      // Customer details
      _customerNameController.text = widget.appointmentData['customer_name']?.toString() ?? '';
      _mobileController.text = widget.appointmentData['phone']?.toString() ?? '';
      _emailController.text = widget.appointmentData['email_id']?.toString() ?? '';

      // Address details
      String address = '';
      if (widget.appointmentData['address_line1'] != null) {
        address += widget.appointmentData['address_line1'].toString();
      }
      if (widget.appointmentData['address_line2'] != null && widget.appointmentData['address_line2'].toString().isNotEmpty) {
        address += address.isNotEmpty ? ', ${widget.appointmentData['address_line2']}' : widget.appointmentData['address_line2'].toString();
      }
      _addressController.text = address;
      _cityController.text = widget.appointmentData['city']?.toString() ?? '';
      _stateController.text = widget.appointmentData['state']?.toString() ?? '';
      _pincodeController.text = widget.appointmentData['pincode']?.toString() ?? '';
      _countryController.text = widget.appointmentData['country']?.toString() ?? '';

      // Vehicle details
      _makeController.text = widget.appointmentData['make']?.toString() ?? '';
      if (_makeController.text.isNotEmpty) {
        _fetchModels(_makeController.text);
      }
      _modelController.text = widget.appointmentData['model']?.toString() ?? '';
      _registrationNumberController.text = widget.appointmentData['registration_number']?.toString() ?? '';
      _searchController.text = _registrationNumberController.text;
      _engineNumberController.text = widget.appointmentData['engine_number']?.toString() ?? '';
      _chassisNumberController.text = widget.appointmentData['chasis_number']?.toString() ?? '';

      // Appointment date
      if (widget.appointmentData['date'] != null) {
        try {
          final dateStr = widget.appointmentData['date'].toString();
          DateTime date;
          try {
            date = DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (e) {
            date = DateTime.parse(dateStr);
          }
          _expectedDateController.text = DateFormat('yyyy-MM-dd').format(date);
          deliveryTime = date;
        } catch (e) {
          print(' object   $e');
          print("Error parsing appointment date: $e");
          _showSnackBar("⚠️ Invalid date format in appointment data.");
        }
      }

      print("Form populated with appointment data:");
      print("Customer Name: ${_customerNameController.text}");
      print("Mobile: ${_mobileController.text}");
      print("Email: ${_emailController.text}");
      print("Address: ${_addressController.text}");
      print("City: ${_cityController.text}");
      print("State: ${_stateController.text}");
      print("Pincode: ${_pincodeController.text}");
      print("Country: ${_countryController.text}");
      print("Make: ${_makeController.text}");
      print("Model: ${_modelController.text}");
      print("Registration Number: ${_registrationNumberController.text}");
      print("Engine Number: ${_engineNumberController.text}");
      print("Chassis Number: ${_chassisNumberController.text}");
      print("Expected Delivery Date: ${_expectedDateController.text}");
    } catch (e) {
      print("Error populating from appointment data: $e");
      _showSnackBar("⚠️ Error loading appointment data: $e");
    }
  }

  // Method to clear all form fields after successful submission
  void _clearAllFields() {
    setState(() {
      // Clear all text controllers
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
      _stateController.clear();
      _pincodeController.clear();
      _countryController.clear();
      _makeController.clear();
      _modelController.clear();
      _purchaseDateController.clear();
      _engineNumberController.clear();
      _chassisNumberController.clear();
      _registrationNumberController.clear();

      // Clear dynamic controllers
      _controllers.forEach((key, controller) {
        controller.clear();
      });

      // Reset all state variables
      notifyCustomer = false;
      _customerRemarksImages.clear();
      partsItems.clear();
      partsTotal = 0.0;
      partsSubtotal = 0.0;
      tax = 0.0;
      deliveryTime = DateTime.now();
      odometerReading = null;
      fuelTankLevel = 0;

      // Clear selected values
      _selectedTag = null;
      insuranceDocument = null;
      registrationCertificate = null;
      serviceItems.clear();

      // Clear makes and models
      _models.clear();

      print("All form fields cleared successfully");
    });
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
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _purchaseDateController.dispose();
    _engineNumberController.dispose();
    _chassisNumberController.dispose();
    _registrationNumberController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  double get serviceTotal =>
      serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get partsTotalAmount =>
      partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get grandTotal => serviceTotal + partsTotalAmount + tax;

  Future<void> _pickRegistrationCertificateImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        registrationCertificate = File(image.path);
      });
    }
  }

  Future<bool> _submitFinalRepairOrder() async {
    if (!mounted) return false;

    setState(() {
      _isSubmitting = true;
    });

    if (!_formKey.currentState!.validate()) {
      _showSnackBar("⚠️ Please fill all required fields.");
      setState(() {
        _isSubmitting = false;
      });
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sid');

    if (sessionId == null || sessionId.isEmpty) {
      _showSnackBar("⚠️ Session expired. Please log in again.");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return false;
    }

    if (serviceItems.isEmpty && partsItems.isEmpty) {
      _showSnackBar("⚠️ Add at least one service or part.");
      setState(() {
        _isSubmitting = false;
      });
      return false;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final expectedDateFormatted = _expectedDateController.text.isNotEmpty
          ? _expectedDateController.text
          : DateFormat('yyyy-MM-dd').format(DateTime.now());

      final formattedServiceItems = serviceItems.map((item) {
        return {
          "item_name": item['item_name'].toString(),
          "qty": item['qty'].toString(),
          "rate": item['rate'] is String
              ? double.tryParse(item['rate']) ?? 0
              : (item['rate'] ?? 0),
        };
      }).toList();


      final formattedPartsItems = partsItems.map((item) {
        return {
          "item_name": item['item_name'].toString(),
          "tax_rate": item['tax_rate'].toString(),
          "qty": item['qty'] is String
              ? int.tryParse(item['qty']) ?? 0
              : (item['qty'] ?? 0),
          "rate": item['rate'] is String
              ? double.tryParse(item['rate']) ?? 0
              : (item['rate'] ?? 0),
        };
      }).toList();
      print(" PARTSSSSSS===== $partsItems");
      print('✅ Formatted PARTSS Items: $formattedPartsItems');

      final fields = {
        "customer_name": _customerNameController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "country": _countryController.text.trim(),
        "make": _makeController.text.trim(),
        "model": _modelController.text.trim(),
        "purchase_date": _purchaseDateController.text.trim(),
        "engine_number": _engineNumberController.text.trim(),
        "chasis_number": _chassisNumberController.text.trim(),
        "registration_number": _registrationNumberController.text.trim(),
        "service_items": jsonEncode(formattedServiceItems),
        "parts_items": jsonEncode(formattedPartsItems),
        "tags": _selectedTag ?? "",
        "remarks": _remarkController.text.trim(),
        "delivery_time": deliveryTime.toIso8601String(),
        "notify_customer": notifyCustomer.toString(),
        "odometer_reading": odometerReading?.toString() ?? "0",
        "expected_date": expectedDateFormatted,
        "customer_remarks": _customerRemarksController.text.trim(),
        "fuel_level": fuelTankLevel.toString(),
      };

      if (widget.appointmentData.containsKey('name')) {
        fields['appointment_id'] = widget.appointmentData['name'].toString();
      }

      final uri = Uri.parse(
        "https://garage.tbo365.cloud/api/method/garage.garage.auth.create_new_repairorder",
      );

      final request = http.MultipartRequest("POST", uri)
        ..headers['Cookie'] = 'sid=$sessionId';

      fields.forEach((key, value) {
        if (value != null && value.isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      Future<void> addImage(String field, File? file) async {
        if (file != null && await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(field, file.path));
        }
      }

      print('--- Data before submission ---');
      print('Session ID: $sessionId');
      print('Service Items: ${jsonEncode(formattedServiceItems)}');
      print('Parts Items: ${jsonEncode(formattedPartsItems)}');
      print('Form Fields:');
      fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('Insurance Document: ${insuranceDocument?.path ?? 'None'}');
      print('Registration Certificate: ${registrationCertificate?.path ?? 'None'}');
      for (int i = 0; i < _customerRemarksImages.length && i < 3; i++) {
        print('Customer Remarks Image $i: ${_customerRemarksImages[i].path}');
      }
      print('--- End of Data ---');
      // --- End of Printing ---

      await addImage('insurance', insuranceDocument);
      await addImage('registration_certificate', registrationCertificate);

      for (int i = 0; i < _customerRemarksImages.length && i < 3; i++) {
        await addImage('customer_remarks_image_$i', _customerRemarksImages[i]);
      }

      final streamedResponse = await request.send();

      if (!mounted) return false;
      Navigator.of(context, rootNavigator: true).pop();

      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);
      print('THE RESPONSE IS ====  ${response.body}');

      // ✅ NEW SUCCESS CHECK BASED ON LATEST RESPONSE
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded.containsKey('message') &&
          decoded['message'] is Map &&
          decoded['message']['status'] == 'success') {
        final repairOrder = decoded['message']['repair_order'];
        await prefs.setString('repair_order_id', repairOrder);

        // Save uploaded file paths
        if (insuranceDocument != null) {
          await prefs.setString('insurance_path', insuranceDocument!.path);
        }
        if (registrationCertificate != null) {
          await prefs.setString('rc_path', registrationCertificate!.path);
        }
        for (int i = 0; i < _customerRemarksImages.length && i < 3; i++) {
          await prefs.setString('remarks_image_path_$i', _customerRemarksImages[i].path);
        }

        _showSnackBar("✅ ${decoded['message']['message'] ?? 'Repair Order Created Successfully!'}");

        _clearAllFields();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrdersListPage()),
        );

        return true;
      }

      // ❌ Handle error cases
      String errorMsg = "Unknown error occurred.";
      if (decoded.containsKey('exception')) {
        errorMsg = decoded['exception'].toString();
      } else if (decoded.containsKey('error')) {
        errorMsg = decoded['error'].toString();
      } else if (decoded.containsKey('message')) {
        final msg = decoded['message'];
        if (msg is String) {
          errorMsg = msg;
        } else if (msg is Map && msg.containsKey('error')) {
          errorMsg = msg['error'].toString();
        }
      }

      _showSnackBar("❌ $errorMsg");
      return false;
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("❌ Network error: $e");
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

  Future<void> _pickImage(bool isCustomerRemarks) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (isCustomerRemarks) {
          // Limit to maximum 3 customer remarks images
          if (_customerRemarksImages.length < 3) {
            _customerRemarksImages.add(File(image.path));
            _showSnackBar("Customer remarks image added (${_customerRemarksImages.length}/3).");
          } else {
            _showSnackBar("Maximum 3 customer remarks images allowed.");
          }
        } else {
          insuranceDocument = File(image.path);
          _showSnackBar("Uploading insurance document...");
        }
      });
    }
  }

  Future<void> _addService() async {
    try {
      final selected = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ServicePage()));

      if (selected != null && selected is List) {
        setState(() {
          serviceItems = List<Map<String, dynamic>>.from(selected);
          print("Selected services: $serviceItems");
        });
      }
    } catch (e) {
      print("Error selecting services: $e");
      _showSnackBar("❌ Error selecting services: ${e.toString()}");
    }
  }

  Future<void> _addPart() async {
    try {
      final result = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ServiceAndParts()));

      if (result != null) {
        if (result is List) {
          setState(() {
            partsItems = List<Map<String, dynamic>>.from(result);
            partsSubtotal = partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));
            print("Selected parts: $partsItems");
            print("Parts subtotal: $partsSubtotal");
          });
        } else if (result is Map<String, dynamic>) {
          setState(() {
            partsItems = List<Map<String, dynamic>>.from(result['items'] ?? []);
            partsSubtotal = result['subtotal'] ?? 0.0;
            tax = result['tax'] ?? 0.0;
            partsTotal = result['total'] ?? 0.0;
            print("Selected parts: $partsItems");
            print("Parts subtotal: $partsSubtotal");
            print("Tax: $tax");
            print("Parts total: $partsTotal");
          });
        }
      }
    } catch (e) {
      print("Error selecting parts: $e");
      _showSnackBar("❌ Error selecting parts: ${e.toString()}");
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

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched Data: $data');

        if (data['message'] != null && data['message']['data'] != null) {
          var tagsData = data['message']['data'];
          print('Tags Data: $tagsData');

          if (tagsData is List) {
            setState(() {
              _tags = tagsData.map((tag) => tag['name'] as String).toList();
            });
          } else {
            _showError("Unexpected response format. 'data' is not a list.");
          }
        } else {
          _showError("Invalid response structure. 'message' or 'data' key missing.");
        }
      } else {
        if (response.body.contains('session_expired')) {
          _showError("Session expired. Please log in again.");
        } else {
          _showError("Failed to fetch tags: ${response.statusCode}");
        }
      }
    } catch (e) {
      print('Error: $e');
      _showError("Failed to fetch tags. Please check your connection.");
    }
  }

  Future<void> _addTag(String tagName) async {
    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.create_tags';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sid');

    if (sessionId == null) {
      _showError("Session expired. Please log in again.");
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
        print('Decoded Response: $decodedResponse');

        if (decodedResponse.containsKey('message') && decodedResponse['message'] == 'Success') {
          _showSnackBar("Tag '$tagName' created successfully!");
          _fetchtags();
        } else {
          String errorMessage = decodedResponse['message'] ?? 'Unknown error';
          print("API Error: $errorMessage");
          _showError("Failed to create tag: $errorMessage");
        }
      } else {
        print("Failed to create tag. Status code: ${response.statusCode}");
        _showError("Failed to create tag. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');
      _showError("Failed to create tag. Please try again.");
    }
  }

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
    final url =
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(make)}';
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.black87));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _fetchVehicleDetails(String registrationNumber) async {
    if (registrationNumber.trim().isEmpty) {
      _showError("Please enter a registration number.");
      return;
    }

    final url =
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.vregnum_search?vehicle_num=${Uri.encodeComponent(registrationNumber)}';

    setState(() {
      _isSubmitting = true;
    });

    try {
      print("Fetching vehicle details for: $registrationNumber");
      print("Using session ID: $_sessionId");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'sid=$_sessionId',
          'Content-Type': 'application/json',
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

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
          _customerNameController.text = customer['customer_name']?.toString() ?? '';
        }

        if (address != null) {
          _mobileController.text = address['phone']?.toString() ?? '';
          _emailController.text = address['email_id']?.toString() ?? '';
          String addressText = '';
          if (address['address_line1'] != null) {
            addressText += address['address_line1'].toString();
          }
          if (address['address_line2'] != null && address['address_line2'].toString().isNotEmpty) {
            addressText += addressText.isEmpty ? address['address_line2'].toString() : ', ${address['address_line2']}';
          }
          _addressController.text = addressText;
          _cityController.text = address['city']?.toString() ?? '';
          _stateController.text = address['state']?.toString() ?? '';
          _pincodeController.text = address['pincode']?.toString() ?? '';
          _countryController.text = address['country']?.toString() ?? '';
        }

        if (vehicle != null) {
          _makeController.text = vehicle['make']?.toString() ?? '';
          _modelController.text = vehicle['model']?.toString() ?? '';
          _engineNumberController.text = vehicle['engine_number']?.toString() ?? '';
          _chassisNumberController.text = vehicle['chasis_number']?.toString() ?? '';
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
      print("Vehicle fetch error: $e");
      _showError("❌ Error fetching vehicle details: ${e.toString()}");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

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
      case "state":
        controller = _stateController;
        break;
      case "pincode":
        controller = _pincodeController;
        break;
      case "country":
        controller = _countryController;
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
        keyboardType: key == 'mobile' || key == 'pincode' ? TextInputType.number : inputType,
        inputFormatters: key == 'mobile'
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
            : key == 'pincode'
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (key == 'mobile' && v.length != 10) return 'Enter 10-digit mobile number';
          if (key == 'pincode' && v.length != 6) return 'Enter 6-digit pincode';
          if (key == 'email' && v.isNotEmpty) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}');
            if (!emailRegex.hasMatch(v)) return 'Enter valid email';
          }
          return null;
        },
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
        readOnly: true, // Prevents manual text input
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
          DateTime now = DateTime.now();
          DateTime tenYearsAgo = DateTime(now.year - 10, now.month, now.day); // Restrict to 10 years ago
          DateTime today = DateTime(now.year, now.month, now.day); // Restrict to today

          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _purchaseDateController.text.isNotEmpty
                ? DateFormat('yyyy-MM-dd').parse(_purchaseDateController.text)
                : today, // Default to today if no date is set
            firstDate: tenYearsAgo, // Earliest allowed date
            lastDate: today, // Latest allowed date
          );

          if (picked != null) {
            setState(() {
              _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(picked);
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }

          try {
            DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(value);
            DateTime now = DateTime.now();
            DateTime tenYearsAgo = DateTime(now.year - 10, now.month, now.day);
            DateTime today = DateTime(now.year, now.month, now.day);

            if (selectedDate.isBefore(tenYearsAgo)) {
              return 'Date cannot be more than 10 years in the past';
            }
            if (selectedDate.isAfter(today)) {
              return 'Date cannot be in the future';
            }
          } catch (e) {
            return 'Invalid date format';
          }

          return null;
        },
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
            _priceRow("Service Total", serviceTotal),
            _priceRow("Parts Total", partsTotalAmount),
            _priceRow("Tax", tax),
            const Divider(),
            _priceRow("TOTAL", grandTotal, bold: true),
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
                        // Show the image instead of file icon and name
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.file(
                            document,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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
          Row(
            children: [
              Text("Customer Remarks Images (${_customerRemarksImages.length}/3)"),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Add Image"),
                onPressed: _customerRemarksImages.length < 3 ? () => _pickImage(true) : null,
              ),
            ],
          ),
          if (_customerRemarksImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _customerRemarksImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  File image = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() {
                            _customerRemarksImages.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

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
                  label: "${fuelTankLevel.toStringAsFixed(0)}",
                  onChanged: (double value) {
                    setState(() {
                      fuelTankLevel = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
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

  Widget _buildItemList(String title, List<Map<String, dynamic>> items, void Function(int) onDelete) {
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
                print('Rendering item at index $index: $item');

                return ListTile(
                  title: Text(item['item_name'] ?? 'Unknown Item'),
                  subtitle: Text('Qty: ${item['qty']} x ₹${item['rate']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('₹${((item['qty'] ?? 0) * (item['rate'] ?? 0)).toStringAsFixed(2)}'),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          onDelete(index); // Call the parent deletion function
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
              _buildTextField("pincode", "Pincode", inputType: TextInputType.number, icon: Icons.pin_drop),
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
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              //   child: Text(
              //     "Services and Parts",
              //     style: TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.blue.shade800,
              //     ),
              //   ),
              // ),
    //           _buildSection("SERVICES", _addService),
    //           if (serviceItems.isNotEmpty)
    //             _buildItemList(
    //   "SERVICES",
    //   serviceItems,
    //       (index) {
    //     setState(() {
    //       serviceItems.removeAt(index);
    //     });
    //   },
    // ),

    //           _buildSection("PARTS", _addPart),
    //           if (partsItems.isNotEmpty) _buildItemList(
    // "PARTS",
    // partsItems,
    // (index) {
    // setState(() {
    // partsItems.removeAt(index);
    // });
    // },
    // ),
    //
    //           // _buildSummary(),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              //   child: Text(
              //     "Additional Details",
              //     style: TextStyle(
              //       fontSize: 18,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.blue.shade800,
              //     ),
              //   ),
              // ),
              // _buildExtraInputs(),
              // _buildTagsRemarks(),
              // _buildImagePickerFields(),
              // _buildExtraTextInputs(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isInspectionNeeded = !isInspectionNeeded;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: isInspectionNeeded,
                        onChanged: (bool? value) {
                          setState(() {
                            isInspectionNeeded = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Inspection Needed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // 🔥 Bold text here
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                    width: screenWidth,
                    height: 50,
                    child: ElevatedButton(style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),

                        onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ServicePartAdding(
                              customername: _customerNameController.text,
                              mobile: _mobileController.text,
                              email: _emailController.text,
                              address: _addressController.text,
                              city: _cityController.text,
                              make: _makeController.text,
                              model: _modelController.text,
                              purchaseDate: _purchaseDateController.text,
                              engineNumber: _engineNumberController.text,
                              chasisNumber: _chassisNumberController.text,
                              registrationNumber: _registrationNumberController.text,
                              notifyCustomer: notifyCustomer,
                              deliveryTime: deliveryTime,
                            )),
                          );

                        }, child: Text('Continue'))
            //   Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: SizedBox(
            //       width: screenWidth * 0.9,
            //       height: 50,
            //       child: ElevatedButton(
            //         onPressed: _isSubmitting ? null : _submitFinalRepairOrder,
            //         style: ElevatedButton.styleFrom(
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //           backgroundColor: Colors.green,
            //         ),
            //         child: _isSubmitting
            //             ? const CircularProgressIndicator(color: Colors.white)
            //             : const Text(
            //           "Submit Repair Order",
            //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ),
        ),
      ]),
    )));
  }
}