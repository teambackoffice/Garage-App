// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class ListPage extends StatefulWidget {
// @override
// _ListPageState createState() => _ListPageState();
// }
//
// class _ListPageState extends State<ListPage> {
//   List<String> items = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchItems();
//   }
//
//   Future<void> fetchItems() async {
//     final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_parts');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> jsonResponse = json.decode(response.body);
//
//       // Debug prints
//       print('Decoded JSON: $jsonResponse');
//
//       final List<dynamic> data = jsonResponse['data']; // ✅ This is your actual list
//       setState(() {
//         items = data.map((item) => item['item_name'].toString()).toList();
//         isLoading = false;
//       });
//     } else {
//       print('Failed to load data. Status code: ${response.statusCode}');
//       setState(() {
//         items = ['Failed to load data'];
//         isLoading = false;
//       });
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('List Page')),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: items.length,
//         itemBuilder: (context, index) => ListTile(
//           title: Text(items[index]),
//         ),
//       ),
//     );
//   }
// }
