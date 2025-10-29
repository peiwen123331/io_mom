import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_3/dash_chat_3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiChatbotPage extends StatefulWidget {
  const GeminiChatbotPage({super.key});

  @override
  State<GeminiChatbotPage> createState() => _GeminiChatbotPageState();
}

class _GeminiChatbotPageState extends State<GeminiChatbotPage> {
  final dbService = DatabaseService();
  final Gemini gemini = Gemini.instance;
  final TextEditingController _controller = TextEditingController();

  // Define chat users
  late ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  final ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage: "assets/images/logo/gemini_logo.png",
  );

  List<ChatMessage> messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userID = prefs.getString("userID");
    final user = await dbService.getUserByUID(userID!);
    final userName = user?.userName ?? "User";

    setState(() {
      currentUser = ChatUser(id: userID, firstName: userName);
    });
  }

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
        centerTitle: true,
        title: Text(
          "AI Chatbot",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat3(
      inputOptions: InputOptions(trailing: [
        IconButton(
            onPressed: (){
              _sendMediaMessage();
            },
            icon: const Icon(Icons.image),)
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if(chatMessage.medias?.isNotEmpty ?? false){
        images = [File(chatMessage.medias!.first.url).readAsBytesSync(),];
      }
      gemini.streamGenerateContent(question,images: images).listen((event){
        ChatMessage? lastMessage = messages.firstOrNull;
        if(lastMessage != null && lastMessage.user == geminiUser){
          lastMessage = messages.removeAt(0);
          // replace your old single-line extraction with this:
          String response = "";
          try {
            final dynamic ev = event; // dynamic so we can access either shape
            response = ev.content?.parts
                ?.fold("", (previous, current) => "$previous ${current.text}") ??
                ev.candidates?.first.content.parts
                    ?.fold("", (previous, current) => "$previous ${current.text}") ??
                "";
          } catch (e) {
            // in case 'event' has a different unexpected shape
            debugPrint("Failed to extract Gemini response text: $e");
            response = "";
          }


          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        }else{
          // replace your old single-line extraction with this:
          String response = "";
          try {
            final dynamic ev = event; // dynamic so we can access either shape
            response = ev.content?.parts
                ?.fold("", (previous, current) => "$previous ${current.text}") ??
                ev.candidates?.first.content.parts
                    ?.fold("", (previous, current) => "$previous ${current.text}") ??
                "";
          } catch (e) {
            // in case 'event' has a different unexpected shape
            debugPrint("Failed to extract Gemini response text: $e");
            response = "";
          }


          ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
          );
        setState(() {
          messages = [message, ...messages];
        });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage() async{
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
  if(file != null){
    ChatMessage chatMessage = ChatMessage(user: currentUser, createdAt: DateTime.now(), text: "Describe this picture?",
        medias: [ChatMedia(url: file.path, fileName: "", type: MediaType.image)]
    );
    _sendMessage(chatMessage);
  }
  }
}
