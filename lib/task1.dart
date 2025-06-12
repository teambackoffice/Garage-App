// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class WhatsAppMessagePage extends StatelessWidget {
//   final String phoneNumber = "919562596317"; // Replace with receiver's number
//
//   void _openWhatsApp(String message) async {
//     final url = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
//
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       throw 'Could not launch WhatsApp';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Send WhatsApp Message')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () => _openWhatsApp("Yes, I confirm the appointment."),
//               child: Text('Yes'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => _openWhatsApp("No, I cannot confirm the appointment."),
//               child: Text('No'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
