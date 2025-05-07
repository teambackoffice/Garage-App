import 'package:flutter/material.dart';

class MyVendorsPage extends StatelessWidget {
  final int vendorCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'My Vendors',
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                '$vendorCount',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Handle view all due action
            },
            child: Text(
              'VIEW ALL DUE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Vendors not found',
            style: TextStyle(color: Colors.teal, fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Add vendor logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: Text(
              'Add Vendor',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
