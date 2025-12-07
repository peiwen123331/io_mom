import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:io_mom/database.dart';
import 'admin_collaboration_request_page.dart';
import 'confinement_center.dart';
import 'confinement_center_home_page.dart';
import 'profile.dart';

class CcProfilePage extends StatefulWidget {
  final String centerID;
  final String from;

  const CcProfilePage({
    super.key,
    required this.centerID,
    required this.from,
  });

  @override
  State<CcProfilePage> createState() => _CcProfilePageState();
}

class _CcProfilePageState extends State<CcProfilePage> {
  final dbService = DatabaseService();
  final _centerNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _centerImage;
  Future<ConfinementCenter?>? centerFuture;
  late bool isEditing;

  String selectedCountryCode = '+60'; // default: Malaysia 🇲🇾
  final List<Map<String, String>> countryCodes = [
    {'code': '+60', 'country': 'Malaysia'},
  ];

  @override
  void initState() {
    super.initState();
    isEditing = false;
    centerFuture = getCenterInfo();
  }

  Future<ConfinementCenter?> getCenterInfo() async {
    // Replace this with your actual database method
    var center = await dbService.getConfinementByCenterID(widget.centerID);
    return center;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _centerImage = File(pickedFile.path);
      });

      // Optionally update image immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Center photo selected")),
      );
    }
  }

  bool _validatePhone(String phone) {
    final regex = RegExp(r'^[0-9]{9,10}$');
    return regex.hasMatch(phone);
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

  Future<void> updateCenter(ConfinementCenter currentCenter) async {
    // Validation
    if (_contactPersonController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showDialog("Validation Error", "Please complete all required fields.");
      return;
    }

    if (!_validatePhone(_contactController.text.trim())) {
      _showDialog("Validation Error", "Please enter a valid phone number");
      return;
    }

    final centerImgPath = _centerImage?.path ?? currentCenter.centerImgPath;

    final updatedCenter = ConfinementCenter(
      CenterID: widget.centerID,
      CenterName: currentCenter.CenterName,
      ContactPersonName: _contactPersonController.text.trim(),
      centerContact: "$selectedCountryCode${_contactController.text.trim()}",
      centerEmail: currentCenter.centerEmail,
      location: _locationController.text.trim().isEmpty
          ? currentCenter.location
          : _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      centerImgPath: centerImgPath,
      accountNo: currentCenter.accountNo,
      accountName: currentCenter.accountName,
      bankName: currentCenter.bankName,
    );

    await dbService.editConfinementCenter(updatedCenter);

    // Show dialog and navigate on OK
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success", style: TextStyle(color: Colors.pink)),
        content: const Text("Profile saved successfully!"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (widget.from == 'Splash') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfinementCenterHomePage(),
                  ),
                );
              }
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    setState(() {
      isEditing = false;
      centerFuture = getCenterInfo();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confinement Center Details"),
        leading: widget.from == 'Splash' ? SizedBox() : IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if(widget.from == 'Admin'){
              Navigator.push(context, MaterialPageRoute(builder: (_)=> AdminCollaborationRequestPage()));
            }else{
              Navigator.push(context, MaterialPageRoute(builder: (_)=> ProfilePage(from: 'Confinement Center',)));
            }
          },
        ),
      ),
      body: FutureBuilder<ConfinementCenter?>(
        future: centerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No center data found"));
          }

          final center = snapshot.data!;
          _centerNameController.text = center.CenterName;
          _contactPersonController.text = center.ContactPersonName;
          _emailController.text = center.centerEmail;
          _locationController.text = center.location;
          _descriptionController.text = center.description ?? "";

          final rawPhone = center.centerContact?.replaceAll(RegExp(r'\D'), '') ?? '';
          _contactController.text = rawPhone.length > 2 ? rawPhone.substring(2) : rawPhone;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _centerImage != null
                                ? FileImage(_centerImage!)
                                : (center.centerImgPath != null &&
                                center.centerImgPath!.isNotEmpty
                                ? (center.centerImgPath!.startsWith('assets/')
                                ? AssetImage(center.centerImgPath!)
                                : FileImage(File(center.centerImgPath!)))
                                : const AssetImage(
                                'assets/images/profile/profile.png')),
                          ),
                          if (isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE91E63),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🏢 Display-only fields
                _buildDisplayField("Center Name", _centerNameController),
                _buildDisplayField("Email", _emailController),
                // 📝 Editable Description field
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _contactPersonController,
                    enabled: isEditing,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: "Contact Person",
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _locationController,
                    enabled: isEditing,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 📞 Editable Phone field with country dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: selectedCountryCode,
                        onChanged: isEditing
                            ? (value) {
                          setState(() {
                            selectedCountryCode = value!;
                          });
                        }
                            : null,
                        items: countryCodes
                            .map(
                              (e) => DropdownMenuItem<String>(
                            value: e['code'],
                            child: Text("${e['country']} (${e['code']})"),
                          ),
                        )
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _contactController,
                          enabled: isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Contact Number",
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pinkAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📝 Editable Description field
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _descriptionController,
                    enabled: isEditing,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (!isEditing) {
                        setState(() => isEditing = true);
                        return;
                      }
                      await updateCenter(center);
                    },
                    child: Text(
                      isEditing ? "Save" : "Edit",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplayField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}