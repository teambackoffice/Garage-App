import 'package:flutter/material.dart';

class GarageSettingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> settingsOptions = [
    {
      'title': 'My Garage Profile',
      'icon': Icons.home_repair_service,
    },
    {
      'title': 'Garage Users',
      'icon': Icons.people,
    },
    {
      'title': 'Service & Parts Master',
      'icon': Icons.build_circle,
    },
    {
      'title': 'My Service Packages',
      'icon': Icons.inventory,
    },
    {
      'title': 'Tags Management',
      'icon': Icons.label,
    },
    {
      'title': 'Customisation Jobcards/Checklists',
      'icon': Icons.edit_note,
    },
    {
      'title': 'Calendar',
      'icon': Icons.calendar_today,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
      ),
      // body: Column(
      //   children: [
      //     SizedBox(height: 12),
      //     Center(
      //       child: Text(
      //         'Garage Settings',
      //         style: TextStyle(
      //           color: Colors.teal,
      //           fontSize: 16,
      //           fontWeight: FontWeight.w500,
      //         ),
      //       ),
      //     ),
      //     SizedBox(height: 12),
      //     Expanded(
      //       child: Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 12),
      //         child: GridView.builder(
      //           itemCount: settingsOptions.length,
      //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //             crossAxisCount: 2,
      //             mainAxisSpacing: 14,
      //             crossAxisSpacing: 14,
      //             childAspectRatio: 1.2,
      //           ),
      //           itemBuilder: (context, index) {
      //             final item = settingsOptions[index];
      //             return GestureDetector(
      //               onTap: () {
      //                 // Navigation logic here
      //               },
      //               child: Container(
      //                 decoration: BoxDecoration(
      //                   color: Colors.white,
      //                   border: Border.all(color: Colors.grey.shade300),
      //                   borderRadius: BorderRadius.circular(10),
      //                 ),
      //                 padding: EdgeInsets.all(10),
      //                 child: Column(
      //                   mainAxisAlignment: MainAxisAlignment.center,
      //                   children: [
      //                     Icon(
      //                       item['icon'],
      //                       size: 42,
      //                       color: Colors.teal,
      //                     ),
      //                     SizedBox(height: 10),
      //                     Text(
      //                       item['title'],
      //                       style: TextStyle(
      //                         fontSize: 13.5,
      //                         fontWeight: FontWeight.w500,
      //                         color: Colors.black87,
      //                       ),
      //                       textAlign: TextAlign.center,
      //                     )
      //                   ],
      //                 ),
      //               ),
      //             );
      //           },
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
