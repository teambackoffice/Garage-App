// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'models.dart'; // Import ModelPage
//
// class MakePage extends StatefulWidget {
//   const MakePage({super.key});
//
//   @override
//   State<MakePage> createState() => _MakePageState();
// }
//
// class _MakePageState extends State<MakePage> {
//   List<String> _makes = [];
//   bool _isLoading = true;
//   String _errorMessage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMakes();
//   }
//
//   Future<void> _fetchMakes() async {
//     const url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_makes';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _makes = List<String>.from(data['message']['makes'].map((m) => m['name']));
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _errorMessage = "Error fetching makes: ${response.statusCode}";
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Error: $e";
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _selectMake(String make) async {
//     final selectedModel = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ModelPage(make: make),
//       ),
//     );
//
//     if (selectedModel != null && selectedModel is String) {
//       Navigator.pop(context, {'make': make, 'model': selectedModel});
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select Make')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//           ? Center(child: Text(_errorMessage))
//           : ListView.builder(
//         itemCount: _makes.length,
//         itemBuilder: (context, index) {
//           final make = _makes[index];
//           return ListTile(
//             title: Text(make),
//             trailing: const Icon(Icons.arrow_forward_ios),
//             onTap: () => _selectMake(make),
//           );
//         },
//       ),
//     );
//   }
// }
