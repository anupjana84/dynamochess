import 'package:dynamochess/screens/chess.dart';
import 'package:dynamochess/screens/grid_screen.dart';
import 'package:dynamochess/screens/login_screen.dart';

import 'package:dynamochess/screens/off_line_chess.dart';

import 'package:dynamochess/screens/playonline1.dart';
import 'package:dynamochess/screens/register_screen.dart';
import 'package:dynamochess/widgets/bacground.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> poplist = ["Login", "Register", "Logout"];

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  void _playOffline() {
    Get.to(const OffLineChessScreen());
    //
  }

  static Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(const HomeScreen()); // Return to home screen after logout
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        toolbarHeight: 1,
        backgroundColor: Colors.black,
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.03),
                _logoDotPart(screenHeight),
                const Text(
                  "DYNAMO CHESS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Develop a Dynamic Mind!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 35,
                    fontFamily: "Rambejaji",
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: screenHeight * 0.25,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Row(children: [
                    _buildButton(
                      context,
                      'Play online',
                      Icons.public,
                      onPressed: () async {
                        bool isLoggedIn = await hasToken();
                        if (isLoggedIn) {
                          Get.to(const GridScreen());
                        } else {
                          Get.to(const LoginScreen());
                        }
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 38.0,
                    top: 8.0,
                    bottom: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton(
                        context,
                        'Play offline',
                        Icons.wifi_off,
                        onPressed: _playOffline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                    top: 4.0,
                    bottom: 4.0,
                  ),
                  child: Row(children: [
                    _buildButton(
                      context,
                      'Puzzles',
                      Icons.extension,
                      onPressed: () {
                        //Get.to(const GridScreen());
                        // Add your onPressed logic here
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 38.0,
                    top: 4.0,
                    bottom: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton(
                        context,
                        'With Friends',
                        Icons.people,
                        onPressed: () {
                          // Get.to(const ChessBoardScreen());
                          Get.snackbar(
                            "With Friends",
                            "You have selected With Friends mode!",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                const Text(
                  "Powered of 100 square Board !",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _logoDotPart(double screenHeight) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.15,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SizedBox(
              width: 200,
              height: screenHeight * 0.15,
              child: Image.asset(
                "assets/images/logo_dynamo.png",
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 0,
            child: FutureBuilder<bool>(
              future: hasToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final isLoggedIn = snapshot.data ?? false;

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  iconSize: 25,
                  onSelected: (value) async {
                    if (value == "Login") {
                      Get.to(const LoginScreen());
                    } else if (value == "Register") {
                      Get.to(const RegisterScreen());
                    } else if (value == "Logout") {
                      await _logout();
                      setState(() {}); // Refresh the UI
                    }
                  },
                  itemBuilder: (context) {
                    if (isLoggedIn) {
                      return [
                        const PopupMenuItem<String>(
                          value: "Logout",
                          child: Text(
                            "Logout",
                            style: TextStyle(fontFamily: "Style2"),
                          ),
                        ),
                      ];
                    } else {
                      return [
                        const PopupMenuItem<String>(
                          value: "Login",
                          child: Text(
                            "Login",
                            style: TextStyle(fontFamily: "Style2"),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: "Register",
                          child: Text(
                            "Register",
                            style: TextStyle(fontFamily: "Style2"),
                          ),
                        ),
                      ];
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon,
      {required VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            spreadRadius: 2,
            blurRadius: 1,
            offset: const Offset(2, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(180, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
