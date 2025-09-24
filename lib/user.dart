

class Users{
  final String userID;
  final String? userName;
  final String userEmail;
  final String? profileImgPath;

  Users({
    required this.userID,
    this.userName,
    required this.userEmail,
    this.profileImgPath,
});

  factory Users.fromMap(Map<String, dynamic> data) {
    return Users(
      userID: data['userID'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      profileImgPath: data['profileImgPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'userName': userName,
      'userEmail': userEmail,
      'profileImgPath': profileImgPath,
    };
  }


}