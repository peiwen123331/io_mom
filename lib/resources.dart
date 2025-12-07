import 'package:cloud_firestore/cloud_firestore.dart';

class Resources{

  final String ResourceID;
  final String title;
  final String description;
  final String articleURL;
  final String articleImgPath;
  final DateTime date;

  Resources({
   required this.ResourceID,
   required this.title,
   required this.description,
   required this.articleURL,
   required this.articleImgPath,
   required this.date,
});

  factory Resources.fromMap(Map<String, dynamic> data){
    return Resources(
        ResourceID: data['ResourceID'],
        title: data['title'],
        description: data['description'],
        articleURL: data['articleURL'],
        articleImgPath: data['articleImgPath'],
        date: data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : (data['date'] is String
            ? DateTime.tryParse(data['date']) ?? DateTime.now()
            : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'ResourceID': ResourceID,
      'title': title,
      'description':description,
      'articleURL': articleURL,
      'articleImgPath': articleImgPath,
      'date': date.toIso8601String(),
    };
  }



}