import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/flutter_quill.dart' as leaf;
import 'package:project/models/page.dart';
import 'package:project/personalScreen/content_page.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:provider/provider.dart';

// Custom embed type for subpages
class SubpageBlockEmbed extends BlockEmbed {
  // Create a custom embed with a single key 'subpage' and a string value
  SubpageBlockEmbed(this.id, this.title)
      : super('subpage', jsonEncode({'id': id, 'title': title}));

  final int id;
  final String title;

  // Helper method to get the full value for debugging
  String get debugValue => '$type:$data';

  // Factory constructor to create from JSON string
  static SubpageBlockEmbed fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final id = json['id'];
      final title = json['title'];

      if (id == null) {
        throw ArgumentError('Missing id in SubpageBlockEmbed JSON');
      }
      if (title == null) {
        throw ArgumentError('Missing title in SubpageBlockEmbed JSON');
      }

      return SubpageBlockEmbed(
        id is int ? id : int.parse(id.toString()),
        title.toString(),
      );
    } catch (e) {
      print('Error creating SubpageBlockEmbed from JSON string: $e');
      rethrow;
    }
  }
}

// Custom embed builder for subpages
class SubpageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'subpage';

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final data = node.value.data;
    print('Building subpage embed with data: $data (type: ${data.runtimeType})');

    try {
      // Parse the data string to get the subpage information
      Map<String, dynamic> dataMap;

      if (data is String) {
        try {
          dataMap = jsonDecode(data) as Map<String, dynamic>;
          print('Successfully parsed subpage data: $dataMap');
        } catch (e) {
          print('Error parsing subpage data: $e');
          return Text('Error: Invalid subpage data format');
        }
      } else {
        print('Invalid subpage data type: ${data.runtimeType}');
        return Text('Error: Invalid subpage data type');
      }

      // Extract id and title
      final id = dataMap['id'];
      final title = dataMap['title'];

      if (id == null || title == null) {
        print('Missing id or title in subpage data');
        return Text('Error: Missing subpage information');
      }

      // Convert id to int
      final idValue = id is int ? id : int.parse(id.toString());

      print('Building subpage widget with ID: $idValue, title: $title');

      // Return the subpage widget
      return _SubpageWidget(
        id: idValue,
        title: title.toString(),
      );
    } catch (e) {
      print('Error building subpage widget: $e');
      return Text('Error: $e');
    }
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: widget,
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  @override
  String toPlainText(Embed node) => '[Subpage]';
}

// Widget to display a subpage embed
class _SubpageWidget extends StatefulWidget {
  final int id;
  final String title;

  const _SubpageWidget({
    required this.id,
    required this.title,
  });

  @override
  _SubpageWidgetState createState() => _SubpageWidgetState();
}

class _SubpageWidgetState extends State<_SubpageWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _navigateToSubpage(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFE3F2FD) : Colors.grey.shade50,
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF255DE1).withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color(0xFF255DE1).withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 20,
                  color: Color(0xFF255DE1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF255DE1),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSubpage(BuildContext context) async {
    print('Navigating to subpage with ID: ${widget.id}, title: ${widget.title}');

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get the PagesProvider to fetch the actual page data
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);

      // Find the page in the provider's list
      final pages = pagesProvider.pages;
      final subpagePage = pages.firstWhere(
        (page) => page.id == widget.id,
        orElse: () {
          print('Subpage not found in pages list, creating temporary page');
          // Create a temporary PageModel if the page is not found
          return PageModel(
            id: widget.id,
            title: widget.title,
            content: '', // Empty content
            parentId: null, // We don't know the parent ID
          );
        },
      );

      print('Found subpage: ID=${subpagePage.id}, title=${subpagePage.title}');
      print('Content length: ${subpagePage.content.length}');

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to the subpage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentPage(page: subpagePage),
        ),
      );
    } catch (e) {
      print('Error navigating to subpage: $e');

      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to subpage: $e')),
      );

      // Fallback to a basic page model if there's an error
      final subpage = PageModel(
        id: widget.id,
        title: widget.title,
        content: '', // Empty content
        parentId: null, // We don't know the parent ID
      );

      // Navigate to the subpage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentPage(page: subpage),
        ),
      );
    }
  }
}
