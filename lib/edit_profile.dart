import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_user_page.dart';
import 'home.dart';
import 'phone_otp.dart';
import 'profile.dart';
import 'user.dart';

class EditProfilePage extends StatefulWidget {
  final String userID;
  final String from;

  const EditProfilePage({
    super.key,
    required this.userID,
    required this.from,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final dbService = DatabaseService();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _statusController = TextEditingController();
  final _regDateController = TextEditingController();
  Users currentUser = Users.empty();

  File? _profileImage;
  DateTime? originalRegDate;
  Future<Users?>? userFuture;
  late bool isEditing;
  String? _loginType;
  String? _selectedRole;
  bool _isRoleLocked = false;
  bool _isPhoneVerified = false; // Track phone verification status
  bool _isVerifying = false; // Track verification loading state
  String? _originalPhoneVerifyStatus; // Store original DB status

  List<String> get userRoles {
    if (widget.from == 'AdminUser') {
      return [
        'Pregnant Women',
        'Family Member/Caregiver',
      ];
    } else if (widget.from == 'Splash') {
      return [
        'Pregnant Women',
        'Family Member/Caregiver',
      ];
    }
    return [
      'Pregnant Women',
      'Family Member/Caregiver',
      'Admin'
    ];
  }

  final List<String> userStatuses = ['Active', 'Inactive'];

  String selectedCountryCode = '+60'; // default: Malaysia 🇲🇾
  final List<Map<String, String>> countryCodes = [
    {'code': '+60', 'country': 'Malaysia'},
  ];

  @override
  void initState() {
    super.initState();
    _isPhoneVerified = false; // ✅ Initialize to false
    isEditing = widget.from == 'Splash' || widget.from == 'AdminUser';
    userFuture = getUserInfo();
  }

  Future<Users?> getUserInfo() async {
    var user = await dbService.getUserByUID(widget.userID);
    setState(() {
      currentUser = user!;
    });
    if (mounted) {
      setState(() {
        _loginType = user!.loginType;
        _selectedRole = mapRoleCodeToLabel(user.userRole);
        _isRoleLocked = widget.from != 'AdminUser' &&
            _selectedRole != null &&
            _selectedRole!.isNotEmpty;

        // --- NEW/MOVED CODE: Populate Controllers ONCE here ---
        _emailController.text = user.userEmail;
        _statusController.text = user.userStatus == 'A' ? "Active" : "Inactive";
        originalRegDate = user.userRegDate;
        _regDateController.text =
            DateFormat('dd-MM-yyyy HH:mm:ss').format(user.userRegDate);
        _usernameController.text = user.userName ?? "";

        final fullPhone = user.phoneNo ?? ''; // e.g., +60123456789
        final rawPhoneDigits = fullPhone.replaceAll(RegExp(r'\D'), ''); // e.g., 60123456789

        // Set the stored country code (assuming +XX format)
        if (fullPhone.startsWith('+') && fullPhone.length >= 3) {
          selectedCountryCode = fullPhone.substring(0, 3); // e.g., +60
        }

        // Set the phone number field (digits without country code)
        final codeDigits = selectedCountryCode.replaceAll(RegExp(r'\D'), ''); // e.g., 60
        if (rawPhoneDigits.startsWith(codeDigits)) {
          // Set the controller to the digits following the country code
          _phoneController.text = rawPhoneDigits.substring(codeDigits.length);
        } else {
          _phoneController.text = rawPhoneDigits;
        }
        // --------------------------------------------------------

        // ✅ Store original phone verification status
        _originalPhoneVerifyStatus = user.isPhoneVerify;

        // ✅ Set verification state based on user type
        if (widget.from == 'AdminUser') {
          _isPhoneVerified = true;
        } else {
          _isPhoneVerified = (user.isPhoneVerify?.toUpperCase() == 'T');
          print('DEBUG: _isPhoneVerified set to $_isPhoneVerified');
        }
      });
    }

    return user;
  }

  String mapRoleCodeToLabel(String? code) {
    switch (code) {
      case 'P':
        return 'Pregnant Women';
      case 'FC':
        return 'Family Member/Caregiver';
      case 'A':
        return 'Admin';
      default:
        return '';
    }
  }

  String mapRoleLabelToCode(String? label) {
    switch (label) {
      case 'Pregnant Women':
        return 'P';
      case 'Family Member/Caregiver':
        return 'FC';
      case 'Admin':
        return 'A';
      default:
        return '';
    }
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

      // Get current user data to preserve other fields
      Users? currentUser = await dbService.getUserByUID(widget.userID);
      if (currentUser == null) return;

      Users updatedUser = Users(
        userID: widget.userID,
        userName: _usernameController.text,
        userEmail: _emailController.text,
        userRegDate: originalRegDate!,
        phoneNo: _phoneController.text.trim(),
        userStatus: _statusController.text == "Active" ? "A" : "I",
        profileImgPath: pickedFile.path,
        userRole: mapRoleLabelToCode(_selectedRole),
        loginType: _loginType!,
        isPhoneVerify: currentUser.isPhoneVerify, // ✅ Preserve verification status
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

  // Method to send OTP
  Future<void> _verifyPhoneNumber() async {
    if (!_validatePhone(_phoneController.text.trim())) {
      _showDialog("Validation Error", "Please enter a valid phone number");
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final fullPhoneNumber = "$selectedCountryCode${_phoneController.text.trim()}";
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          if (mounted) {
            setState(() {
              _isPhoneVerified = true;
              _isVerifying = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Phone verified automatically!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isVerifying = false;
            });
            _showDialog("Verification Failed", e.message ?? "Failed to send OTP");
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (mounted) {
            setState(() {
              _isVerifying = false;
            });

            // Navigate to OTP page
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhoneOtpPage(
                  phoneNumber: fullPhoneNumber,
                  verificationId: verificationId,
                  from: "EditProfile",
                ),
              ),
            );

            if (result == true && mounted) {
              setState(() {
                _isPhoneVerified = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Phone number verified successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showDialog("Error", "Failed to verify phone number: $e");
      }
    }
  }

  Future<void> updateUser(Users currentUser) async {
    // Admin can skip role confirmation
    if (widget.from != 'AdminUser') {
      if (_selectedRole == null || _selectedRole!.isEmpty) {
        _showDialog("Validation Error", "Please select your role");
        return;
      }

      if (!_isRoleLocked) {
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Role", style: TextStyle(color: Colors.pink)),
            content: Text(
                "Once selected as '${_selectedRole}', your role cannot be changed later.\nDo you want to continue?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (!confirm) return;
      }
    }

    if (_usernameController.text.trim().isEmpty) {
      _showDialog("Validation Error", "Please enter username");
      return;
    }

    if (!_validatePhone(_phoneController.text.trim())) {
      _showDialog("Validation Error", "Please enter a valid phone number");
      return;
    }

    // ✅ Check phone verification for non-admin users
    if (widget.from != 'AdminUser' && !_isPhoneVerified) {
      _showDialog("Verification Required", "Please verify your phone number before saving");
      return;
    }

    String status = widget.from == 'AdminUser'
        ? (_statusController.text == "Active" ? "A" : "I")
        : currentUser.userStatus;
    final profilePath = _profileImage?.path ?? currentUser.profileImgPath;

    // ✅ Determine phone verification status
    String phoneVerifyStatus;
    if (widget.from == 'AdminUser') {
      // Admin saves: keep original status or set as verified
      phoneVerifyStatus = currentUser.isPhoneVerify ?? 'T';
    } else {
      // Regular user: set to 'T' if verified, otherwise keep original
      phoneVerifyStatus = _isPhoneVerified ? 'T' : (currentUser.isPhoneVerify ?? 'F');
    }

    final updatedUser = Users(
      userID: widget.userID,
      userName: _usernameController.text,
      userEmail: _emailController.text,
      userRegDate: originalRegDate ?? currentUser.userRegDate,
      phoneNo: "$selectedCountryCode${_phoneController.text.trim()}",
      userStatus: status,
      profileImgPath: profilePath,
      userRole: mapRoleLabelToCode(_selectedRole) ?? currentUser.userRole,
      loginType: _loginType!,
      isPhoneVerify: phoneVerifyStatus, // ✅ Use determined status
    );

    await dbService.editUser(updatedUser);

    if (mounted) {
      setState(() {
        _isRoleLocked = true; // Lock role after saving
      });

      _showDialog("Success", "Profile updated successfully!");
    }

    if (widget.from == 'AdminUser') {
      // For admin, go back to AdminUserPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminUserPage()),
      );
    } else if (widget.from != 'Splash') {
      setState(() {
        isEditing = false;
        userFuture = getUserInfo();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdminEditing = widget.from == 'AdminUser';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdminEditing ? "Edit User" : "Edit Profile"),
        leading: widget.from == 'Splash'
            ? const SizedBox()
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.from == 'AdminUser') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminUserPage()),
              );
            } else if (widget.from == 'Admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfilePage(from: 'Admin')),
              );
            } else if (widget.from == 'ConfinementCenter') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const ProfilePage(from: 'ConfinementCenter')),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfilePage(from: 'User')),
              );
            }
          },
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

          _emailController.text = user.userEmail;
          _statusController.text =
          user.userStatus == 'A' ? "Active" : "Inactive";
          originalRegDate = user.userRegDate;
          _regDateController.text =
              DateFormat('dd-MM-yyyy HH:mm:ss').format(user.userRegDate);
          _usernameController.text = user.userName ?? "";
         /* final rawPhone = user.phoneNo?.replaceAll(RegExp(r'\D'), '') ?? '';
          _phoneController.text =
          rawPhone.length > 2 ? rawPhone.substring(2) : rawPhone;*/

          // ✅ DEBUG: Add this to see current state
          if (!isAdminEditing) {
            print('DEBUG in build: _isPhoneVerified=$_isPhoneVerified, user.isPhoneVerify=${user.isPhoneVerify}');
          }

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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Registration Date + Status badge
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
                    if (!isAdminEditing)
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusController.text == "Active"
                              ? Colors.green
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusController.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 30),

                // Role Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: isAdminEditing
                          ? "User Role"
                          : "Select Your Role",
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole?.isNotEmpty == true
                            ? _selectedRole
                            : null,
                        isExpanded: true,
                        hint: Text(isAdminEditing
                            ? "Select user role"
                            : "Choose role"),
                        items: userRoles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (isAdminEditing || (_isRoleLocked == false && isEditing))
                            ? (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                            : null,
                      ),
                    ),
                  ),
                ),

                // Status Dropdown (Only for Admin)
                /*if (isAdminEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "User Status",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pinkAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.pink),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusController.text,
                          isExpanded: true,
                          items: userStatuses.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _statusController.text = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),*/

                _buildDisplayField("Email", _emailController),
                _buildEditableField("Username", _usernameController),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: selectedCountryCode,
                        // MODIFIED: Follow the same logic as phone field
                        onChanged: (isAdminEditing || (isEditing && !_isPhoneVerified))
                            ? (value) {
                          setState(() {
                            selectedCountryCode = value!;
                            if (!isAdminEditing) {
                              _isPhoneVerified = false; // Must re-verify if country code changes
                            }
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
                        disabledHint: Text("${countryCodes.firstWhere((e) => e['code'] == selectedCountryCode)['country']} ($selectedCountryCode)"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          // MODIFIED: Lock the field if already verified in DB
                          enabled: isAdminEditing || (isEditing && !_isPhoneVerified),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pinkAccent),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pink),
                            ),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: _isPhoneVerified ? Colors.green : Colors.grey,
                              ),
                            ),
                            suffixIcon: _isPhoneVerified && !isAdminEditing
                                ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            )
                                : null,
                          ),
                          onChanged: (value) {
                            // Reset verification for non-admin users when phone changes
                            if (!isAdminEditing && mounted) {
                              setState(() {
                                _isPhoneVerified = false;
                                print('DEBUG: Phone changed, _isPhoneVerified reset to false');
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Show verification message if phone is verified
                if (_isPhoneVerified && !isAdminEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Phone number verified",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Verify Phone Button (Only show if NOT verified and NOT admin)
                if (!isAdminEditing && isEditing && !_isPhoneVerified)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isVerifying ? null : _verifyPhoneNumber,
                        icon: _isVerifying
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isVerifying ? "Sending OTP..." : "Verify Phone Number",
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Save/Edit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (!isAdminEditing && isEditing && !_isPhoneVerified)
                        ? null
                        : () async {
                      if (!isEditing && widget.from != 'Splash' && !isAdminEditing) {
                        setState(() => isEditing = true);
                        return;
                      }
                      await updateUser(user);
                    },
                    child: Text(
                      (widget.from == 'Splash' || isEditing || isAdminEditing)
                          ? "Save"
                          : "Edit",
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