import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

import 'main.dart';

double w = 0; // width reference

class Inspection extends StatefulWidget {
  const Inspection({super.key});

  @override
  State<Inspection> createState() => _InspectionState();
}

class _InspectionState extends State<Inspection> {
  final List<String> inspections = [
    'Battery Inspection',
    'Engine Inspection',
    'Tire Inspection',
    'Brake Inspection',
  ];

  // Store multiple images per item
  final List<List<File>> _images = List.generate(4, (index) => <File>[]);

  // Store status for each inspection (0 = none, 1 = green, 2 = yellow, 3 = red)
  final List<int> _inspectionStatus = List<int>.filled(4, 0);

  // Store parts and service data for each inspection
  final List<TextEditingController> _partsControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _serviceControllers = List.generate(4, (index) => TextEditingController());

  // Store customer remarks for each inspection
  final List<TextEditingController> _customerRemarksControllers = List.generate(4, (index) => TextEditingController());

  // Store voice messages for each inspection
  final List<List<VoiceMessage>> _voiceMessages = List.generate(4, (index) => <VoiceMessage>[]);

  // Voice recording states
  final List<bool> _isRecording = List<bool>.filled(4, false);
  final List<Timer?> _recordingTimers = List<Timer?>.filled(4, null);
  final List<int> _recordingDurations = List<int>.filled(4, 0);

  // Global services and parts lists
  final List<ServiceItem> _globalServices = [];
  final List<PartItem> _globalParts = [];
  final List<TecDocItem> _tecDocItems = [];

  // Add these new variables for parts and service items
  List<Map<String, dynamic>> serviceItems = [];
  List<Map<String, dynamic>> partsItems = [];

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Voice recording functions
  void _startRecording(int index) {
    setState(() {
      _isRecording[index] = true;
      _recordingDurations[index] = 0;
    });

    _recordingTimers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDurations[index]++;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording voice message for ${inspections[index]}...'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _stopRecording(int index) {
    _recordingTimers[index]?.cancel();
    _recordingTimers[index] = null;

    final duration = _recordingDurations[index];

    setState(() {
      _isRecording[index] = false;
      _recordingDurations[index] = 0;

      // Add the voice message to the list
      _voiceMessages[index].add(VoiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        duration: duration,
        timestamp: DateTime.now(),
        filePath: 'voice_${index}_${DateTime.now().millisecondsSinceEpoch}.m4a', // Simulated file path
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice message saved (${duration}s) for ${inspections[index]}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleRecording(int index) {
    if (_isRecording[index]) {
      _stopRecording(index);
    } else {
      _startRecording(index);
    }
  }

  void _playVoiceMessage(VoiceMessage voiceMessage, int inspectionIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing voice message (${voiceMessage.duration}s) for ${inspections[inspectionIndex]}'),
        backgroundColor: Colors.blue,
      ),
    );
    // Here you would implement actual audio playback
  }

  void _deleteVoiceMessage(int inspectionIndex, int messageIndex) {
    setState(() {
      _voiceMessages[inspectionIndex].removeAt(messageIndex);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice message deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Show Customer Remarks Dialog
  void _showCustomerRemarksDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Remarks - ${inspections[index]}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customerRemarksControllers[index],
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter customer remarks or concerns...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.blue[50],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note any specific customer concerns or requests',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer remarks saved for ${inspections[index]}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Show Services Management Dialog
  void _showServicesDialog() {
    TextEditingController serviceNameController = TextEditingController();
    TextEditingController serviceCostController = TextEditingController();
    TextEditingController serviceTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.build, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text('Services Management'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Add new service section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Service',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: serviceNameController,
                            decoration: const InputDecoration(
                              hintText: 'Service name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: serviceCostController,
                                  decoration: const InputDecoration(
                                    hintText: 'Cost',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: serviceTimeController,
                                  decoration: const InputDecoration(
                                    hintText: 'Time (e.g., 1 hour)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (serviceNameController.text.isNotEmpty) {
                                  setStateDialog(() {
                                    _globalServices.add(ServiceItem(
                                      name: serviceNameController.text,
                                      estimatedTime: serviceTimeController.text.isEmpty ? '1 hour' : serviceTimeController.text,
                                      cost: double.tryParse(serviceCostController.text) ?? 0.0,
                                    ));

                                    serviceItems.add({
                                      'item_name': serviceNameController.text,
                                      'qty': 1,
                                      'rate': double.tryParse(serviceCostController.text) ?? 0.0,
                                      'estimated_time': serviceTimeController.text.isEmpty ? '1 hour' : serviceTimeController.text,
                                    });
                                  });

                                  serviceNameController.clear();
                                  serviceCostController.clear();
                                  serviceTimeController.clear();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Service added successfully!')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                              ),
                              child: const Text('Add Service', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Services list
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Services',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _globalServices.isEmpty
                          ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build_circle_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No services added yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: _globalServices.length,
                        itemBuilder: (context, index) {
                          final service = _globalServices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF4CAF50),
                                child: Icon(Icons.build, color: Colors.white, size: 20),
                              ),
                              title: Text(service.name),
                              subtitle: Text('Time: ${service.estimatedTime} • Cost: \$${service.cost.toStringAsFixed(2)}'),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                    onTap: () {
                                      // Edit service logic
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                    onTap: () {
                                      setStateDialog(() {
                                        // Remove from both lists
                                        String serviceName = _globalServices[index].name;
                                        _globalServices.removeAt(index);
                                        serviceItems.removeWhere((item) => item['item_name'] == serviceName);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh the main page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Services updated successfully!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show Parts Management Dialog
  void _showPartsDialog() {
    TextEditingController partNameController = TextEditingController();
    TextEditingController partQuantityController = TextEditingController();
    TextEditingController partPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.precision_manufacturing, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text('Parts Management'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Add new part section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Part',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: partNameController,
                            decoration: const InputDecoration(
                              hintText: 'Part name/number',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: partQuantityController,
                                  decoration: const InputDecoration(
                                    hintText: 'Qty',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: partPriceController,
                                  decoration: const InputDecoration(
                                    hintText: 'Price',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (partNameController.text.isNotEmpty) {
                                  setStateDialog(() {
                                    int quantity = int.tryParse(partQuantityController.text) ?? 1;
                                    double price = double.tryParse(partPriceController.text) ?? 0.0;

                                    _globalParts.add(PartItem(
                                      name: partNameController.text,
                                      quantity: quantity,
                                      price: price,
                                      inStock: true,
                                    ));

                                    partsItems.add({
                                      'item_name': partNameController.text,
                                      'qty': quantity,
                                      'rate': price,
                                    });
                                  });

                                  partNameController.clear();
                                  partQuantityController.clear();
                                  partPriceController.clear();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Part added successfully!')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                              ),
                              child: const Text('Add Part', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Parts list
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Parts Inventory',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _globalParts.isEmpty
                          ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No parts added yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: _globalParts.length,
                        itemBuilder: (context, index) {
                          final part = _globalParts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: part.inStock ? const Color(0xFF4CAF50) : Colors.red,
                                child: Icon(
                                  part.inStock ? Icons.check : Icons.warning,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(part.name),
                              subtitle: Text('Qty: ${part.quantity} • Price: \$${part.price.toStringAsFixed(2)}'),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                    onTap: () {
                                      // Edit part logic
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                    onTap: () {
                                      setStateDialog(() {
                                        // Remove from both lists
                                        String partName = _globalParts[index].name;
                                        _globalParts.removeAt(index);
                                        partsItems.removeWhere((item) => item['item_name'] == partName);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh the main page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parts inventory updated!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show TecDoc Dialog
  void _showTecDocDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.library_books, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Text('TecDoc Database'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Search section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search TecDoc Database',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Enter part number or vehicle info',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Simulate TecDoc search
                                  setStateDialog(() {
                                    _tecDocItems.clear();
                                    _tecDocItems.addAll([
                                      TecDocItem(
                                        partNumber: 'TD123456',
                                        description: 'Brake Pad Set, Front Axle',
                                        manufacturer: 'Bosch',
                                        vehicleApplication: '2018-2023 Honda Civic',
                                        price: 89.99,
                                      ),
                                      TecDocItem(
                                        partNumber: 'TD789012',
                                        description: 'Oil Filter',
                                        manufacturer: 'Mann-Filter',
                                        vehicleApplication: '2018-2023 Honda Civic',
                                        price: 15.99,
                                      ),
                                      TecDocItem(
                                        partNumber: 'TD345678',
                                        description: 'Air Filter',
                                        manufacturer: 'Mahle',
                                        vehicleApplication: '2018-2023 Honda Civic',
                                        price: 24.99,
                                      ),
                                    ]);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  minimumSize: const Size(80, 40),
                                ),
                                child: const Text('Search', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Results section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Search Results',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _tecDocItems.isEmpty
                          ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No search results', style: TextStyle(color: Colors.grey)),
                            Text('Enter search terms above', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: _tecDocItems.length,
                        itemBuilder: (context, index) {
                          final item = _tecDocItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF2196F3),
                                child: Icon(Icons.precision_manufacturing, color: Colors.white, size: 20),
                              ),
                              title: Text(item.partNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(item.description),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTecDocDetailRow('Manufacturer', item.manufacturer),
                                      _buildTecDocDetailRow('Application', item.vehicleApplication),
                                      _buildTecDocDetailRow('Price', '\$${item.price.toStringAsFixed(2)}'),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              // Add to parts list
                                              setState(() {
                                                _globalParts.add(PartItem(
                                                  name: item.partNumber,
                                                  quantity: 1,
                                                  price: item.price,
                                                  inStock: true,
                                                ));

                                                partsItems.add({
                                                  'item_name': item.partNumber,
                                                  'qty': 1,
                                                  'rate': item.price,
                                                });
                                              });

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Added ${item.partNumber} to parts list')),
                                              );
                                            },
                                            icon: const Icon(Icons.add_shopping_cart),
                                            label: const Text('Add to Parts'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Ordered ${item.partNumber}')),
                                              );
                                            },
                                            icon: const Icon(Icons.shopping_cart),
                                            label: const Text('Order Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTecDocDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Show image source selection dialog
  Future<void> _showImageSourceDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Photo for ${inspections[index]}'),
          content: const Text('Choose image source:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Camera'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(index, ImageSource.camera);
              },
            ),
            TextButton(
              child: const Text('Gallery'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(index, ImageSource.gallery);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(int index, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _images[index].add(File(pickedFile.path));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image added to ${inspections[index]}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Remove image
  void _removeImage(int inspectionIndex, int imageIndex) {
    setState(() {
      _images[inspectionIndex].removeAt(imageIndex);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // View image in full screen
  void _viewFullScreenImage(File imageFile, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageFile: imageFile,
          title: title,
        ),
      ),
    );
  }

  void _setInspectionStatus(int index, int status) {
    setState(() {
      _inspectionStatus[index] = status;
    });
  }

  // Build item list widget
  Widget _buildItemList(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  trailing: Text('₹${((item['qty'] ?? 0) * (item['rate'] ?? 0)).toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Build summary widget
  Widget _buildSummary() {
    double serviceTotal = serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));
    double partsTotal = partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 0) * (item['rate'] ?? 0));
    double grandTotal = serviceTotal + partsTotal;

    if (serviceItems.isEmpty && partsItems.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cost Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _priceRow("Services Total", serviceTotal),
            _priceRow("Parts Total", partsTotal),
            const Divider(),
            _priceRow("GRAND TOTAL", grandTotal, bold: true),
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
          Text('₹${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    for (var controller in _partsControllers) {
      controller.dispose();
    }
    for (var controller in _serviceControllers) {
      controller.dispose();
    }
    for (var controller in _customerRemarksControllers) {
      controller.dispose();
    }
    // Cancel any running timers
    for (var timer in _recordingTimers) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Inspection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Top buttons row - ENHANCED COMMAND SECTION
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTopButton(
                    label: 'SERVICES',
                    icon: Icons.build,
                    color: const Color(0xFF4CAF50),
                    onPressed: _showServicesDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTopButton(
                    label: 'PARTS',
                    icon: Icons.precision_manufacturing,
                    color: const Color(0xFF4CAF50),
                    onPressed: _showPartsDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTopButton(
                    label: 'TecDoc',
                    icon: Icons.library_books,
                    color: const Color(0xFF2196F3),
                    onPressed: _showTecDocDialog,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          // Services and Parts Summary
          if (serviceItems.isNotEmpty || partsItems.isNotEmpty) ...[
            _buildItemList("SERVICES (${serviceItems.length})", serviceItems),
            _buildItemList("PARTS (${partsItems.length})", partsItems),
            _buildSummary(),
            Container(
              height: 1,
              color: Colors.grey[200],
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ],

          // Inspection list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main inspection row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Number
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Inspection title
                            Expanded(
                              child: Text(
                                inspections[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            // Action buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Camera button with badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _images[index].isNotEmpty
                                            ? Colors.blue[100]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt, size: 20),
                                        color: _images[index].isNotEmpty
                                            ? Colors.blue[600]
                                            : Colors.grey[600],
                                        onPressed: () => _showImageSourceDialog(index),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    if (_images[index].isNotEmpty)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${_images[index].length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(width: 8),

                                // Voice button with recording indicator
                                Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _isRecording[index]
                                            ? Colors.red[100]
                                            : _voiceMessages[index].isNotEmpty
                                            ? Colors.green[100]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isRecording[index] ? Icons.stop : Icons.mic,
                                          size: 20,
                                        ),
                                        color: _isRecording[index]
                                            ? Colors.red[600]
                                            : _voiceMessages[index].isNotEmpty
                                            ? Colors.green[600]
                                            : Colors.grey[600],
                                        onPressed: () => _toggleRecording(index),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    if (_voiceMessages[index].isNotEmpty)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${_voiceMessages[index].length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    if (_isRecording[index])
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${_recordingDurations[index]}s',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(width: 8),

                                // Customer remarks button
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _customerRemarksControllers[index].text.isNotEmpty
                                        ? Colors.orange[100]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.person_outline, size: 20),
                                    color: _customerRemarksControllers[index].text.isNotEmpty
                                        ? Colors.orange[600]
                                        : Colors.grey[600],
                                    onPressed: () => _showCustomerRemarksDialog(index),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Status buttons
                                Row(
                                  children: [
                                    // Green status
                                    GestureDetector(
                                      onTap: () => _setInspectionStatus(index, 1),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _inspectionStatus[index] == 1
                                              ? const Color(0xFF4CAF50)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFF4CAF50),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus[index] == 1
                                            ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(width: 4),

                                    // Yellow status
                                    GestureDetector(
                                      onTap: () => _setInspectionStatus(index, 2),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _inspectionStatus[index] == 2
                                              ? const Color(0xFFFFC107)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFFFC107),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus[index] == 2
                                            ? const Icon(
                                          Icons.warning,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(width: 4),

                                    // Red status
                                    GestureDetector(
                                      onTap: () => _setInspectionStatus(index, 3),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _inspectionStatus[index] == 3
                                              ? const Color(0xFFF44336)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFF44336),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus[index] == 3
                                            ? const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Display images if available
                        if (_images[index].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photos (${_images[index].length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images[index].length,
                                    itemBuilder: (context, imageIndex) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _viewFullScreenImage(
                                                _images[index][imageIndex],
                                                '${inspections[index]} - Photo ${imageIndex + 1}',
                                              ),
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    _images[index][imageIndex],
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index, imageIndex),
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Display voice messages if available
                        if (_voiceMessages[index].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voice Messages (${_voiceMessages[index].length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: _voiceMessages[index].asMap().entries.map((entry) {
                                    int messageIndex = entry.key;
                                    VoiceMessage message = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.mic, color: Colors.green[600], size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Voice message ${messageIndex + 1} (${message.duration}s)',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.play_arrow, size: 16),
                                            color: Colors.green[600],
                                            onPressed: () => _playVoiceMessage(message, index),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 16),
                                            color: Colors.red[600],
                                            onPressed: () => _deleteVoiceMessage(index, messageIndex),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Parts, Service, and Customer Remarks Fields
                        Column(
                          children: [
                            // Parts and Service Fields Row
                            Row(
                              children: [
                                // Parts field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.build_circle,
                                            size: 16,
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Parts Required',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: TextField(
                                          controller: _partsControllers[index],
                                          decoration: const InputDecoration(
                                            hintText: 'Enter parts...',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Service field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            size: 16,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Service Notes',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green[200]!),
                                        ),
                                        child: TextField(
                                          controller: _serviceControllers[index],
                                          decoration: const InputDecoration(
                                            hintText: 'Enter service notes...',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Customer Remarks Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.orange[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Customer Remarks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _showCustomerRemarksDialog(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: TextField(
                                    controller: _customerRemarksControllers[index],
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      hintText: 'Customer concerns or special requests...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showInspectionSummary();
        },
        icon: const Icon(Icons.assignment),
        label: const Text('Summary'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildTopButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInspectionSummary() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Inspection Summary'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services and Parts Summary
                  if (serviceItems.isNotEmpty || partsItems.isNotEmpty) ...[
                    const Text(
                      'Services & Parts Overview',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    if (serviceItems.isNotEmpty) ...[
                      Text('Services (${serviceItems.length}):',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      ...serviceItems.map((service) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text('• ${service['item_name']} - ₹${service['rate']}'),
                      )),
                      const SizedBox(height: 8),
                    ],

                    if (partsItems.isNotEmpty) ...[
                      Text('Parts (${partsItems.length}):',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      ...partsItems.map((part) => Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text('• ${part['item_name']} - Qty: ${part['qty']} × ₹${part['rate']}'),
                      )),
                      const SizedBox(height: 8),
                    ],

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cost:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${(serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 1) * (item['rate'] ?? 0)) +
                              partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 1) * (item['rate'] ?? 0))).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    const Divider(height: 24),
                  ],

                  // Individual Inspection Results
                  const Text(
                    'Inspection Results',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inspections.length,
                    itemBuilder: (context, index) {
                      String statusText = '';
                      Color statusColor = Colors.grey;

                      switch (_inspectionStatus[index]) {
                        case 1:
                          statusText = 'PASS';
                          statusColor = Colors.green;
                          break;
                        case 2:
                          statusText = 'WARNING';
                          statusColor = Colors.amber;
                          break;
                        case 3:
                          statusText = 'FAIL';
                          statusColor = Colors.red;
                          break;
                        default:
                          statusText = 'PENDING';
                          statusColor = Colors.grey;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inspections[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_images[index].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Photos: ${_images[index].length}',
                                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                ),
                              if (_voiceMessages[index].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Voice Messages: ${_voiceMessages[index].length}',
                                    style: const TextStyle(fontSize: 12, color: Colors.green),
                                  ),
                                ),
                              if (_partsControllers[index].text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Parts: ${_partsControllers[index].text}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (_serviceControllers[index].text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Service: ${_serviceControllers[index].text}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (_customerRemarksControllers[index].text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Customer Remarks: ${_customerRemarksControllers[index].text}',
                                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report generated successfully!')),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }
}

// Voice Message Data Model
class VoiceMessage {
  final String id;
  final int duration; // in seconds
  final DateTime timestamp;
  final String filePath;

  VoiceMessage({
    required this.id,
    required this.duration,
    required this.timestamp,
    required this.filePath,
  });
}

// Data Models
class ServiceItem {
  final String name;
  final String estimatedTime;
  final double cost;

  ServiceItem({
    required this.name,
    required this.estimatedTime,
    required this.cost,
  });
}

class PartItem {
  final String name;
  final int quantity;
  final double price;
  final bool inStock;

  PartItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.inStock = true,
  });
}

class TecDocItem {
  final String partNumber;
  final String description;
  final String manufacturer;
  final String vehicleApplication;
  final double price;

  TecDocItem({
    required this.partNumber,
    required this.description,
    required this.manufacturer,
    required this.vehicleApplication,
    required this.price,
  });
}

// Full screen image viewer
class FullScreenImageViewer extends StatelessWidget {
  final File imageFile;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageFile,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality would go here')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

        ],
      ),


    );
  }
}