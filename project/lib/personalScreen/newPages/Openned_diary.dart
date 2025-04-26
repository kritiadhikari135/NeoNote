import 'dart:io';
import 'dart:convert';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/services/diary_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:video_player/video_player.dart';
// Custom video embed removed
import 'package:flutter_quill/src/common/structs/horizontal_spacing.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:project/personalScreen/bin.dart';
import 'package:url_launcher/url_launcher.dart';

class NewDiaryPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const NewDiaryPage({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  _NewDiaryPageState createState() => _NewDiaryPageState();
}

class _NewDiaryPageState extends State<NewDiaryPage> {
  // Global key for the scaffold messenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _titleController = TextEditingController();

  // Quill controller for rich text editing
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showToolbar = true; // Show toolbar by default

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Fixed image size for embedded images
  final double _fixedImageWidth = 300.0;
  final double _fixedImageHeight = 200.0;

  late DateTime _selectedDate = DateTime.now();
  // Always in edit mode
  final bool _isReadOnly = false;
  String _selectedPage = 'Diary';

  // Added color variables
  Color _backgroundColor = const Color(0xFFFFFFFF); // Default to white
  Color _textColor = const Color(0xFF000000); // Default to black

  // Removed mood emojis and template contents

  // Define color options
  final List<Color> _backgroundColorOptions = [
    const Color(0xFFFFFFFF), // White
    const Color(0xFFF5F5F5), // Light Gray
    const Color(0xFFFFF8E1), // Light Yellow
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFF3E5F5), // Light Purple
    const Color(0xFFFFEBEE), // Light Red
    const Color(0xFFFCE4EC), // Light Pink
  ];


  // Mood variable removed

  @override
  void initState() {
    super.initState();
     print('NewDiaryPage initState called');
     print('Initial widget.initialData: ${widget.initialData}');
    _initializeData();

    // Setup the QuillController to handle formatting changes
    _setupQuillController();

    // Add a delayed check to see if the controllers have text after initialization
    Future.delayed(Duration(milliseconds: 100), () {
      print('Delayed check - Title controller text: "${_titleController.text}"');
      print('Delayed check - Quill controller has content: ${_quillController.document.length > 0}');
    });
  }

  void _initializeData() {
    // Set default values
    setState(() {
      _selectedDate = DateTime.now();

      // Initialize title with empty value
      _titleController.text = '';

      // Initialize quill controller with empty document
      _quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
        keepStyleOnNewLine: true, // Keep formatting when creating new lines
      );

      // Set read-only mode on the controller
      _quillController.readOnly = _isReadOnly;

      // Initialize colors with default values
      _backgroundColor = const Color(0xFFFFFFFF); // Default to white
      _textColor = const Color(0xFF000000); // Default to black

      // Check if initialData is not null
      if (widget.initialData != null) {
        print('Initializing with data: ${widget.initialData}');

        // Handle background color initialization
        try {
          print('Background color before setting: ${_backgroundColor.value.toRadixString(16)}');

          if (widget.initialData!['background_color'] != null) {
            int bgColor = widget.initialData!['background_color'];
            print('Raw background_color value: $bgColor (hex: ${bgColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (bgColor == 0) {
              bgColor = 0xFFFFFFFF; // Default to white with alpha
              print('Background color was 0, defaulting to white with alpha');
            } else if ((bgColor & 0xFF000000) == 0) {
              bgColor = bgColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to background color: ${bgColor.toRadixString(16)}');
            }

            _backgroundColor = Color(bgColor);
            print('Set background color from background_color: $bgColor (hex: ${bgColor.toRadixString(16)})');
          } else if (widget.initialData!['backgroundColor'] != null) {
            int bgColor = widget.initialData!['backgroundColor'];
            print('Raw backgroundColor value: $bgColor (hex: ${bgColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (bgColor == 0) {
              bgColor = 0xFFFFFFFF; // Default to white with alpha
              print('Background color was 0, defaulting to white with alpha');
            } else if ((bgColor & 0xFF000000) == 0) {
              bgColor = bgColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to background color: ${bgColor.toRadixString(16)}');
            }

            _backgroundColor = Color(bgColor);
            print('Set background color from backgroundColor: $bgColor (hex: ${bgColor.toRadixString(16)})');
          } else {
            // If no background color is provided, default to white
            _backgroundColor = const Color(0xFFFFFFFF);
            print('No background color provided, defaulting to white');
          }

          print('Final background color: ${_backgroundColor.value.toRadixString(16)}');
        } catch (e) {
          print('Error setting background color: $e');
          _backgroundColor = const Color(0xFFFFFFFF); // Default to white
          print('Set default background color due to error: ${_backgroundColor.value.toRadixString(16)}');
        }

        // Handle text color initialization
        try {
          print('Text color before setting: ${_textColor.value.toRadixString(16)}');

          if (widget.initialData!['text_color'] != null) {
            int txtColor = widget.initialData!['text_color'];
            print('Raw text_color value: $txtColor (hex: ${txtColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (txtColor == 0) {
              txtColor = 0xFF000000; // Default to black with alpha
              print('Text color was 0, defaulting to black with alpha');
            } else if ((txtColor & 0xFF000000) == 0) {
              txtColor = txtColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to text color: ${txtColor.toRadixString(16)}');
            }

            _textColor = Color(txtColor);
            print('Set text color from text_color: $txtColor (hex: ${txtColor.toRadixString(16)})');
          } else if (widget.initialData!['textColor'] != null) {
            int txtColor = widget.initialData!['textColor'];
            print('Raw textColor value: $txtColor (hex: ${txtColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (txtColor == 0) {
              txtColor = 0xFF000000; // Default to black with alpha
              print('Text color was 0, defaulting to black with alpha');
            } else if ((txtColor & 0xFF000000) == 0) {
              txtColor = txtColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to text color: ${txtColor.toRadixString(16)}');
            }

            _textColor = Color(txtColor);
            print('Set text color from textColor: $txtColor (hex: ${txtColor.toRadixString(16)})');
          } else {
            // If no text color is provided, default to black
            _textColor = const Color(0xFF000000);
            print('No text color provided, defaulting to black');
          }

          print('Final text color: ${_textColor.value.toRadixString(16)}');
        } catch (e) {
          print('Error setting text color: $e');
          _textColor = const Color(0xFF000000); // Default to black
          print('Set default text color due to error: ${_textColor.value.toRadixString(16)}');
        }

        // Load other initial data
        final title = widget.initialData!['title'];
        final content = widget.initialData!['content'];
        print('Initializing with title: "$title", content: "$content"');

        // Set title and content with explicit toString() conversion and fallbacks
        if (title != null) {
          final titleStr = title.toString();
          print('Setting title controller text to: "$titleStr"');
          _titleController.text = titleStr;

          // Force update the controller
          _titleController.value = TextEditingValue(
            text: titleStr,
            selection: TextSelection.collapsed(offset: titleStr.length),
          );
        } else {
          print('Title was null, using default title');
          _titleController.text = 'New Diary Entry';
        }

        if (content != null) {
          final contentStr = content.toString();
          print('Setting quill controller content');

          try {
            // Try to parse content as Delta JSON
            final contentJson = json.decode(contentStr);
            _quillController = QuillController(
              document: Document.fromJson(contentJson),
              selection: const TextSelection.collapsed(offset: 0),
              keepStyleOnNewLine: true, // Keep formatting when creating new lines
            );
            _quillController.readOnly = _isReadOnly;
          } catch (e) {
            // If parsing fails, treat as plain text
            print('Failed to parse content as Delta JSON: $e');
            _quillController = QuillController(
              document: Document()..insert(0, contentStr),
              selection: const TextSelection.collapsed(offset: 0),
              keepStyleOnNewLine: true, // Keep formatting when creating new lines
            );
            _quillController.readOnly = _isReadOnly;
          }
        } else {
          print('Content was null, using empty document');
          _quillController = QuillController(
            document: Document(),
            selection: const TextSelection.collapsed(offset: 0),
            keepStyleOnNewLine: true, // Keep formatting when creating new lines
          );
          _quillController.readOnly = _isReadOnly;
        }

        _selectedDate = DateTime.parse(widget.initialData!['date']);
      }
    });
  }

  // Template and mood selection methods removed

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
          style: TextStyle(color: _textColor),
        ),
        backgroundColor: color,
      ),
    );
  }

  // Method to change text color
  void _changeTextColor(Color color) {
    // Ensure the color is not too light (close to white)
    if ((color.value & 0xFFFFFF) > 0xF0F0F0) {
      print('Selected text color is too light, using black instead');
      color = const Color(0xFF000000); // Use black instead
    }

    print('Changing text color to: ${color.value.toRadixString(16)}');

    // Set as the default text color for future text
    setState(() {
      _textColor = color;

      // Store current selection positions
      final titleSelection = _titleController.selection;

      // Force rebuild of text fields with preserved selection
      _titleController.value = TextEditingValue(
        text: _titleController.text,
        selection: titleSelection,
      );
    });

    // Show a sample of the text with the new color
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Default Text Color Updated', style: TextStyle(color: color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New text will appear in this color:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sample Text',
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To apply color to existing text, use the color picker in the toolbar.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
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

  // Method to show text color picker using flutter_colorpicker
  void _showTextColorPicker() {
    Color pickerColor = _textColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a text color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
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
                _changeTextColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Note: We're using the built-in QuillToolbar for text formatting
  // This provides all the necessary formatting options like bold, italic, underline,
  // strikethrough, font size, text color, alignment, headings, and lists.

  // Add a listener to the QuillController to handle formatting changes
  void _setupQuillController() {
    // Add a listener to the controller to handle formatting changes
    _quillController.addListener(() {
      // This ensures that when a formatting option is selected,
      // it will be applied to new text that is typed
      setState(() {
        // Force a rebuild to apply the current formatting
      });
    });
  }

  // Method to get the link at the current cursor position
  String? _getLinkAtCursor() {
    try {
      final selection = _quillController.selection;
      final document = _quillController.document;

      if (selection.baseOffset >= 0) {
        // Try to get the leaf node at the cursor position
        final leaf = document.querySegmentLeafNode(selection.baseOffset).leaf;
        if (leaf != null && leaf.style.attributes.containsKey('link')) {
          return leaf.style.attributes['link']?.value;
        }

        // If no link at cursor, try to check if there's a link in the selected text
        if (selection.baseOffset != selection.extentOffset) {
          final text = document.getPlainText(selection.baseOffset, selection.extentOffset);
          // Check if the text looks like a URL
          final urlRegex = RegExp(
            r'(https?://[^\s]+)|(www\.[^\s]+)|([^\s]+\.(com|org|net|edu|gov|io|co)[^\s]*)',
            caseSensitive: false
          );
          if (urlRegex.hasMatch(text)) {
            return text;
          }
        }
      }
    } catch (e) {
      print('Error in _getLinkAtCursor: $e');
    }
    return null;
  }

  // Method to handle link taps
  Future<void> _handleLinkTap(String? link) async {
    if (link != null && link.isNotEmpty) {
      print('Attempting to open link: $link');
      try {
        // Ensure the link has a scheme
        String processedLink = link;
        if (!link.startsWith('http://') && !link.startsWith('https://')) {
          if (link.startsWith('www.')) {
            processedLink = 'https://$link';
            print('Added https:// prefix to link: $processedLink');
          } else {
            // Try to determine if it's a valid domain
            final RegExp domainRegex = RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}$|^[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}$');
            if (domainRegex.hasMatch(link)) {
              processedLink = 'https://$link';
              print('Added https:// prefix to domain: $processedLink');
            }
          }
        }

        final Uri uri = Uri.parse(processedLink);
        print('URI parsed: $uri');

        // For desktop platforms, ensure we're using the correct mode
        final bool canLaunch = await canLaunchUrl(uri);
        print('Can launch URL: $canLaunch');

        if (canLaunch) {
          // Use platformDefaultBrowser for desktop platforms
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          print('Launch result: $launched');

          if (!launched) {
            print('launchUrl returned false, trying externalApplication mode');
            // Try with externalApplication mode as fallback
            final bool launchedExternal = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!launchedExternal) {
              print('externalApplication mode also failed');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to open link: $processedLink')),
              );
            } else {
              print('Successfully launched with externalApplication mode');
            }
          }
        } else {
          print('canLaunchUrl returned false for: $processedLink');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $processedLink')),
          );
        }
      } catch (e) {
        print('Error launching URL: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    } else {
      print('Link is null or empty');
    }
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
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Image added successfully')),
      );
    } catch (e) {
      print('Error picking image: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    }
  }

  // Method to pick and embed a video
  Future<void> _pickAndEmbedVideo() async {
    try {
      final XFile? pickedVideo = await _imagePicker.pickVideo(source: ImageSource.gallery);

      if (pickedVideo == null) {
        print('No video selected');
        return;
      }

      String videoSource = pickedVideo.path;
      print('Video source: $videoSource');

      // Create a custom embed for the video
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;

      // Insert the video at the current cursor position using the standard video embed
      _quillController.replaceText(
        index,
        length,
        BlockEmbed.video(videoSource),
        null, // TextSelection parameter should be null or a valid TextSelection object
      );

      // Show a success message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Video added successfully')),
      );
    } catch (e) {
      print('Error picking video: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error adding video: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 37, 93, 225),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 37, 93, 225),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to update an existing diary entry
  void _updateSaveDiary() async {
    try {
      if (widget.initialData == null || widget.initialData!['id'] == null) {
        print('Cannot update: No ID found in initialData');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot update: No diary ID found')),
        );
        return;
      }

      final diaryService = DiaryService();
      final id = widget.initialData!['id'];

      // Get title from controller and content from quill controller
      final title = _titleController.text.trim();
      final content = jsonEncode(_quillController.document.toDelta().toJson());
      print('Updating diary with title: "$title", length: ${title.length}');
      print('Updating diary with content: Delta JSON');

      // Extract image paths from the document for debugging
      final delta = _quillController.document.toDelta();
      final operations = delta.toList();
      final imageBlocks = operations.where((op) =>
        op.isInsert && op.data is Map && (op.data as Map).containsKey('image')).toList();

      if (imageBlocks.isNotEmpty) {
        print('Document contains ${imageBlocks.length} images:');
        for (var block in imageBlocks) {
          final imagePath = (block.data as Map)['image'];
          print('Image path: $imagePath');
        }
      } else {
        print('Document contains no images');
      }

if (title.isEmpty || content.isEmpty) {
  _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  _scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Please enter both title and content before updating.')),
  );
  return;
}


      print('Updating diary entry with ID: $id');
      print('Title: "$title", Content: "$content"');

      // Ensure color values are never null or zero
      final bgColor = _backgroundColor.value != 0 ? _backgroundColor.value : 0xFFFFFFFF; // Default to white

      // For text color, ensure it's black if it's 0 or very close to white
      int txtColor;
      if (_textColor.value == 0) {
        txtColor = 0xFF000000; // Default to black with alpha
        print('Text color was 0, using black with alpha: ${txtColor.toRadixString(16)}');
      } else {
        txtColor = _textColor.value;

        // If the color is too light (close to white), use black instead
        if ((txtColor & 0xFFFFFF) > 0xF0F0F0) {
          txtColor = 0xFF000000; // Black with alpha
          print('Text color was too light, using black: ${txtColor.toRadixString(16)}');
        }
      }

      print('Final bgColor: ${bgColor.toRadixString(16)}');
      print('Final txtColor: ${txtColor.toRadixString(16)}');

      // Create a diary entry with the ID included
      final diary = DiaryEntry(
        id: id,
        title: title,
        content: content,
        date: _selectedDate,
        mood: '', // Mood removed
        backgroundColor: bgColor,
        textColor: txtColor,
        template: 'Default', // Template removed
        // Include any other fields from the original entry
        images: widget.initialData!['images'] != null ?
          (widget.initialData!['images'] as List).map((img) =>
            DiaryImage(id: img['id'], imageUrl: img['image'])).toList() : [],
      );

      print('Updating diary with data: ${diary.toJson()}');

      // Update the existing diary entry
      final updatedDiary = await diaryService.updateEntry(id, diary);
      print('Diary updated with ID: ${updatedDiary.id}');

      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry updated successfully.')),
      );

      // Return to the previous screen with the updated diary data
      Navigator.pop(context, updatedDiary.toJson());
    } catch (e) {
      print('Error updating diary: $e');
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error updating diary: $e')),
      );
    }
  }

  // Method to delete a diary entry
  void _deleteDiary() async {
    try {
      if (widget.initialData == null || widget.initialData!['id'] == null) {
        print('Cannot delete: No ID found in initialData');
        _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Cannot delete: No diary ID found')),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Diary Entry'),
            content: const Text('Are you sure you want to delete this diary entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        print('Deletion cancelled by user');
        return;
      }

      final diaryService = DiaryService();
      final id = widget.initialData!['id'];
      print('Deleting diary entry with ID: $id');

      // Create a DiaryEntry object from the initialData
      final diary = DiaryEntry(
        id: id,
        title: _titleController.text.trim(),
        content: jsonEncode(_quillController.document.toDelta().toJson()),
        date: _selectedDate,
        mood: widget.initialData!['mood'],
        backgroundColor: _backgroundColor.value,
        textColor: _textColor.value,
        template: widget.initialData!['template'] ?? 'Default',
        images: widget.initialData!['images'] != null ?
          (widget.initialData!['images'] as List).map((img) =>
            DiaryImage(id: img['id'], imageUrl: img['image'])).toList() : [],
        createdAt: widget.initialData!['created_at'] != null ? DateTime.parse(widget.initialData!['created_at']) : null,
        updatedAt: widget.initialData!['updated_at'] != null ? DateTime.parse(widget.initialData!['updated_at']) : null,
      );

      // Add the diary to the bin
      Provider.of<BinProvider>(context, listen: false).addDeletedDiary(diary);

      // Delete the diary from the backend
      await diaryService.deleteEntry(id);
      print('Diary entry deleted successfully');

      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry moved to bin')),
      );

      // Return to the previous screen with null to indicate deletion
      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      print('Error deleting diary: $e');
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error deleting diary: $e')),
      );
    }
  }

  // Method to save a new diary entry
  void _saveDiary() async {
    try {
      final diaryService = DiaryService();
      // Ensure color values are never null or zero
      final bgColor = _backgroundColor.value != 0 ? _backgroundColor.value : 0xFFFFFFFF; // Default to white

      // For text color, ensure it's black if it's 0 or very close to white
      int txtColor;
      if (_textColor.value == 0) {
        txtColor = 0xFF000000; // Default to black with alpha
        print('Text color was 0, using black with alpha: ${txtColor.toRadixString(16)}');
      } else {
        txtColor = _textColor.value;

        // If the color is too light (close to white), use black instead
        if ((txtColor & 0xFFFFFF) > 0xF0F0F0) {
          txtColor = 0xFF000000; // Black with alpha
          print('Text color was too light, using black: ${txtColor.toRadixString(16)}');
        }
      }

      print('Final bgColor: ${bgColor.toRadixString(16)}');
      print('Final txtColor: ${txtColor.toRadixString(16)}');

      // Get title from controller and content from quill controller
      final title = _titleController.text.trim();
      final content = jsonEncode(_quillController.document.toDelta().toJson());
      print('Saving diary with title: "$title", length: ${title.length}');
      print('Saving diary with content: Delta JSON');

      // Extract image paths from the document for debugging
      final delta = _quillController.document.toDelta();
      final operations = delta.toList();
      final imageBlocks = operations.where((op) =>
        op.isInsert && op.data is Map && (op.data as Map).containsKey('image')).toList();

      if (imageBlocks.isNotEmpty) {
        print('Document contains ${imageBlocks.length} images:');
        for (var block in imageBlocks) {
          final imagePath = (block.data as Map)['image'];
          print('Image path: $imagePath');
        }
      } else {
        print('Document contains no images');
      }

      // Check if title or content is empty before creating the DiaryEntry object
if (title.isEmpty || content.isEmpty) {
  // Clear any existing snackbars before showing a new one
  _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  _scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Please enter both title and content before saving.')),
  );
  return;
}


      final diary = DiaryEntry(
        title: title,
        content: content,
        date: _selectedDate,
        mood: '', // Mood removed
        backgroundColor: bgColor,
        textColor: txtColor,
        template: 'Default', // Template removed
      );

      print('Saving diary: ${diary.toJson()}');
      print('JSON payload: ${json.encode(diary.toJson())}');

      // Create new entry
      print('Creating new diary entry');
      await diaryService.createEntry(diary);
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry created successfully.')),
      );

      Navigator.pop(context, diary.toJson());
    } catch (e) {
      print('Error saving diary: $e'); // Log the error
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error saving diary: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug the controller values in build
    print('Build method - Title controller text: "${_titleController.text}"');
    print('Build method - Quill controller has content: ${_quillController.document.length > 0}');

    // Main diary content widget
    Widget diaryContent = Column(
      children: [
        // Top bar with date, mood, and actions
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 230, 230, 230),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Date picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Row(
                  children: [
                    Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 37, 93, 225),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today,
                      color: Color.fromARGB(255, 37, 93, 225),
                      size: 18,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Mood display removed
            ],
          ),
        ),

        // Title and content area with background color
        Expanded(
          child: Container(
            color: _backgroundColor, // Apply the selected background color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field with text color
                  TextField(
                    key: const Key('titleField'),
                    controller: _titleController,
                    readOnly: _isReadOnly,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColor, // Apply the selected text color
                    ),
                    cursorColor: _textColor, // Set cursor color to match text color
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Force rebuild to apply text color to new text
                        _titleController.value = TextEditingValue(
                          text: value,
                          selection: _titleController.selection,
                        );
                      });
                      print('Title text changed to: "$value"');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Updated Rich text toolbar
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
                  // Content area with rich text editor
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTapUp: (details) {
                          final link = _getLinkAtCursor();
                          print('Tap detected, link: $link');
                          if (link != null && link.isNotEmpty) {
                            _handleLinkTap(link);
                          }
                        },
                        child: QuillEditor(
                          controller: _quillController,
                          scrollController: _scrollController,
                          focusNode: _focusNode,
                          config: QuillEditorConfig(
                            // readOnly is set on the controller, not in the config
                            placeholder: 'Write your thoughts here...',
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
                            // Use default styles for simplicity and compatibility
                            customStyles: DefaultStyles(
                              paragraph: DefaultTextBlockStyle(
                                TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: _textColor,
                                ),
                                const HorizontalSpacing(0, 0),  // horizontalSpacing
                                const VerticalSpacing(0, 0),    // verticalSpacing
                                const VerticalSpacing(0, 0),    // lineSpacing
                                null,                           // decoration
                              ),
                              link: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            // Configure embedBuilders to handle images and videos with fixed size
                            embedBuilders: [
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
                                        // Attempt to load a placeholder
                                        return NetworkImage('https://via.placeholder.com/300x200?text=Video');
                                      } catch (e) {
                                        print('Error loading placeholder image: $e');
                                        // Fallback to a default color or another placeholder
                                        return MemoryImage(Uint8List(0)); // Empty image
                                      }
                                    } else if (kIsWeb) {
                                      // For web, we can't use FileImage, so we'll use a network placeholder
                                      print('Warning: Unsupported image source on web: $imageSource');
                                      return NetworkImage('https://via.placeholder.com/300x200?text=Image');
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
                                videoEmbedConfig: QuillEditorVideoEmbedConfig(
                                  onVideoInit: (videoContainerKey) {
                                    print('Video initialized with key: $videoContainerKey');
                                  },
                                  customVideoBuilder: (videoUrl, readOnly) {
                                    print('Building custom video for URL: $videoUrl');
                                    return null; // Return null to use default video builder
                                  },
                                ),
                              ),
                              // Custom video embed builder removed
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),


      ],
    );

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: CustomScaffold(
      selectedPage: _selectedPage,
      onItemSelected: (String page) {
        setState(() {
          _selectedPage = page;
        });
      },
      body: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.menu_book, size: 24, color: Color(0xFF255DE1)),
              SizedBox(width: 8),
              Text('Diary'),
            ],
          ),
         actions: [
  // Template and mood selection buttons removed
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

  // Video button removed - using Flutter Quill toolbar for video embedding

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
  // Show only the appropriate button based on whether we're editing or creating
  IconButton(
    icon: widget.initialData != null && widget.initialData!['id'] != null
      ? const Icon(Icons.update)
      : const Icon(Icons.save),
    onPressed: widget.initialData != null && widget.initialData!['id'] != null
      ? _updateSaveDiary
      : _saveDiary,
    tooltip: widget.initialData != null && widget.initialData!['id'] != null
      ? 'Update Diary'
      : 'Save New Diary',
  ),
  // Show delete button only when editing an existing entry
  if (widget.initialData != null && widget.initialData!['id'] != null)
    IconButton(
      icon: const Icon(Icons.delete),
      onPressed: _deleteDiary,
      tooltip: 'Delete Diary',
    ),
],

        ),
        body: diaryContent,
      ),
      floatingActionButton: null,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}