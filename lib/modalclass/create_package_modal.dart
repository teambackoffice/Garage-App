// To parse this JSON data, do
//
//     final createPackagesTypes = createPackagesTypesFromJson(jsonString);

import 'dart:convert';

CreatePackagesTypes createPackagesTypesFromJson(String str) => CreatePackagesTypes.fromJson(json.decode(str));

String createPackagesTypesToJson(CreatePackagesTypes data) => json.encode(data.toJson());

class CreatePackagesTypes {
    String packName;
    String packType;
    List<Item> partsItems;
    List<Item> serviceItems;

    CreatePackagesTypes({
        required this.packName,
        required this.packType,
        required this.partsItems,
        required this.serviceItems,
    });

    factory CreatePackagesTypes.fromJson(Map<String, dynamic> json) => CreatePackagesTypes(
        packName: json["pack_name"],
        packType: json["pack_type"],
        partsItems: List<Item>.from(json["parts_items"].map((x) => Item.fromJson(x))),
        serviceItems: List<Item>.from(json["service_items"].map((x) => Item.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "pack_name": packName,
        "pack_type": packType,
        "parts_items": List<dynamic>.from(partsItems.map((x) => x.toJson())),
        "service_items": List<dynamic>.from(serviceItems.map((x) => x.toJson())),
    };
}

class Item {
    String itemName;
    int qty;
    int rate;

    Item({
        required this.itemName,
        required this.qty,
        required this.rate,
    });

    factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemName: json["item_name"],
        qty: json["qty"],
        rate: json["rate"],
    );

    Map<String, dynamic> toJson() => {
        "item_name": itemName,
        "qty": qty,
        "rate": rate,
    };
}
