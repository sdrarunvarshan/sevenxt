import 'package:flutter/material.dart';
import 'package:sevenxt/route/api_service.dart';

class CategoryImagesProvider extends ChangeNotifier {
  Map<String, String> _imagesMap = {};
  bool _isLoading = true; // Start as loading so spinner shows immediately
  String? _error;

  Map<String, String> get imagesMap => _imagesMap;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryImagesProvider() {
    // Optional: auto-fetch when provider is created
    // fetchCategoryImages();
  }

  Future<void> fetchCategoryImages() async {
    try {
      final rawMap = await ApiService.getCategoryImages();

      // Normalize keys to lowercase for reliable matching
      final normalizedMap = <String, String>{};
      rawMap.forEach((key, value) {
        normalizedMap[key.toLowerCase().trim()] = value;
      });

      _imagesMap = normalizedMap;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _imagesMap = {};
    } finally {
      _isLoading = false;
      notifyListeners(); // Only called once, after async work
    }
  }

  /// Returns image URL for given category name (case-insensitive)
  String? getImageForCategory(String categoryName) {
    final normalized = categoryName.toLowerCase().trim();
    return _imagesMap[normalized];
  }
}