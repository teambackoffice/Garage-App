import 'package:flutter/material.dart';
import 'package:garage_app/modalclass/create_package_modal.dart';
import 'package:garage_app/modalclass/getpackagetypesModalclass.dart';
import 'package:garage_app/service/create_package_service.dart';
import 'package:garage_app/service/get_all_package_types.dart';

class PackageController extends ChangeNotifier {
  bool isLoading = false;
  GetAllPackagesTypes? packageDetails;
   // ✅ Field name with capital D
   

  Future<void> getPackageDetails() async {
    isLoading = true;
    notifyListeners();

    try {
      packageDetails = await GetAllPackageTypesService.fetchPackages();
    } catch (e) {
      print('❌ Error: $e');
    }

    isLoading = false;
    notifyListeners();
  }


   Future<bool?> createNewPackage( CreatePackagesTypes newPackage) async {
    isLoading = true;
    notifyListeners();

    bool? result;

    try {
      result = await CreatePackageService.createPackage(createPackage: newPackage);
    } catch (e) {
      print('❌ Error while creating package: $e');
      result = null;
    }

    isLoading = false;
    notifyListeners();

    return result; // You can use this to show success/failure in UI
  }
}
