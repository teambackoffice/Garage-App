import 'package:flutter/material.dart';
import 'package:garage_app/modalclass/getpackagetypesModalclass.dart';
import 'package:garage_app/service/get_all_package_types.dart';

class PackageController extends ChangeNotifier {
  bool isLoading = false;
  GetAllPackagesTypes? packageDetails; // ✅ Field name with capital D

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
}
