import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _chassisNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  // Dropdown values
  List<String> _makes = [];
  List<String> _models = [];
  String? _selectedMake;
  String? _selectedModel;
  bool _isSubmitting = false;
  DateTime? _purchaseDate;
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _sendWhatsApp = true;
  String? _sessionId;
  bool _isFetchingMakes = false;
  bool _isFetchingModels = false;

  @override
  void initState() {
    super.initState();
    _loadSessionId();
    _fetchMakes();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _appointmentTimeController.dispose();
    _engineNumberController.dispose();
    _chasisNumberController.dispose();
    _registrationController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _mobileController.dispose();
    _chassisNumberController.dispose();
    _registrationNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // Load session ID
  Future<void> _loadSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('sid');
      if (_sessionId == null || _sessionId!.isEmpty) {
        _showError("Session not found. Please login again.");
      }
    } catch (e) {
      _showError("Error loading session: $e");
    }
  }

  // Clear all form fields
  void _clearAllFields() {
    setState(() {
      // Clear text controllers
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
      _searchController.clear();
      _customerNameController.clear();
      _mobileController.clear();
      _chassisNumberController.clear();
      _registrationNumberController.clear();
      _makeController.clear();
      _modelController.clear();

      // Reset dropdown values
      _selectedMake = null;
      _selectedModel = null;

      // Reset date/time values
      _purchaseDate = null;
      _appointmentDate = null;
      _appointmentTime = null;

      // Reset other values
      _errorMessage = null;
      _sendWhatsApp = true;

      // Clear models list
      _models.clear();
    });
  }

  // Enhanced refresh method
  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      // Clear all form fields first
      _clearAllFields();

      // Reload session ID
      await _loadSessionId();

      // Fetch fresh data from APIs
      await _fetchMakes();

      if (mounted) {
        _showSuccessMessage("🔄 Form refreshed successfully! Ready for new appointment.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to refresh data: $e";
        });
        _showError("❌ Error refreshing data: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // WhatsApp functionality
  Future<void> openWhatsApp(String phone, String message) async {
    final phoneNumber = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeFull(message)}");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessMessage("📱 Redirecting to WhatsApp...");
      } else {
        _showError("❌ Could not open WhatsApp");
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
      _showError("❌ Error: Could not open WhatsApp. $e");
    }
  }

  // Fetch makes from API - FIXED VERSION
  Future<void> _fetchMakes() async {
    if (!mounted) return;

    setState(() {
      _isFetchingMakes = true;
      _errorMessage = null;
    });

    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_makes';

    try {
      print("🔄 Fetching makes from: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null && _sessionId!.isNotEmpty) 'Cookie': 'sid=$_sessionId',
        },
      );

      print("📡 Makes API Response Status: ${response.statusCode}");
      print("📡 Makes API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response structures
        List<String> makes = [];

        if (data['message'] != null) {
          // Check if it's directly a list
          if (data['message'] is List) {
            final makesList = data['message'] as List;
            makes = makesList.map((m) => m.toString()).toList();
          }
          // Check if it has 'makes' key
          else if (data['message'] is Map && data['message']['makes'] != null) {
            final makesList = data['message']['makes'] as List;
            makes = makesList.map((m) {
              if (m is Map && m['name'] != null) {
                return m['name'].toString();
              } else if (m is String) {
                return m;
              } else {
                return m.toString();
              }
            }).toList();
          }
          // Check if message itself contains make data
          else if (data['message'] is Map) {
            // Try to extract makes from various possible structures
            final messageMap = data['message'] as Map;
            for (var key in ['data', 'result', 'makes', 'make_list']) {
              if (messageMap[key] is List) {
                final makesList = messageMap[key] as List;
                makes = makesList.map((m) {
                  if (m is Map && m['name'] != null) {
                    return m['name'].toString();
                  } else if (m is String) {
                    return m;
                  } else {
                    return m.toString();
                  }
                }).toList();
                break;
              }
            }
          }
        }
        // Direct data array
        else if (data is List) {
          makes = data.map((m) => m.toString()).toList();
        }

        if (makes.isNotEmpty) {
          setState(() {
            _makes = makes;
          });
          print("✅ Successfully fetched ${_makes.length} makes: ${_makes.take(5)}");
        } else {
          throw Exception("No makes found in response");
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ Error fetching makes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to fetch vehicle makes: $e";
        });
        _showError("Failed to fetch vehicle makes. Please try refreshing.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMakes = false;
        });
      }
    }
  }

  // Fetch models based on selected make - FIXED VERSION
  Future<void> _fetchModels(String make) async {
    if (!mounted || make.isEmpty) return;

    setState(() {
      _isFetchingModels = true;
      _models.clear();
      _selectedModel = null;
    });

    final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(make)}';

    try {
      print("🔄 Fetching models for make: $make");
      print("🔄 Models API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null && _sessionId!.isNotEmpty) 'Cookie': 'sid=$_sessionId',
        },
      );

      print("📡 Models API Response Status: ${response.statusCode}");
      print("📡 Models API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<String> models = [];

        if (data['message'] != null) {
          // Check if it's directly a list
          if (data['message'] is List) {
            final modelsList = data['message'] as List;
            models = modelsList.map((m) => m.toString()).toList();
          }
          // Check if it has 'models' key
          else if (data['message'] is Map && data['message']['models'] != null) {
            final modelsList = data['message']['models'] as List;
            models = modelsList.map((m) {
              if (m is Map && m['model'] != null) {
                return m['model'].toString();
              } else if (m is Map && m['name'] != null) {
                return m['name'].toString();
              } else if (m is String) {
                return m;
              } else {
                return m.toString();
              }
            }).toList();
          }
          // Check other possible structures
          else if (data['message'] is Map) {
            final messageMap = data['message'] as Map;
            for (var key in ['data', 'result', 'models', 'model_list']) {
              if (messageMap[key] is List) {
                final modelsList = messageMap[key] as List;
                models = modelsList.map((m) {
                  if (m is Map && m['model'] != null) {
                    return m['model'].toString();
                  } else if (m is Map && m['name'] != null) {
                    return m['name'].toString();
                  } else if (m is String) {
                    return m;
                  } else {
                    return m.toString();
                  }
                }).toList();
                break;
              }
            }
          }
        }

        if (models.isNotEmpty) {
          setState(() {
            _models = models;
          });
          print("✅ Successfully fetched ${_models.length} models for $make: ${_models.take(5)}");
        } else {
          print("⚠️ No models found for make: $make");
          if (mounted) {
            _showError("No models found for selected make: $make");
          }
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ Error fetching models for $make: $e');
      if (mounted) {
        _showError("Failed to fetch models for $make. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingModels = false;
        });
      }
    }
  }

  // Fetch vehicle details by registration number - IMPROVED VERSION
  Future<void> _fetchVehicleDetails(String registrationNumber) async {
    if (registrationNumber.trim().isEmpty) {
      _showError("Please enter a registration number.");
      return;
    }

    final url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.vregnum_search?vehicle_num=${Uri.encodeComponent(registrationNumber)}';

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      print("🔍 Fetching vehicle details for: $registrationNumber");
      print("🔍 Vehicle API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': 'sid=${_sessionId ?? ''}',
          'Content-Type': 'application/json',
        },
      );

      print("📡 Vehicle API Response status: ${response.statusCode}");
      print("📡 Vehicle API Response body: ${response.body}");

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

        // Populate customer details
        if (customer != null) {
          _nameController.text = customer['customer_name']?.toString() ?? '';
        }

        // Populate address details
        if (address != null) {
          _phoneController.text = address['phone']?.toString() ?? '';
          _emailController.text = address['email_id']?.toString() ?? '';

          String addressText = '';
          if (address['address_line1'] != null && address['address_line1'].toString().isNotEmpty) {
            addressText = address['address_line1'].toString();
          }
          if (address['address_line2'] != null && address['address_line2'].toString().isNotEmpty) {
            addressText += addressText.isEmpty ? address['address_line2'].toString() : ', ${address['address_line2']}';
          }
          _addressController.text = addressText;
          _cityController.text = address['city']?.toString() ?? '';
          _pincodeController.text = address['pincode']?.toString() ?? '';
        }

        // Populate vehicle details and handle make/model dropdown
        if (vehicle != null) {
          final make = vehicle['make']?.toString() ?? '';
          final model = vehicle['model']?.toString() ?? '';

          _makeController.text = make;
          _modelController.text = model;
          _engineNumberController.text = vehicle['engine_number']?.toString() ?? '';
          _chasisNumberController.text = vehicle['chasis_number']?.toString() ?? '';
          _registrationController.text = registrationNumber;

          // Handle make selection
          if (make.isNotEmpty) {
            // Check if make exists in current list
            String? matchingMake = _makes.firstWhere(
                  (m) => m.toLowerCase() == make.toLowerCase(),
              orElse: () => '',
            );

            if (matchingMake.isEmpty) {
              // If make not found, add it to the list
              setState(() {
                _makes.add(make);
                _selectedMake = make;
              });
            } else {
              setState(() {
                _selectedMake = matchingMake;
              });
            }

            // Fetch and set model
            try {
              await _fetchModels(_selectedMake!);

              if (model.isNotEmpty && _models.isNotEmpty) {
                String? matchingModel = _models.firstWhere(
                      (m) => m.toLowerCase() == model.toLowerCase(),
                  orElse: () => '',
                );

                if (matchingModel.isEmpty) {
                  // If model not found, add it to the list
                  setState(() {
                    _models.add(model);
                    _selectedModel = model;
                  });
                } else {
                  setState(() {
                    _selectedModel = matchingModel;
                  });
                }
              }
            } catch (e) {
              print("Error fetching models during vehicle search: $e");
              // Fallback: add model directly if fetch fails
              if (model.isNotEmpty) {
                setState(() {
                  _models = [model];
                  _selectedModel = model;
                });
              }
            }
          }
        }

        _showSuccessMessage("✅ Vehicle details loaded successfully!");
      } else {
        _showError("❌ No data found for registration number: $registrationNumber");
      }
    } catch (e) {
      print("❌ Vehicle fetch error: $e");
      _showError("❌ Error fetching vehicle details: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Date picker
  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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

  // Time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _appointmentTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _appointmentTime = picked;
        _appointmentTimeController.text = _formatTimeOfDay(picked);
      });
    }
  }

  // Format time
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('HH:mm').format(dateTime);
  }

  // Format date
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Submit appointment
  Future<void> _submitAppointment() async {
    // Validation
    if (_selectedMake == null || _selectedModel == null) {
      setState(() => _errorMessage = "Please select Make and Model!");
      return;
    }

    if (_appointmentDate == null) {
      setState(() => _errorMessage = "Please select Appointment date!");
      return;
    }

    if (_appointmentTime == null) {
      setState(() => _errorMessage = "Please select Appointment time!");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    const url = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.create_customer_vehicle_details';

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
        _showSuccessMessage('🎉 Appointment successfully booked!');

        if (_sendWhatsApp) {
          final customerName = _nameController.text.trim();
          final registration = _registrationController.text.trim();
          final appointmentDate = _formatDate(_appointmentDate);
          final appointmentTime = _appointmentTimeController.text.trim();

          final message = "Hello $customerName, your appointment for vehicle $registration has been confirmed for $appointmentDate at $appointmentTime. Thank you for choosing our service. - GarageHub";

          openWhatsApp(_phoneController.text.trim(), message);
        }

        // Clear form after successful submission
        _clearForm();
      } else {
        setState(() => _errorMessage = 'Failed to book appointment: ${data['message']}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network Error: $e');
    }

    setState(() => _isLoading = false);
  }

  // Clear form after submission
  void _clearForm() {
    _clearAllFields();
    _showSuccessMessage("✅ Form cleared! Ready for next appointment.");
  }

  // Show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show error message
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Build form field widget
  Widget _buildFormField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLength: label == 'Phone' ? 10 : (label == 'Pincode' ? 6 : null),
        // inputFormatters: label == 'Phone' || label == 'Pincode'
        //     ? [FilteringTextInputFormatter.digitsOnly]
        //     : [],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          if (label == 'Phone' && !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
            return 'Enter valid 10 digit phone';
          }
          if (label == 'Pincode' && !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
            return 'Enter valid 6 digit pincode';
          }
          if (label == 'Email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) {
            return 'Enter valid email';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
                : const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh Form',
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BottomNavBarScreen()),
              );
            },
            tooltip: 'Home',
          ),
        ],
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: h * 0.01),

                  // Vehicle search section
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text("Search"),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.03),

                  // Make dropdown with loading indicator
                  DropdownButtonFormField<String>(
                    value: _selectedMake,
                    hint: _isFetchingMakes
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Loading makes..."),
                      ],
                    )
                        : const Text("Tap to select"),
                    items: _makes.map((make) => DropdownMenuItem(value: make, child: Text(make))).toList(),
                    onChanged: _isFetchingMakes ? null : (value) {
                      setState(() {
                        _selectedMake = value;
                        _selectedModel = null; // Reset model when make changes
                        _models.clear();
                      });
                      if (value != null) {
                        _fetchModels(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Make',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Please select Make' : null,
                  ),

                  const SizedBox(height: 10),

                  // Model dropdown with loading indicator
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    hint: _isFetchingModels
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Loading models..."),
                      ],
                    )
                        : _selectedMake == null
                        ? const Text("Select make first")
                        : const Text("Tap to select"),
                    items: _models.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                    onChanged: (_isFetchingModels || _selectedMake == null) ? null : (value) {
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

                  // Customer details
                  _buildFormField('Customer Name', _nameController, icon: Icons.person),
                  _buildFormField('Phone', _phoneController, inputType: TextInputType.phone, icon: Icons.phone),
                  _buildFormField('Email', _emailController, inputType: TextInputType.emailAddress, icon: Icons.email),
                  _buildFormField('Address', _addressController, icon: Icons.location_on),
                  _buildFormField('City', _cityController, icon: Icons.location_city),
                  _buildFormField('Pincode', _pincodeController, inputType: TextInputType.number, icon: Icons.pin),

                  // Appointment date picker
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: ListTile(
                      title: Text(
                        _appointmentDate == null
                            ? 'Select Appointment Date'
                            : 'Date: ${_formatDate(_appointmentDate)}',
                        style: TextStyle(
                          color: _appointmentDate == null ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.green),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),

                  // Appointment time picker
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: ListTile(
                      title: Text(
                        _appointmentTime == null
                            ? 'Select Appointment Time'
                            : 'Time: ${_formatTimeOfDay(_appointmentTime!)}',
                        style: TextStyle(
                          color: _appointmentTime == null ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time, color: Colors.green),
                      onTap: () => _selectTime(context),
                    ),
                  ),

                  // Hidden field for appointment time
                  Visibility(
                    visible: false,
                    child: TextFormField(
                      controller: _appointmentTimeController,
                    ),
                  ),

                  // Vehicle details
                  _buildFormField('Engine Number', _engineNumberController, icon: Icons.engineering),
                  _buildFormField('Chasis Number', _chasisNumberController, icon: Icons.directions_car),
                  _buildFormField('Registration', _registrationController, icon: Icons.assignment),

                  // WhatsApp option
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SwitchListTile(
                      title: const Text('Send WhatsApp confirmation'),
                      subtitle: const Text('Customer will receive a confirmation message'),
                      value: _sendWhatsApp,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _sendWhatsApp = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Error message display
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Submit button section
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _isLoading
                            ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                            : ElevatedButton(
                          onPressed: _submitAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Submit Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.05),

                  // Debug info section (remove in production)
                  if (_makes.isNotEmpty || _models.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}