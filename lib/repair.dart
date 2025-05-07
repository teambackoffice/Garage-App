import 'package:flutter/material.dart';

class RepairOrderPreviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        leading: BackButton(),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png', // replace with your logo path
                    height: 150,
                  ),
                  SizedBox(height: 10),
                  Text('Repair Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('VEHICLE', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('wdkme,cefl'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 14),
                            SizedBox(width: 4),
                            Text('7306539258'),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, size: 14),
                            SizedBox(width: 4),
                            Text('murshid@gmail.com'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Customer & Vehicle Info Table
            Table(
              border: TableBorder.all(color: Colors.blue.shade100),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow(['CUSTOMER', 'VEHICLE', 'ESTIMATE'], isHeader: true),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Murshid'),
                        Text('7306539258'),
                        Text('khanmurshid1112@gmail.com'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AMW BMW PETROL'),
                        Text('KL53L4912'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apr 15, 2025'),
                        Text('Amount: ₹0.00'),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
            SizedBox(height: 12),

            // Services
            Text('SERVICES', style: TextStyle(fontWeight: FontWeight.bold)),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                _buildTableRow(['Service', 'Qty', 'Rate', 'Amount'], isHeader: true),
                _buildTableRow(['General service', '1', '0.00', '0.00']),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Total: ₹0.00", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            SizedBox(height: 16),
            Text('SUMMARY', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // Submit action here
          },
          icon: Icon(Icons.build),
          label: Text('Create Repair Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.blue.shade100 : null,
      ),
      children: cells
          .map((cell) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(cell, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
      ))
          .toList(),
    );
  }
}
