import 'dart:convert';
import 'package:garage_app/modalclass/create_package_modal.dart';
import 'package:http/http.dart' as http;

class CreatePackageService {
  static Future<bool?> createPackage({
    required CreatePackagesTypes createPackage,
  }) async {
    final uri = Uri.parse("https://garage.tbo365.cloud/api/method/garage.garage.auth.create_new_package");

    final body = jsonEncode({
      'pack_name': createPackage.packName,
      'pack_type': createPackage.packType,
      'parts_items': createPackage.partsItems.map((item) => item.toJson()).toList(),
      'service_items': createPackage.serviceItems.map((item) => item.toJson()).toList(),
    });

    try {
      final response = await http.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}
