import 'dart:io';
import 'login_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:io_mom/collaboration_request.dart';
import 'package:io_mom/smtp_service.dart';

class RequestCollaborationPage extends StatefulWidget {
  const RequestCollaborationPage({super.key});

  @override
  State<RequestCollaborationPage> createState() => _RequestCollaborationPageState();
}

class _RequestCollaborationPageState extends State<RequestCollaborationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBank;
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessRegNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _accNoController = TextEditingController();
  final TextEditingController _accHolderController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  String? _selectedCountry;

// List of countries (you can expand this)
  final List<String> countries = [
    "Malaysia",
  ];

// Malaysian states list (for Malaysia-specific validation)
  final List<String> malaysianStates = [
    "Johor",
    "Kedah",
    "Kelantan",
    "Malacca",
    "Negeri Sembilan",
    "Pahang",
    "Penang",
    "Perak",
    "Perlis",
    "Sabah",
    "Sarawak",
    "Selangor",
    "Terengganu",
    "Kuala Lumpur",
    "Labuan",
    "Putrajaya",
  ];

  List<String> bankList = [
    "Affin Bank",
    "Agrobank",
    "Al Rajhi Bank",
    "Alliance Bank",
    "AmBank",
    "Bangkok Bank",
    "Bank Islam",
    "Bank Muamalat",
    "Bank of America",
    "Bank of China",
    "Bank Rakyat",
    "BSN (Bank Simpanan Nasional)",
    "BNP Paribas",
    "China Construction Bank",
    "CIMB Bank",
    "Citibank",
    "Deutsche Bank",
    "Hong Leong Bank",
    "HSBC Bank",
    "ICBC (Industrial and Commercial Bank of China)",
    "J.P. Morgan Chase",
    "Kuwait Finance House",
    "Maybank",
    "Mizuho Bank",
    "OCBC Bank",
    "Public Bank",
    "RHB Bank",
    "Standard Chartered",
    "SMBC (Sumitomo Mitsui Banking Corporation)",
    "MUFG Bank (Bank of Tokyo-Mitsubishi UFJ)",
    "UOB Bank",
  ];



  // List of required documents
  final List<Map<String, dynamic>> _documents = [
    {"name": "Business Registration Certification", "file": null},
    {"name": "NRIC copy", "file": null},
    {"name": "Bank Statement", "file": null},
    {"name": "Logo", "file": null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Request Collaboration",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile info",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 15),

              _buildLabeledField("Business Name", _businessNameController,keyboard: TextInputType.text),
              _buildLabeledField("Business Reg. No.", _businessRegNoController),
              _buildLabeledField("Email", _emailController, keyboard: TextInputType.emailAddress),
              _buildLabeledField("Street Address", _streetController, keyboard: TextInputType.streetAddress, maxLines: 2),
              Row(
                children: [
                  Expanded(
                    child: _buildLabeledField("Postcode", _postcodeController,  keyboard: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLabeledField("City", _cityController, keyboard: TextInputType.text),
                  ),
                ],
              ),
              _buildStateDropdownField("State"),
              _buildCountryDropdownField("Country"),
              _buildLabeledField("Contact Person Name", _contactController, keyboard: TextInputType.text),
              _buildDropdownField("Bank Name"),
              _buildLabeledField("Acc No", _accNoController,keyboard: TextInputType.number),
              _buildLabeledField("Acc Holder Name", _accHolderController, keyboard: TextInputType.text),

              const SizedBox(height: 20),
              const Text(
                "Support Document",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // Document upload cards
              ..._documents.map((doc) => _buildDocumentCard(doc)),

              const SizedBox(height: 30),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Add this new method for State dropdown:
  Widget _buildStateDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent)),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _stateController.text.isEmpty ? null : _stateController.text,
            decoration: const InputDecoration(
              labelText: "Select State",
              labelStyle: TextStyle(color: Colors.pinkAccent),
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
              ),
            ),
            items: malaysianStates.map((state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(state, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _stateController.text = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a state';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

// Add this new method for Country dropdown:
  Widget _buildCountryDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent)),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: "Select Country",
              labelStyle: TextStyle(color: Colors.pinkAccent),
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
              ),
            ),
            items: countries.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a country';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }


  Widget _buildLabeledField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent)),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.pinkAccent, width: 2)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }

              final trimmedValue = value.trim();

              // Street Address validation
              if (label == "Street Address") {
                if (trimmedValue.length < 5) {
                  return 'Street address is too short';
                }
                if (trimmedValue.length > 100) {
                  return 'Street address is too long';
                }
              }

              // Postcode validation
              if (label == "Postcode") {
                final cleanValue = trimmedValue.replaceAll(RegExp(r'[\s\-]'), '');
                if (cleanValue.length < 4 || cleanValue.length > 6) {
                  return 'Invalid postcode format';
                }
                if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
                  return 'Postcode should only contain numbers';
                }
              }

              // City validation
              if (label == "City") {
                if (trimmedValue.length < 2) {
                  return 'City name is too short';
                }
                if (trimmedValue.length > 50) {
                  return 'City name is too long';
                }
                if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(trimmedValue)) {
                  return 'City name should only contain letters';
                }
              }

              // Business Name validation
              if (label == "Business Name") {
                if (trimmedValue.length < 3) {
                  return 'Business name must be at least 3 characters';
                }
                if (trimmedValue.length > 100) {
                  return 'Business name is too long';
                }
                if (!RegExp(r'^[a-zA-Z0-9\s&\-.,()]+$').hasMatch(trimmedValue)) {
                  return 'Business name contains invalid characters';
                }
              }

              // Business Registration Number validation
              if (label == "Business Reg. No.") {
                final cleanValue = trimmedValue.replaceAll(RegExp(r'[\s\-]'), '');
                if (cleanValue.length < 6) {
                  return 'Registration number is too short';
                }
                if (!RegExp(r'^[A-Z0-9\-\s]+$', caseSensitive: false).hasMatch(trimmedValue)) {
                  return 'Registration number contains invalid characters';
                }
              }

              // Email validation
              if (label == "Email") {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(trimmedValue)) {
                  return 'Please enter a valid email address';
                }
              }

              // Contact Person Name validation
              if (label == "Contact Person Name") {
                if (trimmedValue.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (trimmedValue.length > 50) {
                  return 'Name is too long';
                }
                if (!RegExp(r'^[a-zA-Z\s.]+$').hasMatch(trimmedValue)) {
                  return 'Name should only contain letters';
                }
              }

              // Account Number validation
              if (label == "Acc No") {
                final cleanValue = trimmedValue.replaceAll(RegExp(r'[\s\-]'), '');
                if (cleanValue.length < 8 || cleanValue.length > 20) {
                  return 'Account number must be 8-20 digits';
                }
                if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
                  return 'Account number should only contain digits';
                }
              }

              // Account Holder Name validation
              if (label == "Acc Holder Name") {
                if (trimmedValue.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (trimmedValue.length > 100) {
                  return 'Name is too long';
                }
                if (!RegExp(r'^[a-zA-Z\s.@&\-]+$').hasMatch(trimmedValue)) {
                  return 'Name contains invalid characters';
                }
              }

              return null;
            },
          ),
        ],
      ),
    );
  }


  Widget _buildDropdownField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent)),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedBank,
            decoration: const InputDecoration(
              labelText: "Select Bank",
              labelStyle: TextStyle(color: Colors.pinkAccent),
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
              ),
            ),
            items: bankList.map((bank) {
              return DropdownMenuItem<String>(
                value: bank,
                child: Text(bank, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBank = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a bank';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }



  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_copy_rounded,
            color: Colors.pinkAccent, size: 30),
        title: Text(
          doc["name"],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: doc["file"] != null
            ? Text(
          "Uploaded: ${doc["file"].path.split('/').last}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        )
            : const Text(
          "No file selected",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_box_rounded, color: Colors.pinkAccent),
          onPressed: () async {
            FilePickerResult? result =
            await FilePicker.platform.pickFiles(type: FileType.any);

            if (result != null) {
              setState(() {
                doc["file"] = File(result.files.single.path!);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${doc['name']} uploaded successfully!")),
              );
            }
          },
        ),
      ),
    );
  }


  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields correctly."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    bool allDocsUploaded = _documents.every((doc) => doc["file"] != null);
    if (!allDocsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload all required documents."),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      ),
    );

    try {
      // Combine address fields
      final fullAddress =
          "${_streetController.text.trim()}, "
          "${_postcodeController.text.trim()} ${_cityController.text.trim()}, "
          "${_stateController.text.trim()}, "
          "${_selectedCountry ?? ''}";

      var requestID = await dbService.generateRequestID();
      final formData = CollaborationRequest(
        RequestID: requestID,
        centerName: _businessNameController.text.trim(),
        contactPersonName: _contactController.text.trim(),
        businessRegNo: _businessRegNoController.text.trim(),
        centerEmail: _emailController.text.trim(),
        requestDate: DateTime.now(),
        bankName: _selectedBank!,
        accountNo: _accNoController.text.trim(),
        accountName: _accHolderController.text.trim(),
        status: 'P',
        approveDate: '',
        location: fullAddress, // Combined address
      );

      await dbService.insertCollaborationRequest(formData);
      await sendCollaborationRequestEmail(
        formData,
        _documents[0]['file']?.path,
        _documents[1]['file']?.path,
        _documents[2]['file']?.path,
        _documents[3]['file']?.path,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Request Submitted",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              content: const Text(
                "Your collaboration request is under review.\n\nOnce approved, you will receive an email notification. Please keep an eye on your inbox.",
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                          (route) => false,
                    );
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit request: $e"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

}
