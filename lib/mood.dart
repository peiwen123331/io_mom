

class Mood{
  final String MoodID;
  final String MoodDesc;
  final DateTime MoodDate;
  final String MoodStatus;
  final String userID;
  final String MoodTypeID;

  Mood({
    required this.MoodID,
    required this.MoodDesc,
    required this.MoodDate,
    required this.MoodStatus,
    required this.userID,
    required this.MoodTypeID,
  });

  factory Mood.fromMap(Map<String, dynamic> data){
    return Mood(
        MoodID: data['MoodID'],
        MoodDesc: data['MoodDesc'],
        MoodDate: DateTime.tryParse(data['MoodDate']) ?? DateTime.now(),
        MoodStatus: data['MoodStatus'],
        userID: data['userID'],
        MoodTypeID: data['MoodTypeID'],
    );
  }



  Map<String, dynamic> toMap(){
   return{
     'MoodID': MoodID,
     'MoodDesc': MoodDesc,
     'MoodDate': MoodDate.toIso8601String(),
     'MoodStatus': MoodStatus,
     'userID': userID,
     'MoodTypeID': MoodTypeID,

   };
  }



}