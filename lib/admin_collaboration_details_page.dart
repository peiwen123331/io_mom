import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:io_mom/user.dart';
import 'dart:math';
import 'admin_collaboration_request_page.dart';
import 'collaboration_request.dart';
import 'confinement_center.dart';
import 'database.dart';
import 'smtp_service.dart';


class AdminCollaborationDetailsPage extends StatefulWidget {
  final String requestID;

  const AdminCollaborationDetailsPage({
    super.key,
    required this.requestID
  });

  @override
  State<AdminCollaborationDetailsPage> createState() =>
      _AdminCollaborationDetailsPageState();
}

class _AdminCollaborationDetailsPageState
    extends State<AdminCollaborationDetailsPage> {
  CollaborationRequest? request;
  final dbService = DatabaseService();

  bool loading = true;

  // Checkbox states
  bool docBusinessCert = false;
  bool docNRIC = false;
  bool docBank = false;
  bool docMama = false;
  bool displayButton = false;

  @override
  void initState() {
    super.initState();
    fetchRequestInfo();
  }

  Future<void> fetchRequestInfo() async {
    request = await dbService.getColRequestByRequestID(widget.requestID);
    setState(() => loading = false);
    if(request!.status == 'P'){
      setState(() {
        displayButton = true;
      });
    }
  }

  // 🔐 Generate secure 8-character password
  String generateSecurePassword() {
    const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const lower = "abcdefghijklmnopqrstuvwxyz";
    const digits = "0123456789";
    const symbols = "@#\$%^&*()-_=+!";

    final rand = Random.secure();
    String password = "";

    password += upper[rand.nextInt(upper.length)];
    password += lower[rand.nextInt(lower.length)];
    password += digits[rand.nextInt(digits.length)];
    password += symbols[rand.nextInt(symbols.length)];

    // Fill remaining 4 chars randomly
    const all = upper + lower + digits + symbols;
    for (int i = 0; i < 4; i++) {
      password += all[rand.nextInt(all.length)];
    }

    // Shuffle
    return String.fromCharCodes(password.runes.toList()..shuffle());
  }

  Future<void> showAcceptConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Acceptance",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to accept this collaboration request?\n\n"
                "An approval email will be sent to the center.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await approveRequest(); // Your accept function
              },
              child: const Text(
                "Accept",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> showRejectConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Rejection",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to reject this collaboration request?\n\n"
                "This action cannot be undone.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                await rejectRequest(); // Your reject function
              },
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> rejectRequest() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      ConfinementCenter tempCenter = ConfinementCenter(
        CenterID: '',
        CenterName: request!.centerName,
        ContactPersonName: request!.contactPersonName,
        centerContact: '',
        centerEmail: request!.centerEmail,
        location: request!.location,
        description: '',
        centerImgPath: '',
        accountNo: '',
        accountName: '',
        bankName: '',
      );

      CollaborationRequest tempRequest = CollaborationRequest(
          RequestID: request!.RequestID,
          centerName: request!.centerName,
          contactPersonName: request!.contactPersonName,
          businessRegNo: request!.businessRegNo,
          centerEmail: request!.centerEmail,
          requestDate: request!.requestDate,
          approveDate: '',
          bankName: request!.bankName,
          accountNo: request!.accountNo,
          accountName: request!.accountName,
          status: 'R',
          location: request!.location);

      await sendTemporaryPasswordEmail(tempCenter, '', 'Rejected');
      await dbService.editColRequestByRequestId(tempRequest);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request rejected successfully."),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const AdminCollaborationRequestPage()),
              (route) => false,
        );
      }
    } on FirebaseException catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      String message = 'An error occurred';
      if (e.code == 'network-request-failed') {
        message = 'No internet connection. Please check your network and try again.';
      } else if (e.code == 'unavailable') {
        message = 'Service temporarily unavailable. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Firebase error during rejection: $e');
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Error during rejection: $e');
    }
  }

  // Approve action
  Future<void> approveRequest() async {
    try {
      if (!(docBusinessCert && docNRIC && docBank && docMama)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify all documents.")),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String tempPassword = generateSecurePassword();
      String centerID = await dbService.generateCenterID();

      CollaborationRequest tempRequest = CollaborationRequest(
          RequestID: request!.RequestID,
          centerName: request!.centerName,
          contactPersonName: request!.contactPersonName,
          businessRegNo: request!.businessRegNo,
          centerEmail: request!.centerEmail,
          requestDate: request!.requestDate,
          approveDate: DateTime.now().toIso8601String(),
          bankName: request!.bankName,
          accountNo: request!.accountNo,
          accountName: request!.accountName,
          status: 'A',
          location: request!.location);

      ConfinementCenter newCenter = ConfinementCenter(
        CenterID: centerID,
        CenterName: request!.centerName,
        ContactPersonName: request!.contactPersonName,
        centerContact: '',
        centerEmail: request!.centerEmail,
        location: request!.location,
        description: '',
        centerImgPath: '',
        accountNo: request!.accountNo,
        accountName: request!.accountName,
        bankName: request!.bankName,
      );

      // Create Firebase Auth user with timeout
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: newCenter.centerEmail,
        password: tempPassword,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      print('tempPassword: $tempPassword');

      Users newUser = Users(
          userID: cred.user!.uid,
          userName: request!.centerName,
          userEmail: request!.centerEmail,
          phoneNo: '',
          userRegDate: DateTime.now(),
          userStatus: 'A',
          userRole: 'C',
          loginType: 'P',
          isPhoneVerify: 'F',
      );

      await dbService.insertUser(newUser);
      await dbService.insertConfinementCenter(newCenter);
      await sendTemporaryPasswordEmail(newCenter, tempPassword, 'Approved');
      await dbService.editColRequestByRequestId(tempRequest);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Approval completed & Email sent."),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const AdminCollaborationRequestPage()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      String message = 'An error occurred';

      if (e.code == 'network-request-failed') {
        message = 'No internet connection. Please check your network and try again.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already registered in the system.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled.';
      } else {
        message = 'Authentication error: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('FirebaseAuth error: ${e.code} - ${e.message}');
    } on FirebaseException catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      String message = 'Database error occurred';
      if (e.code == 'unavailable') {
        message = 'Service temporarily unavailable. Please check your internet connection.';
      } else if (e.code == 'permission-denied') {
        message = 'Permission denied. Please contact administrator.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Firebase error: ${e.code} - ${e.message}');
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Error creating user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (request == null) {
      return const Scaffold(
        body: Center(child: Text("No request found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Confinement Center Management",
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Profile info",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          Text(
            request!.centerName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 5),

          // Business Registration No + Address
          const Text("Business Registration No.",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.pink)),
          const SizedBox(height: 5),
          Text("${request!.businessRegNo}\n${request!.location}",
              style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 30),

          _readonlyField("Email", request!.centerEmail),
          _readonlyField(
              "Contact Person", "${request!.contactPersonName}"),
          _readonlyField("Bank Name", request!.bankName),
          _readonlyField("Account No", request!.accountNo),
          _readonlyField("Account Holder", request!.accountName),

          const SizedBox(height: 30),

          displayButton? Text("Support Documents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              : SizedBox(),
          const SizedBox(height: 15),

          displayButton ? _documentCheckbox(
              "Business Registration Certification", docBusinessCert, (v) {
            setState(() => docBusinessCert = v);
          }) : SizedBox(),
          displayButton ?_documentCheckbox("NRIC Copy", docNRIC, (v) {
            setState(() => docNRIC = v);
          }) : SizedBox(),
          displayButton ?_documentCheckbox("Bank Statement", docBank, (v) {
            setState(() => docBank = v);
          }) : SizedBox(),
          displayButton ?_documentCheckbox("Logo Document", docMama, (v) {
            setState(() => docMama = v);
          }) : SizedBox(),

          const SizedBox(height: 30),

          displayButton ? Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (docBusinessCert &&
                      docNRIC &&
                      docBank &&
                      docMama)
                      ? () {
                    showAcceptConfirmationDialog(context);
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      disabledBackgroundColor: Colors.pink.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      )),
                  child: const Text("Approve",
                      style: TextStyle(color: Colors.white)),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showRejectConfirmationDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Reject",
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ) : SizedBox(),
        ]),
      ),
    );
  }

  // ----------------------------
  // Read-Only Data Field
  // ----------------------------
  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.pink)),
        TextFormField(
          readOnly: true,
          initialValue: value,
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.pink),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.pink),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // Document Checkbox Tile
  // ----------------------------
  Widget _documentCheckbox(
      String title, bool checked, Function(bool) onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            activeColor: Colors.pink,
            onChanged: (v) => onChange(v!),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}