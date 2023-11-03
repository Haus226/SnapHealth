import 'package:flutter/material.dart';
import 'homePage.dart';
import 'loginPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'profilePage.dart';

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