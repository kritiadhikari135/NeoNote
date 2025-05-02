

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/src/common/structs/horizontal_spacing.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:provider/provider.dart';
import 'package:project/models/page.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/widgets/subpage_embed.dart';

class ContentPage extends StatefulWidget {
  final PageModel page;
  ContentPage({required this.page});

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Add a text editing controller for the title
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;
  bool _showToolbar = true; // Show toolbar by default

  // Controller for new subpage title
  final TextEditingController _newSubpageTitleController = TextEditingController();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Fixed image size for embedded images
  final double _fixedImageWidth = 300.0;
  final double _fixedImageHeight = 200.0;

  // Background color for the content
  Color _backgroundColor = const Color(0xFFFFFFFF); // Default to white

  // List to store subpages
  List<PageModel> _subpages = [];

  // Track hovered subpage
  int? _hoveredSubpageId;

  // Track if content has changed
  bool _contentChanged = false;


  void _openUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Show error if URL cannot be launched
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not open link: $url")),
    );
  }


}


  @override
  void dispose() {
    // Save content before disposing if there are changes
    if (_contentChanged && mounted) {
      _saveSilently();
    }

    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Helper method to get PageModel by title.
  PageModel getPageModelByTitle(String title) {
    List<PageModel> pages = Provider.of<PagesProvider>(context, listen: false).pages;
    return pages.firstWhere(
      (page) => page.title == title,
      orElse: () => PageModel(id: 0, title: 'Not Found', content: ''),
    );
  }

  // Helper method to get parent page if exists
  PageModel? getParentPage() {
    if (widget.page.parentId == null) return null;

    List<PageModel> pages = Provider.of<PagesProvider>(context, listen: false).pages;
    try {
      return pages.firstWhere((page) => page.id == widget.page.parentId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to build the breadcrumb path
  List<PageModel> getBreadcrumbPath() {
    List<PageModel> path = [];
    List<PageModel> pages = Provider.of<PagesProvider>(context, listen: false).pages;

    // Add the current page to the path
    path.add(widget.page);

    // Recursively add parent pages to the path
    int? parentId = widget.page.parentId;

    while (parentId != null) {
      try {
        // Find the parent page
        final parentPage = pages.firstWhere((page) => page.id == parentId);

        // Add it to the path
        path.add(parentPage);

        // Move up to the next parent
        parentId = parentPage.parentId;
      } catch (e) {
        print('Error finding parent page with ID $parentId: $e');
        break;
      }
    }

    // Reverse the path so it goes from root to current page
    return path.reversed.toList();
  }

  // Navigate to a specific page in the breadcrumb
  void _navigateToPage(PageModel page) {
    // Always save current content before navigating to ensure it's saved
    _saveSilently();
    _contentChanged = false;

    print('Navigating to page ID: ${page.id}, title: ${page.title}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentPage(page: page),
      ),
    ).then((_) {
      if (mounted) {
        print('Returned from page');
      }
    });
  }

  // Navigate to parent page
  void _navigateToParentPage() {
    final parentPage = getParentPage();
    if (parentPage != null) {
      _navigateToPage(parentPage);
    }
  }

  // Add a listener to the QuillController to handle formatting changes
  void _setupQuillController() {
    // Add a listener to the controller to handle formatting changes
    _quillController.addListener(() {
      // This ensures that when a formatting option is selected,
      // it will be applied to new text that is typed
      setState(() {
        // Force a rebuild to apply the current formatting
      });

      // Mark content as changed to trigger auto-save
      _contentChanged = true;
    });
  }

  // Method to change background color
  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          'Background color updated',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: color,
      ),
    );
  }

  // Method to show background color picker using flutter_colorpicker
  void _showBackgroundColorPicker() {
    Color pickerColor = _backgroundColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a background color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              availableColors: [
                Colors.white,
                Colors.grey[100]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
                Colors.yellow[100]!,
                Colors.blue[100]!,
                Colors.green[100]!,
                Colors.purple[100]!,
                Colors.red[100]!,
                Colors.pink[100]!,
                Colors.orange[100]!,
                Colors.teal[100]!,
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                _changeBackgroundColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to pick and embed an image
  Future<void> _pickAndEmbedImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedImage == null) {
        print('No image selected');
        return;
      }

      String imageSource;

      if (kIsWeb) {
        // For web, we need to use a data URL
        final bytes = await pickedImage.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = pickedImage.mimeType ?? 'image/jpeg';
        imageSource = 'data:$mimeType;base64,$base64Image';
        print('Web image source: data URL (truncated for brevity)');
      } else {
        // For mobile, we can use the file path
        imageSource = pickedImage.path;
        print('Mobile image source: $imageSource');
      }

      // Create a custom embed for the image with fixed size
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;

      // Insert the image at the current cursor position
      _quillController.replaceText(
        index,
        length,
        BlockEmbed.image(imageSource),
        null, // TextSelection parameter should be null or a valid TextSelection object
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image added successfully')),
      );
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    }
  }

  // Method to fetch subpages for the current page
  void _fetchSubpages() {
    print('Fetching subpages for page ID: ${widget.page.id}');

    try {
      // Check if the page has subpages directly from the model first
      if (widget.page.hasSubpages) {
        print('Page has subpages directly in the model: ${widget.page.subpages!.length}');

        // Convert subpage maps to PageModel objects
        final directSubpages = widget.page.subpages!.map((subpageMap) {
          // Create minimal PageModel objects from the subpage data
          return PageModel(
            id: subpageMap['id'],
            title: subpageMap['title'],
            content: '', // Empty content since we don't need it for the list
            parentId: widget.page.id,
          );
        }).toList();

        setState(() {
          _subpages = directSubpages;
        });

        print('Set ${directSubpages.length} subpages from direct model data');
      } else {
        // Fallback to provider method if no direct subpages in model
        final pagesProvider = Provider.of<PagesProvider>(context, listen: false);
        final subpages = pagesProvider.getSubpages(widget.page.id);

        print('Found ${subpages.length} subpages from provider');
        for (var subpage in subpages) {
          print('Subpage: ID=${subpage.id}, title=${subpage.title}, content length=${subpage.content.length}');
        }

        setState(() {
          _subpages = subpages;
        });
      }
    } catch (e) {
      print('Error fetching subpages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subpages: $e')),
      );
    }
  }

  // Method to show dialog for creating a new subpage
  void _showCreateSubpageDialog() {
    _newSubpageTitleController.clear(); // Clear previous input

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Subpage'),
          content: TextField(
            controller: _newSubpageTitleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter subpage title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createSubpage();
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Method to show dialog for inserting an existing subpage
  void _showInsertSubpageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Insert Existing Subpage'),
          content: SizedBox(
            width: 300,
            height: 350,
            child: Column(
              children: [
                // Create New Subpage button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close current dialog
                      _showCreateSubpageDialog(); // Show create dialog
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Subpage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF255DE1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // Existing subpages list
                Expanded(
                  child: _subpages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subpages yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a subpage using the button above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _subpages.length,
                          itemBuilder: (context, index) {
                            final subpage = _subpages[index];
                            return ListTile(
                              leading: const Icon(Icons.article_outlined, color: Colors.blue),
                              title: Text(subpage.title),
                              onTap: () {
                                _insertSubpageEmbed(subpage);
                                Navigator.of(context).pop(); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Subpage "${subpage.title}" inserted')),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Method to create a new subpage
  void _createSubpage() async {
    final title = _newSubpageTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

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

      // Create empty content with default formatting
      final emptyDocument = Document();
      final deltaJson = emptyDocument.toDelta().toJson();
      final emptyContent = jsonEncode(deltaJson);

      print('Empty document delta: $deltaJson');
      print('Empty content JSON: $emptyContent');

      // Create metadata with default background color
      final metadata = {
        'backgroundColor': Colors.white.value,
      };

      // Create the content map
      final contentMap = {
        'content': emptyContent,
        'metadata': metadata,
      };

      // Combine content and metadata
      final contentWithMetadata = jsonEncode(contentMap);

      print('Creating subpage with content (truncated): ${contentWithMetadata.length > 100 ? contentWithMetadata.substring(0, 100) + "..." : contentWithMetadata}');

      // Verify the JSON is valid by parsing it back
      try {
        final parsed = jsonDecode(contentWithMetadata);
        print('Subpage content is valid JSON');
      } catch (e) {
        print('Warning: Subpage content is not valid JSON: $e');
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Invalid JSON format - $e')),
        );
        return;
      }

      // Create the subpage with the current page as parent
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);

      try {
        final newPage = await pagesProvider.createPage(
          title,
          contentWithMetadata,
          parentId: widget.page.id,
        );

        print('Subpage created with ID: ${newPage.id}, title: ${newPage.title}');
        print('Subpage content: ${newPage.content}');

        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Refresh subpages list
        _fetchSubpages();

        // Insert the subpage embed into the editor at the current cursor position
        _insertSubpageEmbed(newPage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subpage "$title" created and inserted')),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        print('Error creating subpage: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating subpage: $e')),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error in subpage creation process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating subpage: $e')),
      );
    }
  }

  // Method to insert a subpage embed into the editor
  void _insertSubpageEmbed(PageModel subpage) {
    // Get the current cursor position
    final index = _quillController.selection.baseOffset;
    final length = _quillController.selection.extentOffset - index;

    print('Inserting subpage embed for ID: ${subpage.id}, title: ${subpage.title}');

    try {
      // Create a subpage embed
      final embed = SubpageBlockEmbed(subpage.id, subpage.title);
      print('Created subpage embed: ${embed.debugValue}');

      // Insert the embed at the current cursor position
      _quillController.replaceText(
        index,
        length,
        embed,
        null,
      );

      // Add a new line after the embed
      _quillController.replaceText(
        index + 1, // +1 because the embed counts as 1 character
        0,
        '\n',
        null,
      );

      // Verify the document contains the embed
      final delta = _quillController.document.toDelta();
      print('Document delta after insert: ${jsonEncode(delta.toJson())}');

      // Save the content after inserting the embed
      _saveSilently();
      _contentChanged = false;

      print('Subpage embed inserted and content saved');
    } catch (e) {
      print('Error inserting subpage embed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting subpage: $e')),
      );
    }
  }

  // Method to navigate to a subpage
  void _navigateToSubpage(PageModel subpage) {
    // Always save current content before navigating to ensure it's saved
    _saveSilently();
    _contentChanged = false;

    print('Navigating to subpage ID: ${subpage.id}, title: ${subpage.title}');

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

      // Find the page in the provider's list to ensure we have the latest data
      final pages = pagesProvider.pages;
      final latestSubpage = pages.firstWhere(
        (page) => page.id == subpage.id,
        orElse: () => subpage, // Use the provided subpage if not found
      );

      print('Found latest subpage data: ID=${latestSubpage.id}, title=${latestSubpage.title}');
      print('Content length: ${latestSubpage.content.length}');

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to the subpage with the latest data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentPage(page: latestSubpage),
        ),
      ).then((_) {
        if (mounted) {
          print('Returned from subpage, refreshing subpages list');
          // Refresh subpages list when returning from the subpage
          _fetchSubpages();

          // Also refresh the content to ensure any changes to subpage embeds are reflected
          setState(() {
            // Force a rebuild
          });
        }
      });
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

      // Fallback to using the provided subpage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentPage(page: subpage),
        ),
      ).then((_) {
        if (mounted) {
          print('Returned from subpage, refreshing subpages list');
          // Refresh subpages list when returning from the subpage
          _fetchSubpages();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Document doc;
    String content = widget.page.content;

    print('Loading content for page ID: ${widget.page.id}, title: ${widget.page.title}');
    print('Is subpage: ${widget.page.isSubpage}, parent ID: ${widget.page.parentId}');
    print('Raw content: $content');

    // Try to parse the content as a JSON object with metadata
    try {
      Map<String, dynamic> contentData = jsonDecode(content);
      print('Content parsed as JSON: $contentData');

      if (contentData.containsKey('content') && contentData.containsKey('metadata')) {
        // Extract the actual content and metadata
        String actualContent = contentData['content'];
        Map<String, dynamic> metadata = contentData['metadata'];

        print('Found content and metadata structure');
        print('Metadata: $metadata');
        print('Actual content (truncated): ${actualContent.length > 100 ? actualContent.substring(0, 100) + "..." : actualContent}');

        // Set the background color if available
        if (metadata.containsKey('backgroundColor')) {
          int bgColorValue = metadata['backgroundColor'];
          _backgroundColor = Color(bgColorValue);
          print('Set background color to: $bgColorValue');
        }

        // Update the content to just the actual content part
        content = actualContent;
      } else {
        print('Content JSON does not have expected structure with content and metadata fields');
      }
    } catch (e) {
      // If parsing fails, just use the content as is
      print('Failed to parse content with metadata: $e');
    }

    // Now parse the actual content for the document
    try {
      print('Attempting to parse content as Document: $content');

      // Try to parse the content as JSON first
      final contentJson = jsonDecode(content);
      print('Content parsed as JSON: $contentJson');

      // Now create a Document from the parsed JSON
      doc = Document.fromJson(contentJson);
      print('Successfully created Document from JSON');
    } catch (e) {
      print('Error parsing content as Document: $e');

      // Try a different approach - maybe the content is already a string representation of Delta
      try {
        print('Trying alternative parsing approach');
        // Create an empty document and insert the content as text
        doc = Document();

        // If content is not empty, insert it
        if (content.isNotEmpty) {
          print('Inserting content as text');
          doc.insert(0, content);
        }
      } catch (e2) {
        print('Error with alternative parsing: $e2');
        // Last resort - create a completely empty document
        print('Creating empty document');
        doc = Document();
      }
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      keepStyleOnNewLine: true, // Keep formatting when creating new lines
    );

    // Setup the QuillController to handle formatting changes
    _setupQuillController();

    // Initialize the title controller with the current page title
    _titleController.text = widget.page.title;

    // Fetch subpages for this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubpages();
    });
  }

  // Silent save method that doesn't show notifications
  void _saveSilently() {
    if (!mounted) return;

    try {
      // Encode the current document as Delta JSON.
      final delta = _quillController.document.toDelta();
      final deltaJson = delta.toJson();
      String updatedContent = jsonEncode(deltaJson);

      print('Silently saving content for page ID: ${widget.page.id}, title: ${_titleController.text}');
      print('Is subpage: ${widget.page.isSubpage}, parent ID: ${widget.page.parentId}');

      // Create a map to store additional metadata
      Map<String, dynamic> metadata = {
        'backgroundColor': _backgroundColor.value,
      };

      // Create the content with metadata structure
      Map<String, dynamic> contentMap = {
        'content': updatedContent,
        'metadata': metadata,
      };

      // Convert to JSON string
      String contentWithMetadata = jsonEncode(contentMap);

      // Verify the JSON is valid by parsing it back
      try {
        jsonDecode(contentWithMetadata);
      } catch (e) {
        print('Warning: Content is not valid JSON: $e');
        return;
      }

      // Get the provider before checking mounted again
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);

      // Check mounted again before proceeding
      if (!mounted) return;

      // Update the page with the new content
      pagesProvider.updatePage(
        widget.page.id,
        _titleController.text,
        contentWithMetadata,
        parentId: widget.page.parentId, // Preserve the parent-child relationship
      ).then((_) {
        if (mounted) {
          print('Content silently saved for page ID: ${widget.page.id}');
          // Mark content as not changed after successful save
          _contentChanged = false;
        }
      }).catchError((error) {
        print('Error saving content for page ID: ${widget.page.id}: $error');
      });
    } catch (e) {
      print('Error in silent save: $e');
    }
  }

  // Save content with notification - used when user explicitly presses save
  void _saveContent() {
    if (!mounted) return;

    try {
      // Encode the current document as Delta JSON.
      final delta = _quillController.document.toDelta();
      final deltaJson = delta.toJson();
      String updatedContent = jsonEncode(deltaJson);

      print('Saving content for page ID: ${widget.page.id}, title: ${_titleController.text}');
      print('Is subpage: ${widget.page.isSubpage}, parent ID: ${widget.page.parentId}');

      // Create a map to store additional metadata
      Map<String, dynamic> metadata = {
        'backgroundColor': _backgroundColor.value,
      };

      // Create the content with metadata structure
      Map<String, dynamic> contentMap = {
        'content': updatedContent,
        'metadata': metadata,
      };

      // Convert to JSON string
      String contentWithMetadata = jsonEncode(contentMap);

      // Verify the JSON is valid by parsing it back
      try {
        jsonDecode(contentWithMetadata);
      } catch (e) {
        print('Warning: Content is not valid JSON: $e');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: Invalid content format")));
        }
        return;
      }

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text("Saving content..."),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Get the provider before checking mounted again
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);

      // Check mounted again before proceeding
      if (!mounted) return;

      // Update the page with the new content
      pagesProvider.updatePage(
        widget.page.id,
        _titleController.text,
        contentWithMetadata,
        parentId: widget.page.parentId, // Preserve the parent-child relationship
      ).then((_) {
        if (mounted) {
          print('Content saved successfully for page ID: ${widget.page.id}');
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Content saved")));

          // Mark content as not changed after successful save
          _contentChanged = false;
        }
      }).catchError((error) {
        print('Error saving content for page ID: ${widget.page.id}: $error');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error saving content: $error")));
        }
      });
    } catch (e) {
      print('Error saving content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving content")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use WillPopScope to save content when user navigates back
    return WillPopScope(
      onWillPop: () async {
        // Save content before popping if there are changes
        if (_contentChanged) {
          _saveSilently();
        }
        return true;
      },
      child: CustomScaffold(
      selectedPage: _titleController.text,
      body: Scaffold(
        appBar: AppBar(
          title: _isEditingTitle
            ? TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter page title',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) {
                  setState(() {
                    _isEditingTitle = false;
                  });
                  _saveSilently(); // Save the title when done editing without showing notification
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show breadcrumb navigation if this is a subpage
                  if (widget.page.isSubpage)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      margin: const EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Home icon at the beginning
                            const Icon(
                              Icons.home,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),

                            // Build the breadcrumb path
                            ...getBreadcrumbPath().asMap().entries.map((entry) {
                              final index = entry.key;
                              final page = entry.value;
                              final isLastItem = index == getBreadcrumbPath().length - 1;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Show all pages in the path
                                  InkWell(
                                    onTap: isLastItem ? null : () => _navigateToPage(page),
                                    child: Text(
                                      page.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLastItem ? Colors.grey : Colors.blue,
                                        fontWeight: isLastItem ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),

                                  // Add separator between items (except after the last item)
                                  if (!isLastItem)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  // Page title
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleController.text,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          setState(() {
                            _isEditingTitle = true;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
          actions: [
            // Toggle toolbar button
            IconButton(
              icon: Icon(_showToolbar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  _showToolbar = !_showToolbar;
                });
              },
              tooltip: _showToolbar ? 'Hide formatting' : 'Show formatting',
            ),

            // Background Color button - direct access to background color picker
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.format_color_fill,
                    color: Colors.black,
                    size: 28,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: _showBackgroundColorPicker,
              tooltip: 'Background Color',
            ),

            // Save button
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveContent,
              tooltip: 'Save Content',
            ),
          ],
        ),
        body: Container(
          color: _backgroundColor, // Apply the selected background color
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [


                // Display the Quill toolbar if showToolbar is true
                if (_showToolbar)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: const BoxDecoration(
                      color: Colors.white, // White background for toolbar
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3.0,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: QuillSimpleToolbar(
                      controller: _quillController,
                      config: QuillSimpleToolbarConfig(
                        // Enable all formatting options for MS Word-like experience
                        multiRowsDisplay: true,
                        showFontFamily: true,
                        showFontSize: true,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showInlineCode: true,
                        showColorButton: true,
                        showBackgroundColorButton: false, // Disabled background color in toolbar
                        showClearFormat: true,
                        showAlignmentButtons: true,
                        showHeaderStyle: true,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: true,
                        showCodeBlock: true,
                        showQuote: true,
                        showIndent: true,
                        showLink: true,
                        // Enable image embedding in the toolbar
                        embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                        // Add custom buttons to the toolbar
                        customButtons: [
                          QuillToolbarCustomButtonOptions(
                            icon: const Icon(Icons.folder_outlined),
                            tooltip: 'Insert Subpage',
                            onPressed: () {
                              _showInsertSubpageDialog();
                            },
                          ),
                        ],
                        // Custom button options to ensure formatting is applied to new text
                        buttonOptions: QuillSimpleToolbarButtonOptions(
                          base: QuillToolbarBaseButtonOptions(
                            afterButtonPressed: () {
                              // Force focus on the editor after a button is pressed
                              _focusNode.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Display the Quill editor
                Expanded(
                  child: Column(
                    children: [
                      // Editor
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final selection = _quillController.selection;
                            final text = _quillController.document.getPlainText(selection.baseOffset, selection.extentOffset);

                            // Check if the tapped text is a valid URL
                            final uri = Uri.tryParse(text);
                            if (uri != null && uri.hasAbsolutePath) {
                              _openUrl(text); // Open URL in browser
                            }
                          },
                          child: QuillEditor(
                            controller: _quillController,
                            focusNode: _focusNode,
                            scrollController: _scrollController,
                            config: QuillEditorConfig(
                              placeholder: "Enter page content here...",
                              padding: const EdgeInsets.all(0),
                              // Set autoFocus to true to ensure the editor receives focus
                              // This helps with applying formatting to new text
                              autoFocus: true,
                              expands: true,
                              scrollable: true,
                              keyboardAppearance: Brightness.light,
                              enableInteractiveSelection: true,
                              // Enable retaining formatting when typing new text
                              // This makes the toolbar buttons work for new text
                              // Configure embedBuilders to handle images with fixed size
                              embedBuilders: [
                                // Add our custom subpage embed builder
                                SubpageEmbedBuilder(),
                                // Add the default image embed builders
                                ...FlutterQuillEmbeds.editorBuilders(
                                  imageEmbedConfig: QuillEditorImageEmbedConfig(
                                    imageProviderBuilder: (context, imageSource) {
                                      if (imageSource.startsWith('http') && !imageSource.startsWith('blob:http')) {
                                        // Regular network image (not blob)
                                        return NetworkImage(imageSource);
                                      } else if (imageSource.startsWith('data:')) {
                                        // Data URL (for web)
                                        return MemoryImage(Uri.parse(imageSource).data!.contentAsBytes());
                                      } else if (imageSource.startsWith('blob:')) {
                                        // Blob URL (for web)
                                        print('Blob URL detected: $imageSource');
                                        try {
                                          // Attempt to load the placeholder asset
                                          return const AssetImage('assets/images/image_placeholder.png');
                                        } catch (e) {
                                          print('Error loading placeholder image: $e');
                                          // Fallback to a default color or another placeholder
                                          return MemoryImage(Uint8List(0)); // Empty image
                                        }
                                      } else if (kIsWeb) {
                                        // For web, we can't use FileImage, so we'll use an asset image as a fallback
                                        print('Warning: Unsupported image source on web: $imageSource');
                                        return const AssetImage('assets/images/image_placeholder.png');
                                      } else if (imageSource.startsWith('file:')) {
                                        // File URI (for mobile)
                                        return FileImage(File(imageSource.replaceFirst('file:', '')));
                                      } else {
                                        // Local file path (for mobile)
                                        return FileImage(File(imageSource));
                                      }
                                    },
                                    // Callback when an image is removed
                                    onImageRemovedCallback: (imageSource) async {
                                      print('Image removed: $imageSource');
                                      return; // Return a completed Future<void>
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onItemSelected: (String selectedPageTitle) {
        // Always save current content before navigating to ensure it's saved
        _saveSilently();
        _contentChanged = false;

        final selectedPage = getPageModelByTitle(selectedPageTitle);
        print('Navigating to page from sidebar: ID: ${selectedPage.id}, title: ${selectedPage.title}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentPage(page: selectedPage),
          ),
        ).then((_) {
          if (mounted) {
            print('Returned from sidebar-selected page');
          }
        });
      },
    ),
    );
  }
}
