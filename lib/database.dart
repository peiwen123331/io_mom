import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'user.dart';


class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();
  static Database? _database;

  //get an instance of database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // delete old database if need to rebuild the table
  Future<void> resetDatabase() async {
    final getDirectory = await getApplicationDocumentsDirectory();
    String path = '${getDirectory.path}/io_mom.db';
    await deleteDatabase(path);
    log("Database deleted: $path");
  }

  //initialize a database
  Future<Database> initDatabase() async {
    final getDirectory = await getApplicationDocumentsDirectory();
    String path = '${getDirectory.path}/io_mom.db';
    log("DB path: $path");
    return await openDatabase(path, onCreate: _onCreate, version: 1);
  }
  //create an instance of database with tables
  void _onCreate(Database db, int version) async {
    //sql queries of create the tables needed in spms
    await db.execute(
      'CREATE TABLE Users('
          'userID TEXT PRIMARY KEY, '
          'userName TEXT, '
          'userEmail TEXT, '
          'userRegDate DATETIME, '
          'phoneNo TEXT ,'
          'userStatus TEXT, '
          'profileImgPath TEXT)',
    );

    log('TABLE CREATED');
  }

  // insert delivery to database
 Future insertUser(Users user) async {
    final db = await _databaseService.database;

    var data = await db.rawInsert(
      'INSERT INTO Users(userID, userName, userEmail, userRegDate, phoneNo, userStatus, profileImgPath) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        user.userID,
        user.userName,
        user.userEmail,
        user.userRegDate.toIso8601String(),
        user.phoneNo,
        user.userStatus,
        user.profileImgPath,
      ],
    );

    log('Inserted Delivery $data with ID: ${user.userID}');
  }


  // Schedule Details
  // Insert dummy deliveries if table is empty
  Future<void> initializeData() async {
    final db = await _databaseService.database;
    final user = await db.query("Users");

    //Profile
    if(user.isEmpty){
      await db.insert("Users", {
        "userID": "xhayPRUx4dfXWkXWQNfb8QBY6Hj2",
        "userName": "peiwen",
        "userEmail": "pwen0331@gmail.com",
        "userRegDate" : "2025-02-13 12:00:00",
        "phoneNo" : "",
        "userStatus" : "A",
        "profileImgPath": "assets/images/profile/Flim2.jpeg"
      });
    }
    print("Data inserted");
  }


  Future<Users?> getUserByEmail(String email) async {
    final db = await _databaseService.database;

    final result = await db.query(
      'Users', // ✅ your Users table
      where: 'userEmail = ?', // ✅ lookup by email
      whereArgs: [email],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Users.fromMap(result.first); // ✅ convert row into Users model
    }
    return null; // return null if no user found
  }

  Future<Users?> getUserByUID(String userID) async {
    final db = await _databaseService.database;

    final result = await db.query(
      'Users', // ✅ your Users table
      where: 'userID = ?', // ✅ lookup by email
      whereArgs: [userID],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Users.fromMap(result.first); // ✅ convert row into Users model
    }
    return null; // return null if no user found
  }


  Future<String> getPartImgPathByPartID(String partID) async{
    final db = await _databaseService.database;
    final result = await db.query(
      'Part',
      columns: ['partImgPath'], // assuming your Part table has an imgPath column
      where: 'partID = ?',
      whereArgs: [partID],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['partImgPath'] as String;
    }
    return "Unable to get Part Image Path";
  }

  //edit user details of previous data
  Future editUser(Users user) async {
    final db = await _databaseService.database;
    var data = await db.update(
      'Users',
      user.toMap(),
      where: 'userID = ?',
      whereArgs: [user.userID],
    );
    log('updated $data');
  }

  //delete user
  Future deleteUser(String userID) async {
    final db = await _databaseService.database;
    var data = await db.delete(
      'Users',
      where: 'userID = ?',
      whereArgs: [userID],
    );
    log('updated $data');
  }


}


