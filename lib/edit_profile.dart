import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'profile.dart';
import 'user.dart';

class EditProfilePage extends StatefulWidget {
  final String userID;
  final bool fromSplash;

  const EditProfilePage({
    super.key,
    required this.userID,
    required this.fromSplash,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final dbService = DatabaseService();

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _statusController = TextEditingController();
  final _regDateController = TextEditingController();

  File? _profileImage;
  DateTime? originalRegDate;
  Future<Users?>? userFuture;
  late bool isEditing;

  String selectedCountryCode = '+60'; // default: Malaysia 🇲🇾

  final List<Map<String, String>> countryCodes = [
    {'code': '+60', 'country': 'Malaysia'},
    /*{'code': '+65', 'country': 'Singapore'},
    {'code': '+62', 'country': 'Indonesia'},
    {'code': '+63', 'country': 'Philippines'},
    {'code': '+66', 'country': 'Thailand'},
    {'code': '+1', 'country': 'USA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+91', 'country': 'India'},*/
  ];

  @override
  void initState() {
    super.initState();
    isEditing = widget.fromSplash;
    userFuture = getUserInfo();
  }

  Future<Users?> getUserInfo() async {
    return await dbService.getUserByUID(widget.userID);
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
        _profileImage = File(pickedFile.path);
      });

      Users updatedUser = Users(
        userID: _userIdController.text,
        userName: _usernameController.text,
        userEmail: _emailController.text,
        userRegDate: originalRegDate!,
        phoneNo: _phoneController.text.trim(),
        userStatus: _statusController.text == "Active" ? "A" : "I",
        profileImgPath: pickedFile.path,
      );

      await dbService.editUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo updated")),
      );
    }
  }

  bool _validatePhone(String phone) {
    final regex = RegExp(r'^[0-9]{9,10}$');
    return regex.hasMatch(phone);
  }

  Future<void> updateUser(Users currentUser) async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter username")));
      return;
    }

    if (!_validatePhone(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid phone number")));
      return;
    }

    String status = currentUser.userStatus;
    final profilePath = _profileImage?.path ?? currentUser.profileImgPath;

    final updatedUser = Users(
      userID: _userIdController.text,
      userName: _usernameController.text,
      userEmail: _emailController.text,
      userRegDate: originalRegDate ?? currentUser.userRegDate,
      phoneNo: "$selectedCountryCode ${_phoneController.text.trim()}",
      userStatus: status,
      profileImgPath: profilePath,
    );

    await dbService.editUser(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );

    setState(() {
      if (!widget.fromSplash) isEditing = false;
      userFuture = getUserInfo();
    });

    if (widget.fromSplash) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: widget.fromSplash
            ? const SizedBox()
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
        ),
      ),
      body: FutureBuilder<Users?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data found"));
          }

          final user = snapshot.data!;
          _userIdController.text = user.userID;
          _emailController.text = user.userEmail;
          _statusController.text =
          user.userStatus == 'A' ? "Active" : "Inactive";
          originalRegDate = user.userRegDate;
          _regDateController.text =
              DateFormat('dd-MM-yyyy HH:mm:ss').format(user.userRegDate);
          _usernameController.text = user.userName ?? "";
          final rawPhone = user.phoneNo?.replaceAll(RegExp(r'\D'), '') ?? '';
          _phoneController.text = rawPhone.length > 2 ? rawPhone.substring(2) : rawPhone;


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
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : (user.profileImgPath != null &&
                                user.profileImgPath!.isNotEmpty
                                ? (user.profileImgPath!.startsWith('assets/')
                                ? AssetImage(user.profileImgPath!)
                            as ImageProvider
                                : FileImage(File(user.profileImgPath!)))
                                : const AssetImage(
                                'assets/images/profile/profile.png')),
                          ),
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
                      /*Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ID: ${user.userID}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: user.userID));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("User ID copied to clipboard")),
                              );
                            },
                          )
                        ],
                      ),*/
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 Registration Date + Status badge
                // 🟢 Registration Date + Status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Registered on: \n${_regDateController.text}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      alignment: Alignment.center, // ✅ centers text in box
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusController.text == "Active"
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusController.text,
                        textAlign: TextAlign.center, // ✅ horizontal centering
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                _buildDisplayField("Email", _emailController),
                _buildEditableField("Username", _usernameController),

                // 🌍 Phone field with country dropdown
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
                          controller: _phoneController,
                          enabled: isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.pinkAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      if (!isEditing && !widget.fromSplash) {
                        setState(() => isEditing = true);
                        return;
                      }
                      await updateUser(user);
                    },
                    child: Text(
                      (widget.fromSplash || isEditing) ? "Save" : "Edit",
                      style:
                      const TextStyle(color: Colors.white, fontSize: 18),
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

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pinkAccent),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),
          ),
        ),
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
