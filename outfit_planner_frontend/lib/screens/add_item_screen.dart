import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/services/api_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  String? _name;
  String? _category;
  String? _color;
  String? _season;

  File? _imageFile;
  Uint8List? _webImage;
  String? _webFilename;

  bool _loading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _webImage = result.files.first.bytes;
          _webFilename = result.files.first.name;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(result.files.single.path!);
          _webImage = null;
          _webFilename = null;
        });
      }
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await api.addWardrobeItem(
        fields: {
          'name': _name!,
          'category': _category!,
          'color': _color!,
          if (_season != null && _season!.isNotEmpty) 'season': _season!,
        },
        image: _imageFile,
        webImage: _webImage,
        webFilename: _webFilename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Item added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to add item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wardrobe Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => _name = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Shirt', 'Pant', 'Jacket', 'Shoes', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Color'),
                onChanged: (val) => _color = val,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a color' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Season (optional)'),
                onChanged: (val) => _season = val,
              ),
              const SizedBox(height: 20),

              // ✅ Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : _webImage != null
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : const Center(
                                child: Text(
                                  'Tap to select an image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Submit button
              ElevatedButton.icon(
                onPressed: _loading ? null : _submitItem,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_loading ? 'Uploading...' : 'Add Item'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
