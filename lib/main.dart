
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/CustomLoginScreen.dart';
import 'package:inventory_management/CustomRegisterScreen.dart';
import 'package:inventory_management/admin_home_page.dart';
import 'package:inventory_management/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventory_management/user_home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  print("Connected to database.");

  runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CustomLoginScreen(),

      debugShowCheckedModeBanner: false,

      routes: {
        '/sign-in': (context) =>  CustomLoginScreen(),
        '/register': (context) => CustomRegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home' : (context) =>  UserHomePage(),
        '/admin-home' : (context) =>  AdminHomePage(),
      },

    );
  }
}


