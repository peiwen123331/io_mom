import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:io_mom/booking.dart';
import 'package:io_mom/bookmark.dart';
import 'package:io_mom/confinement_center.dart';
import 'package:io_mom/linked_account.dart';
import 'package:io_mom/milestone_reminder.dart';
import 'package:io_mom/mood_type.dart';
import 'package:io_mom/package.dart';
import 'package:io_mom/package_images.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'RTHealthData.dart';
import 'collaboration_request.dart';
import 'health_data.dart';
import 'medication_reminder.dart';
import 'mood.dart';
import 'resources.dart';
import 'ultrasound_image.dart';
import 'user.dart';
import 'ChatMessages.dart';
import 'transaction.dart';


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
    /*await db.execute(
      'CREATE TABLE ChatMessages('
          'MessageID TEXT PRIMARY KEY, '
          'messageContent TEXT, '
          'SenderID TEXT, '
          'ReceiverID TEXT, '
          'time DATETIME)',
    );*/

    log('TABLE CREATED');
  }


  // Insert dummy data if database is empty
  Future<void> initializeData() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final List<Map<String, dynamic>> weeks = [
        // First Trimester
        {'week': 1, 'length': 0, 'size': 'Very tiny', 'weight': '', 'daysLeft': 273},
        {'week': 2, 'length': 0, 'size': 'Very tiny', 'weight': '', 'daysLeft': 273},
      ];
try {
  // Upload to Firestore
  for (var weekData in weeks) {
    await _firestore.collection('BabyInfo')
        .doc(weekData['week'].toString())
        .collection('babyInfo').add({
      'week': weekData['week'].toString(),
      'babyLength': weekData['length'].toString(),
      'babySize': weekData['size'],
      'babyWeight': weekData['weight']?.toString() ?? '-',
      'dayLeft': weekData['daysLeft'].toString(),
    });
  }
}catch(e){
  print(e);
}
    log("Data inserted");
  }

//-------------------------------
//---------Generate ID-----------
//-------------------------------

  Future<String> generateMoodID() async{
    String? mood = await getLastMoodID();
    int tempID = 0;
    int newID = 0;

    if(mood == null){
      return "MD0001";
    }
    tempID = int.parse(mood!.substring(2));
    newID = tempID+1;
    return 'MD${newID.toString().padLeft(mood.length - 2, '0')}';
  }

  Future<String> generateMilReminderID() async{
    String? milReminderID = await getLastMilReminderID();
    int tempID = 0;
    int newID = 0;

    if(milReminderID == null){
      return "MIL0001";
    }
    tempID = int.parse(milReminderID!.substring(3));
    newID = tempID+1;
    return 'MIL${newID.toString().padLeft(milReminderID.length - 3, '0')}';
  }
  Future<String> generateMedReminderID() async{
    String? medReminderID = await getLastMedReminderID();
    int tempID = 0;
    int newID = 0;

    if(medReminderID == null){
      return "MED0001";
    }
    tempID = int.parse(medReminderID!.substring(3));
    newID = tempID+1;
    return 'MED${newID.toString().padLeft(medReminderID.length - 3, '0')}';
  }

  Future<String> generateCenterID() async{
    String? CenterID = await getLastCenterID();
    int tempID = 0;
    int newID = 0;

    if(CenterID == null){
      return "CC0001";
    }
    tempID = int.parse(CenterID!.substring(2));
    newID = tempID+1;
    return 'CC${newID.toString().padLeft(CenterID.length - 2, '0')}';
  }

  Future<String> generatePackageID() async{
    String? PackageID = await getLastPackageID();
    int tempID = 0;
    int newID = 0;

    if(PackageID == null){
      return "PK0001";
    }
    tempID = int.parse(PackageID!.substring(2));
    newID = tempID+1;
    return 'PK${newID.toString().padLeft(PackageID.length - 2, '0')}';
  }

  Future<String> generateBookingID() async{
    String? BookingID = await getLastBookingID();
    int tempID = 0;
    int newID = 0;

    if(BookingID == null){
      return "BK0001";
    }
    tempID = int.parse(BookingID!.substring(2));
    newID = tempID+1;
    return 'BK${newID.toString().padLeft(BookingID.length - 2, '0')}';
  }

  Future<String> generateHealthDataID() async{
    String? healthDataID = await getLastHealthDataID();
    int tempID = 0;
    int newID = 0;

    if(healthDataID == null){
      return "HD0001";
    }
    tempID = int.parse(healthDataID!.substring(2));
    newID = tempID+1;
    return 'HD${newID.toString().padLeft(healthDataID.length - 2, '0')}';
  }

  Future<String> generateResourcesID() async{
    String? resourceID = await getLastResourceID();
    int tempID = 0;
    int newID = 0;

    if(resourceID == null){
      return "RS0001";
    }
    tempID = int.parse(resourceID!.substring(2));
    newID = tempID+1;
    return 'RS${newID.toString().padLeft(resourceID.length - 2, '0')}';
  }


  Future<String> generateUltrasoundImgID() async{
    String? imageID = await getLastUltrasoundImgID();
    int tempID = 0;
    int newID = 0;

    if(imageID == null){
      return "IMG0001";
    }
    tempID = int.parse(imageID!.substring(3));
    newID = tempID+1;
    return 'IMG${newID.toString().padLeft(imageID.length - 3, '0')}';
  }
  Future<String> generateRequestID() async{
    String? requestID = await getLastRequestID();
    int tempID = 0;
    int newID = 0;

    if(requestID == null){
      return "RQ0001";
    }
    tempID = int.parse(requestID!.substring(2));
    newID = tempID+1;
    return 'RQ${newID.toString().padLeft(requestID.length - 2, '0')}';
  }

  Future<String> generateTransactionID() async{
    String? requestID = await getLastTransactionsID();
    int tempID = 0;
    int newID = 0;

    if(requestID == null){
      return "TS0001";
    }
    tempID = int.parse(requestID!.substring(2));
    newID = tempID+1;
    return 'TS${newID.toString().padLeft(requestID.length - 2, '0')}';
  }





//-------------------------------
//------------User---------------
//-------------------------------

  // insert user to database
  Future insertUser(Users user) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Mirror to Firestore (for history)
    await _firestore
        .collection('Users')
        .doc(user.userID)
        .collection('user')
        .add(user.toMap());

    log('Inserted User with ID: ${user.userID}');
  }


  Future<Users?> getUserByEmail(String email) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // 1. Use the efficient Collection Group Query on all 'user' subcollections
      final subCollectionSnapshot = await _firestore
          .collectionGroup('user') // Query all collections named 'user'
          .where('userEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (subCollectionSnapshot.docs.isNotEmpty) {
        final doc = subCollectionSnapshot.docs.first;
        final data = doc.data();

        // The main userID is the ID of the document *above* the 'user' subcollection.
        // doc.reference.parent is the 'user' collection.
        // doc.reference.parent.parent is the [UserID] document reference
        return Users.fromMap(data);
      }
      // If no user found
      return null;
    } catch (e) {
      log("Error fetching user by email: $e");
      return null;
    }
  }


  Future<Users?> getUserByUID(String userID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Access subcollection "user" under the userID document
      final userSnapshot = await _firestore
          .collection('Users')
          .doc(userID)
          .collection('user')
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final data = userSnapshot.docs.first.data();
        return Users.fromMap(data);
      } else {
        log('No user found for ID: $userID');
        return null;
      }
    } catch (e) {
      log('Error fetching user by ID: $e');
      return null;
    }
  }

// for list out chat user
  Future<List<Users>> getAllChatUser(String userID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // A Set to store unique IDs of users the current user has chatted with
    Set<String> uniqueOtherUserIDs = {};

    // A Map to store fetched Users objects, preventing duplicate profile reads
    Map<String, Users> fetchedUsersMap = {};

    // 1. Query ALL messages where the current user is either the Sender or the Receiver.
    // We use two separate collectionGroup queries combined, which is currently the best practice
    // since Firestore does not allow OR queries on different fields in a collection group.

    // Query 1: Messages SENT by the current user
    final sentSnapshot = await _firestore
        .collectionGroup('messages')
        .where('SenderID', isEqualTo: userID)
        .get();

    // Query 2: Messages RECEIVED by the current user
    final receivedSnapshot = await _firestore
        .collectionGroup('messages')
        .where('ReceiverID', isEqualTo: userID)
        .get();

    // Combine all messages from both queries
    final allMessages = [...sentSnapshot.docs, ...receivedSnapshot.docs];
    log("Total relevant messages found: ${allMessages.length}");

    // 2. Extract the unique IDs of the other participants
    for (var messageDoc in allMessages) {
      final data = messageDoc.data();
      final senderId = data['SenderID'] as String;
      final receiverId = data['ReceiverID'] as String;


      if (senderId == userID && receiverId.isNotEmpty) {
        uniqueOtherUserIDs.add(receiverId);
      } else if (receiverId == userID && senderId.isNotEmpty) {
        uniqueOtherUserIDs.add(senderId);
      }
    }

    // 3. Batch-fetch the user profiles for all unique IDs
    if (uniqueOtherUserIDs.isEmpty) {
      return [];
    }

    // This still requires a separate read per unique user, but it's the
    // necessary step given your nested Users/{uid}/user structure.
    for (final otherUserID in uniqueOtherUserIDs) {

      // Skip if we already fetched this user
      if (fetchedUsersMap.containsKey(otherUserID)) continue;

      // Fetch user info from Firestore: Users/[otherUserID]/user/
      final userSnapshot = await _firestore
          .collection('Users')
          .doc(otherUserID)
          .collection('user')
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final data = userSnapshot.docs.first.data();
        final user = Users.fromMap(data);
        log('user:            ${user.userID}');
        fetchedUsersMap[otherUserID] = user; // Store in map
      } else {
        log("Warning: No user profile found for $otherUserID");
      }
    }
    // 4. Return the list of unique chat users
    return fetchedUsersMap.values.toList();
  }

  Future<List<Users>> getAllUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .orderBy('userID')
          .get();

      if (snapshot.docs.isEmpty) {
        log("No user data");
        return [];
      }

      log("Found user data: ${snapshot.docs.length} records");

      return snapshot.docs
          .map((doc) => Users.fromMap(doc.data()))
          .toList();

    } catch (e) {
      log("Error loading users: $e");
      return [];
    }
  }


  Future<List<Users>> getAllActiveUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['P', 'FC'])
          .where('userStatus', isEqualTo: 'A')
          .orderBy('userID')
          .get();

      if (snapshot.docs.isEmpty) {
        log("No user data");
        return [];
      }

      log("Found user data: ${snapshot.docs.length} records");

      return snapshot.docs
          .map((doc) => Users.fromMap(doc.data()))
          .toList();

    } catch (e) {
      log("Error loading users: $e");
      return [];
    }
  }


  Future<List<Users>> getAllInactiveUsers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['P', 'FC'])
          .where('userStatus', isEqualTo: 'I')
          .orderBy('userID')
          .get();

      if (snapshot.docs.isEmpty) {
        log("No user data");
        return [];
      }

      log("Found user data: ${snapshot.docs.length} records");

      return snapshot.docs
          .map((doc) => Users.fromMap(doc.data()))
          .toList();

    } catch (e) {
      log("Error loading users: $e");
      return [];
    }
  }

  Future<List<Users>> getAllActivePregnantWomen() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['P'])
          .where('userStatus', isEqualTo: 'A')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No active pregnant women data");
        return [];
      }
      print("Found active pregnant women: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading active pregnant women: $e");
      return [];
    }
  }

  Future<List<Users>> getAllInactivePregnantWomen() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['P'])
          .where('userStatus', isEqualTo: 'I')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No inactive pregnant women data");
        return [];
      }
      print("Found inactive pregnant women: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading inactive pregnant women: $e");
      return [];
    }
  }
  Future<List<Users>> getAllActiveFamilyCaregiver() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['FC'])
          .where('userStatus', isEqualTo: 'A')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No active family caregiver data");
        return [];
      }
      print("Found active family caregivers: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading active family caregivers: $e");
      return [];
    }
  }

  Future<List<Users>> getAllInactiveFamilyCaregiver() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['FC'])
          .where('userStatus', isEqualTo: 'I')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No inactive family caregiver data");
        return [];
      }
      print("Found inactive family caregivers: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading inactive family caregivers: $e");
      return [];
    }
  }

  Future<List<Users>> getAllInactiveCenter() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['C'])
          .where('userStatus', isEqualTo: 'I')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No inactive center data");
        return [];
      }
      print("Found inactive centers: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading inactive centers: $e");
      return [];
    }
  }

  Future<List<Users>> getAllActiveCenter() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', whereIn: ['C'])
          .where('userStatus', isEqualTo: 'A')
          .orderBy('userID')
          .get();
      if (snapshot.docs.isEmpty) {
        print("No active center data");
        return [];
      }
      print("Found active centers: ${snapshot.docs.length} records");
      return snapshot.docs.map((doc) => Users.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error loading active centers: $e");
      return [];
    }
  }



  Future<List<Users>> getAllUserByRoleAndDate(
      String userRole, String startDate, String endDate) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', isEqualTo: userRole)
          .where('userStatus', isEqualTo: 'A')
          .where('userRegDate', isGreaterThanOrEqualTo: startDate)
          .where('userRegDate', isLessThanOrEqualTo: endDate)
          .orderBy('userRegDate')
          .get();

      if (snapshot.docs.isEmpty) {
        log("No user data");
        return [];
      }

      log("Found user data: ${snapshot.docs.length} records");

      return snapshot.docs
          .map((doc) => Users.fromMap(doc.data()))
          .toList();

    } catch (e) {
      log("Error loading users: $e");
      return [];
    }
  }

  Future<List<Users>> getAllInactiveUserByRoleAndDate(
      String userRole, String startDate, String endDate) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collectionGroup('user')
          .where('userRole', isEqualTo: userRole)
          .where('userStatus', isEqualTo: 'I')
          .where('userRegDate', isGreaterThanOrEqualTo: startDate)
          .where('userRegDate', isLessThanOrEqualTo: endDate)
          .orderBy('userRegDate')
          .get();

      if (snapshot.docs.isEmpty) {
        log("No user data");
        return [];
      }

      log("Found user data: ${snapshot.docs.length} records");

      return snapshot.docs
          .map((doc) => Users.fromMap(doc.data()))
          .toList();

    } catch (e) {
      log("Error loading users: $e");
      return [];
    }
  }

  //edit user details of previous data
  Future<void> editUser(Users user) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('Users')
          .doc(user.userID)
          .collection('user')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;

        await _firestore
            .collection('Users')
            .doc(user.userID)
            .collection('user')
            .doc(docID)
            .update(user.toMap());

        log('Updated user data for ${user.userID}');
      } else {
        log('No existing user document found for ${user.userID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }



//delete user
  Future<void> deleteUser(String userID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('Users')
          .doc(userID)
          .collection('user')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('Users')
            .doc(userID)
            .collection('user')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore.collection('Users').doc(userID).delete();

      log('Successfully deleted userID: $userID and all related user data.');
    } catch (e) {
      log('Error deleting userID: $userID — $e');
    }
  }




//-------------------------------
//---------ChatMessages----------
//-------------------------------

  Future insertChatMessage(ChatMessages chatMessages) async {
    final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://io-mom-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final msgData = {
      'messageContent': chatMessages.messageContent,
      'SenderID': chatMessages.SenderID,
      'ReceiverID': chatMessages.ReceiverID,
      'time': chatMessages.time.toIso8601String(),
    };

    // Push to Realtime DB (instant communication)
    await _rtdb.ref('chats/${chatMessages.MessageID}/messages').push().set(msgData);

  // Mirror to Firestore (for history)
    await _firestore
      .collection('ChatMessages')
      .doc(chatMessages.MessageID)
      .collection('messages')
      .add(chatMessages.toMap());

  log('Inserted ChatMessages with ID: ${chatMessages.MessageID}');
  }



  Future<List<ChatMessages>> getChatMessages(String roomID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Load chat history from Firestore
    final snapshot = await _firestore
        .collection('ChatMessage')
        .doc(roomID)
        .collection('messages')
        .orderBy('time', descending: true)
        .get();

    // Convert Firestore docs to ChatMessages model
    final firestoreMessages = snapshot.docs.map((doc) {
      final data = doc.data();
      return ChatMessages.fromMap(data);
    }).toList();

    return firestoreMessages;
  }



//-------------------------------
//------------Mood---------------
//-------------------------------

  Future insertMood(Mood mood) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Mirror to Firestore (for history)
    await _firestore
        .collection('Mood')
        .doc(mood.MoodID)
        .collection('moods')
        .add(mood.toMap());

    log('Inserted Mood with ID: ${mood.MoodID}');
  }



  Future<String?> getLastMoodID() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final snapshot = await _firestore
      .collectionGroup('moods')
      .orderBy('MoodDate', descending: true)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final data = snapshot.docs.first.data();
    log(data['MoodID']);
    return data['MoodID'];
  } else {
    log("No moodID found");
  }
  return null;
  }

  Future<List<Mood>?> getMoodByUserID(String userID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('moods')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
   final moodList = snapshot.docs.map((doc) {
     final data = doc.data();
     return Mood.fromMap(data);
   }).toList();
      return moodList;
    }else{
      log("No mood data found for ${userID}");
      return null;
    }

  }

  Future<MoodType?> getMoodTypeByMoodTypeID(String moodTypeID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore.collection('MoodType')
        .doc(moodTypeID)
        .collection('moodType')
        .limit(1)
        .get();

      if (snapshot.docs.isNotEmpty) {
        log('Retrieve moodType data for ID: $moodTypeID');
        final data = snapshot.docs.first.data();
        return MoodType.fromMap(data);
      } else {
        log('No moodType for ID: $moodTypeID');
        return null;
      }

  }


  Future<List<MoodType>?> getAllMoodType() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore.collectionGroup('moodType')
        .orderBy('MoodTypeID')
        .get();

    if (snapshot.docs.isNotEmpty) {
      final moodTypeList = snapshot.docs.map((doc) {
        final data = doc.data();
        return MoodType.fromMap(data);
      }).toList();
      log("Found mood type data");
      return moodTypeList;
    } else {
      log('No moodType data');
      return null;
    }

  }


  //edit user details of previous data
  Future<void> editMood(Mood mood) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('Mood')
          .doc(mood.MoodID)
          .collection('moods')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('Mood')
            .doc(mood.MoodID)
            .collection('moods')
            .doc(docID)
            .update(mood.toMap());

        log('Updated mood data for user with userID : ${mood.userID}');
      } else {
        log('No existing user document found for ${mood.userID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }

  Future<void> deleteMoodById(String MoodID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('Mood')
          .doc(MoodID)
          .collection('moods')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('Mood')
            .doc(MoodID)
            .collection('moods')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore.collection('Mood').doc(MoodID).delete();

      log('Successfully deleted MoodID: $MoodID and all related mood data.');
    } catch (e) {
      log('Error deleting userID: $MoodID — $e');
    }


  }



//-------------------------------
//-----Milestone Reminder--------
//-------------------------------

  Future insertMilReminder(MilestoneReminder milReminder) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)
    await _firestore
        .collection('MilestoneReminder')
        .doc(milReminder.milReminderID)
        .collection('milestoneReminder')
        .add(milReminder.toMap());

    log('Inserted Milestone Reminder with ID: ${milReminder.milReminderID}');
  }

  Future<List<MilestoneReminder>?> getAllMilReminder(String startDate, String endDate) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('milestoneReminder')
          .where('startDate', isGreaterThanOrEqualTo: startDate)
          .where('startDate', isLessThanOrEqualTo: endDate)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final milList = snapshot.docs.map((doc) {
          final data = doc.data();
          return MilestoneReminder.fromMap(data);
        }).toList();
        print("Found milestone reminder data: ${milList.length} records");
        return milList;
      } else {
        print("No milestone reminder data");
        return null;
      }
    } catch (e) {
      print("Error loading milestone reminders: $e");
      return null;
    }
  }


  Future<String?> getLastMilReminderID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('milestoneReminder')
        .orderBy('milReminderID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['milReminderID']);
      return data['milReminderID'];
    } else {
      log("No milReminderID found");
    }
    return null;
  }

  Future<List<MilestoneReminder>?> getMilReminderByUserID(String userID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('milestoneReminder')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final milList = snapshot.docs.map((doc) {
        final data = doc.data();
        return MilestoneReminder.fromMap(data);
      }).toList();
      log("Found milestone reminder data for ${userID}");
      return milList;
    }else{
      log("No milestone reminder data found for ${userID}");
      return null;
    }
  }


//edit user details of previous data
  Future<void> editMilReminder(MilestoneReminder milReminder) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('MilestoneReminder')
          .doc(milReminder.milReminderID)
          .collection('milestoneReminder')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('MilestoneReminder')
            .doc(milReminder.milReminderID)
            .collection('milestoneReminder')
            .doc(docID)
            .update(milReminder.toMap());

        log('Updated milestone reminder data for user with userID : ${milReminder.userID}');
      } else {
        log('No existing user document found for ${milReminder.userID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }


  Future<void> deleteMilReminderById(String milReminderID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('MilestoneReminder')
          .doc(milReminderID)
          .collection('milestoneReminder')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('MilestoneReminder')
            .doc(milReminderID)
            .collection('milestoneReminder')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore
          .collection('MilestoneReminder')
          .doc(milReminderID)
          .delete();

      log(
          'Successfully deleted milReminderID: $milReminderID and all related milestone reminder data.');
    } catch (e) {
      log('Error deleting milReminderID: $milReminderID — $e');
    }
  }

//-------------------------------
//-----Medication Reminder-------
//-------------------------------

  Future insertMedReminder(MedicationReminder medReminder) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('MedicationReminder')
        .doc(medReminder.medReminderID)
        .collection('medicationReminder')
        .add(medReminder.toMap());

    log('Inserted Medication Reminder with ID: ${medReminder.medicationName}');
  }

  Future<String?> getLastMedReminderID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('medicationReminder')
        .orderBy('medReminderID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['medReminderID']);
      return data['medReminderID'];
    } else {
      log("No medReminderID found");
    }
    return null;
  }

  Future<List<MedicationReminder>?> getAllMedReminder(String startDate, String endDate) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('medicationReminder')
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThanOrEqualTo: endDate)
        .get();

    if(snapshot.docs.isNotEmpty){
      final medList = snapshot.docs.map((doc) {
        final data = doc.data();
        return MedicationReminder.fromMap(data);
      }).toList();
      log("Found medication reminder data");
      return medList;
    }else{
      log("No medication reminder data found");
      return null;
    }
  }

  Future<List<MedicationReminder>?> getMedReminderByUserID(String userID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('medicationReminder')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final medList = snapshot.docs.map((doc) {
        final data = doc.data();
        return MedicationReminder.fromMap(data);
      }).toList();
      log("Found medication reminder data for ${userID}");
      return medList;
    }else{
      log("No medication reminder data found for ${userID}");
      return null;
    }
  }

  Future<MedicationReminder?> getMedReminderByMedReminderID(String medReminderID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final snapshot = await _firestore.collection('MedicationReminder')
        .doc(medReminderID)
        .collection('medicationReminder')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      log('Retrieve medication reminder data for ID: $medReminderID');
      final data = snapshot.docs.first.data();
        return MedicationReminder.fromMap(data);
    }else{
      log("No medication reminder data found for ${medReminderID}");
      return null;
    }
  }

//edit user details of previous data
  Future<void> editMedReminder(MedicationReminder medReminder) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('MedicationReminder')
          .doc(medReminder.medReminderID)
          .collection('medicationReminder')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('MedicationReminder')
            .doc(medReminder.medReminderID)
            .collection('medicationReminder')
            .doc(docID)
            .update(medReminder.toMap());

        log('Updated Medication Reminder data for user with userID : ${medReminder.userID}');
      } else {
        log('No existing user document found for ${medReminder.userID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }


    Future<void> deleteMedReminderById(String medReminderID) async{
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      try {
        // Step 1: Delete all documents in subcollection 'user'
        final subcollectionSnapshot = await _firestore
            .collection('MedicationReminder')
            .doc(medReminderID)
            .collection('medicationReminder')
            .get();

        for (final doc in subcollectionSnapshot.docs) {
          await _firestore
              .collection('MedicationReminder')
              .doc(medReminderID)
              .collection('medicationReminder')
              .doc(doc.id)
              .delete();
        }

        // Step 2: Delete the parent document (userID)
        await _firestore.collection('MedicationReminder').doc(medReminderID).delete();

        log('Successfully deleted medReminderID: $medReminderID and all related medication reminder data.');
      } catch (e) {
        log('Error deleting medReminderID: $medReminderID — $e');
      }
      }



//-------------------------------
//------Confinement Center-------
//-------------------------------

  Future insertConfinementCenter(ConfinementCenter center) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('ConfinementCenter')
        .doc(center.CenterID)
        .collection('confinementCenter')
        .add(center.toMap());

    log('Inserted confinement center with ID: ${center.CenterID}');
  }

  Future<String?> getLastCenterID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('confinementCenter')
        .orderBy('CenterID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['CenterID']);
      return data['CenterID'];
    } else {
      log("No CenterID found");
    }
    return null;
  }

  Future<List<ConfinementCenter>> getAllCenter() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('confinementCenter')
        .get();

    if(snapshot.docs.isNotEmpty){
        final centerList = snapshot.docs.map((doc) {
        final data = doc.data();
        return ConfinementCenter.fromMap(data);
      }).toList();
      log("Found confinement center data");
      return centerList;
    }else{
      log("No confinement center data found}");
      return [];
    }
  }

  Future<ConfinementCenter?> getConfinementByCenterID(String CenterID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collection('ConfinementCenter')
        .doc(CenterID)
        .collection('confinementCenter')
        .where('CenterID', isEqualTo: CenterID)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      log('Retrieve Confinement Center data for ID: $CenterID');
      final data = snapshot.docs.first.data();
      return ConfinementCenter.fromMap(data);
    }else{
      log("No Confinement Center data found for ${CenterID}");
      return null;
    }
  }
  Future<ConfinementCenter?> getConfinementByEmail(String? email) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('confinementCenter')
        .where('centerEmail', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      log('Retrieve Confinement Center data for email: $email');
      final data = snapshot.docs.first.data();
      return ConfinementCenter.fromMap(data);
    }else{
      log("No Confinement Center data found for ${email}");
      return null;
    }
  }

//edit user details of previous data
  Future<void> editConfinementCenter(ConfinementCenter center) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('ConfinementCenter')
          .doc(center.CenterID)
          .collection('confinementCenter')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('ConfinementCenter')
            .doc(center.CenterID)
            .collection('confinementCenter')
            .doc(docID)
            .update(center.toMap());

        log('Updated Confinement Center data with CenterID : ${center.CenterID}');
      } else {
        log('No existing Confinement Center found for ${center.CenterID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }


  Future<void> deleteCenterByCenterId(String CenterID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('ConfinementCenter')
          .doc(CenterID)
          .collection('confinementCenter')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('ConfinementCenter')
            .doc(CenterID)
            .collection('confinementCenter')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore.collection('ConfinementCenter').doc(CenterID).delete();

      log('Successfully deleted CenterID: $CenterID and all related confinement center data.');
    } catch (e) {
      log('Error deleting CenterID: $CenterID — $e');
    }
  }

//-------------------------------
//------------Package------------
//-------------------------------
  Future insertPackage(Package package) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('Package')
        .doc(package.PackageID)
        .collection('packages')
        .add(package.toMap());

    log('Inserted package with ID: ${package.PackageID}');
  }


  Future<String?> getLastPackageID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('packages')
        .orderBy('PackageID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['PackageID']);
      return data['PackageID'];
    } else {
      log("No PackageID found");
    }
    return null;
  }

  Future<List<Package>?> getAllPackage() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('packages')
        .get();

    if(snapshot.docs.isNotEmpty){
      final packageList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Package.fromMap(data);
      }).toList();
      log("Found Package data");
      return packageList;
    }else{
      log("No Package data found");
      return null;
    }
  }

  Future<List<Package>> getPackageByCenterID(String CenterID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('packages')
        .where('CenterID', isEqualTo: CenterID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final packageList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Package.fromMap(data);
      }).toList();
      log("Found Package data for $CenterID");
      return packageList;
    }else{
      log("No Package data found for $CenterID");
      return [];
    }
  }

  Future<Package?> getPackageByPackageID(String packageID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('packages')
        .where('PackageID', isEqualTo: packageID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return Package.fromMap(data);
    } else {
      log("No PackageID found");
    }
    return null;
  }


  //edit user details of previous data
  Future<void> editPackage(Package package) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('Package')
          .doc(package.PackageID)
          .collection('packages')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('Package')
            .doc(package.PackageID)
            .collection('packages')
            .doc(docID)
            .update(package.toMap());

        log('Updated package data for user with PackageID : ${package.PackageID}');
      } else {
        log('No existing package document found for ${package.PackageID}');
      }
    } catch (e) {
      log('Error updating user: $e');
    }
  }


  Future<void> deletePackageById(String PackageID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('Package')
          .doc(PackageID)
          .collection('packages')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('Package')
            .doc(PackageID)
            .collection('packages')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore.collection('Package').doc(PackageID).delete();

      log('Successfully deleted PackageID: $PackageID');
    } catch (e) {
      log('Error deleting PackageID: $PackageID — $e');
    }
  }

//-------------------------------
//------------Booking------------
//-------------------------------

  Future insertBooking(Booking booking) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('Booking')
        .doc(booking.BookingID)
        .collection('booking')
        .add(booking.toMap());

    log('Inserted booking with ID: ${booking.BookingID}');
  }

  Future<String?> getLastBookingID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('booking')
        .orderBy('BookingID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['BookingID']);
      return data['BookingID'];
    } else {
      log("No BookingID found");
    }
    return null;
  }
  Future<List<Booking>> getAllBooking() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('booking')
        .orderBy('BookingID')
        .get();

    if(snapshot.docs.isNotEmpty){
      final bookingList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromMap(data);
      }).toList();
      log("Found Booking data");
      return bookingList;
    }else{
      log("No Booking data found");
      return [];
    }
  }

  Future<List<Booking>> getBookingsByCenterID(String centerID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Find packages belonging to that center
      final packageSnapshot = await _firestore
          .collectionGroup('packages')
          .where('CenterID', isEqualTo: centerID)
          .get();

      if (packageSnapshot.docs.isEmpty) {
        log("No packages found for this center.");
        return [];
      }

      // Extract package IDs
      List<String> packageIDs = packageSnapshot.docs
          .map((doc) => doc.data()['PackageID'].toString())
          .toList();

      log("Packages found: $packageIDs");

      // Step 2: Get bookings that match these package IDs
      final bookingSnapshot = await _firestore
          .collectionGroup('booking')
          .where('PackageID', whereIn: packageIDs)
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        log("No booking found for this center.");
        return [];
      }

      // Convert to Booking objects
      return bookingSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log("Error getting booking by centerID: $e");
      return [];
    }
  }


  Future<List<Booking>> getBookingsByCenterIDAndDate(String centerID, String startDate, String endDate) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Find packages belonging to that center
      final packageSnapshot = await _firestore
          .collectionGroup('packages')
          .where('CenterID', isEqualTo: centerID)
          .get();

      if (packageSnapshot.docs.isEmpty) {
        log("No packages found for this center.");
        return [];
      }

      // Extract package IDs
      List<String> packageIDs = packageSnapshot.docs
          .map((doc) => doc.data()['PackageID'].toString())
          .toList();

      log("Packages found: $packageIDs");

      // Step 2: Get bookings that match these package IDs
      final bookingSnapshot = await _firestore
          .collectionGroup('booking')
          .where('PackageID', whereIn: packageIDs)
          .where('bookingDate', isGreaterThanOrEqualTo: startDate)
          .where('bookingDate', isLessThanOrEqualTo: endDate)
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        log("No booking found for this center.");
        return [];
      }
      log("Booking found for this center.    $centerID");
      // Convert to Booking objects
      return bookingSnapshot.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log("Error getting booking by centerID: $e");
      return [];
    }
  }



  Future<List<Booking>?> getBookingByUserID(String userID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('booking')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final bookingList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Booking.fromMap(data);
      }).toList();
      log("Found Booking data for $userID");
      return bookingList;
    }else{
      log("No Booking data found for $userID");
      return null;
    }
  }

  Future<Booking?> getBookingByBookingID(String BookingID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('booking')
        .where('BookingID', isEqualTo: BookingID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final data = snapshot.docs.first.data();
      log("Found Booking data for $BookingID");
      return Booking.fromMap(data);

    }else{
      log("No Booking data found for $BookingID");
      return null;
    }
  }

  //edit user details of previous data
  Future<void> editBooking(Booking booking) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final querySnapshot = await _firestore
        .collection('Booking')
        .doc(booking.BookingID)
        .collection('booking')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docID = querySnapshot.docs.first.id;

      await _firestore
          .collection('Booking')
          .doc(booking.BookingID)
          .collection('booking')
          .doc(docID)
          .update(booking.toMap());

      log('Updated resource data for ${booking.BookingID}');
    } else {
      log('No existing resource data found for ${booking.BookingID}');
    }
  }



//-------------------------------
//----------Health Data----------
//-------------------------------

  Future<void> insertHealthData(HealthData healthData) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('HealthData')
        .doc(healthData.healthDataID)
        .collection('healthData')
        .add(healthData.toMap());

    log('Inserted health data with ID: ${healthData.healthDataID}');
  }


  Future<RTHealthData?> getRTHealthData() async{
    try {
      final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://io-mom-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      final snapshot = await _rtdb.ref('Sensors').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final rthd = RTHealthData.fromMap(data);
        return rthd;
      }else{
        return null;
      }
    }catch(e){
      log("Error when retrieve health data: $e");
    }
  }

  Future<double> getUserWithHealthData(String startDate, String endDate) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final snapshot = await firestore
          .collectionGroup('healthData')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No healthData found in date range");
        return 0;
      }
      final userSnapshot = await firestore
          .collectionGroup("user")
          .get();
      if (userSnapshot.docs.isEmpty) {
        print("No user found");
        return 0;
      }
      final healthDataList = snapshot.docs.map((doc) {
        final data = doc.data();
        return HealthData.fromMap(data);}).toList();

      final userList = userSnapshot.docs.map((doc) {
        final data = doc.data();
        return Users.fromMap(data);}).toList();
     var count = 0;
      for(var u in userList) {
        for (var hd in healthDataList) {
          if(u.userID == hd.userID){
            count++;
            break;
          }
        }
      }


      print("Found users with health data: $count");
      return (count/userList.length)*100;
    } catch (e) {
      print("Error loading users with health data: $e");
      return 0;
    }
  }

  Future<String?> getLastHealthDataID() async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('healthData')
        .orderBy('healthDataID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['healthDataID']);
      return data['healthDataID'];
    } else {
      log("No healthDataID found");
    }
    return null;
  }

  Future<HealthData?> getLastHealthData(String userID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('healthData')
        .where('userID',isEqualTo: userID)
        .orderBy('healthDataID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['healthDataID']);
      return HealthData.fromMap(data);
    } else {
      log("No healthDataID found");
    }
    return null;
  }

  Future<List<HealthData>?> getAllHealthDataByUserID(String userID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('healthData')
        .where('userID',isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final healthDataList = snapshot.docs.map((doc) {
        final data = doc.data();
        return HealthData.fromMap(data);}).toList();
      log("Found health Data data");
      return healthDataList;
    }else{
      log("No health data found");
      return null;
    }
  }


//-------------------------------
//----------PackageImages--------
//-------------------------------

  Future<void> insertPackageImages(PackageImages PackageImages) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('PackageImages')
        .doc(PackageImages.PackageID)
        .collection('packageImages')
        .add(PackageImages.toMap());

    log('Inserted package images with ID: ${PackageImages.PackageID}');
  }


  Future<List<PackageImages>?> getPackageImagesByPackageID(String PackageID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('packageImages')
        .where('PackageID', isEqualTo: PackageID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final imgList = snapshot.docs.map((doc) {
        final data = doc.data();
        return PackageImages.fromMap(data);
      }).toList();
      log("Found image for $PackageID");
      return imgList;
    }else{
      log("No image found for $PackageID");
      return null;
    }
  }


//-------------------------------
//----------Resources------------
//-------------------------------

  Future<void> insertResources(Resources resource) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('Resources')
        .doc(resource.ResourceID)
        .collection('resources')
        .add(resource.toMap());

    log('Inserted package with ID: ${resource.ResourceID}');
  }

  Future<String?> getLastResourceID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('resources')
        .orderBy('ResourceID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['ResourceID']);
      return data['ResourceID'];
    } else {
      log("No ResourceID found");
    }
    return null;
  }


  Future<List<Resources>> getAllResources() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('resources')
        .get();

    if(snapshot.docs.isNotEmpty){
      final packageList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Resources.fromMap(data);
      }).toList();
      log("Found bookmark data");
      return packageList;
    }else{
      log("No bookmark data found");
      return [];
    }
  }



  Future<Resources?> getResourceByResourceID(String ResourceID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('resources')
        .where('ResourceID', isEqualTo: ResourceID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return Resources.fromMap(data);
    } else {
      log("No PackageID found");
    }
    return null;
  }


  //edit user details of previous data
  Future<void> editResources(Resources resources) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final querySnapshot = await _firestore
          .collection('Resources')
          .doc(resources.ResourceID)
          .collection('resources')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;

        await _firestore
            .collection('Resources')
            .doc(resources.ResourceID)
            .collection('resources')
            .doc(docID)
            .update(resources.toMap());

        log('Updated resource data for ${resources.ResourceID}');
      } else {
        log('No existing resource data found for ${resources.ResourceID}');
      }
  }


//delete user
  Future<void> deleteResource(String ResourceID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;


      final subcollectionSnapshot = await _firestore
          .collection('Resources')
          .doc(ResourceID)
          .collection('resources')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('Resources')
            .doc(ResourceID)
            .collection('resources')
            .doc(doc.id)
            .delete();
      }

      await _firestore.collection('Resources').doc(ResourceID).delete();

      log('Successfully deleted ResourceID: $ResourceID');

  }



//-------------------------------
//----------Bookmark-------------
//-------------------------------
  Future<void> insertBookmark(Bookmark bookmark) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // Mirror to Firestore (for history)

    await _firestore
        .collection('Bookmark')
        .doc(bookmark.userID)
        .collection('bookmark')
        .add(bookmark.toMap());

    log('Inserted bookmark with userID: ${bookmark.userID}');

  }
  Future<String?> getLastUltrasoundImgID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('ultrasoundImages')
        .orderBy('ImageID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['ImageID']);
      return data['ImageID'];
    } else {
      log("No ImageID found");
    }
    return null;
  }


  Future<List<Bookmark>?> getBookmarkByUserID(String userID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('bookmark')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final bookmarkList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Bookmark.fromMap(data);
      }).toList();
      log("Found bookmark data for $userID");
      return bookmarkList;
    }else{
      log("No bookmark data found for $userID");
      return null;
    }
  }

  Future<List<Resources>?> getResourcesByUserID(List<Bookmark>? bookmarks) async{
    List<Resources> resourcesList =[];
    if(bookmarks != null){
      for(var bm in bookmarks){
        var temp = await getResourceByResourceID(bm.ResourceID);
        resourcesList.add(temp!);
      }
      return resourcesList;
    }else{
      return null;
    }
  }


  Future<void> deleteBookmark(Bookmark bookmark) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Find the document in the subcollection matching the ResourceID
    final querySnapshot = await _firestore
        .collection('Bookmark')
        .doc(bookmark.userID)
        .collection('bookmark')
        .where('ResourceID', isEqualTo: bookmark.ResourceID)
        .get();

    // Delete only matching documents
    for (final doc in querySnapshot.docs) {
      await _firestore
          .collection('Bookmark')
          .doc(bookmark.userID)
          .collection('bookmark')
          .doc(doc.id)
          .delete();
    }

    log('Successfully deleted bookmark for ResourceID: ${bookmark.ResourceID}');
  }


//-------------------------------
//------ultrasoundImages---------
//-------------------------------
  Future<void> insertUltrasoundImage(UltrasoundImages ultrasoundImages) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    await _firestore
        .collection('UltrasoundImages')
        .doc(ultrasoundImages.userID)
        .collection('ultrasoundImages')
        .add(ultrasoundImages.toMap());

    log('Inserted ultrasound images with ImageID: ${ultrasoundImages.ImageID}');
  }

  Future<List<UltrasoundImages>?> getUltrasoundImgByUserID(String userID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('ultrasoundImages')
        .where('userID', isEqualTo: userID)
        .get();

    if(snapshot.docs.isNotEmpty){
      final imgList = snapshot.docs.map((doc) {
        final data = doc.data();
        return UltrasoundImages.fromMap(data);
      }).toList();
      log("Found ultrasound Images data for $userID");
      return imgList;
    }else{
      log("No ultrasound Images found for $userID");
      return null;
    }
  }


  //edit user details of previous data
  Future<void> editUltrasoundImgByImageId(UltrasoundImages ultrasoundImages) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('UltrasoundImages')
          .doc(ultrasoundImages.userID)
          .collection('ultrasoundImages')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('UltrasoundImages')
            .doc(ultrasoundImages.userID)
            .collection('ultrasoundImages')
            .doc(docID)
            .update(ultrasoundImages.toMap());

        log('Updated Ultrasound Images data for user with id : ${ultrasoundImages.userID}');
      } else {
        log('No existing Ultrasound Images data found for ${ultrasoundImages.userID}');
      }
    } catch (e) {
      log('Error updating Ultrasound Images: $e');
    }
  }


  Future<void> deleteUltrasoundImageByImageId(UltrasoundImages ultrasoundImg) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Query to find the document with matching ImageID
      final querySnapshot = await _firestore
          .collection('UltrasoundImages')
          .doc(ultrasoundImg.userID)
          .collection('ultrasoundImages')
          .where('ImageID', isEqualTo: ultrasoundImg.ImageID)
          .get();

      // Delete each matching document (should be only one)
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      log('Successfully deleted ImageID: ${ultrasoundImg.ImageID}');
    } catch (e) {
      log('Error deleting ImageID: ${ultrasoundImg.ImageID} — $e');
    }
  }


//-------------------------------
//---------LinkedAccount---------
//-------------------------------

  Future<void> insertLinkedAccount(LinkedAccount linkedAccount) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    await _firestore
        .collection('LinkedAccount')
        .doc(linkedAccount.MainUserID)
        .collection('linkedAccount')
        .add(linkedAccount.toMap());

    log('Inserted linked account data MainUserID ${linkedAccount.MainUserID}');
  }

  Future<double> getPercentageUsersWithLinkedAccounts(String startDate, String endDate) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      var linkAccCount = 0;
      var totalUser = 0;
      final snapshot = await firestore
          .collectionGroup('linkedAccount')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();


      if (snapshot.docs.isNotEmpty) {
        final accList = snapshot.docs.map((doc) {
          final data = doc.data();
          return LinkedAccount.fromMap(data);
        }).toList();
        linkAccCount = accList.length;

        final usersSnapshot = await firestore
            .collectionGroup("user")
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          final userList = usersSnapshot.docs.map((doc) {
            final data = doc.data();
            return Users.fromMap(data);
          }).toList();
          totalUser = userList.length;
        } else {
          print("No user found");
        }
      } else {
        print("No linked accounts found");
      }

      double percentage = (linkAccCount/ totalUser) * 100;

      print("Users with linked accounts: $linkAccCount");
      print("Total users: $totalUser");
      print("Percentage: $percentage");

      return percentage;
    } catch (e) {
      print("Error calculating percentage with linked accounts: $e");
      return 0;
    }
  }




  Future<List<LinkedAccount>?> getLinkedAccountByMainUserID(String mainUserID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('linkedAccount')
        .where('MainUserID', isEqualTo: mainUserID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final accList = snapshot.docs.map((doc) {
        final data = doc.data();
        return LinkedAccount.fromMap(data);
      }).toList();
      log("Found linked Account data for $mainUserID");
      return accList;
    } else {
      log("No linked Account found");
    }
    return null;
  }

  Future<List<LinkedAccount>?> getLinkedAccountByLinkedUserID(String linkedUserID) async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collectionGroup('linkedAccount')
        .where('LinkedUserID', isEqualTo: linkedUserID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final accList = snapshot.docs.map((doc) {
        final data = doc.data();
        return LinkedAccount.fromMap(data);
      }).toList();
      log("Found linked Account data for $linkedUserID");
      return accList;
    } else {
      log("No linked Account found");
    }
    return null;
  }



  Future<void> editLinkedAccount(LinkedAccount linkedAcc) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('LinkedAccount')
          .doc(linkedAcc.MainUserID)
          .collection('linkedAccount')
          .where('LinkedUserID', isEqualTo: linkedAcc.LinkedUserID)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('LinkedAccount')
            .doc(linkedAcc.MainUserID)
            .collection('linkedAccount')
            .doc(docID)
            .update(linkedAcc.toMap());

        log('Updated linked account data for user with MainUserID : ${linkedAcc.MainUserID} \nand linkedUserID: ${linkedAcc.LinkedUserID}');
      } else {
        log('No existing linked account data found for ${linkedAcc.MainUserID}');
      }
    } catch (e) {
      log('Error updating Ultrasound Images: $e');
    }
  }


  Future<void> editVisibility(String mainUserID, String linkedAcc, String field, bool value) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final query = await _firestore
          .collection('LinkedAccount')
          .doc(mainUserID)
          .collection('linkedAccount')
          .where('LinkedUserID', isEqualTo: linkedAcc)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({field: value ? 'T' : 'F'});
      }

        log('Updated linked account data for user with MainUserID : ${mainUserID} \nand linkedUserID: ${linkedAcc}');
    } catch (e) {
      log('Error updating Ultrasound Images: $e');
    }
  }

  Future<void> deleteLinkedAccount(String LinkedUserID, String MainUserID) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Find the document in the subcollection matching the ResourceID
    final querySnapshot = await _firestore
        .collection('LinkedAccount')
        .doc(MainUserID)
        .collection('linkedAccount')
        .where('LinkedUserID', isEqualTo: LinkedUserID)
        .get();

    // Delete only matching documents
    for (final doc in querySnapshot.docs) {
      await _firestore
          .collection('LinkedAccount')
          .doc(MainUserID)
          .collection('linkedAccount')
          .doc(doc.id)
          .delete();
    }

    log('Successfully deleted linked account for LinkedUserID: ${LinkedUserID}');
  }



//-------------------------------
//----CollaborationRequest-------
//-------------------------------

  Future<void> insertCollaborationRequest(CollaborationRequest colRequest) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    await _firestore
        .collection('CollaborationRequest')
        .doc(colRequest.RequestID)
        .collection('collaborationRequest')
        .add(colRequest.toMap());

    log('Inserted collaboration request data with requestID: ${colRequest.RequestID}');
  }

  Future<String?> getLastRequestID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('collaborationRequest')
        .orderBy('RequestID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      log(data['RequestID']);
      return data['RequestID'];
    } else {
      log("No RequestID found");
    }
    return null;
  }

  Future<List<CollaborationRequest>> getAllCollaborationRequest() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('collaborationRequest')
        .get();

    if(snapshot.docs.isNotEmpty){
      final colRequestList = snapshot.docs.map((doc) {
        final data = doc.data();
        return CollaborationRequest.fromMap(data);
      }).toList();
      log("Found collaboration request data");
      return colRequestList;
    }else{
      log("No collaboration request data found");
      return [];
    }
  }

  Future<List<CollaborationRequest>> getAllRequest() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('collaborationRequest')
        .where('status', isEqualTo: 'P')
        .get();

    if(snapshot.docs.isNotEmpty){
      final colRequestList = snapshot.docs.map((doc) {
        final data = doc.data();
        return CollaborationRequest.fromMap(data);
      }).toList();
      log("Found collaboration request data");
      return colRequestList;
    }else{
      log("No collaboration request data found");
      return [];
    }
  }

  Future<List<CollaborationRequest>> getAllRejectRequest() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('collaborationRequest')
        .where('status', isEqualTo: 'R')
        .get();

    if(snapshot.docs.isNotEmpty){
      final colRequestList = snapshot.docs.map((doc) {
        final data = doc.data();
        return CollaborationRequest.fromMap(data);
      }).toList();
      log("Found collaboration request data");
      return colRequestList;
    }else{
      log("No collaboration request data found");
      return [];
    }
  }
  Future<List<CollaborationRequest>> getAllApproveRequest() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('collaborationRequest')
        .where('status', isEqualTo: 'A')
        .get();

    if(snapshot.docs.isNotEmpty){
      final colRequestList = snapshot.docs.map((doc) {
        final data = doc.data();
        return CollaborationRequest.fromMap(data);
      }).toList();
      log("Found collaboration request data");
      return colRequestList;
    }else{
      log("No collaboration request data found");
      return [];
    }
  }


  Future<CollaborationRequest?> getColRequestByRequestID(String RequestID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collection('CollaborationRequest')
        .doc(RequestID)
        .collection('collaborationRequest')
        .limit(1)
        .get();
    if(snapshot.docs.isNotEmpty){
      final data = snapshot.docs.first.data();
      return CollaborationRequest.fromMap(data);
    }else{
      log("No collaboration request data found for $RequestID");
      return null;
    }
  }

  Future<void> editColRequestByRequestId(CollaborationRequest colRequest) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      // Find the document inside the subcollection "user"
      final querySnapshot = await _firestore
          .collection('CollaborationRequest')
          .doc(colRequest.RequestID)
          .collection('collaborationRequest')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docID = querySnapshot.docs.first.id;
        await _firestore
            .collection('CollaborationRequest')
            .doc(colRequest.RequestID)
            .collection('collaborationRequest')
            .doc(docID)
            .update(colRequest.toMap());

        log('Updated collaboration Request data for RequestID : ${colRequest.RequestID}');
      } else {
        log('No existing collaboration Request data found for ${colRequest.RequestID}');
      }
    } catch (e) {
      log('Error collaboration Request data: $e');
    }
  }


  Future<void> deleteColRequestByRequestID(String RequestID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      // Step 1: Delete all documents in subcollection 'user'
      final subcollectionSnapshot = await _firestore
          .collection('CollaborationRequest')
          .doc(RequestID)
          .collection('collaborationRequest')
          .get();

      for (final doc in subcollectionSnapshot.docs) {
        await _firestore
            .collection('CollaborationRequest')
            .doc(RequestID)
            .collection('collaborationRequest')
            .doc(doc.id)
            .delete();
      }

      // Step 2: Delete the parent document (userID)
      await _firestore.collection('CollaborationRequest').doc(RequestID).delete();

      log('Successfully deleted RequestID: $RequestID');
    } catch (e) {
      log('Error deleting RequestID: $RequestID — $e');
    }
  }



//-------------------------------
//---------Transaction-----------
//-------------------------------
  Future<void> insertTransaction(Transactions transaction) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    await _firestore
        .collection('Transaction')
        .doc(transaction.TransactionID)
        .collection('transaction')
        .add(transaction.toMap());

    log('Inserted collaboration request data with requestID: ${transaction.TransactionID}');
  }

  Future<String?> getLastTransactionsID() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('transaction')
        .orderBy('transactionDate', descending: true)
        .limit(1)
        .get();

    if(snapshot.docs.isNotEmpty){
      final data = snapshot.docs.first.data();
      log(data['TransactionID']);
      return data['TransactionID'];
    }else{
      log("No transaction found");
      return null;
    }
  }

  Future<List<Transactions>> getAllTransactions() async {

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collectionGroup('transaction')
        .orderBy('TransactionID')
        .get();

    if(snapshot.docs.isNotEmpty){
      final transactionList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Transactions.fromMap(data);
      }).toList();
      log("Found transaction data");
      return transactionList;
    }else{
      log("No transaction found");
      return [];
    }
  }

  Future<Transactions?> getTransactionByTransactionID(String TransactionID) async{
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collection('Transaction')
        .doc(TransactionID)
        .collection('transaction')
        .limit(1)
        .get();
    if(snapshot.docs.isNotEmpty){
      final data = snapshot.docs.first.data();
      return Transactions.fromMap(data);
    }else{
      log("No Transaction found for $TransactionID");
      return null;
    }
  }





}


