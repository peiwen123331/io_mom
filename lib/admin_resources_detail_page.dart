import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:io_mom/database.dart';
import 'admin_resources_page.dart';
import 'resources.dart';
import 'admin_home_page.dart';

class ResourceDetailPage extends StatefulWidget {
  final Resources? resource; // null means adding new resource

  const ResourceDetailPage({super.key, this.resource});

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _articleURLController;

  String _resourceID = '';
  File? _selectedImage;
  String? _existingImagePath;
  String? _imageDownloadUrl;
  bool isLoading = false;
  bool _isGeneratingID = true;

  bool get isEditMode => widget.resource != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (!isEditMode) {
      _generateID();
    } else {
      _resourceID = widget.resource!.ResourceID;
      _existingImagePath = widget.resource!.articleImgPath;
      _isGeneratingID = false;
      // Load image URL if path exists
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.resource?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.resource?.description ?? '',
    );
    _articleURLController = TextEditingController(
      text: widget.resource?.articleURL ?? '',
    );
  }

  Future<void> _generateID() async {
    setState(() => _isGeneratingID = true);
    try {
      var rid = await dbService.generateResourcesID();
      setState(() {
        _resourceID = rid;
        _isGeneratingID = false;
      });
    } catch (e) {
      setState(() => _isGeneratingID = false);
      _showDialog("Error", "Failed to generate ID: $e");
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _articleURLController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showDialog("Error", "Failed to pick image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pink),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.pink),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null || _imageDownloadUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _existingImagePath = null;
                      _imageDownloadUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveResource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_resourceID.isEmpty) {
      _showDialog("Error", "Resource ID is not generated yet");
      return;
    }

    if(_titleController.text.trim().isEmpty){
      _showDialog("Error", "Please enter the title");
      return;
    }
    if(_titleController.text.trim().length > 100){
      _showDialog("Title too long", "Please enter a valid title");
      return;
    }
    if(_descriptionController.text.trim().isEmpty){
      _showDialog("Error", "Please enter the description");
      return;
    }
    if(_descriptionController.text.trim().length > 300){
      _showDialog("Title too long", "Please enter a valid title");
      return;
    }
    if(_articleURLController.text.trim().isEmpty){
      _showDialog("Error", "Please enter the url");
      return;
    }
    if(!_articleURLController.text.trim().contains('http://') && !_articleURLController.text.trim().contains('https://')){
      _showDialog("Error", "Please enter valid url");
      return;
    }
    setState(() => isLoading = true);

    try {
      String imagePath = _existingImagePath ?? '';

      final resource = Resources(
        ResourceID: _resourceID,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        articleURL: _articleURLController.text.trim(),
        articleImgPath: imagePath,
        date: widget.resource?.date ?? DateTime.now(),
      );

      if (isEditMode) {
        await dbService.editResources(resource);
        _showDialog("Success", "Resource updated successfully!");
      } else {
        await dbService.insertResources(resource);
        _showDialog("Success", "Resource added successfully!");
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
      Navigator.push(context, MaterialPageRoute(builder: (_)=>AdminResourcesPage()));
    } catch (e) {
      _showDialog("Error", "Failed to save resource: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteResource() async {
    if (!isEditMode) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Resource",
            style: TextStyle(color: Colors.pink)),
        content: const Text(
            "Are you sure you want to delete this resource? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await dbService.deleteResource(widget.resource!.ResourceID);
        _showDialog("Success", "Resource deleted successfully!");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showDialog("Error", "Failed to delete resource: $e");
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _showDialog(String title, String message) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.pink)),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = true,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.pink, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      ),
      validator: required
          ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Resource Image",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
                : _existingImagePath != null && _existingImagePath!.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                _existingImagePath!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              ),
            )
                : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tap to ${_selectedImage != null || _existingImagePath != null ? 'change' : 'add'} image",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            "Add Image",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>AdminHomePage())),
        ),
        title: Text(
          isEditMode ? "Edit Resource" : "Add Resource",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: isLoading ? null : _deleteResource,
            ),
        ],
      ),
      body: isLoading || _isGeneratingID
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resource ID (View Only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resource ID",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resourceID.isEmpty ? "Generating..." : _resourceID,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              _buildTextField(
                controller: _titleController,
                label: "Title",
                hint: "Enter resource title",
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Enter resource description",
                maxLines: 4,
                required: false,
              ),
              const SizedBox(height: 16),

              // Article URL
              _buildTextField(
                controller: _articleURLController,
                label: "Article URL",
                hint: "Enter article URL",
                required: false,
              ),
              const SizedBox(height: 24),

              // Image Section
              _buildImageSection(),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: isLoading ? null : _saveResource,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEditMode ? "Update Resource" : "Add Resource",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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