import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Pack extends StatefulWidget {
  const Pack({super.key});

  @override
  State<Pack> createState() => _PackState();
}

class _PackState extends State<Pack> {
  Future<List<dynamic>?> fetchPackages() async {
    const String baseUrl =
        'https://garage.teambackoffice.com/api/method/garage.garage.auth.get_all_packages';

    try {
      final response = await http.get(Uri.parse(baseUrl));

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('packages') && data['packages'] is List) {
          return data['packages'];
        } else {
          debugPrint("Error: 'packages' key missing or incorrect format.");
          return [];
        }
      } else {
        debugPrint("Failed to load data - Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      return null;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Packages',style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600
      ),),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: Icon(Icons.arrow_back_ios_new,color: Colors.black),
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: fetchPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No packages available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final package = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(package['name'] ?? 'No Name'),
                    subtitle: Text('Price: ${package['price'] ?? 'N/A'}'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}