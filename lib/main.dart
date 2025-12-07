import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'database.dart';
import 'splash_screen.dart';
import 'user_provider.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;


void main() async {
  final dbservice = await DatabaseService();
  WidgetsFlutterBinding.ensureInitialized();
  tzData.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Gemini.init(apiKey: "AIzaSyDo510C-f2gnYn_83sUcmv7aWwwMr0BECk",
    disableAutoUpdateModelName: false,);

  //dbservice.resetDatabase();
  //dbservice.initDatabase();
  //dbservice.initializeData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Login Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(), // Here!!
    );
  }
}

