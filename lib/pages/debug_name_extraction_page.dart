import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/gemini_service.dart';

/// Debug page to test name extraction from receipts
class DebugNameExtractionPage extends StatefulWidget {
  const DebugNameExtractionPage({super.key});

  @override
  State<DebugNameExtractionPage> createState() =>
      _DebugNameExtractionPageState();
}

class _DebugNameExtractionPageState extends State<DebugNameExtractionPage> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  String? _extractedName;
  String? _fullText;
  String? _fullResponse;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedName = null;
          _fullText = null;
          _fullResponse = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _testNameExtraction() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();

      // 1. Try focused name extraction
      final name = await _geminiService.extractRecipientName(bytes);

      // 2. Get full text debug
      final fullText = await _geminiService.debugExtractAllText(bytes);

      // 3. Get full receipt analysis
      final fullResponse = await _geminiService.analyzeReceiptImage(bytes);

      setState(() {
        _extractedName = name;
        _fullText = fullText;
        _fullResponse = fullResponse?.toString();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        title: const Text('Debug Name Extraction'),
        backgroundColor: const Color(0xFFE0E5EC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test button
            ElevatedButton.icon(
              onPressed: _selectedImage == null || _isProcessing
                  ? null
                  : _testNameExtraction,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.science),
              label: Text(_isProcessing ? 'Testing...' : 'Test Extraction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_errorMessage != null)
              _buildResultCard(
                'Error',
                _errorMessage!,
                Colors.red,
                Icons.error_outline,
              ),

            if (_extractedName != null)
              _buildResultCard(
                'Extracted Name (Focused Method)',
                _extractedName!,
                Colors.green,
                Icons.person,
                copyable: true,
              ),

            if (_fullText != null)
              _buildResultCard(
                'All Text AI Can See',
                _fullText!,
                Colors.blue,
                Icons.text_fields,
                copyable: true,
                expandable: true,
              ),

            if (_fullResponse != null)
              _buildResultCard(
                'Full Receipt Data',
                _fullResponse!,
                Colors.purple,
                Icons.receipt_long,
                copyable: true,
                expandable: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    String title,
    String content,
    Color color,
    IconData icon, {
    bool copyable = false,
    bool expandable = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: !expandable,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: copyable
            ? IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
