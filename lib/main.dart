import 'package:flutter/material.dart';
import 'pages/homePage.dart';
import 'pages/loginPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/profilePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
  );
  runApp(MaterialApp(  
    title: '',
    debugShowCheckedModeBanner: false,
    initialRoute: "/login",
    routes: {
      '/login': (context) => LoginPage(),
      '/home': (context) => const Home(),
      "/profile": (context) => const ProfilePage(),
    },
  ));
}