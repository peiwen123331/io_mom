import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationReminder{
  final String medReminderID;
  final String medicationName;
  final double dosage;
  final int repeatDuration;
  final DateTime startTime;
  late final DateTime? lastConfirmedDate;
  final String userID;

  MedicationReminder({
    required this.medReminderID,
    required this.medicationName,
    required this.dosage,
    required this.repeatDuration,
    required this.startTime,
    this.lastConfirmedDate,
    required this.userID,
  });

  factory MedicationReminder.fromMap(Map<String, dynamic> data){
    return MedicationReminder(
      medReminderID: data['medReminderID'],
      medicationName: data['medicationName'],
      dosage: data['dosage'],
      repeatDuration: data['repeatDuration'],
      startTime: data['startTime'] is Timestamp
          ? (data['startTime'] as Timestamp).toDate()
          : (data['startTime'] is String
          ? DateTime.tryParse(data['startTime']) ?? DateTime.now()
          : DateTime.now()),
      lastConfirmedDate: data['lastConfirmedDate'] is Timestamp
          ? (data['lastConfirmedDate'] as Timestamp).toDate()
          : (data['lastConfirmedDate'] is String
          ? DateTime.tryParse(data['lastConfirmedDate']) ?? DateTime.now()
          : DateTime.now()),
      userID: data['userID'],
    );
  }



  Map<String, dynamic> toMap(){
    return{
      'medReminderID': medReminderID,
      'medicationName': medicationName,
      'dosage': dosage,
      'repeatDuration': repeatDuration,
      'startTime': startTime.toIso8601String(),
      'lastConfirmedDate': lastConfirmedDate?.toIso8601String(),
      'userID': userID,

    };
  }



}