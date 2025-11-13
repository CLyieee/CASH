import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/gemini_controller.dart';

class CustomImageAnalysisPage extends StatefulWidget {
  const CustomImageAnalysisPage({super.key});

  @override
  State<CustomImageAnalysisPage> createState() =>
      _CustomImageAnalysisPageState();
}

class _CustomImageAnalysisPageState extends State<CustomImageAnalysisPage> {
  final GeminiController geminiController = Get.put(GeminiController());
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  Map<String, dynamic>? _receiptData;
  String? _customAnalysis;

  final List<TextEditingController> _fieldControllers = [];
  final TextEditingController _requirementsController = TextEditingController();

  @override
  void dispose() {
    for (var controller in _fieldControllers) {
      controller.dispose();
    }
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _receiptData = null;
          _customAnalysis = null;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _analyzeReceipt() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final result = await geminiController.analyzeReceiptImage(bytes);

      setState(() {
        _receiptData = result;
      });
    } catch (e) {
      _showError('Error analyzing receipt: $e');
    }
  }

  Future<void> _extractCustomFields() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    final fields = _fieldControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (fields.isEmpty) {
      _showError('Please add at least one field to extract');
      return;
    }

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final result = await geminiController.extractCustomInfo(
        bytes,
        fields,
      );

      setState(() {
        _customAnalysis = result;
      });
    } catch (e) {
      _showError('Error extracting fields: $e');
    }
  }

  Future<void> _analyzeWithCustomRequirements() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    if (_requirementsController.text.trim().isEmpty) {
      _showError('Please enter analysis requirements');
      return;
    }

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final result = await geminiController.analyzeCustomDocument(
        bytes,
        _requirementsController.text.trim(),
      );

      setState(() {
        _customAnalysis = result;
      });
    } catch (e) {
      _showError('Error analyzing document: $e');
    }
  }

  void _addFieldInput() {
    setState(() {
      _fieldControllers.add(TextEditingController());
    });
  }

  void _removeFieldInput(int index) {
    setState(() {
      _fieldControllers[index].dispose();
      _fieldControllers.removeAt(index);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        title: const Text('Custom Image Analysis'),
        backgroundColor: const Color(0xFFE0E5EC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection
            _buildImageSection(),
            const SizedBox(height: 24),

            // Tab Selection
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.blue[700],
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue[700],
                    tabs: const [
                      Tab(text: 'Receipt'),
                      Tab(text: 'Custom Fields'),
                      Tab(text: 'Custom Analysis'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildReceiptTab(),
                        _buildCustomFieldsTab(),
                        _buildCustomAnalysisTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results
            if (_receiptData != null || _customAnalysis != null)
              _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
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
                const SizedBox(width: 12),
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
    );
  }

  Widget _buildReceiptTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Automatically extract receipt information',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton(
                onPressed:
                    geminiController.isLoading.value ? null : _analyzeReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: geminiController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Analyze Receipt'),
              )),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Specify exact fields to extract',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _fieldControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fieldControllers[index],
                          decoration: InputDecoration(
                            hintText: 'e.g., Total Amount',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeFieldInput(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addFieldInput,
            icon: const Icon(Icons.add),
            label: const Text('Add Field'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => ElevatedButton(
                onPressed: geminiController.isLoading.value
                    ? null
                    : _extractCustomFields,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: geminiController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Extract Fields'),
              )),
        ],
      ),
    );
  }

  Widget _buildCustomAnalysisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Describe what you want to analyze',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _requirementsController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'e.g., Extract all product names and prices, identify the store type, check for discounts...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton(
                onPressed: geminiController.isLoading.value
                    ? null
                    : _analyzeWithCustomRequirements,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: geminiController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Analyze'),
              )),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      margin: const EdgeInsets.only(top: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy to clipboard functionality
                  },
                  tooltip: 'Copy results',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_receiptData != null)
              _buildReceiptResults(_receiptData!)
            else if (_customAnalysis != null)
              SelectableText(
                _customAnalysis!,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptResults(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final key = entry.key.replaceAll('_', ' ').toUpperCase();
        final value = entry.value;

        if (value is List) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...value.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('• ${item.toString()}'),
                  )),
              const SizedBox(height: 8),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
