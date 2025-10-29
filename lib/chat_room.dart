import 'dart:async';
import 'package:dash_chat_3/dash_chat_3.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:io_mom/database.dart';

import 'ChatMessages.dart';

class ChatRoomPage extends StatefulWidget {
  final String SenderID;
  final String ReceiverID;

  const ChatRoomPage({
    super.key,
    required this.SenderID,
    required this.ReceiverID,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final dbService = DatabaseService();
  final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://io-mom-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late ChatUser currentUser = ChatUser(id: widget.SenderID);
  late ChatUser receiverUser = ChatUser(id: widget.ReceiverID);

  List<ChatMessage> messages = [];
  late DatabaseReference chatRef;
  //Stream<DatabaseEvent>? chatStream;
  StreamSubscription<DatabaseEvent>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    currentUser = ChatUser(id: widget.SenderID);
    receiverUser = ChatUser(id: widget.ReceiverID);
    _initChat();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    final roomIDSR = _getChatRoomID(widget.SenderID, widget.ReceiverID);
    final roomIDRS = _getChatRoomID(widget.ReceiverID, widget.SenderID);
    late final String roomID;

    try {
      // Check which chat room exists in RTDB
      final snapshotSR = await _rtdb.ref('chats/$roomIDSR/messages').get();
      final snapshotRS = await _rtdb.ref('chats/$roomIDRS/messages').get();

      if (!snapshotSR.exists) {
        chatRef = _rtdb.ref('chats/$roomIDRS/messages');
        roomID = roomIDRS;
      } else {
        chatRef = _rtdb.ref('chats/$roomIDSR/messages');
        roomID = roomIDSR;
      }

      // 🔹 Fetch Firestore chat history as List<ChatMessages>
      final chatMessages = await dbService.getChatMessages(roomID);

      // 🔹 Convert each ChatMessages → ChatMessage (for DashChat)
      List<ChatMessage> convertedMessages = chatMessages.map((cm) {
        return ChatMessage(
          text: cm.messageContent,
          createdAt: cm.time,
          user: ChatUser(id: cm.SenderID),
        );
      }).toList();

      // 🔹 Update state for DashChat
      setState(() {
        messages = convertedMessages;
      });

      // 🔹 Start listening to Realtime DB updates
      _listenToRealtimeMessages(roomID);

    } catch (e) {
      print("Error initializing chat: $e");
    }
  }


  String _getChatRoomID(String senderID, String receiverID) {
    final sortedIDs = [senderID, receiverID]..sort();
    return '${sortedIDs[0]}_${sortedIDs[1]}';
  }


  void _listenToRealtimeMessages(String roomID) {
    _chatSubscription = _rtdb.ref('chats/$roomID/messages').onChildAdded.listen((event) {
      if (!mounted) return; // double-check before doing anything

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final chatMsg = ChatMessage(
        text: data['messageContent'] ?? '',
        createdAt: DateTime.parse(data['time']),
        user: ChatUser(id: data['SenderID']),
        medias: data['mediaUrl'] != null
            ? [
          ChatMedia(
            url: data['mediaUrl'],
            fileName: data['fileName'] ?? '',
            type: MediaType.image,
          )
        ]
            : [],
      );

      bool exists = messages.any((m) =>
      m.text == chatMsg.text &&
          m.createdAt == chatMsg.createdAt &&
          m.user.id == chatMsg.user.id);

      if (!exists && mounted) {
        setState(() {
          messages.insert(0, chatMsg);
        });
      }
    });
  }


  Future<void> _sendMessage(ChatMessage chatMessage) async {
    final roomID = _getChatRoomID(widget.SenderID, widget.ReceiverID);
    final timestamp = DateTime.now();

    final ChatMessages cm =  ChatMessages(
      MessageID: roomID,
      messageContent: chatMessage.text,
      SenderID: widget.SenderID,
      ReceiverID: widget.ReceiverID,
      time: timestamp,
    );

    dbService.insertChatMessage(cm);
    /*setState(() {
      messages.insert(0, chatMessage);
    });*/
  }

  /*Future<void> _sendMediaMessage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final roomIDSR = _getChatRoomID(widget.SenderID, widget.ReceiverID);
    final roomIDRS = _getChatRoomID(widget.ReceiverID, widget.SenderID);
    late final roomID;
    final timestamp = DateTime.now();

    try {
      final snapshotSR = await _rtdb.ref('chats/$roomIDSR/messages').get();
      final snapshotRS = await _rtdb.ref('chats/$roomIDRS/messages').get();

      if (!snapshotSR.exists) {
        chatRef = _rtdb.ref('chats/$roomIDRS/messages');
        roomID = roomIDRS;
      } else if (!snapshotRS.exists) {
        chatRef = _rtdb.ref('chats/$roomIDSR/messages');
        roomID = roomIDSR;
      }

      final ChatMessages cm = ChatMessages(
          MessageID: roomID,
          messageContent: '[Image]',
          SenderID: widget.SenderID,
          ReceiverID: widget.ReceiverID,
          time: timestamp);

      // Upload image to Firebase Storage
      final path = file.path;
      final fileName = file.name;
      final List<String>? strList = await dbService.insertMediaChatMessage(cm, fileName, path);

      final chatMessage = ChatMessage(
        user: ChatUser(id: widget.SenderID),
        createdAt: timestamp,
        text: "[Image]",
        medias: [
          ChatMedia(
            url: strList!.elementAt(1),
            fileName: strList!.elementAt(0),
            type: MediaType.image,
          ),
        ],
      );

      setState(() {
        messages.insert(0, chatMessage);
      });
    }catch(e){
      print(e);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          receiverUser.firstName ?? "Chat",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: DashChat3(
        currentUser: currentUser,
        messages: messages,
        onSend: _sendMessage,
      ),
    );
  }
}
