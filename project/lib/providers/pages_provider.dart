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
  // Optional parentId parameter for creating subpages
  Future<PageModel> createPage(String title, String content, {int? parentId}) async {
    final newPage = await _apiService.createPage(title, content, parentId: parentId);
    await fetchPages();
    return newPage;
  }

  // Get subpages for a specific parent page
  List<PageModel> getSubpages(int parentId) {
    print('Getting subpages for parent ID: $parentId');

    final subpages = _pages.where((page) => page.parentId == parentId).toList();

    print('Found ${subpages.length} subpages for parent ID: $parentId');
    for (var subpage in subpages) {
      print('Subpage: ID=${subpage.id}, title=${subpage.title}, parentId=${subpage.parentId}');
    }

    return subpages;
  }

  // Get top-level pages (pages without a parent)
  List<PageModel> getTopLevelPages() {
    return _pages.where((page) => page.parentId == null).toList();
  }

  // Update an existing page.
  Future<void> updatePage(int id, String title, String content, {int? parentId}) async {
    try {
      print('PagesProvider: Updating page ID: $id, title: $title, parentId: $parentId');
      await _apiService.updatePage(id, title, content, parentId: parentId);
      print('PagesProvider: Page updated successfully, refreshing pages');
      await fetchPages();
      print('PagesProvider: Pages refreshed successfully');
    } catch (e) {
      print('PagesProvider: Error updating page: $e');
      throw e; // Re-throw the error to be handled by the caller
    }
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


