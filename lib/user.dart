

class Users{
  final String userID;
  final String? userName;
  final String userEmail;
  final DateTime userRegDate;
  final String? phoneNo;
  final String userStatus;
  final String? profileImgPath;

  Users({
    required this.userID,
    this.userName,
    required this.userEmail,
    required this.userRegDate,
    this.phoneNo,
    required this.userStatus,
    this.profileImgPath,
});

  factory Users.fromMap(Map<String, dynamic> data) {
    return Users(
      userID: data['userID'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      userRegDate: DateTime.tryParse(data['userRegDate']) ?? DateTime.now(),
      phoneNo: data['phoneNo'],
      userStatus: data['userStatus'],
      profileImgPath: data['profileImgPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'userName': userName,
      'userEmail': userEmail,
      'userRegDate': userRegDate.toIso8601String(),
      'phoneNo': phoneNo,
      'userStatus': userStatus,
      'profileImgPath': profileImgPath,
    };
  }


}