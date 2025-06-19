// GetAllPackageTypesService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:garage_app/modalclass/getpackagetypesModalclass.dart';

class GetAllPackageTypesService {
  static const String baseUrl = 'https://garage.tbo365.cloud/api/method/garage.garage.auth.get_all_package_type';

  static Future<GetAllPackagesTypes?> fetchPackages() async {  // 👈 Renamed here
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return GetAllPackagesTypes.fromJson(json.decode(response.body));
      } else {
        print('❌ Failed to load data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching package types: $e');
      return null;
    }
  }
}
