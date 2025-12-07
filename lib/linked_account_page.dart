import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:io_mom/ChatMessages.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'database.dart';
import 'linked_account.dart';
import 'user.dart';
import 'qr_scanner_page.dart';

class LinkedAccountPage extends StatefulWidget {
  final String currentUserID;

  const LinkedAccountPage({
    super.key,
    required this.currentUserID,
  });

  @override
  State<LinkedAccountPage> createState() => _LinkedAccountPageState();
}

class _LinkedAccountPageState extends State<LinkedAccountPage> {
  final dbService = DatabaseService();
  Users user = Users.empty();
  String? _scannedUserID;
  bool _isLinking = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    getUserRole();
  }

  Future<void> getUserRole() async{
    var user = await dbService.getUserByUID(widget.currentUserID);
    setState(() {
      userRole = user!.userRole;
    });
  }

  String generateMessageID(String mainUser, String linkedUser){
    return'${mainUser}_${linkedUser}';
  }
  // -----------------------------------------------------------------------------
  // Get Linked Accounts based on role
  // -----------------------------------------------------------------------------
  Future<List<LinkedAccount>?> _getLinkedAccounts() async {
    if (userRole == 'P') {
      return dbService.getLinkedAccountByMainUserID(widget.currentUserID);
    } else {
      return dbService.getLinkedAccountByLinkedUserID(widget.currentUserID);
    }
  }

  // -----------------------------------------------------------------------------
  // Link Account
  // -----------------------------------------------------------------------------
  Future<void> _linkAccount() async {
    if (_scannedUserID == null) return;

    setState(() => _isLinking = true);

    try {
      LinkedAccount newLink;
      ChatMessages chatMessages;
      final u = await dbService.getUserByUID(widget.currentUserID);
      setState(() {
        user = u!;
      });
      // If current user is main user (P)
      if (userRole == 'P') {
        newLink = LinkedAccount(
          MainUserID: widget.currentUserID,
          LinkedUserID: _scannedUserID!,
          healthDataVisibility: 'T',
          moodDataVisibility: 'T',
          ultrasoundImageVisibility: 'T',
          date: DateTime.now(),
        );
        final id = generateMessageID(user.userID, _scannedUserID!);
        chatMessages = ChatMessages(
            MessageID: id,
            messageContent: 'Hi, I''m ${user.userName!.isEmpty ? user.userEmail : user.userName}' ,
            SenderID: widget.currentUserID,
            ReceiverID: _scannedUserID!,
            time: DateTime.now()
        );
      } else {
        // If current user is linked user (FC)
        newLink = LinkedAccount(
          MainUserID: _scannedUserID!,
          LinkedUserID: widget.currentUserID,
          healthDataVisibility: 'T',
          moodDataVisibility: 'T',
          ultrasoundImageVisibility: 'T',
          date: DateTime.now(),
        );

        final id = generateMessageID(_scannedUserID!,user.userID);
        chatMessages = ChatMessages(
            MessageID: id,
            messageContent: 'Hi, I''m ${user.userName!.isEmpty ? user.userEmail : user.userName}' ,
            SenderID: widget.currentUserID,
            ReceiverID: _scannedUserID!,
            time: DateTime.now()
        );
      }

      await dbService.insertLinkedAccount(newLink);
      await dbService.insertChatMessage(chatMessages);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account linked successfully!')),
      );

      setState(() => _scannedUserID = null);
    } catch (e) {
      log('Error linking account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLinking = false);
    }
  }

  // -----------------------------------------------------------------------------
  Widget _buildQRCode() {
    return QrImageView(
      data: widget.currentUserID,
      version: QrVersions.auto,
      size: 180.0,
    );
  }

  // -----------------------------------------------------------------------------
  Future<void> _openScanner() async {
    final qrResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (qrResult == null) return;

    _scannedUserID = qrResult;

    final scannedUser = await dbService.getUserByUID(_scannedUserID!);

    if (scannedUser == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('User Not Found'),
          content: const Text('Invalid QR code'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if(user.userRole == scannedUser.userRole){
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Link Account Failed'),
            content: const Text('Same user role cannot link to each other account'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      return;
    }

    // Check already linked
    final existing = await _getLinkedAccounts();
    bool isAlreadyLinked = false;

    if (existing != null) {
      for (var l in existing) {
        if (userRole == 'P' &&
            l.LinkedUserID == _scannedUserID!) isAlreadyLinked = true;

        if (userRole == 'FC' &&
            l.MainUserID == _scannedUserID!) isAlreadyLinked = true;
      }
    }

    if (isAlreadyLinked) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Already Linked'),
          content: Text('This account is already linked.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm Linking
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link Account'),
        content: Text('Link with user ID: $_scannedUserID ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _linkAccount();
              setState(() {});
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  Future<void> _unlink(String targetUserID) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink Account'),
        content: Text('Unlink user: $targetUserID ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (userRole == 'P') {
      await dbService.deleteLinkedAccount(targetUserID, widget.currentUserID);
    } else {
      await dbService.deleteLinkedAccount(widget.currentUserID, targetUserID);
    }

    setState(() {});
  }

  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Linked Accounts"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Your QR Code",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildQRCode(),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR Code"),
            ),

            const SizedBox(height: 20),

            const Divider(),
            const Text(
              "Linked Accounts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            FutureBuilder<List<LinkedAccount>?>(
              future: _getLinkedAccounts(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) return const Text("No linked accounts.");

                return Column(
                  children: snap.data!.map((acc) {
                    String targetID =
                    userRole == 'P' ? acc.LinkedUserID : acc.MainUserID;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FutureBuilder<Users?>(
                          future: dbService.getUserByUID(targetID),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const Text("Loading...");
                            }

                            final user = userSnap.data!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.userName?.isNotEmpty == true
                                            ? "Name: ${user.userName}"
                                            : "Email: ${user.userEmail}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _unlink(targetID),
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                    )
                                  ],
                                ),

                                // Visibility toggles ONLY for main user
                                if (userRole == 'P') ...[
                                  SwitchListTile(
                                    value: acc.healthDataVisibility == 'T',
                                    title: const Text("Health Data Visibility"),
                                    onChanged: (val) async {
                                      await dbService.editVisibility(
                                        acc.MainUserID,
                                        acc.LinkedUserID,
                                        'healthDataVisibility',
                                        val,
                                      );
                                      setState(() {
                                        acc.healthDataVisibility =
                                        val ? 'T' : 'F';
                                      });
                                    },
                                  ),
                                  SwitchListTile(
                                    value: acc.moodDataVisibility == 'T',
                                    title: const Text("Mood Data Visibility"),
                                    onChanged: (val) async {
                                      await dbService.editVisibility(
                                        acc.MainUserID,
                                        acc.LinkedUserID,
                                        'moodDataVisibility',
                                        val,
                                      );
                                      setState(() {
                                        acc.moodDataVisibility =
                                        val ? 'T' : 'F';
                                      });
                                    },
                                  ),
                                  SwitchListTile(
                                    value: acc.ultrasoundImageVisibility == 'T',
                                    title: const Text("Dairy Image Visibility"),
                                    onChanged: (val) async {
                                      await dbService.editVisibility(
                                        acc.MainUserID,
                                        acc.LinkedUserID,
                                        'ultrasoundImageVisibility',
                                        val,
                                      );
                                      setState(() {
                                        acc.ultrasoundImageVisibility =
                                        val ? 'T' : 'F';
                                      });
                                    },
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
