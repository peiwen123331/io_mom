import 'package:cloud_firestore/cloud_firestore.dart';

class Users{
  final String userID;
  final String? userName;
  final String userEmail;
  final DateTime userRegDate;
  final String? phoneNo;
  final String userStatus;
  final String? profileImgPath;
  final String? userRole;
  final String loginType;
  DateTime? pregnantDate;
  String? isPhoneVerify;

  Users({
    required this.userID,
    this.userName,
    required this.userEmail,
    required this.userRegDate,
    this.phoneNo,
    required this.userStatus,
    this.profileImgPath,
    this.userRole,
    required this.loginType,
    this.pregnantDate,
    required this.isPhoneVerify,
});

  factory Users.fromMap(Map<String, dynamic> data) {
    return Users(
      userID: data['userID'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      userRegDate: data['userRegDate'] is Timestamp
          ? (data['userRegDate'] as Timestamp).toDate()
          : (data['userRegDate'] is String
          ? DateTime.tryParse(data['userRegDate']) ?? DateTime.now()
          : DateTime.now()),
      phoneNo: data['phoneNo'],
      userStatus: data['userStatus'] ?? 'A',
      profileImgPath: data['profileImgPath'],
      userRole: data['userRole'],
      loginType: data['loginType'],
      pregnantDate: data['userRegDate'] is Timestamp
          ? (data['userRegDate'] as Timestamp).toDate()
          : (data['userRegDate'] is String
          ? DateTime.tryParse(data['userRegDate']) ?? DateTime.now()
          : DateTime.now()),
      isPhoneVerify: data['isPhoneVerify'],
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
      'userRole': userRole,
      'loginType': loginType,
      'pregnantDate': pregnantDate?.toIso8601String(),
      'isPhoneVerify':isPhoneVerify,
    };
  }

  static Users empty ()=> Users(
      userID: '',
      userEmail: '',
      userRegDate: DateTime.now(),
      userStatus: '',
      loginType: '',
      isPhoneVerify: '');


}