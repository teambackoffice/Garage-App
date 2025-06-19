import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:garage_app/inspection.dart';
import 'package:garage_app/view_inspection/view_inspection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkInProgress extends StatefulWidget {
  final List<dynamic> services;
  final List<dynamic> parts;
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
             TextButton(
      onPressed: () {
        _showOrderDetailsDialog(context);
      },
      child: Text(
        "View Order Details",
        style: TextStyle(
          color: Colors.blue,
          fontSize: width * 0.03,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue,
        ),
      ),
    ),
              
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

void _showOrderDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Order Details',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Check if there are any items to display
                  if (widget.services.isEmpty && widget.parts.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'There are no services or parts in this order.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Services Section - only show if there are services
                    if (widget.services.isNotEmpty) ...[
                      _buildSectionHeader('Services', Icons.build),
                      SizedBox(height: 8),
                      _buildItemsList(widget.services, true),
                      
                      // Add spacing only if there are also parts
                      if (widget.parts.isNotEmpty) SizedBox(height: 20),
                    ],
                    
                    // Parts Section - only show if there are parts
                    if (widget.parts.isNotEmpty) ...[
                      _buildSectionHeader('Parts', Icons.settings),
                      SizedBox(height: 8),
                      _buildItemsList(widget.parts, false),
                    ],
                    
                    // Total Section - only show if there are items
                    if (widget.services.isNotEmpty || widget.parts.isNotEmpty) ...[
                      SizedBox(height: 20),
                      _buildTotalSection(),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
             color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<dynamic> items, bool isService) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    isService ? 'Service Name' : 'Part Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                       color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                       color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            
            // Handle both Map<String, dynamic> and direct object access
            String itemName = '';
            double qty = 0.0;
            double rate = 0.0;
            
            if (item is Map) {
              itemName = item['item_name']?.toString() ?? 'N/A';
              qty = (item['qty'] ?? 0.0).toDouble();
              rate = (item['rate'] ?? 0.0).toDouble();
            } else {
              // If it's an object with properties, try to access them
              try {
                itemName = item.item_name?.toString() ?? 'N/A';
                qty = (item.qty ?? 0.0).toDouble();
                rate = (item.rate ?? 0.0).toDouble();
              } catch (e) {
                itemName = 'N/A';
                qty = 0.0;
                rate = 0.0;
              }
            }
            
            double total = qty * rate;
            
            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                border: Border(
                  bottom: index == items.length - 1 
                    ? BorderSide.none 
                    : BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      itemName,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      qty.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹$rate',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹$total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    double servicesTotal = widget.services.fold(0.0, (sum, item) {
      double qty = (item['qty'] ?? 0.0).toDouble();
      double rate = (item['rate'] ?? 0.0).toDouble();
      return sum + (qty * rate);
    });
    
    double partsTotal = widget.parts.fold(0.0, (sum, item) {
      double qty = (item['qty'] ?? 0.0).toDouble();
      double rate = (item['rate'] ?? 0.0).toDouble();
      return sum + (qty * rate);
    });
    
    double grandTotal = servicesTotal + partsTotal;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Services Total:', style: TextStyle(fontSize: 14)),
              Text('₹${servicesTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Parts Total:', style: TextStyle(fontSize: 14)),
              Text('₹${partsTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
            ],
          ),
          Divider(color: Colors.blue[300]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                '₹${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

