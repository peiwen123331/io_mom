import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessages{

  final String MessageID;
  final String messageContent;
  final String SenderID;
  final String ReceiverID;
  final DateTime time;


  ChatMessages({
    required this.MessageID,
    required this.messageContent,
    required this.SenderID,
    required this.ReceiverID,
    required this.time,
  });

factory ChatMessages.fromMap(Map<String, dynamic> data){
  return ChatMessages(
      MessageID: data['MessageID'],
      messageContent: data['messageContent'],
      SenderID: data['SenderID'],
      ReceiverID: data['ReceiverID'],
      time:data['time'] is Timestamp
          ? (data['time'] as Timestamp).toDate()
          : (data['time'] is String
          ? DateTime.tryParse(data['time']) ?? DateTime.now()
          : DateTime.now()),
  );
}

Map<String, dynamic> toMap(){
  return {
    'MessageID': MessageID,
    'messageContent': messageContent,
    'SenderID': SenderID,
    'ReceiverID': ReceiverID,
    'time': time.toIso8601String(),
  };
}


}