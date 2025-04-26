// pages_provider.dart
import 'package:flutter/material.dart';
import 'package:project/models/page.dart';
import 'package:project/services/api_service.dart';



class PagesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PageModel> _pages = [];
  bool _isLoading = false;

  List<PageModel> get pages => _pages;
  bool get isLoading => _isLoading;

  // Fetch pages from the API.
  Future<void> fetchPages() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pages = await _apiService.fetchPages();
    } catch (error) {
      print(error);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Create a new page (with empty content) and return the created page.
  Future<PageModel> createPage(String title, String content) async {
    final newPage = await _apiService.createPage(title, content);
    await fetchPages();
    return newPage;
  }

  // Update an existing page.
  Future<void> updatePage(int id, String title, String content) async {
    await _apiService.updatePage(id, title, content);
    await fetchPages();
  }

  // Delete a page.
  Future<void> deletePage(int id) async {
    await _apiService.deletePage(id);
    await fetchPages();
  }

  // Add a method to clear pages
  void clearPages() {
    _pages = [];
    notifyListeners();
  }
}


