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

  Future<PageModel> createPage(String title, String content, {int? parentId}) async {
    try {
      // Validate content format
      dynamic contentValue;
      try {
        // Try to parse the content as JSON to ensure it's valid
        contentValue = jsonDecode(content);
        print('Content successfully parsed as JSON');

        // Check if the content has the expected structure
        if (contentValue is Map<String, dynamic>) {
          if (contentValue.containsKey('content') && contentValue.containsKey('metadata')) {
            print('Content has the expected structure with content and metadata fields');

            // Check if inner content is valid JSON
            try {
              final innerContent = contentValue['content'];
              if (innerContent is String) {
                jsonDecode(innerContent);
                print('Inner content is valid JSON');
              }
            } catch (e) {
              print('Warning: Inner content is not valid JSON: $e');
            }
          } else {
            print('Content does not have the expected structure');
          }
        } else {
          print('Content is not a Map: ${contentValue.runtimeType}');
        }
      } catch (e) {
        print('Error parsing content as JSON: $e');
        // If content is not valid JSON, keep it as is
        contentValue = content;
      }

      // Create the request body
      final Map<String, dynamic> requestBody = {
        "title": title,
        "content": content,
      };

      // Add parent_id to the request if provided
      if (parentId != null) {
        requestBody["parent_id"] = parentId;
      }

      print('Creating page with title: $title');
      print('Parent ID: $parentId');
      print('Content (truncated): ${content.length > 100 ? content.substring(0, 100) + "..." : content}');

      final headers = await _getHeaders();
      print('Headers: $headers');

      // Add retry logic
      int maxRetries = 3;
      int retryCount = 0;
      http.Response? response;

      while (retryCount < maxRetries) {
        try {
          response = await http.post(
            Uri.parse(baseUrl),
            headers: headers,
            body: jsonEncode(requestBody),
          );

          // If successful, break out of the retry loop
          if (response.statusCode == 201 || response.statusCode == 200) {
            break;
          }

          // If we get a 500 error, retry
          if (response.statusCode == 500) {
            retryCount++;
            print('Received 500 error, retrying (${retryCount}/${maxRetries})...');
            await Future.delayed(Duration(seconds: 1)); // Wait before retrying
          } else {
            // For other error codes, don't retry
            break;
          }
        } catch (e) {
          retryCount++;
          print('Network error during create, retrying (${retryCount}/${maxRetries}): $e');
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying

          if (retryCount >= maxRetries) {
            throw e; // Re-throw if we've exhausted retries
          }
        }
      }

      if (response == null) {
        throw Exception('Failed to create page: No response after retries');
      }

      print('Create response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed response: $responseData');

        // Check if the response contains the content field
        if (responseData.containsKey('content')) {
          print('Response contains content field');
          print('Content type: ${responseData['content'].runtimeType}');
          print('Content (truncated): ${responseData['content'].toString().length > 100 ? responseData['content'].toString().substring(0, 100) + "..." : responseData['content']}');
        } else {
          print('Response does not contain content field');
        }

        final pageModel = PageModel.fromJson(responseData);
        print('Created PageModel with ID: ${pageModel.id}, title: ${pageModel.title}');
        return pageModel;
      } else {
        print('Failed to create page: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create page: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createPage: $e');
      throw Exception('Failed to create page: $e');
    }
  }

  Future<void> updatePage(int id, String title, String content, {int? parentId}) async {
    try {
      // Validate content format
      dynamic contentValue;
      try {
        // Try to parse the content as JSON to ensure it's valid
        contentValue = jsonDecode(content);
        print('Content successfully parsed as JSON');

        // Check if the content has the expected structure
        if (contentValue is Map<String, dynamic>) {
          if (contentValue.containsKey('content') && contentValue.containsKey('metadata')) {
            print('Content has the expected structure with content and metadata fields');

            // Ensure the inner content is also valid JSON
            if (contentValue['content'] is String) {
              try {
                // Try to parse the inner content
                jsonDecode(contentValue['content']);
                print('Inner content is valid JSON');
              } catch (e) {
                print('Inner content is not valid JSON: $e');
                // If inner content is not valid JSON, keep it as is
              }
            }
          } else {
            print('Content does not have the expected structure');
          }
        } else {
          print('Content is not a Map: ${contentValue.runtimeType}');
        }
      } catch (e) {
        print('Error parsing content as JSON: $e');
        // If content is not valid JSON, keep it as is
        contentValue = content;
      }

      // Create the request body
      final Map<String, dynamic> requestBody = {
        "title": title,
        "content": content, // Use the original content string
      };

      // Add parent_id to the request if provided
      if (parentId != null) {
        requestBody["parent_id"] = parentId;
      }

      print('Updating page ID: $id');
      print('Title: $title');
      print('Parent ID: $parentId');
      print('Content (truncated): ${content.length > 100 ? content.substring(0, 100) + "..." : content}');

      final headers = await _getHeaders();
      print('Headers: $headers');

      // Add retry logic
      int maxRetries = 3;
      int retryCount = 0;
      http.Response? response;

      while (retryCount < maxRetries) {
        try {
          response = await http.put(
            Uri.parse("$baseUrl$id/"),
            headers: headers,
            body: jsonEncode(requestBody),
          );

          // If successful, break out of the retry loop
          if (response.statusCode == 200) {
            break;
          }

          // If we get a 500 error, retry
          if (response.statusCode == 500) {
            retryCount++;
            print('Received 500 error, retrying (${retryCount}/${maxRetries})...');
            await Future.delayed(Duration(seconds: 1)); // Wait before retrying
          } else {
            // For other error codes, don't retry
            break;
          }
        } catch (e) {
          retryCount++;
          print('Network error during update, retrying (${retryCount}/${maxRetries}): $e');
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying

          if (retryCount >= maxRetries) {
            throw e; // Re-throw if we've exhausted retries
          }
        }
      }

      if (response == null) {
        throw Exception('Failed to update page: No response after retries');
      }

      print('Update response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Page updated successfully');

        // Parse the response to check the saved content
        final responseData = jsonDecode(response.body);
        print('Response data: $responseData');
        if (responseData.containsKey('content')) {
          print('Saved content (truncated): ${responseData['content'].toString().length > 100 ? responseData['content'].toString().substring(0, 100) + "..." : responseData['content']}');
        }
      } else {
        print('Failed to update page: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update page: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updatePage: $e');
      throw Exception('Failed to update page: $e');
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
