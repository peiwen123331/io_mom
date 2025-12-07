import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneReminder{
  final String milReminderID;
  final String mileStoneName;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String userID;

  MilestoneReminder({
    required this.milReminderID,
    required this.mileStoneName,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.userID,
  });

  factory MilestoneReminder.fromMap(Map<String, dynamic> data){
    return MilestoneReminder(
      milReminderID: data['milReminderID'],
      mileStoneName: data['mileStoneName'],
      description: data['description'],
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : (data['startDate'] is String
          ? DateTime.tryParse(data['startDate']) ?? DateTime.now()
          : DateTime.now()),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : (data['endDate'] is String
          ? DateTime.tryParse(data['endDate']) ?? DateTime.now()
          : DateTime.now()),
      userID: data['userID'],
    );
  }



  Map<String, dynamic> toMap(){
    return{
      'milReminderID': milReminderID,
      'mileStoneName': mileStoneName,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userID': userID,

    };
  }



}