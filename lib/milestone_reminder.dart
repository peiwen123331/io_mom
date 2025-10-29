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
      startDate: DateTime.tryParse(data['startDate']) ?? DateTime.now(),
      endDate: DateTime.tryParse(data['endDate']) ?? DateTime.now(),
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