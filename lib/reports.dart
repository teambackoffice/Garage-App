import 'package:flutter/material.dart';

// Reports Page
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  final List<Map<String, dynamic>> reports = const [
    {"icon": Icons.account_balance, "title": "Income/Expense Reports"},
    {"icon": Icons.receipt, "title": "Order Based Income Reports"},
    {"icon": Icons.money, "title": "TAG/Mechanic based"},
    {"icon": Icons.upload_file, "title": "Invoice Export"},
    {"icon": Icons.logout, "title": "Inventory Stock Out"},
    {"icon": Icons.login, "title": "Inventory Stock In"},
    {"icon": Icons.payment, "title": "Account Payable"},
    {"icon": Icons.bar_chart, "title": "Service Sales Reports"},
    {"icon": Icons.list_alt, "title": "Parts Sales Reports"},
    {"icon": Icons.inventory, "title": "Inventory Ageing Report"},
    {"icon": Icons.receipt_long, "title": "GST Reports"},
    {"icon": Icons.description, "title": "Payment Reports"},
    {"icon": Icons.assignment, "title": "Open Order Report"},
    {"icon": Icons.report, "title": "Service Reports"},
    {"icon": Icons.alarm, "title": "Service Reminder Report"},
    {"icon": Icons.today, "title": "Daily Report"},
    {"icon": Icons.calendar_today, "title": "Monthly Report"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: reports.map((report) {
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(report['icon'], size: 40, color: Colors.deepPurple),
                    const SizedBox(height: 8),
                    Text(report['title'], textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
