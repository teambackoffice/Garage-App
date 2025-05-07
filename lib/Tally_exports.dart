import 'package:flutter/material.dart';

class TallyExportPage extends StatefulWidget {
  const TallyExportPage({super.key});

  @override
  State<TallyExportPage> createState() => _TallyExportPageState();
}

class _TallyExportPageState extends State<TallyExportPage>
    with SingleTickerProviderStateMixin {
  String formatType = 'XML';
  TabController? _tabController;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tally Export'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildFormatSelector(),
          const Divider(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRadioOption("XML"),
        const SizedBox(width: 20),
        _buildRadioOption("Excel"),
      ],
    );
  }

  Widget _buildRadioOption(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: formatType,
          onChanged: (val) => setState(() => formatType = val!),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.teal,
        unselectedLabelColor: Colors.black54,
        indicatorColor: Colors.teal,
        tabs: const [
          Tab(text: 'SALES'),
          Tab(text: 'RECEIPTS'),
          Tab(text: 'EXPENSES'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFormSection(),
        _buildFormSection(),
        _buildFormSection(),
      ],
    );
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("Please select invoice date range for Tally export"),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: selectedDate != null
                      ? "${selectedDate!.toLocal()}".split(' ')[0]
                      : "Select date",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // implement export logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tally Export triggered")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.download),
            label: const Text("Generate Tally Export"),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 10),
          const Text("View Reports", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: const [
                Icon(Icons.shopping_cart_outlined,
                    size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text("No Reports Found",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
