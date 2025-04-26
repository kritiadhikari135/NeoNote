import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/page.dart';
import 'package:project/services/local_storage.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/pages/";

  Future<Map<String, String>> _getHeaders() async {
    String? token = await LocalStorage.getToken();

    if (token == null || token.isEmpty) {
      print("⚠️ No token found. User is unauthorized.");
      return {"Content-Type": "application/json"};
    }

    print("✅ Using Token: $token");

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<List<PageModel>> fetchPages() async {
    try {
      print('✅ Fetching pages from: $baseUrl');
      final headers = await _getHeaders();
      print('✅ Using headers: $headers');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      );

      print('✅ Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final pages = data.map((item) => PageModel.fromJson(item)).toList();
        print('✅ Fetched ${pages.length} pages successfully');
        return pages;
      } else {
        print('❌ Failed to load pages: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load pages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchPages: $e');
      throw Exception('Failed to load pages: $e');
    }
  }

  Future<PageModel> createPage(String title, String content) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _getHeaders(),
      body: jsonEncode({
        "title": title,
        "content": content,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return PageModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create page');
    }
  }

  Future<void> updatePage(int id, String title, String content) async {
    final response = await http.put(
      Uri.parse("$baseUrl$id/"),
      headers: await _getHeaders(),
      body: jsonEncode({
        "title": title,
        "content": content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update page');
    }
  }

  Future<void> deletePage(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl$id/"),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete page');
    }
  }

  // Add a method to reset token
  Future<void> resetToken() async {
    await LocalStorage.clearToken();
  }
}
