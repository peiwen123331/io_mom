import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:io_mom/milestone_reminder.dart';
import 'package:io_mom/mood_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'medication_reminder.dart';
import 'mood.dart';
import 'user.dart';
import 'ChatMessages.dart';


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

    await _firestore
        .collection('MilestoneReminder')
        .doc('MIL0001')
        .collection('milestoneReminder')
        .add({
      'milReminderID': 'MIL0001',
      'mileStoneName': 'Check up',
      'description': 'Go Sultan Bakar Abdul Halim Hospital',
      'startDate': '2025-10-29 14:00:00',
      'endDate': '2025-10-29 16:00:00',
      'userID': 'Gd6BwscZpvMGUdugFvCdA8rgKRx2',
    });

    await _firestore
        .collection('MedicationReminder')
        .doc('MED0001')
        .collection('medicationReminder')
        .add({
      'medReminderID': 'MED0001',
      'medicationName': 'Vitamin C',
      'dosage': 1.0,
      'frequency': 3,
      'repeatDuration': 4,
      'startTime': '2025-10-29 8:00:00',
      'lastConfirmedDate': '2025-10-29 17:04:00',
      'userID': 'Gd6BwscZpvMGUdugFvCdA8rgKRx2',
    });



    print("Data inserted");
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
        .add({
      'userName': user.userName,
      'userEmail': user.userEmail,
      'userRegDate': user.userRegDate,
      'phoneNo': user.phoneNo,
      'userStatus': user.userStatus,
      'profileImgPath': user.profileImgPath,
    });

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
        // doc.reference.parent.parent is the [UserID] document reference.
        final userID = doc.reference.parent.parent?.id ?? '';

        return Users(
          // Extract the userID from the path
          userID: userID,
          userName: data['userName'] ?? '',
          userEmail: data['userEmail'] ?? '',
          userRegDate: (data['userRegDate'] is Timestamp)
              ? (data['userRegDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['userRegDate'].toString()) ?? DateTime.now(),
          phoneNo: data['phoneNo'] ?? '',
          userStatus: data['userStatus'] ?? '',
          profileImgPath: data['profileImgPath'] ?? '',
        );
      }

      // If no user found
      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
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

        return Users(
          userID: userID,
          userName: data['userName'] ?? '',
          userEmail: data['userEmail'] ?? '',
          userRegDate: (data['userRegDate'] is Timestamp)
              ? (data['userRegDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['userRegDate'].toString()) ?? DateTime.now(),
          phoneNo: data['phoneNo'] ?? '',
          userStatus: data['userStatus'] ?? '',
          profileImgPath: data['profileImgPath'] ?? '',
        );
      } else {
        print('No user found for ID: $userID');
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
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
    print("Total relevant messages found: ${allMessages.length}");

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
        final user = Users(
          userID: otherUserID,
          userName: data['userName'] ?? '',
          userEmail: data['userEmail'] ?? '',
          userRegDate: (data['userRegDate'] is Timestamp)
              ? (data['userRegDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['userRegDate'].toString()) ?? DateTime.now(),
          phoneNo: data['phoneNo'] ?? '',
          userStatus: data['userStatus'] ?? '',
          profileImgPath: data['profileImgPath'] ?? '',
        );
        fetchedUsersMap[otherUserID] = user; // Store in map
      } else {
        print("Warning: No user profile found for $otherUserID");
      }
    }

    // 4. Return the list of unique chat users
    return fetchedUsersMap.values.toList();
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
            .update({
          'userName': user.userName,
          'userEmail': user.userEmail,
          'userRegDate': user.userRegDate,
          'phoneNo': user.phoneNo,
          'userStatus': user.userStatus,
          'profileImgPath': user.profileImgPath,
        });

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
      .add({
    'messageContent': chatMessages.messageContent,
    'SenderID': chatMessages.SenderID,
    'ReceiverID': chatMessages.ReceiverID,
    'time': chatMessages.time,
    });

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
      return ChatMessages(
        MessageID: roomID,
        messageContent: data['messageContent'] ?? '',
        SenderID: data['SenderID'] ?? '',
        ReceiverID: data['ReceiverID'] ?? '',
        time: (data['time'] as Timestamp).toDate(),
      );
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
        .add({
      'MoodDesc': mood.MoodDesc,
      'MoodDate': mood.MoodDate,
      'MoodStatus': mood.MoodStatus,
      'userID': mood.userID,
      'MoodTypeID': mood.MoodTypeID,
    });

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
    print(data['MoodID']);
    return data['MoodID'];
  } else {
    print("No moodID found");
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
     return Mood(
       MoodID: data['MoodID'],
       MoodDesc: data['MoodDesc'] ?? '',
       MoodStatus: data['MoodDate'] ?? '',
       MoodDate: (data['MoodDate'] is Timestamp)
           ? (data['MoodDate'] as Timestamp).toDate()
           : DateTime.tryParse(data['MoodDate'].toString()) ?? DateTime.now(),
       userID: data['userID']!,
       MoodTypeID: data['MoodTypeID'],
     );
   }).toList();
      return moodList;
    }else{
      print("No mood data found for ${userID}");
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
        print('Retrieve moodType data for ID: $moodTypeID');
        final data = snapshot.docs.first.data();
        return MoodType(
          MoodTypeID: data['MoodTypeID'],
          MoodTypeImg: data['MoodTypeImg'],
          MoodTypeStatus: data['MoodTypeStatus'],
          MoodTypeName: data['MoodTypeName'],
        );

      } else {
        print('No moodType for ID: $moodTypeID');
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
            .update({
          'MoodDesc': mood.MoodDesc,
          'MoodDate': mood.MoodDate,
          'MoodStatus': mood.MoodStatus,
          'userID': mood.userID,
          'MoodTypeID': mood.MoodTypeID,
        });

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
        .add({
      'milReminderID': milReminder.milReminderID,
      'mileStoneName': milReminder.mileStoneName,
      'description': milReminder.description,
      'startDate': milReminder.startDate,
      'endDate': milReminder.endDate,
      'userID': milReminder.userID,
    });

    log('Inserted Milestone Reminder with ID: ${milReminder.milReminderID}');
  }

  Future<String?> getLastMilReminderID() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final snapshot = await _firestore
        .collectionGroup('milestoneReminder')
        .orderBy('milReminderID', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      print(data['milReminderID']);
      return data['milReminderID'];
    } else {
      print("No milReminderID found");
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
        return MilestoneReminder(
            milReminderID: data['milReminderID'],
            mileStoneName: data['mileStoneName'],
            description: data['description'],
            startDate:  (data['startDate'] is Timestamp)
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['startDate'].toString()) ?? DateTime.now(),
            endDate: (data['startDate'] is Timestamp)
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['startDate'].toString()) ?? DateTime.now(),
            userID: data['userID'],
        );
      }).toList();
      print("Found milestone reminder data for ${userID}");
      return milList;
    }else{
      print("No milestone reminder data found for ${userID}");
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
            .update({
          'milReminderID': milReminder.milReminderID,
          'mileStoneName': milReminder.mileStoneName,
          'description': milReminder.description,
          'startDate': milReminder.startDate,
          'endDate': milReminder.endDate,
          'userID': milReminder.userID,
        });

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
        .add({
      'medReminderID': medReminder.medReminderID,
      'medicationName': medReminder.medicationName,
      'dosage': medReminder.dosage,
      'frequency': medReminder.frequency,
      'repeatDuration': medReminder.repeatDuration,
      'startTime': medReminder.startTime,
      'lastConfirmedDate': medReminder.lastConfirmedDate,
      'userID': medReminder.userID,
    });

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
      print(data['medReminderID']);
      return data['medReminderID'];
    } else {
      print("No medReminderID found");
    }
    return null;
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
        return MedicationReminder(
            medReminderID: data['medReminderID'],
            medicationName: data['medicationName'],
            dosage: data['dosage'],
            frequency: data['frequency'],
            repeatDuration: data['repeatDuration'],
            startTime: (data['startTime'] is Timestamp)
                ? (data['startTime'] as Timestamp).toDate()
                : DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now(),
            userID: data['userID']
        );
      }).toList();
      print("Found medication reminder data for ${userID}");
      return medList;
    }else{
      print("No medication reminder data found for ${userID}");
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
      print('Retrieve medication reminder data for ID: $medReminderID');
      final data = snapshot.docs.first.data();
        return MedicationReminder(
            medReminderID: data['medReminderID'],
            medicationName: data['medicationName'],
            dosage: data['dosage'],
            frequency: data['frequency'],
            repeatDuration: data['repeatDuration'],
            startTime: (data['startTime'] is Timestamp)
                ? (data['startTime'] as Timestamp).toDate()
                : DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now(),
            userID: data['userID']
        );
    }else{
      print("No medication reminder data found for ${medReminderID}");
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
            .update({
          'medReminderID': medReminder.medReminderID,
          'medicationName': medReminder.medicationName,
          'dosage': medReminder.dosage,
          'frequency': medReminder.frequency,
          'repeatDuration': medReminder.repeatDuration,
          'startTime': medReminder.startTime,
          'lastConfirmedDate': medReminder.lastConfirmedDate,
          'userID': medReminder.userID,
        });

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






/*Future<List<String>?> insertMediaChatMessage(ChatMessages chatMessages, String fileName, String path) async {
    final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://io-mom-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseStorage _storage = FirebaseStorage.instance;

    final ref = _storage.ref().child('chat_images/${chatMessages.MessageID}/$fileName');
    await ref.putFile(File(path));
    final mediaUrl = await ref.getDownloadURL();
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    List<String>? strList;

    final msgData = {
      'messageContent': chatMessages.messageContent,
      'SenderID': chatMessages.SenderID,
      'ReceiverID': chatMessages.ReceiverID,
      'time': chatMessages.time,
      'mediaUrl': mediaUrl,
      'fileName': filename,
    };

    // Push to Realtime DB
    await _rtdb.ref('chats/${chatMessages.MessageID}/messages').push().set(msgData);

    // Mirror to Firestore
    await _firestore
        .collection('chats')
        .doc(chatMessages.MessageID)
        .collection('messages')
        .add({
      ...msgData,
      'time': chatMessages.time,
    });
    strList!.add(filename);
    strList!.add(mediaUrl);

    log('Inserted ChatMessages with ID: ${chatMessages.MessageID}');
    return strList;
  }*/
}


