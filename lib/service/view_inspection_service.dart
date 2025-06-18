// inspection_service.dart
import 'dart:convert';
import 'package:garage_app/modalclass/view_inspection_modalclss.dart';
import 'package:http/http.dart' as http;

class InspectionService {
  static const String baseUrl = 'https://garage.tbo365.cloud';
  
  static Future<InspectionResponse> getInspectionsByRepairOrder(String repairOrder) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/method/garage.garage.auth.get_inspection_by_repair_order?repair_order=$repairOrder'),
        headers: {
          'Content-Type': 'application/json',
          // Add any required headers like authorization if needed
          // 'Authorization': 'Bearer $token',
        },
      );
      print("url $response");

      if (response.statusCode == 200) {
        print("response $response");
        final jsonData = json.decode(response.body);
        return InspectionResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load inspections: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching inspections: $e");
      throw Exception('Error fetching inspections: $e');
    }
  }
}