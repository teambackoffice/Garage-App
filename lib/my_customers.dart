import 'package:flutter/material.dart';

class MyCustomersPage extends StatelessWidget {
  final List<Map<String, String>> customers = [
    {'name': 'Murshid', 'phone': '7306539258'},
    {'name': 'Sammish', 'phone': '9544045533'},
    {'name': 'Murshid', 'phone': '1234569'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Text(
              'My Customers',
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                customers.length.toString(),
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            )
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Add Customer
            },
            icon: Icon(Icons.add, color: Colors.teal),
            label: Text('+ Customer', style: TextStyle(color: Colors.teal)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name/mobile no/Reg no',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListTile(
                    title: Text('${customer['name']} (${customer['phone']})'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          // Icon(Icons.whatsapp, size: 20, color: Colors.teal),
                          SizedBox(width: 6),
                          Text(
                            'WhatsApp',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.more_vert),
                    onTap: () {
                      // Handle customer tap
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add new customer logic
        },
        icon: Icon(Icons.add),
        label: Text('Customer'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
