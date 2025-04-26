import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:provider/provider.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/providers/pages_provider.dart';

class QuickNotesPage extends StatefulWidget {
  const QuickNotesPage({Key? key}) : super(key: key);

  @override
  _QuickNotesPageState createState() => _QuickNotesPageState();
}

class _QuickNotesPageState extends State<QuickNotesPage> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showToolbar = false;
  final TextEditingController _titleController = TextEditingController(text: 'Untitled');
  bool _isDirty = false; // Track if content has been modified

  @override
  void initState() {
    super.initState();
    // Initialize with empty document
    _quillController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen for changes to mark content as dirty
    _quillController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  Future<void> _saveContent() async {
    try {
      // Convert the document to Delta JSON
      final content = jsonEncode(_quillController.document.toDelta().toJson());

      // Save using the PagesProvider
      await Provider.of<PagesProvider>(context, listen: false)
          .createPage(_titleController.text, content);

      setState(() {
        _isDirty = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: ${e.toString()}'))
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isDirty) {
      // Show confirmation dialog if there are unsaved changes
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Do you want to save your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () async {
                await _saveContent();
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CustomScaffold(
        selectedPage: 'Quick Notes',
        onItemSelected: (page) {
          // Handle navigation if needed
        },
        body: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Untitled Note',
                border: InputBorder.none,
              ),
            ),
            actions: [
              if (_isDirty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.circle, color: Colors.blue, size: 12),
                ),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: _saveContent,
                tooltip: 'Save note',
              ),
              IconButton(
                icon: Icon(_showToolbar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                onPressed: () {
                  setState(() {
                    _showToolbar = !_showToolbar;
                  });
                },
                tooltip: _showToolbar ? 'Hide formatting' : 'Show formatting',
              ),
            ],
          ),
          body: Column(
            children: [
              if (_showToolbar)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: const QuillSimpleToolbarConfig(),
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: QuillEditor.basic(
                    controller: _quillController,
                    config: const QuillEditorConfig(
                      // No need for readOnly parameter here, it's controlled by the controller
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quillController.removeListener(_onTextChanged);
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}

