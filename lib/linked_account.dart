import 'package:cloud_firestore/cloud_firestore.dart';

class LinkedAccount{
  final String MainUserID;
  final String LinkedUserID;
   String healthDataVisibility;
   String moodDataVisibility;
   String ultrasoundImageVisibility;
   final DateTime date;

  LinkedAccount({
   required this.MainUserID,
   required this.LinkedUserID,
   required this.healthDataVisibility,
   required this.moodDataVisibility,
    required this.ultrasoundImageVisibility,
    required this.date,
});
  factory LinkedAccount.fromMap(Map<String, dynamic> data){
    return LinkedAccount(
        MainUserID: data['MainUserID'],
        LinkedUserID: data['LinkedUserID'],
        healthDataVisibility: data['healthDataVisibility'],
        moodDataVisibility: data['moodDataVisibility'],
        ultrasoundImageVisibility: data['ultrasoundImageVisibility'],
        date: data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : (data['date'] is String
            ? DateTime.tryParse(data['date']) ?? DateTime.now()
            : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'MainUserID':MainUserID,
      'LinkedUserID': LinkedUserID,
      'healthDataVisibility': healthDataVisibility,
      'moodDataVisibility': moodDataVisibility,
      'ultrasoundImageVisibility': ultrasoundImageVisibility,
      'date': date.toIso8601String(),
    };
  }

  static LinkedAccount empty ()=>LinkedAccount(
      MainUserID: '',
      LinkedUserID: '',
      healthDataVisibility: '',
      moodDataVisibility: '',
      ultrasoundImageVisibility: '',
      date: DateTime.now(),
  );


}