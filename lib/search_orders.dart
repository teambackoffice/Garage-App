import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchOrdersPage extends StatefulWidget {
  @override
  _SearchOrdersPageState createState() => _SearchOrdersPageState();
}

class _SearchOrdersPageState extends State<SearchOrdersPage> {
  String selectedOption = 'jobcard';
  final TextEditingController _jobCardController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Orders"),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search orders by", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            RadioListTile<String>(
              value: 'jobcard',
              groupValue: selectedOption,
              title: Text("By Jobcards/Repair Order number"),
              onChanged: (value) {
                setState(() => selectedOption = value!);
              },
            ),
            RadioListTile<String>(
              value: 'invoice',
              groupValue: selectedOption,
              title: Text("By invoice number"),
              onChanged: (value) {
                setState(() => selectedOption = value!);
              },
            ),
            RadioListTile<String>(
              value: 'date',
              groupValue: selectedOption,
              title: Text("By date range"),
              onChanged: (value) {
                setState(() => selectedOption = value!);
              },
            ),
            if (selectedOption == 'jobcard') ...[
              TextField(
                controller: _jobCardController,
                decoration: InputDecoration(labelText: "Enter Jobcard number"),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Do search
                  String jobCard = _jobCardController.text;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $jobCard')),
                  );
                },
                child: Text("Search"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
