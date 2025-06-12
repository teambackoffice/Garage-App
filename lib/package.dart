import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PackagePage extends StatefulWidget {
  const PackagePage({super.key});

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  List<dynamic> packageList = [];
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchPackageData();
  }

  Future<void> fetchPackageData() async {
    const url =
        'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_packages';

    try {
      final response = await http.get(Uri.parse(url));
      final decoded = jsonDecode(response.body);
      print("Package API Response: $decoded");

      if (response.statusCode == 200 && decoded['data'] is List) {
        setState(() {
          packageList = decoded['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = 'No packages found.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Package"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMsg != null
            ? Center(
          child: Text(
            errorMsg!,
            style: const TextStyle(color: Colors.red),
          ),
        )
            : packageList.isEmpty
            ? const Center(child: Text("No packages available"))
            : ListView.builder(
          itemCount: packageList.length,
          itemBuilder: (context, index) {
            final item = packageList[index];

            final packageName = item['package_name'] ?? 'Unnamed';
            final packageType = item['package_type'] ?? 'N/A';
            final packageId = item['name'] ?? '—';

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                title: Text(
                  packageName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: w * 0.045,
                  ),
                ),
                subtitle: Text(
                  "Type: $packageType\nID: $packageId",
                  style: TextStyle(fontSize: w * 0.035),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context, packageName);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
