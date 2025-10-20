import 'package:flutter/material.dart';
import 'user.dart';

class UserProvider extends ChangeNotifier {
  Users? _user;

  Users? get user => _user;

  void setUser(Users newUser) {
    _user = newUser;
    notifyListeners();
  }

  void updateProfileImage(String path) {
    if (_user != null) {
      _user = Users(
        userID: _user!.userID,
        userName: _user!.userName,
        userEmail: _user!.userEmail,
        userRegDate: _user!.userRegDate,
        phoneNo: _user!.phoneNo,
        userStatus: _user!.userStatus,
        profileImgPath: path,
      );
      notifyListeners();
    }
  }
}
