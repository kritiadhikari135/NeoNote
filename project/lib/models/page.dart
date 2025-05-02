import 'dart:convert';

class PageModel {
  final int id;
  final String title;
  final String content;
  final int? parentId; // Add parentId to track parent-child relationships
  final List<Map<String, dynamic>>? subpages; // Add subpages list

  PageModel({
    required this.id,
    required this.title,
    required this.content,
    this.parentId, // Optional parameter for parent-child relationship
    this.subpages, // Optional list of subpages
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    // Handle content field
    String contentStr;
    if (json['content'] == null) {
      print('Warning: content is null for page ID: ${json['id']}');
      contentStr = '';
    } else if (json['content'] is String) {
      contentStr = json['content'];
    } else {
      // If content is not a string (e.g., it's a Map), convert it to a JSON string
      try {
        contentStr = jsonEncode(json['content']);
        print('Converted content to JSON string for page ID: ${json['id']}');
      } catch (e) {
        print('Error converting content to string: $e');
        contentStr = json['content'].toString();
      }
    }

    // Handle subpages field
    List<Map<String, dynamic>>? subpagesList;
    if (json.containsKey('subpages') && json['subpages'] != null) {
      try {
        // Convert the list of dynamic to list of Map<String, dynamic>
        subpagesList = List<Map<String, dynamic>>.from(json['subpages']);
        print('Parsed ${subpagesList.length} subpages for page ID: ${json['id']}');
      } catch (e) {
        print('Error parsing subpages: $e');
        subpagesList = null;
      }
    }

    return PageModel(
      id: json['id'],
      title: json['title'],
      content: contentStr,
      parentId: json['parent_id'], // Parse parent_id from JSON
      subpages: subpagesList, // Add subpages list
    );
  }

  // Helper method to check if this is a subpage
  bool get isSubpage => parentId != null;

  // Helper method to check if this page has subpages
  bool get hasSubpages => subpages != null && subpages!.isNotEmpty;

  // Helper method to get content as a Map if it's valid JSON
  Map<String, dynamic>? getContentAsMap() {
    try {
      return jsonDecode(content);
    } catch (e) {
      print('Error parsing content as JSON: $e');
      return null;
    }
  }
}


