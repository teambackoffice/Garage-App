// To parse this JSON data, do
//
//     final getAllPackages = getAllPackagesFromJson(jsonString);

import 'dart:convert';

GetAllPackages getAllPackagesFromJson(String str) => GetAllPackages.fromJson(json.decode(str));

String getAllPackagesToJson(GetAllPackages data) => json.encode(data.toJson());

class GetAllPackages {
    List<Datum> data;
    String message;
    String status;

    GetAllPackages({
        required this.data,
        required this.message,
        required this.status,
    });

    factory GetAllPackages.fromJson(Map<String, dynamic> json) => GetAllPackages(
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        message: json["message"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "message": message,
        "status": status,
    };
}

class Datum {
    String name;
    String packageName;
    String packageType;
    List<dynamic> partsItems;
    List<ServiceItem> serviceItems;

    Datum({
        required this.name,
        required this.packageName,
        required this.packageType,
        required this.partsItems,
        required this.serviceItems,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        name: json["name"],
        packageName: json["package_name"],
        packageType: json["package_type"],
        partsItems: List<dynamic>.from(json["parts_items"].map((x) => x)),
        serviceItems: List<ServiceItem>.from(json["service_items"].map((x) => ServiceItem.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "package_name": packageName,
        "package_type": packageType,
        "parts_items": List<dynamic>.from(partsItems.map((x) => x)),
        "service_items": List<dynamic>.from(serviceItems.map((x) => x.toJson())),
    };
}

class ServiceItem {
    int amount;
    int availableQty;
    DateTime creation;
    int docstatus;
    String doctype;
    int idx;
    dynamic itemName;
    DateTime modified;
    String modifiedBy;
    String name;
    String owner;
    String parent;
    String parentfield;
    String parenttype;
    int qty;
    int rate;
    dynamic uom;

    ServiceItem({
        required this.amount,
        required this.availableQty,
        required this.creation,
        required this.docstatus,
        required this.doctype,
        required this.idx,
        required this.itemName,
        required this.modified,
        required this.modifiedBy,
        required this.name,
        required this.owner,
        required this.parent,
        required this.parentfield,
        required this.parenttype,
        required this.qty,
        required this.rate,
        required this.uom,
    });

    factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        amount: json["amount"],
        availableQty: json["available_qty"],
        creation: DateTime.parse(json["creation"]),
        docstatus: json["docstatus"],
        doctype: json["doctype"],
        idx: json["idx"],
        itemName: json["item_name"],
        modified: DateTime.parse(json["modified"]),
        modifiedBy: json["modified_by"],
        name: json["name"],
        owner: json["owner"],
        parent: json["parent"],
        parentfield: json["parentfield"],
        parenttype: json["parenttype"],
        qty: json["qty"],
        rate: json["rate"],
        uom: json["uom"],
    );

    Map<String, dynamic> toJson() => {
        "amount": amount,
        "available_qty": availableQty,
        "creation": creation.toIso8601String(),
        "docstatus": docstatus,
        "doctype": doctype,
        "idx": idx,
        "item_name": itemName,
        "modified": modified.toIso8601String(),
        "modified_by": modifiedBy,
        "name": name,
        "owner": owner,
        "parent": parent,
        "parentfield": parentfield,
        "parenttype": parenttype,
        "qty": qty,
        "rate": rate,
        "uom": uom,
    };
}
