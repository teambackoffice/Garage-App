import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/inspection.dart';
import 'package:garage_app/view_inspection/view_inspection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkInProgress extends StatefulWidget {
  final String? services;
  final String? parts;
  final String phnumber;

  const WorkInProgress({super.key, required this.services, required this.parts, required this.phnumber});

  @override
  State<WorkInProgress> createState() => _WorkInProgressState();
}

class _WorkInProgressState extends State<WorkInProgress> {
  bool _isLoading = false;
  String? _error;
  String orderId = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      setState(() {
        orderId = args;
      });
      debugPrint("🟡 Received Order ID: $orderId");
    } else {
      setState(() {
        _error = '❌ No valid order ID provided.';
      });
    }
  }

  Future<void> _markRepairOrderAsReady() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('sid');
    debugPrint("🟡 SID: $sid");

    if (sid == null || sid.isEmpty) {
      setState(() {
        _error = '❌ Session expired. Please login again.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.repairorder_ready_orders');

    final requestBody = jsonEncode({
      'repairorder_id': orderId,
      'status': 'ready',
    });

    debugPrint("🔵 Request Body: $requestBody");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'sid=$sid',
        },
        body: requestBody,
      );

      debugPrint("🟢 Status Code: ${response.statusCode}");
      debugPrint("🟢 Response Body: ${response.body}");

      final responseData = jsonDecode(response.body);

      final success = responseData['message']?['success'];
      final message = responseData['message']?['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Marked as Ready")),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = '❌ Failed: $message';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Exception occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to mark this order as ready?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _markRepairOrderAsReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          const Icon(Icons.home, color: Colors.black),
        ],
        title: const Text('In Progress List', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: height * 0.05),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Order ID: $orderId",
                style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
             widget.services == null ? SizedBox() : Text(
                "Services: ${widget.services}",
                style: TextStyle( fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
             widget.parts == null ? SizedBox() : Text(
                "Parts: ${widget.parts}",
                style: TextStyle( fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: height * 0.03),
              SizedBox(
                width: width * 0.6,
                height: height * 0.06,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(fontSize: width * 0.045),
                  ),
                  child: const Text('Mark as Ready'),
                ),

              ),
              SizedBox(height: 10,),
              SizedBox(width: width * 0.4,
                height: height * 0.06,

                child: ElevatedButton( style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(fontSize: width * 0.038),
                ),
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  Inspection( orderId : orderId,ph_number :widget.phnumber),

                        ),
                      );
                    }, child: Text('Add Inspection',style: TextStyle(fontWeight: FontWeight.bold),)),
              ),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    // width: width * 0.4,
                    // height: height * 0.06,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(fontSize: width * 0.028),
                      ),
                      onPressed: () {
                       
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InspectionScreen(orderId : orderId),
                          ),
                        );
                        
                        // For now, showing a placeholder message
                        
                      },
                      child: Text('View Inspection', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                SizedBox(height: height * 0.03),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red, fontSize: width * 0.04),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}