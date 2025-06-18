import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

import 'main.dart';

double w = 0; // width reference

class Inspection extends StatefulWidget {
  final String orderId;
  final String ph_number;

  

  const Inspection({super.key, required this.orderId, required this.ph_number, });

  @override
  State<Inspection> createState() => _InspectionState();
}

class _InspectionState extends State<Inspection> {
  

  bool _isLoading = false;
  final List<String> inspections = [
    'Battery Inspection',
    'Engine Inspection',
    'Tire Inspection',
    'Brake Inspection',
  ];

  // Store multiple images per item
  final List<List<File>> _images = List.generate(4, (index) => <File>[]);
  List<File> allImages = [];

void prepareImages() {
  allImages = _images.expand((imageList) => imageList).toList();
}


  // Store status for each inspection (0 = none, 1 = green, 2 = yellow, 3 = red)
  final List<int> _inspectionStatus = [];

  // Store parts and service data for each inspection
  final List<TextEditingController> _partsControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _serviceControllers = List.generate(4, (index) => TextEditingController());

  // Store customer remarks for each inspection
  final List<TextEditingController> _customerRemarksControllers = List.generate(4, (index) => TextEditingController());
   
  // Store voice messages for each inspection
  final List<List<VoiceMessage>> _voiceMessages = List.generate(4, (index) => <VoiceMessage>[]);
   final List<AudioRecorder> _audioRecorders = List.generate(4, (index) => AudioRecorder());
  


List<InspectionItem> _allInspections = [];
List<bool> _selectedInspections = [];

bool _IsLoading = false;



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

  void _showInspectionSelectionDialog() {
  // Initialize selection list if empty
  if (_selectedInspections.isEmpty) {
    _selectedInspections = List.filled(inspections.length, false);
  }
  
  List<bool> tempSelection = List.from(_selectedInspections);
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          int selectedCount = tempSelection.where((selected) => selected).length;
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[600]!,
                          Colors.blue[700]!,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.checklist_rtl,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Inspections',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose the inspections you want to perform',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection Counter
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedCount > 0 ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedCount > 0 ? Colors.green[200]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedCount > 0 ? Icons.check_circle : Icons.info_outline,
                          color: selectedCount > 0 ? Colors.green[600] : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedCount > 0 
                              ? '$selectedCount inspection${selectedCount == 1 ? '' : 's'} selected'
                              : 'No inspections selected',
                          style: TextStyle(
                            color: selectedCount > 0 ? Colors.green[700] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (selectedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$selectedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                tempSelection = List.filled(inspections.length, true);
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 18),
                            label: const Text('Select All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[600],
                              side: BorderSide(color: Colors.blue[600]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                tempSelection = List.filled(inspections.length, false);
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear All'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(color: Colors.red[600]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Inspections List
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _allInspections.length,
                        itemBuilder: (context, index) {
                          bool isSelected = tempSelection[index];
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue[200]! : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                _allInspections[index].name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.blue[700] : Colors.grey[800],
                                ),
                              ),
                              // subtitle: Text(
                              //   'Inspection ${index + 1}',
                              //   style: TextStyle(
                              //     fontSize: 12,
                              //     color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              //   ),
                              // ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  tempSelection[index] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[600],
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: selectedCount > 0 ? () {
                              setState(() {
      _selectedInspections = tempSelection;
      _showSelectedInspections = tempSelection.any((selected) => selected);
      
      // Ensure _inspectionStatus has the same length (use clear/addAll for final lists)
      if (_inspectionStatus.length != _allInspections.length) {
        _inspectionStatus.clear();
        _inspectionStatus.addAll(List<int>.filled(_allInspections.length, 0));
      }
    });
    Navigator.of(context).pop();
  } : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              selectedCount > 0 
                                  ? 'Apply Selection ($selectedCount)'
                                  : 'Select Inspections',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedCount > 0 ? Colors.blue[600] : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: selectedCount > 0 ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  // Add these variables to your class state
bool _showSelectedInspections = false;



  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Voice recording functions
 void _startRecording(int index) async {
  print("🟢 Starting recording for index: $index");
  
  if (index < 0 || index >= _isRecording.length) return;
  if (_isRecording[index]) return;
  
  try {
    if (await _audioRecorders[index].hasPermission()) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String fileName = 'voice_${index}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      String fullPath = '${appDocDir.path}/$fileName';
      
      await _audioRecorders[index].start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: fullPath,
      );
      
      // THIS IS THE CRITICAL PART - Set state AFTER recording starts successfully
      setState(() {
        _isRecording[index] = true;
        _recordingDurations[index] = 0;
      });
      
      print("✅ State updated - _isRecording[$index]: ${_isRecording[index]}");
      
      // Start timer
      _recordingTimers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDurations[index]++;
          });
          print("⏱️ Recording duration: ${_recordingDurations[index]}s");
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording started for ${_allInspections[index].name}...'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
      
      print("✅ Recording started successfully");
    } else {
      print("❌ Permission denied");
    }
  } catch (e) {
    print('❌ Recording failed: $e');
    // Reset state if recording fails
    setState(() {
      _isRecording[index] = false;
      _recordingDurations[index] = 0;
    });
    _recordingTimers[index]?.cancel();
    _recordingTimers[index] = null;
  }
}
void _stopRecording(int index) async {
  print("🔴 _stopRecording called for index: $index");
  
  if (index < 0 || index >= _isRecording.length) {
    print("❌ Invalid index bounds");
    return;
  }
  
  print("🔴 Current recording state: ${_isRecording[index]}");
  print("🔴 Timer exists: ${_recordingTimers[index] != null}");
  
  _recordingTimers[index]?.cancel();
  _recordingTimers[index] = null;

  final duration = _recordingDurations[index];
  print("🔴 Recording duration: ${duration}s");

  try {
    print("🔴 Attempting to stop recorder...");
    
    // Check if recorder is actually recording
    bool isRecording = await _audioRecorders[index].isRecording();
    print("🔴 Recorder isRecording: $isRecording");
    
    if (isRecording) {
      String? recordedPath = await _audioRecorders[index].stop();
      print("🔴 Stop recording returned path: $recordedPath");

      if (recordedPath != null && recordedPath.isNotEmpty) {
        setState(() {
          _isRecording[index] = false;
          _recordingDurations[index] = 0;

          _voiceMessages[index].add(VoiceMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            duration: duration,
            timestamp: DateTime.now(),
            filePath: recordedPath,
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice message saved (${duration}s) for ${_allInspections[index].name}'),
            backgroundColor: Colors.green,
          ),
        );

        print("✅ Voice message recorded at: $recordedPath");
      } else {
        print("❌ Recording failed - no file path returned");
        setState(() {
          _isRecording[index] = false;
          _recordingDurations[index] = 0;
        });
      }
    } else {
      print("❌ Recorder was not recording");
      setState(() {
        _isRecording[index] = false;
        _recordingDurations[index] = 0;
      });
    }
  } catch (e) {
    print('❌ Error stopping recording: $e');
    setState(() {
      _isRecording[index] = false;
      _recordingDurations[index] = 0;
    });
  }
}
Color? _getRecordingButtonColor(int index) {
  if (_isRecording[index]) {
    return Colors.red[600];
  } else if (_voiceMessages[index].isNotEmpty) {
    return Colors.green[600];
  } else {
    return Colors.grey[600];
  }
}
Color? _getBackgroundColor(int index) {
  if (index >= _isRecording.length) return Colors.grey[300];
  
  if (_isRecording[index]) {
    return Colors.red[100];
  } else if (index < _voiceMessages.length && _voiceMessages[index].isNotEmpty) {
    return Colors.green[100];
  } else {
    return Colors.grey[300];
  }
}

// Optional: Add this method for pulsing animation while recording
Widget _buildPulsingBorder(int index) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _isRecording.length > index && _isRecording[index]
            ? Colors.red.withOpacity(0.8)
            : Colors.transparent,
        width: 2,
      ),
    ),
  );
}
 void _toggleRecording(int index) {
  print("🟡 _toggleRecording called for index: $index");
  print("🟡 _isRecording array: $_isRecording");
  print("🟡 Current _isRecording[$index]: ${_isRecording[index]}");
  
  if (index < 0 || index >= _isRecording.length) {
    print('❌ Invalid recording index: $index');
    return;
  }

  if (_isRecording[index]) {
    print("🟡 Calling _stopRecording");
    _stopRecording(index);
  } else {
    print("🟡 Calling _startRecording");
    _startRecording(index);
  }
}

  void _playVoiceMessage(VoiceMessage voiceMessage, int inspectionIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing voice message (${voiceMessage.duration}s) for ${_allInspections[inspectionIndex].name}'),
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
                  'Customer Remarks - ${_allInspections[index].name}',
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
                    content: Text('Customer remarks saved for ${_allInspections[index].name}'),
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
          title: Text('Add Photo for ${_allInspections[index].name}'),
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
            content: Text('Image added to ${_allInspections[index].name}'),
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
initState(){
  super.initState();
  // fetchAllInspections();
  initializeInspections();
    _selectedInspections = List<bool>.filled(_allInspections.length, false);
}
//  List fetchedInspections

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
    for (var recorder in _audioRecorders) {
      recorder.dispose();
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
      // Replace your entire body with this structure:
body: SingleChildScrollView(
  child: Column(
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

      // Inspection list - NO Expanded, NO ListView, just Column with children
      Padding(
  padding: const EdgeInsets.all(8),
  child: Column(
    children: [
      // Show Inspections Button or Selected Inspections
      if (!_showSelectedInspections)
        Center(
          child: ElevatedButton.icon(
            onPressed: _showInspectionSelectionDialog,
            icon: const Icon(Icons.checklist),
            label: const Text('Show Inspections'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        )
      else
        Column(
          children: [
            // Header with selected count and actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200] ?? Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Inspections (${_selectedInspections.where((selected) => selected).length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showInspectionSelectionDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSelectedInspections = false;
                        _selectedInspections = List.filled(inspections.length, false);
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected Inspections List
            ...List.generate(
              _allInspections.length,
              (index) {
                if (_selectedInspections.length <= index || !_selectedInspections[index]) {
                  return const SizedBox.shrink();
                }
                
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
                                _allInspections[index].name,
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
                                        color: _images.length > index && _images[index].isNotEmpty
                                            ? Colors.blue[100]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt, size: 20),
                                        color: _images.length > index && _images[index].isNotEmpty
                                            ? Colors.blue[600]
                                            : Colors.grey[600],
                                        onPressed: () => _showImageSourceDialog(index),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                    if (_images.length > index && _images[index].isNotEmpty)
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
        color: _getBackgroundColor(index),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          _isRecording[index] ? Icons.stop : Icons.mic,  // Simplified check
          size: 20,
        ),
        color: _getRecordingButtonColor(index),
        onPressed: () {
          print("🔵 IconButton pressed for index: $index");
          print("🔵 Current state: ${_isRecording[index] ? 'RECORDING' : 'NOT_RECORDING'}");
          _toggleRecording(index);
        },
        padding: EdgeInsets.zero,
      ),
    ),
    
    // Make sure overlays don't block button presses
    if (_voiceMessages.length > index && _voiceMessages[index].isNotEmpty)
      Positioned(
        right: -2,
        top: -2,
        child: IgnorePointer(  // ADD THIS
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
      ),
    
    if (_isRecording[index])
      Positioned(
        bottom: -2,
        left: 0,
        right: 0,
        child: IgnorePointer(  // ADD THIS
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
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
      ),
  ],
),
                                const SizedBox(width: 8),

                                // Customer remarks button
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _customerRemarksControllers.length > index && 
                                           _customerRemarksControllers[index].text.isNotEmpty
                                        ? Colors.orange[100]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.person_outline, size: 20),
                                    color: _customerRemarksControllers.length > index && 
                                           _customerRemarksControllers[index].text.isNotEmpty
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
                                          color: _inspectionStatus.length > index && _inspectionStatus[index] == 1
                                              ? const Color(0xFF4CAF50)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFF4CAF50),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus.length > index && _inspectionStatus[index] == 1
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
                                          color: _inspectionStatus.length > index && _inspectionStatus[index] == 2
                                              ? const Color(0xFFFFC107)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFFFC107),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus.length > index && _inspectionStatus[index] == 2
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
                                          color: _inspectionStatus.length > index && _inspectionStatus[index] == 3
                                              ? const Color(0xFFF44336)
                                              : Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFF44336),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _inspectionStatus.length > index && _inspectionStatus[index] == 3
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
                        if (_images.length > index && _images[index].isNotEmpty)
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
                                    // ✅ FIXED: Use API name for image title
                                    '${_allInspections[index].name} - Photo ${imageIndex + 1}',
                                  ),
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
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
                        if (_voiceMessages.length > index && _voiceMessages[index].isNotEmpty)
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
                                        border: Border.all(color: Colors.green[200] ?? Colors.green),
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
                                          // IconButton(
                                          //   icon: const Icon(Icons.play_arrow, size: 16),
                                          //   color: Colors.green[600],
                                          //   onPressed: () => _playVoiceMessage(message, index),
                                          //   padding: EdgeInsets.zero,
                                          //   constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          // ),
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
                                          border: Border.all(color: Colors.blue[200] ?? Colors.blue),
                                        ),
                                        child: TextField(
                                          controller: _partsControllers.length > index 
                                              ? _partsControllers[index] 
                                              : TextEditingController(),
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
                                          border: Border.all(color: Colors.green[200] ?? Colors.green),
                                        ),
                                        child: TextField(
                                          controller: _serviceControllers.length > index 
                                              ? _serviceControllers[index] 
                                              : TextEditingController(),
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
                                    border: Border.all(color: Colors.orange[200] ?? Colors.orange),
                                  ),
                                  child: TextField(
                                    controller: _customerRemarksControllers.length > index 
                                        ? _customerRemarksControllers[index] 
                                        : TextEditingController(),
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
          ],
        ),
    ],
  ),
)
    ],
  ),
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


  Widget _buildSectionHeader(String title, IconData icon, Color color) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

Widget _buildFinancialCard(String title, List items, double total, IconData icon, Color color, {required bool isService}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${items.length} items)',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: color,
                ),
              ),
              SizedBox(height: 5,),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...items.take(3).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['item_name'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                isService 
                  ? '₹${item['rate']}'
                  : '${item['qty']} × ₹${item['rate']}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        )),
        
        if (items.length > 3)
          Text(
            '+${items.length - 3} more items',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    ),
  );
}

Widget _buildStatusChip(String label, int count, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInspectionCard(int index) {
  String statusText = '';
  Color statusColor = Colors.grey;
  IconData statusIcon = Icons.pending;

  switch (_inspectionStatus[index]) {
    case 1:
      statusText = 'Satisfied';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      break;
    case 2:
      statusText = 'Immediate Attention';
      statusColor = Colors.amber;
      statusIcon = Icons.warning;
      break;
    case 3:
      statusText = 'Attention in Future';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      break;
    default:
      statusText = 'PENDING';
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: statusColor.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _allInspections[index].name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,

                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_images.length > index && _images[index].isNotEmpty ||
              _voiceMessages.length > index && _voiceMessages[index].isNotEmpty ||
              _partsControllers.length > index && _partsControllers[index].text.isNotEmpty ||
              _serviceControllers.length > index && _serviceControllers[index].text.isNotEmpty ||
              _customerRemarksControllers.length > index && _customerRemarksControllers[index].text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_images.length > index && _images[index].isNotEmpty)
                    _buildDetailRow(Icons.camera_alt, 'Photos', '${_images[index].length}', Colors.blue),
                  
                  if (_voiceMessages.length > index && _voiceMessages[index].isNotEmpty)
                    _buildDetailRow(Icons.mic, 'Voice Messages', '${_voiceMessages[index].length}', Colors.green),
                  
                  if (_partsControllers.length > index && _partsControllers[index].text.isNotEmpty)
                    _buildDetailRow(Icons.build_circle, 'Parts', _partsControllers[index].text, Colors.blue),
                  
                  if (_serviceControllers.length > index && _serviceControllers[index].text.isNotEmpty)
                    _buildDetailRow(Icons.settings, 'Service', _serviceControllers[index].text, Colors.green),
                  
                  if (_customerRemarksControllers.length > index && _customerRemarksControllers[index].text.isNotEmpty)
                    _buildDetailRow(Icons.person_outline, 'Customer Remarks', _customerRemarksControllers[index].text, Colors.orange),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
// Model class for inspection data

// Get session ID
Future<String?> _getSessionId() async {
  final prefs = await SharedPreferences.getInstance();
  final sid = prefs.getString('sid');
  debugPrint('Retrieved session ID: $sid');
  return sid;
}

// Fetch all inspections from API
Future<List<InspectionItem>> fetchAllInspections() async {
  String? sessionId = await _getSessionId();
  
  if (sessionId == null) {
    throw Exception('No session ID found. Please login first.');
  }

  try {
    print('🔍 Fetching inspections from API...');
    
    var response = await http.get(
      Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_inspection'),
      headers: {
        'Cookie': 'sid=$sessionId',
        'Accept': 'application/json',
      },
    );

    print('📥 Inspections API Status: ${response.statusCode}');
    print('📥 Inspections API Response: ${response.body}');

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Parse the specific structure from your API response
      if (jsonResponse.containsKey('message') && 
          jsonResponse['message']['status'] == 'success' &&
          jsonResponse['message'].containsKey('data')) {
        
        List<dynamic> inspectionData = jsonResponse['message']['data'] as List<dynamic>;
        
        List<InspectionItem> inspections = inspectionData
            .map((item) => InspectionItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        print('✅ Fetched ${inspections.length} inspections:');
        for (var inspection in inspections) {
          print('  - ${inspection.name}');
        }
        
        return inspections;
      } else {
        throw Exception('Invalid API response structure');
      }
    } else {
      throw Exception('Failed to fetch inspections: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Error fetching inspections: $e');
    throw Exception('Failed to fetch inspections: $e');
  }
}

// Initialize inspections when the screen loads
Future<void> initializeInspections() async {
  try {
    setState(() {
      _isLoading = true;
    });

    List<InspectionItem> fetchedInspections = await fetchAllInspections();
    
    setState(() {
      // Update your inspection lists with API data
      _allInspections = fetchedInspections;
      
      // Clear and refill the final lists instead of reassigning
      _inspectionStatus.clear();
      _inspectionStatus.addAll(List<int>.filled(fetchedInspections.length, 0));
      
      // Initialize _selectedInspections if it's not final
      _selectedInspections = List<bool>.filled(fetchedInspections.length, false);
      
      _isLoading = false;
    });
    
    print('🎉 Inspections initialized successfully with ${fetchedInspections.length} items');
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    showError('Failed to load inspections: $e');
  }
}

// Export report using API-fetched inspection names
// Fixed export method to match your exact backend format
// Fixed export method to match your exact backend format
Future<void> exportReport() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
    });
  }

  // ✅ Increase delay to make loading visible (optional, for testing)
  await Future.delayed(const Duration(milliseconds: 300));

  String? sessionId = await _getSessionId();
  
  if (sessionId == null || sessionId.isEmpty) {
    setState(() {
      _isLoading = false;
    });
    showError('No session found. Please login first.');
    return;
  }

  List<String> statusNames = ['', 'Satisfied', 'Immediate Attention', 'Attention in Future'];
  
  // Build selected inspections using API-fetched names
  List<Map<String, dynamic>> selectedInspections = [];
  for (int i = 0; i < _allInspections.length; i++) {
    if (_selectedInspections[i] && _inspectionStatus[i] > 0 && _inspectionStatus[i] < statusNames.length) {
      selectedInspections.add({
        "inspection_type": _allInspections[i].name, // ✅ API-fetched name
        "status": statusNames[_inspectionStatus[i]]
      });
    }
  }

  print('🔍 Selected inspections data:');
  for (var inspection in selectedInspections) {
    print('  inspection_type: "${inspection['inspection_type']}"');
    print('  status: "${inspection['status']}"');
  }

  if (selectedInspections.isEmpty) {
    setState(() {
      _isLoading = false;
    });
    showError('Please select at least one inspection and set its status before exporting.');
    return;
  }

  String formattedDate = DateTime.now().toIso8601String().split('T').first;
  
  // Collect customer remarks from selected inspections only
  List<String> customerRemarks = [];
  for (int i = 0; i < _allInspections.length; i++) {
    if (_selectedInspections[i] && 
        _customerRemarksControllers.length > i && 
        _customerRemarksControllers[i].text.isNotEmpty) {
      customerRemarks.add(_customerRemarksControllers[i].text);
    }
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.create_inspection'),
  );

  // ✅ FIXED: Create inspection table in EXACT format as your example
  String formattedInspectionTable = selectedInspections.map((inspection) {
    return '{"inspection_type": "${inspection['inspection_type']}", "status": "${inspection['status']}"}';
  }).join(',\n  '); // Note the exact spacing: comma + newline + 2 spaces
  formattedInspectionTable = '[$formattedInspectionTable]';

  // ✅ FIXED: Use exact field format as your example
  request.fields.addAll({
    'repair_order_id': widget.orderId,
    'inspection_date': formattedDate,
    'remarks': customerRemarks.join(', '),
    'Inspection Table': formattedInspectionTable, // Exact format with newlines and spacing
  });

  // Add authentication headers
  request.headers.addAll({
    'Cookie': 'sid=$sessionId',
    'Accept': 'application/json',
  });

  // ✅ FIXED: Add images with 'photo' field name (not 'images')
  int imagesAdded = 0;
  for (int i = 0; i < _allInspections.length; i++) {
    if (_selectedInspections[i] && _images.length > i && _images[i].isNotEmpty) {
      for (int j = 0; j < _images[i].length; j++) {
        File image = _images[i][j];
        if (await image.exists()) {
          try {
            // ✅ FIXED: Use 'photo' field name instead of 'images'
            request.files.add(await http.MultipartFile.fromPath('photo', image.path));
            imagesAdded++;
            print('✅ Added photo from ${_allInspections[i].name}: ${image.path}');
          } catch (e) {
            print('❌ Error adding photo: $e');
          }
        }
      }
    }
  }

  // ✅ FIXED: Add voice messages with 'audio' field name - SIMPLIFIED
  int audioAdded = 0;
  for (int i = 0; i < _allInspections.length; i++) {
    if (_selectedInspections[i] && _voiceMessages.length > i && _voiceMessages[i].isNotEmpty) {
      for (var voiceMessage in _voiceMessages[i]) {
        if (voiceMessage.filePath.isNotEmpty) {
          // Use the path directly - no need to resolve it
          File voiceFile = File(voiceMessage.filePath);
          
          if (await voiceFile.exists()) {
            try {
              request.files.add(await http.MultipartFile.fromPath('audio', voiceMessage.filePath));
              audioAdded++;
              print('✅ Added audio from ${_allInspections[i].name}: ${voiceMessage.filePath}');
            } catch (e) {
              print('❌ Error adding audio: $e');
            }
          } else {
            print("❌ File does not exist at: ${voiceMessage.filePath}");
          }
        }
      }
    }
  }

  print('📤 Final Request Summary:');
  print('  Photos: $imagesAdded (using "photo" field)');
  print('  Audio: $audioAdded (using "audio" field)');
  print('  Inspections: ${selectedInspections.length}');
  print('  Customer Remarks: ${customerRemarks.length}');

  try {
    print('🚀 Sending request...');
    http.StreamedResponse response = await request.send();

    String responseString = await response.stream.bytesToString();
    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: $responseString');

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    

    if (response.statusCode == 200) {
  print('🎉 SUCCESS! Data exported successfully');

  // ✅ Read stream to string (you can only do this once)
//  final responseString = await response.stream.bytesToString();
final responseBody = jsonDecode(responseString);

final String link = responseBody['message']['link'];

if (link.isNotEmpty) {
  await _sendToWhatsApp(link);
} else {
  print('❌ No link provided in response.');
  showError('Export succeeded but no link was returned.');
}


  // Send to WhatsApp
   // ✅ Only pop if there's a navigator to pop
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // ✅ Show success dialog only if widget is still mounted
      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success tick icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Report Exported Successfully!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Your report has been sent to WhatsApp',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Single action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Add bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ));
       
        
      }
        



} else {
  print('❌ Export failed: ${response.statusCode}');

  // ✅ Here you CANNOT use response.body because this is a StreamedResponse
  // You need to read the stream even in error case
  final responseString = await response.stream.bytesToString();

  showError('Export failed: ${response.statusCode}\n$responseString');
}
  } catch (e) {
     if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    print('❌ Error sending request: $e');
    showError('Error sending request: $e'); 
  }
}

// Simple WhatsApp function
Future<void> _sendToWhatsApp(String reportLink) async {
  try {
    String phone = widget.ph_number; // PUT YOUR PHONE NUMBER HERE
    String message = "🔧 Vehicle Inspection Report\n\n📋 Order: ${widget.orderId}\n📅 Date: ${DateTime.now().toLocal().toString().split(' ')[0]}\n\n🔗 View Report: $reportLink\n\nThank you for choosing our service!";
    
    String url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    
    print('📱 Opening WhatsApp...');
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    print('✅ WhatsApp opened successfully');
  } catch (e) {
    print('❌ Error opening WhatsApp: $e');
    showError('Error opening WhatsApp: $e');
  }
}

// Helper method for voice file path resolution (same as before)
Future<String> _resolveVoiceFilePath(String filePath) async {
  // Check if it's already a full path
  if (filePath.startsWith('/')) {
    // It's already a full path, just return it
    return filePath;
  }
  
  // If it's just a filename, resolve it
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String fullPath = '${appDocDir.path}/$filePath';
  return fullPath;
}

// Debug method to test with your exact format
Future<void> testExactFormat() async {
  String? sessionId = await _getSessionId();
  if (sessionId == null) return;
  
  // Test with exact format from your example
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.create_inspection'),
  );

  request.fields.addAll({
    'repair_order_id': widget.orderId,
    'inspection_date': '2025-06-16',
    'remarks': 'Test remarks',
    'Inspection Table': '[{"inspection_type": "Battery Inspection", "status": "Immediate Attention"},\n  {"inspection_type": "Tier Inspection", "status": "Satisfied"}]'
  });

  request.headers.addAll({
    'Cookie': 'sid=$sessionId',
    'Accept': 'application/json',
  });

  print('🧪 Testing exact format from your example...');
  print('Inspection Table: ${request.fields['Inspection Table']}');

  try {
    http.StreamedResponse response = await request.send();
    String responseBody = await response.stream.bytesToString();
    
    print('📥 Test Response: ${response.statusCode}');
    print('📥 Test Body: $responseBody');
    
    if (response.statusCode == 200) {
      print('✅ Exact format test: SUCCESS!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Exact format test successful!'), backgroundColor: Colors.green),
      );
    } else {
      print('❌ Exact format test: FAILED');
    }
  } catch (e) {
    print('💥 Test Exception: $e');
  }
}
// Helper method to resolve voice file paths (same as before)
List<InspectionItem> getSelectedInspections() {
  List<InspectionItem> selected = [];
  for (int i = 0; i < _allInspections.length; i++) {
    if (_selectedInspections[i]) {
      selected.add(_allInspections[i]);
    }
  }
  return selected;
}

// Helper method to get the status name for an inspection
String getInspectionStatusName(int index) {
  List<String> statusNames = ['Not Set', 'Satisfied', 'Immediate Attention', 'Attention in Future'];
  if (index >= 0 && index < statusNames.length) {
    return statusNames[index];
  }
  return 'Not Set';
}

// Helper method to update inspection status
void updateInspectionStatus(int index, int statusValue) {
  setState(() {
    if (index >= 0 && index < _inspectionStatus.length) {
      _inspectionStatus[index] = statusValue;
    }
  });
}

// Method to check if an inspection is ready for export (selected + has status)
bool isInspectionReadyForExport(int index) {
  return _selectedInspections[index] && _inspectionStatus[index] > 0;
}

// Get count of inspections ready for export
int getReadyForExportCount() {
  int count = 0;
  for (int i = 0; i < _allInspections.length; i++) {
    if (isInspectionReadyForExport(i)) {
      count++;
    }
  }
  return count;
}

// Future<String> _resolveVoiceFilePath(String originalPath) async {
//   if (originalPath.startsWith('/')) {
//     return originalPath;
//   }
  
//   try {
//     Directory appDocDir = await getApplicationDocumentsDirectory();
//     String testPath = '${appDocDir.path}/$originalPath';
//     if (await File(testPath).exists()) {
//       return testPath;
//     }
//   } catch (e) {
//     print('Error resolving voice path: $e');
//   }
  
//   return originalPath;
// }
// Call this before exportReport to test your session
// await testSessionAuth();
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text('Error: $message'),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  void _showInspectionSummary() {
  // Calculate totals
  double servicesTotal = serviceItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 1) * (item['rate'] ?? 0));
  double partsTotal = partsItems.fold(0.0, (sum, item) => sum + (item['qty'] ?? 1) * (item['rate'] ?? 0));
  double grandTotal = servicesTotal + partsTotal;
  
  // Count inspection statuses
  int passCount = _inspectionStatus.where((status) => status == 1).length;
  int warningCount = _inspectionStatus.where((status) => status == 2).length;
  int failCount = _inspectionStatus.where((status) => status == 3).length;
  int pendingCount = _inspectionStatus.where((status) => status == 0 || status == null).length;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[50]!,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green[600]!,
                      Colors.green[700]!,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.summarize,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inspection Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete overview of services, parts & inspections',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Summary Cards Row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Total Cost Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.blue[700]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Total Cost',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Items Count Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple[600]!, Colors.purple[700]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${serviceItems.length + partsItems.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Total Items',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Status Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[600]!, Colors.orange[700]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.assessment,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${passCount}/${_inspectionStatus.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Passed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Services & Parts Section
                      if (serviceItems.isNotEmpty || partsItems.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Financial Overview',
                          Icons.account_balance_wallet,
                          Colors.blue[600]!,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // Services Column
                            if (serviceItems.isNotEmpty)
                              Expanded(
                                child: _buildFinancialCard(
                                  'Services',
                                  serviceItems,
                                  servicesTotal,
                                  Icons.build,
                                  Colors.green,
                                  isService: true,
                                ),
                              ),
                            
                            if (serviceItems.isNotEmpty && partsItems.isNotEmpty)
                              const SizedBox(width: 16),
                            
                            // Parts Column
                            if (partsItems.isNotEmpty)
                              Expanded(
                                child: _buildFinancialCard(
                                  'Parts',
                                  partsItems,
                                  partsTotal,
                                  Icons.settings,
                                  Colors.orange,
                                  isService: false,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Inspection Results Section
                      _buildSectionHeader(
                        'Inspection Results',
                        Icons.checklist,
                        Colors.green[600]!,
                      ),
                      const SizedBox(height: 8),
                      
                      // Status Overview
                      // Container(
                      //   margin: const EdgeInsets.only(bottom: 16),
                      //   padding: const EdgeInsets.all(16),
                      //   decoration: BoxDecoration(
                      //     color: Colors.grey[50],
                      //     borderRadius: BorderRadius.circular(12),
                      //     border: Border.all(color: Colors.grey[200]!),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       _buildStatusChip('Satisfied', passCount, Colors.green),
                      //       const SizedBox(width: 8),
                      //       _buildStatusChip('Immediate Attention', warningCount, Colors.amber),
                      //       const SizedBox(width: 8),
                      //       _buildStatusChip('Attention in Future', failCount, Colors.red),
                      //       const SizedBox(width: 8),
                      //       _buildStatusChip('Pending', pendingCount, Colors.grey),
                      //     ],
                      //   ),
                      // ),

                      // Individual Inspections
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedInspections.length,
                        itemBuilder: (context, index) {
                          // Only show selected inspections
                          if (_selectedInspections.length <= index || !_selectedInspections[index]) {
                            return const SizedBox.shrink();
                          }
                          
                          return _buildInspectionCard(index);
                        },
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
       Expanded(
  flex: 2,
  child: ElevatedButton.icon(
    onPressed: _isLoading ? null : () async {
      // ✅ Add async/await here to properly handle the loading state
      await exportReport();
    },
    icon: _isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : const Icon(Icons.download),
    label: Text(_isLoading ? 'Exporting...' : 'Export Report'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
      ],
    ),
              ),
            ],
          ),
        ),
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
class ApiResponse {
  final Message message;

  ApiResponse({required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      message: Message.fromJson(json['message']),
    );
  }
}

class Message {
  final String status;
  final List<InspectionItem> data;

  Message({required this.status, required this.data});

  factory Message.fromJson(Map<String, dynamic> json) {
    var inspectionsJson = json['data'] as List<dynamic>;
    return Message(
      status: json['status'] ?? '',
      data: inspectionsJson
          .map((item) => InspectionItem.fromJson(item))
          .toList(),
    );
  }
}

class InspectionItem {
  final String name;

  InspectionItem({required this.name});

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      name: json['name'] ?? '',
    );
  }
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
