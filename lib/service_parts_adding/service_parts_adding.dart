import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bottom_nav.dart';
import '../login_page.dart';
import '../orders_page.dart';
import '../part_service.dart';
import '../service_page.dart';

class ServicePartAdding extends StatefulWidget {
  final String customername;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String make;
  final String model;
  final String purchaseDate;
  final String engineNumber;
  final String chasisNumber;
  final String registrationNumber;
  final bool notifyCustomer;
  final DateTime deliveryTime;

  const ServicePartAdding({super.key,required this.customername, required this.mobile, required this.email, required this.address, required this.city, required this.make, required this.model, required this.purchaseDate, required this.engineNumber, required this.chasisNumber, required this.registrationNumber, required this.notifyCustomer, required this.deliveryTime,
  });

  @override
  State<ServicePartAdding> createState() => _ServicePartAddingState();
}

class _ServicePartAddingState extends State<ServicePartAdding> {
  List<Map<String, dynamic>> serviceItems = [];
  List<Map<String, dynamic>> partsItems = [];
  double partsTotal = 0.0;
  double partsSubtotal = 0.0;
  double tax = 0.0;
  bool isTyping = false;
  DateTime deliveryTime = DateTime.now();
  int? odometerReading;
  double fuelTankLevel = 0;
  double h = 0;
  List<String> _tags = [];
  String? _selectedTag;
  File? customerRemarksImage;
  File? insuranceDocument;
 bool _isSubmitting=false;
  File? registrationCertificate;
  final TextEditingController _expectedDateController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _customerRemarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  String? _sessionId;



  // final _formKey = GlobalKey<FormState>();
  // bool _isSubmitting = false;
  // String? _sessionId;
  // bool _uploadingInsurance = false;

  List<String> _makes = [];
  // List<String> _models = [];
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
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     // Clear form data only when user chooses to create another order
            //     _clearAllFormData();
            //     _showSnackBar("✅ Form has been cleared for new order");
            //   },
            //   child: const Text("Create Another Order"),
            // ),
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
        builder: (_) =>
        const AlertDialog(
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
        "customer_name": widget.customername.trim(),
        "mobile": widget.mobile.trim(),
        "email": widget.email.trim(),
        "address": widget.address.trim(),
        "city": widget.city.trim(),
        "make": widget.make.trim(),
        "model": widget.model.trim(),
        "purchase_date": widget.purchaseDate.trim(),
        "engine_number": widget.engineNumber.trim(),
        "chasis_number": widget.chasisNumber.trim(),
        "registration_number": widget.registrationNumber.trim(),
        "tags": _selectedTag ?? "",
        "remarks": _remarkController.text.trim(),
        "delivery_time": deliveryTime.toIso8601String(),
        "notify_customer": widget.notifyCustomer.toString(),
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
        request.files.add(await http.MultipartFile.fromPath(
            'insurance', insuranceDocument!.path));
        print('insurance ${insuranceDocument}');

      }
      if (registrationCertificate != null &&
          await registrationCertificate!.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
            'registration_certificate', registrationCertificate!.path));
      }
      if (customerRemarksImage != null &&
          await customerRemarksImage!.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
            'image', customerRemarksImage!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        Navigator
            .of(context, rootNavigator: true)
            .pop(); // Close loading dialog
      }

      if (!mounted) return false;

      final decoded = jsonDecode(response.body);
      final message = decoded['message'];

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("===== response FOR POPST ==== ${streamedResponse}");
        print("===== response FOR POPST Boddyy ==== ${response.body}");

        // Handle successful response
        if (message != null) {
          // Check if message is a Map (contains repair_order_id)
          if (message is Map<String, dynamic> &&
              message.containsKey('repair_order_id')) {
            // Save repair order ID
            await prefs.setString(
                'repair_order_id', message['repair_order_id']);

            // Save file paths if they exist
            if (insuranceDocument != null) {
              await prefs.setString('insurance_path', insuranceDocument!.path);
            }
            if (registrationCertificate != null) {
              await prefs.setString('rc_path', registrationCertificate!.path);
            }
            if (customerRemarksImage != null) {
              await prefs.setString(
                  'remarks_image_path', customerRemarksImage!.path);
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
          print("=== THE ERRORR ISS === $e");
          errorMsg = "❌ Error processing response. Please try again.";
        }

        _showSnackBar(errorMsg);
        return false;
      }
    } catch (e) {
      print("=== THE ERRORR ISS === $e");
      if (mounted) {
        Navigator
            .of(context, rootNavigator: true)
            .pop(); // Close loading dialog
        _showSnackBar("❌ Network error: ${e.toString()}");
      }
      return false;
    } finally {
      print("rrrrrr");
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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

  List<File> customerRemarksImages = [];

  Future<void> _pickRegistrationCertificateImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        registrationCertificate = File(image.path);
      });
    }
  }
  double get serviceTotal =>
      serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get partsTotalAmount =>
      partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));

  double get grandTotal => serviceTotal + partsTotalAmount + tax;


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
            // TextButton(
            //   child: const Text("Refresh"),
            //   onPressed: () {
            //     Navigator.of(context).pop();
            //     _clearAllFormData();
            //     _showSnackBar("✅ Form has been refreshed");
            //   },
            // ),
          ],
        );
      },
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


  @override
  void initState() {
    print(' initstate');
    super.initState();
    _loadSessionId();
    _fetchtags();
    _fetchMakes();
    _controllers['odometer'] = TextEditingController();
  }
  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Services and Parts",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              _buildSection("SERVICES", _addService),
              if (serviceItems.isNotEmpty)
                _buildItemList("SERVICES", serviceItems),
          
              _buildSection("PARTS", _addPart),
              if (partsItems.isNotEmpty)
                _buildItemList("PARTS", partsItems),
          
              SizedBox(height: 20),
          
              _buildSummary(),
          
              SizedBox(height: 20),
          
              // Additional Details Section
              Text(
                "Additional Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
          
              SizedBox(height: 10),
          
              _buildExtraInputs(),
              _buildTagsRemarks(),
              _buildImagePickerFields(),
              _buildExtraTextInputs(),
          
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFinalRepairOrder,
                  style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 110),
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
            ],
          ),
        ),
      ),


    );
  }
}
