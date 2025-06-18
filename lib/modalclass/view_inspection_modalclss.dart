class InspectionResponse {
  final List<InspectionData> inspections;
  
  InspectionResponse({required this.inspections});
  
  factory InspectionResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different possible response structures
      var inspectionsList;
      
      if (json.containsKey('message') && json['message'] != null) {
        if (json['message'] is Map && json['message'].containsKey('inspections')) {
          inspectionsList = json['message']['inspections'];
        } else if (json['message'] is List) {
          inspectionsList = json['message'];
        }
      } else if (json.containsKey('inspections')) {
        inspectionsList = json['inspections'];
      } else if (json is List) {
        inspectionsList = json;
      }
      
      if (inspectionsList == null) {
        print('No inspections found in response structure');
        return InspectionResponse(inspections: []);
      }
      
      return InspectionResponse(
        inspections: (inspectionsList as List)
            .map((e) => InspectionData.fromJson(e))
            .toList(),
      );
    } catch (e) {
      print('Error parsing InspectionResponse: $e');
      print('JSON structure: $json');
      throw Exception('Failed to parse inspection response: $e');
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'message': {
        'inspections': inspections.map((e) => e.toJson()).toList(),
      }
    };
  }
}

class InspectionData {
  final InspectionDetail inspection;
  final List<InspectionItem> items;
  
  InspectionData({required this.inspection, required this.items});
  
  factory InspectionData.fromJson(Map<String, dynamic> json) {
    try {
      return InspectionData(
        inspection: InspectionDetail.fromJson(json['inspection'] ?? {}),
        items: json['items'] != null 
            ? (json['items'] as List)
                .map((e) => InspectionItem.fromJson(e))
                .toList()
            : [],
      );
    } catch (e) {
      print('Error parsing InspectionData: $e');
      print('JSON: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'inspection': inspection.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class InspectionDetail {
  final String name;
  final String status;
  final String repairOrder;
  
  InspectionDetail({
    required this.name,
    required this.status,
    required this.repairOrder,
  });
  
  factory InspectionDetail.fromJson(Map<String, dynamic> json) {
    try {
      return InspectionDetail(
        name: json['name']?.toString() ?? 'Unknown Inspection',
        status: json['status']?.toString() ?? 'unknown',
        repairOrder: json['repair_order']?.toString() ?? 'N/A',
      );
    } catch (e) {
      print('Error parsing InspectionDetail: $e');
      print('JSON: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'repair_order': repairOrder,
    };
  }
}

class InspectionItem {
  final String inspectionName;
  final String status;
  final bool? checked;
  
  InspectionItem({
    required this.inspectionName,
    required this.status,
    this.checked,
  });
  
  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different types for the checked field
      bool? checkedValue;
      
      if (json['checked'] != null) {
        if (json['checked'] is bool) {
          checkedValue = json['checked'];
        } else if (json['checked'] is String) {
          String checkedStr = json['checked'].toString().toLowerCase();
          checkedValue = checkedStr == 'true' || checkedStr == '1' || checkedStr == 'yes';
        } else if (json['checked'] is int) {
          checkedValue = json['checked'] == 1;
        }
      }
      
      return InspectionItem(
        inspectionName: json['inspection_name']?.toString() ?? 'Unknown Item',
        status: json['status']?.toString() ?? 'unknown',
        checked: checkedValue,
      );
    } catch (e) {
      print('Error parsing InspectionItem: $e');
      print('JSON: $json');
      rethrow;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'inspection_name': inspectionName,
      'status': status,
      'checked': checked,
    };
  }
}