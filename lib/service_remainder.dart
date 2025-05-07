import 'package:flutter/material.dart';

class ServiceRemindersPage extends StatefulWidget {
  const ServiceRemindersPage({super.key});

  @override
  State<ServiceRemindersPage> createState() => _ServiceRemindersPageState();
}

class _ServiceRemindersPageState extends State<ServiceRemindersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> tabs = [
    {'label': 'DUE', 'count': 0},
    {'label': 'OVERDUE', 'count': 0},
    {'label': 'DONE', 'count': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Reminders',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: Colors.black54),
            onPressed: () {
              // Filter logic here
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          tabs: tabs
              .map((tab) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tab['label']),
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tab['count']}',
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                  ),
                )
              ],
            ),
          ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((tab) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  'No Reminders found',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
