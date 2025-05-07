import 'package:flutter/material.dart';

class PrintInvoicePage extends StatelessWidget {
  final String invoiceNumber;
  final String customerName;
  final String mobile;
  final String email;
  final List<Map<String, dynamic>> parts;
  final List<Map<String, dynamic>> services;
  final double serviceTotal;
  final double partsTotal;
  final double grandTotal;

  const PrintInvoicePage({
    super.key,
    required this.invoiceNumber,
    required this.customerName,
    required this.mobile,
    required this.email,
    required this.parts,
    required this.services,
    required this.serviceTotal,
    required this.partsTotal,
    required this.grandTotal,
  });

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.black26),
          columnWidths: const {
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.black12),
              children: [
                Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            ...items.map((item) {
              final qty = item['qty'] ?? 1;
              final rate = item['rate'] ?? 0.0;
              final total = rate * qty;
              return TableRow(children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(item['item_name'] ?? '')),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("₹${rate.toStringAsFixed(2)}")),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(qty.toString())),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("₹${total.toStringAsFixed(2)}")),
              ]);
            }).toList(),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _summaryRow("Service Total", serviceTotal),
        _summaryRow("Parts Total", partsTotal),
        const Divider(thickness: 1),
        _summaryRow("Grand Total", grandTotal, isBold: true),
      ],
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("₹${value.toStringAsFixed(2)}",
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Invoice #: $invoiceNumber", style: const TextStyle(fontSize: 16)),
        Text("Customer: $customerName"),
        Text("Mobile: $mobile"),
        Text("Email: $email"),
        const Divider(thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Preview"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerInfo(),
              const SizedBox(height: 10),
              if (services.isNotEmpty) _buildSection("Services", services),
              if (parts.isNotEmpty) _buildSection("Parts", parts),
              _buildSummary(),
            ],
          ),
        ),
      ),
    );
  }
}
