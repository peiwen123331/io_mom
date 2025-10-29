class MedicationReminder{
  final String medReminderID;
  final String medicationName;
  final double dosage;
  final int frequency;
  final int repeatDuration;
  final DateTime startTime;
  late final DateTime? lastConfirmedDate;
  final String userID;

  MedicationReminder({
    required this.medReminderID,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
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
      frequency: data['frequency'],
      repeatDuration: data['repeatDuration'],
      startTime: DateTime.tryParse(data['startTime']) ?? DateTime.now(),
      lastConfirmedDate: DateTime.tryParse(data['lastConfirmedDate']) ?? DateTime.now(),
      userID: data['userID'],
    );
  }



  Map<String, dynamic> toMap(){
    return{
      'medReminderID': medReminderID,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'repeatDuration': repeatDuration,
      'startTime': startTime.toIso8601String(),
      'lastConfirmedDate': lastConfirmedDate?.toIso8601String(),
      'userID': userID,

    };
  }



}