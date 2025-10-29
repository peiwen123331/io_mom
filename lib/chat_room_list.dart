import 'package:flutter/material.dart';
import 'package:io_mom/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_room.dart';
import 'user.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late List<Users> chatUsers = [];
  final dbService = DatabaseService();
  late final currentUser;

  void _openChat(String name) async{
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          SenderID: currentUser,
          ReceiverID: name,
        ),
      ),
    );
  }

  //get all user that chat with current user
  Future<void> _loadChatUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString("userID");
    if (userID == null) return;
    final users = await dbService.getAllChatUser(userID);

    setState(() {
      currentUser = userID;
      chatUsers = users;
    });
  }


  @override
  void initState(){
    super.initState();
    _loadChatUsers();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        itemCount: chatUsers.length,
        itemBuilder: (context, index) {
          final name = chatUsers[index].userID;
          return GestureDetector(
            onTap: () => _openChat(name),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.pink[50],
                  child: const Icon(Icons.pets, color: Colors.pink),
                ),
                title: Text(
                  chatUsers[index].userName! != "" ? chatUsers[index].userName! : chatUsers[index].userID,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
              ),
            ),
          );
        },
      ),
    );
  }
}
