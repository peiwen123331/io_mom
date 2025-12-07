import 'package:cloud_firestore/cloud_firestore.dart';


class UltrasoundImages{

  final String ImageID;
  final String imagePath;
  final String description;
  final DateTime uploadDate;
  final String userID;

  UltrasoundImages({
    required this.ImageID,
    required this.imagePath,
    required this.description,
    required this.uploadDate,
    required this.userID,
});

  factory UltrasoundImages.fromMap(Map<String, dynamic> data){
    return UltrasoundImages(
        ImageID: data['ImageID'],
      imagePath: data['imagePath'],
        description: data['description'],
        uploadDate: data['uploadDate'] is Timestamp
            ? (data['uploadDate'] as Timestamp).toDate()
            : (data['uploadDate'] is String
            ? DateTime.tryParse(data['uploadDate']) ?? DateTime.now()
            : DateTime.now()),
        userID: data['userID'],
    );
  }


  Map<String, dynamic> toMap(){
    return{
      'ImageID': ImageID,
      'imagePath': imagePath,
      'description': description,
      'uploadDate': uploadDate.toIso8601String(),
      'userID': userID,
    };
  }

}