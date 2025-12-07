import 'package:cloud_firestore/cloud_firestore.dart';

class HealthData{

  final String healthDataID;
  final double PulseRate;
  final double bodyTemp;
  final double SpO2;
  final String healthRisk;
  final DateTime date;
  final String userID;


  HealthData({
    required this.healthDataID,
    required this.PulseRate,
    required this.bodyTemp,
    required this.SpO2,
    required this.healthRisk,
    required this.date,
    required this.userID,
});


  factory HealthData.fromMap(Map<String,dynamic> data){
    return HealthData(
      healthDataID: data['healthDataID'],
      PulseRate: (data['PulseRate'] ?? 0).toDouble(),
      SpO2: (data['SpO2']?? 0).toDouble(),
      bodyTemp: (data['bodyTemp']?? 0).toDouble(),
      healthRisk: data['healthRisk'],
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : (data['date'] is String
          ? DateTime.tryParse(data['date']) ?? DateTime.now()
          : DateTime.now()),
      userID: data['userID'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'healthDataID': healthDataID,
      'PulseRate': PulseRate,
      'SpO2': SpO2,
      'bodyTemp':bodyTemp,
      'healthRisk': healthRisk,
      'date':date.toIso8601String(),
      'userID': userID,
    };
  }

}