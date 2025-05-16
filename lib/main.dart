import 'package:dynamochess/screens/chess.dart';
import 'package:dynamochess/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      title: 'Flutter Demo',
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      initialBinding: ControllerBinder(),
      home: ChessBoardScreen(),
    );
  }
}

ThemeData _darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    iconTheme: const IconThemeData(
      color: Colors.white, // Set the desired color here
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 36.00, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(
          fontSize: 28.00, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(
        fontSize: 20.00,
        color: Color(0XFFffffff),
      ),
      titleSmall: TextStyle(fontSize: 14.00, color: Colors.white),
    ),
    inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
  );
}

ThemeData _lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 36.00, fontWeight: FontWeight.bold, color: Colors.black),
      titleLarge: TextStyle(
          fontSize: 28.00, fontWeight: FontWeight.bold, color: Colors.black),
      titleMedium: TextStyle(
        fontSize: 20.00,
        color: Color(0XFF000000),
      ),
      titleSmall: TextStyle(fontSize: 14.00, color: Colors.black),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.black),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white, // Set the desired color here
    ),
  );
}
