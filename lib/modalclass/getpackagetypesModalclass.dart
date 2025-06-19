import 'dart:convert';

GetAllPackagesTypes getAllPackagesTypesFromJson(String str) =>
    GetAllPackagesTypes.fromJson(json.decode(str));

String getAllPackagesTypesToJson(GetAllPackagesTypes data) =>
    json.encode(data.toJson());

class GetAllPackagesTypes {
  String status;
  String message;
  List<PackageType> data;

  GetAllPackagesTypes({
    required this.status,
    required this.message,
    required this.data,
  });

  factory GetAllPackagesTypes.fromJson(Map<String, dynamic> json) =>
      GetAllPackagesTypes(
        status: json["status"],
        message: json["message"],
        data: List<PackageType>.from(
            json["data"].map((x) => PackageType.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class PackageType {
  String name;

  PackageType({
    required this.name,
  });

  factory PackageType.fromJson(Map<String, dynamic> json) => PackageType(
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
      };
}
