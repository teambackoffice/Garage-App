import 'package:flutter/material.dart';

class VehicleSearchPage extends StatefulWidget {
  const VehicleSearchPage({super.key});

  @override
  State<VehicleSearchPage> createState() => _VehicleSearchPageState();
}

class _VehicleSearchPageState extends State<VehicleSearchPage> {
  String _searchType = 'registration';
  final TextEditingController _searchController = TextEditingController();

  void _performSearch() {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a search value")),
      );
      return;
    }

    // TODO: implement actual search logic here
    debugPrint("Searching for '$searchText' by $_searchType");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Search"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio options
            const Text("Search Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text("By Vehicle Registration Number"),
              leading: Radio<String>(
                value: 'registration',
                groupValue: _searchType,
                onChanged: (value) => setState(() => _searchType = value!),
              ),
            ),
            ListTile(
              title: const Text("By Customer Number"),
              leading: Radio<String>(
                value: 'customer',
                groupValue: _searchType,
                onChanged: (value) => setState(() => _searchType = value!),
              ),
            ),
            ListTile(
              title: const Text("By VIN Number"),
              leading: Radio<String>(
                value: 'vin',
                groupValue: _searchType,
                onChanged: (value) => setState(() => _searchType = value!),
              ),
            ),
            const SizedBox(height: 10),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Search button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text("Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // "More" tab selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "Service"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Parts"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Accounts"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
        ],
        onTap: (index) {
          // TODO: implement navigation
        },
      ),
    );
  }
}
