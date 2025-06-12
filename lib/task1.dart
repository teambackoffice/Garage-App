// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class ListPage extends StatefulWidget {
//   @override
//   _ListPageState createState() => _ListPageState();
// }
//
// class _ListPageState extends State<ListPage> {
//   List<Map<String, dynamic>> items = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchItems();
//   }
//
//   // Function to fetch data from the API
//   Future<void> fetchItems() async {
//     final url = Uri.parse('https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_parts');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> jsonResponse = json.decode(response.body);
//
//       final List<dynamic> data = jsonResponse['data'];
//
//       setState(() {
//         items = data.map((item) => item as Map<String, dynamic>).toList();
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         items = [];
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Parts List'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: items.length,
//         itemBuilder: (context, index) {
//           final item = items[index];
//
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//             elevation: 5,
//             child: ListTile(
//               contentPadding: EdgeInsets.all(15),
//               title: Text(
//                 item['item_name'] ?? 'No name',  // Display item name
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Item Code: ${item['item_code']}'),  // Display item code
//                   Text('Rate: \$${item['rate']}'),  // Display the rate
//                   Text('Description: ${item['description'] ?? 'No description'}'),  // Display description
//                 ],
//               ),
//               leading: Icon(Icons.archive, size: 40, color: Colors.blue),  // Placeholder icon
//               onTap: () {
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
