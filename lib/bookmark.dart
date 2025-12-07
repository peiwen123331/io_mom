class Bookmark{

  final String userID;
  final String ResourceID;

  Bookmark({
    required this.userID,
    required this.ResourceID,
});

  factory Bookmark.fromMap(Map<String, dynamic> data){
    return Bookmark(
      userID: data['userID'],
      ResourceID: data['ResourceID'],
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'userID': userID,
      'ResourceID':ResourceID,
    };
  }
}