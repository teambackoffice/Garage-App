// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class ModelPage extends StatefulWidget {
//   final String make;
//   const ModelPage({super.key, required this.make});
//
//   @override
//   State<ModelPage> createState() => _ModelPageState();
// }
//
// class _ModelPageState extends State<ModelPage> {
//   List<String> _models = [];
//   bool _isLoading = true;
//   String _errorMessage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchModels();
//   }
//
//   Future<void> _fetchModels() async {
//     final url = 'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_models_by_make?make=${Uri.encodeComponent(widget.make)}';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['message'] != null && data['message']['models'] is List) {
//           setState(() {
//             _models = List<String>.from(data['message']['models'].map((m) => m['model']));
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _errorMessage = "No models found";
//             _isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           _errorMessage = "Error fetching models: ${response.statusCode}";
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Select Model for ${widget.make}')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//           ? Center(child: Text(_errorMessage))
//           : ListView.builder(
//         itemCount: _models.length,
//         itemBuilder: (context, index) {
//           final model = _models[index];
//           return ListTile(
//             title: Text(model),
//             onTap: () {
//               Navigator.pop(context, model); // Return selected model
//             },
//           );
//         },
//       ),
//     );
//   }
// }
