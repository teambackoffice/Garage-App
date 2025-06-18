// InspectionResponse.dart

class InspectionResponse {
  final List<InspectionData> inspections;

  InspectionResponse({required this.inspections});

  factory InspectionResponse.fromJson(Map<String, dynamic> json) {
    return InspectionResponse(
      inspections: (json['message']['inspections'] as List)
          .map((e) => InspectionData.fromJson(e))
          .toList(),
    );
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
    return InspectionData(
      inspection: InspectionDetail.fromJson(json['inspection']),
      items: (json['items'] as List)
          .map((e) => InspectionItem.fromJson(e))
          .toList(),
    );
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
    return InspectionDetail(
      name: json['name'],
      status: json['status'],
      repairOrder: json['repair_order'],
    );
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
    return InspectionItem(
      inspectionName: json['inspection_name'],
      status: json['status'],
      checked: json['checked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspection_name': inspectionName,
      'status': status,
      'checked': checked,
    };
  }
}
