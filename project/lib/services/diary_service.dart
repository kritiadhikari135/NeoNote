
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';

class DiaryEntry {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final String? mood;
  final int backgroundColor;
  final int textColor;
  final String template;
  final List<DiaryImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood,
    required this.backgroundColor,
    required this.textColor,
    required this.template,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // Ensure background_color and text_color are valid integers
    int bgColor = 0xFFFFFF; // Default white
    int txtColor = 0x000000; // Default black

    try {
      if (json['background_color'] != null) {
        bgColor = int.parse(json['background_color'].toString());
        print('Parsed background_color: ${bgColor.toRadixString(16)}');

        // Add alpha channel if missing
        if ((bgColor & 0xFF000000) == 0) {
          bgColor = bgColor | 0xFF000000;
          print('Added alpha channel to background color: ${bgColor.toRadixString(16)}');
        }
      } else {
        print('background_color is null, using default white');
      }
    } catch (e) {
      print('Error parsing background_color: $e');
    }

    try {
      if (json['text_color'] != null) {
        txtColor = int.parse(json['text_color'].toString());
        print('Parsed text_color: ${txtColor.toRadixString(16)}');

        // If text color is 0, use black (with alpha)
        if (txtColor == 0) {
          txtColor = 0xFF000000; // Black with alpha
          print('Text color was 0, using black with alpha: ${txtColor.toRadixString(16)}');
        }
        // Add alpha channel if missing
        else if ((txtColor & 0xFF000000) == 0) {
          txtColor = txtColor | 0xFF000000;
          print('Added alpha channel to text color: ${txtColor.toRadixString(16)}');
        }
      } else {
        print('text_color is null, using default black');
        txtColor = 0xFF000000; // Black with alpha
      }
    } catch (e) {
      print('Error parsing text_color: $e');
      txtColor = 0xFF000000; // Black with alpha
    }

    // Debug title and content
    final title = json['title'];
    final content = json['content'];
    print('Parsing title: $title, content: $content');

    // Parse created_at and updated_at if available
    DateTime? createdAt;
    DateTime? updatedAt;

    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at']);
      }
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at']);
      }
    } catch (e) {
      print('Error parsing created_at or updated_at: $e');
    }

    return DiaryEntry(
      id: json['id'],
      title: title ?? '',
      content: content ?? '',
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      backgroundColor: bgColor,
      textColor: txtColor,
      template: json['template'] ?? 'Default',
      images: json['images'] != null
          ? (json['images'] as List<dynamic>).map((image) => DiaryImage.fromJson(image)).toList()
          : [],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

// Map<String, dynamic> toJson() {
//   return {
//     'title': title,
//     'content': content,
//     'date': date.toIso8601String().split('T')[0],
//     'mood': ((mood ?? '').isEmpty) ? null : mood,
//     // Strip the alpha channel by keeping only the lower 24 bits.
//     'background_color': backgroundColor & 0xFFFFFF,
//     'text_color': textColor & 0xFFFFFF,
//     'template': template,
//   };
// }

Map<String, dynamic> toJson() {
  // Debug color values
  print('Original backgroundColor: ${backgroundColor.toRadixString(16)}');
  print('Original textColor: ${textColor.toRadixString(16)}');

  // Ensure backgroundColor and textColor are never null
  final bgColor = backgroundColor != 0 ? backgroundColor & 0xFFFFFF : 0xFFFFFF; // Default to white if 0

  // For text color, ensure it's black (0x000000) if it's 0 or very close to 0
  int txtColor;
  if (textColor == 0) {
    txtColor = 0x000000; // Default to black if 0
    print('Text color was 0, defaulting to black: ${txtColor.toRadixString(16)}');
  } else {
    // Strip the alpha channel
    txtColor = textColor & 0xFFFFFF;

    // If the resulting color is too light (close to white), use black instead
    if (txtColor > 0xF0F0F0) {
      txtColor = 0x000000;
      print('Text color was too light, defaulting to black: ${txtColor.toRadixString(16)}');
    }
  }

  print('Final bgColor: ${bgColor.toRadixString(16)}');
  print('Final txtColor: ${txtColor.toRadixString(16)}');

  // Create the base JSON object
  final json = {
    'title': title,
    'content': content,
    'date': date.toIso8601String().split('T')[0],
    'mood': mood ?? '', // Send an empty string if mood is null
    'background_color': bgColor, // Strip the alpha channel and ensure non-null
    'text_color': txtColor, // Strip the alpha channel and ensure non-null
    'template': template,
    'images': [], // Add empty images array to satisfy the API requirement
  };

  // Add created_at and updated_at if they exist
  if (createdAt != null) {
    json['created_at'] = createdAt!.toIso8601String();
  }
  if (updatedAt != null) {
    json['updated_at'] = updatedAt!.toIso8601String();
  }

  // Add the ID if it exists (important for updates)
  if (id != null) {
    // Cast to non-nullable int before assigning
    json['id'] = id as int;
    print('Including ID in JSON: $id');
  }

  return json;
}



}

class DiaryImage {
  final int id;
  final String imageUrl;

  DiaryImage({required this.id, required this.imageUrl});

  factory DiaryImage.fromJson(Map<String, dynamic> json) {
    return DiaryImage(
      id: json['id'],
      imageUrl: json['image'],
    );
  }
}

class DiaryService {
  final String baseUrl = "http://127.0.0.1:8000/diary/";

  Future<Map<String, String>> _getHeaders() async {
    try {
      print('Getting authentication token');
      String? token = await LocalStorage.getToken();
      print('✅ Retrieved Token: $token');

      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        throw Exception('No authentication token found');
      }

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      print('Headers prepared: $headers');
      return headers;
    } catch (e) {
      print('❌ Error getting headers: $e');
      throw Exception('Failed to get headers: $e');
    }
  }

  // Fetch a single diary entry by ID
  Future<DiaryEntry> getEntry(dynamic id) async {
    try {
      print('Fetching diary entry with ID: $id');
      final response = await http.get(
        Uri.parse('${baseUrl}entries/$id/'),
        headers: await _getHeaders(),
      );

      print('Get entry response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response body: $responseBody');

        final data = json.decode(responseBody);
        return DiaryEntry.fromJson(data);
      } else {
        throw Exception('Failed to load diary entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getEntry: $e');
      throw Exception('Failed to load diary entry: $e');
    }
  }

  // Fetch all diary entries
  Future<List<DiaryEntry>> getAllEntries() async {
    try {
      print('Fetching all diary entries');
      final response = await http.get(
        Uri.parse('${baseUrl}entries/'),
        headers: await _getHeaders(),
      );

      print('Get all entries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response body: $responseBody');

        List<dynamic> data = json.decode(responseBody);
        print('Parsed ${data.length} diary entries');

        // Debug the first entry if available
        if (data.isNotEmpty) {
          print('First entry: ${data[0]}');
        }

        final entries = data.map((jsonData) {
          try {
            final entry = DiaryEntry.fromJson(jsonData);
            print('Parsed entry: ${entry.toJson()}');
            return entry;
          } catch (e) {
            print('Error parsing diary entry: $e');
            // Return a default entry if parsing fails
            return DiaryEntry(
              id: null,
              title: 'Error loading entry',
              content: 'There was an error loading this entry',
              date: DateTime.now(),
              backgroundColor: 0xFFFFFFFF,
              textColor: 0xFF000000,
              template: 'Default',
            );
          }
        }).toList();

        return entries;
      } else {
        print('Failed to load diary entries: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load diary entries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllEntries: $e');
      throw Exception('Failed to load diary entries: $e');
    }
  }

  // Create a new diary entry
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      final jsonData = entry.toJson();
      print('Creating diary entry with data: $jsonData');

      final headers = await _getHeaders();
      print('Headers: $headers');

      final jsonBody = json.encode(jsonData);
      print('JSON body: $jsonBody');

      final response = await http.post(
        Uri.parse('${baseUrl}entries/'),
        headers: headers,
        body: jsonBody,
      );

      print('Create response status: ${response.statusCode}');
      print('Create response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return DiaryEntry.fromJson(responseData);
      } else {
        throw Exception('Failed to create diary entry: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createEntry: $e');
      throw Exception('Failed to create diary entry: $e');
    }
  }

  // Update an existing diary entry
  Future<DiaryEntry> updateEntry(dynamic id, DiaryEntry entry) async {
    // Check if id is null or invalid
    if (id == null) {
      print('ERROR: ID is null, cannot update entry');
      throw Exception('Cannot update diary entry: ID is null');
    }

    try {
      // Get the existing entry first to preserve any fields we don't want to change
      print('Fetching existing diary entry with ID: $id');
      final existingEntry = await getEntry(id);
      print('Existing entry: ${existingEntry.toJson()}');

      // Prepare the JSON data for update
      final jsonData = entry.toJson();

      // Ensure the images field is included
      if (!jsonData.containsKey('images')) {
        jsonData['images'] = [];
        print('Added empty images array to update payload');
      }

      print('Updating diary entry $id with data: $jsonData');

      final headers = await _getHeaders();
      print('Headers: $headers');

      final jsonBody = json.encode(jsonData);
      print('JSON body: $jsonBody');

      final response = await http.put(
        Uri.parse('${baseUrl}entries/$id/'),
        headers: headers,
        body: jsonBody,
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return DiaryEntry.fromJson(responseData);
      } else {
        throw Exception('Failed to update diary entry: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateEntry: $e');
      throw Exception('Failed to update diary entry: $e');
    }
  }

  // Delete a diary entry
  Future<void> deleteEntry(dynamic id) async {
    // Check if id is null or invalid
    if (id == null) {
      print('Cannot delete entry with null ID');
      throw Exception('Cannot delete entry with null ID');
    }

    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}entries/$id/'),
        headers: await _getHeaders(),
      );

      print('Delete response status: ${response.statusCode}');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete diary entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteEntry: $e');
      throw Exception('Failed to delete diary entry: $e');
    }
  }

  // Fetch available moods
  Future<List<String>> getMoods() async {
    final response = await http.get(
      Uri.parse('${baseUrl}entries/moods/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data.keys.toList();
    } else {
      throw Exception('Failed to load moods');
    }
  }

  // Fetch available templates
  Future<Map<String, String>> getTemplates() async {
    final response = await http.get(
      Uri.parse('${baseUrl}entries/templates/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } else {
      throw Exception('Failed to load templates');
    }
  }
}