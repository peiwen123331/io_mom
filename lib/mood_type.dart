class MoodType{

  final String MoodTypeID;
  final String MoodTypeName;
  final String MoodTypeImg;
  final String MoodTypeStatus;

  MoodType({
   required this.MoodTypeID,
   required this.MoodTypeName,
   required this.MoodTypeImg,
   required this.MoodTypeStatus,
});
//retrieve database
  factory MoodType.fromMap(Map<String, dynamic> data){
    return MoodType(
        MoodTypeID: data['MoodTypeID'],
        MoodTypeName: data['MoodTypeName'],
        MoodTypeImg: data['MoodTypeImg'],
        MoodTypeStatus: data['MoodTypeStatus'],
    );
  }

  //store to database
  Map<String, dynamic> toMap(){
    return{
      'MoodTypeID': MoodTypeID,
      'MoodTypeName': MoodTypeName,
      'MoodTypeImg': MoodTypeImg,
      'MoodTypeStatus': MoodTypeStatus,
    };
  }


}