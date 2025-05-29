import 'package:dynamochess/screens/chess.dart';

import 'package:dynamochess/screens/login_screen.dart';
import 'package:dynamochess/screens/off_line_chess.dart';
import 'package:dynamochess/screens/online_play.dart';
import 'package:dynamochess/screens/playonline.dart';

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

  // Define a function for "Play offline"
  void _playOffline() {
    // Add your logic for "Play offline" here
    // Get.snackbar(
    //   "Play Offline",
    //   "You have selected Play Offline mode!",
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    // );
    Get.to(OffLineChessScreen());
  }

  static Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // print("All SharedPreferences keys cleared.");
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
                  SizedBox(height: screenHeight * 0.03), // 3% of screen height
                  _logoDotPart(screenHeight),
                  const Text(
                    "DYNAMO CHESS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    "Develop a Dynamic Mind!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 35,
                        fontFamily: "Rambejaji",
                        color: Colors.white),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: screenHeight * 0.25, // 25% of screen height
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
                            // Go directly to ChessBoardScreen
                            Get.to(const ChessBoardScreen());
                          } else {
                            // Navigate to Login Screen
                            Get.to(
                                const LoginScreen()); // or your login page route
                          }
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 38.0, top: 8.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildButton(
                          context,
                          'Play offline',
                          Icons.wifi_off,
                          onPressed: _playOffline, // Pass the function here
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
                    child: Row(children: [
                      _buildButton(
                        context,
                        'Puzzles',
                        Icons.extension,
                        onPressed: () {
                          // Add your onPressed logic here
                          //Get.to(const OnlineChessScreen());
                          // Get.snackbar(
                          //   "Puzzles",
                          //   "You have selected Puzzles mode!",
                          //   snackPosition: SnackPosition.BOTTOM,
                          //   backgroundColor: Colors.green,
                          //   colorText: Colors.white,
                          // );
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 38.0, top: 4.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildButton(
                          context,
                          'With Friends',
                          Icons.people,
                          onPressed: () {
                            // Add your onPressed logic here
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
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    "Powered of 100 square Board !",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  SizedBox _logoDotPart(double screenHeight) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.15, // 15% of screen height
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SizedBox(
              width: 200,
              height: screenHeight * 0.15, // 15% of screen height
              child: Image.asset(
                "assets/images/logo_dynamo.png",
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: Colors.white), // Icon for the button
              iconSize: 25,
              onSelected: (value) {
                if (value == "Login") {
                  Get.to(const LoginScreen());
                } else if (value == "Register") {
                  Get.to(const RegisterScreen());
                } else {
                  _logout();
                }
              },
              itemBuilder: (context) {
                return poplist
                    .map((e) => PopupMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(fontFamily: "Style2"),
                          ),
                        ))
                    .toList();
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
            color: Colors.white.withOpacity(0.9), // Shadow color with opacity
            spreadRadius: 2, // Spread radius
            blurRadius: 1, // Blur radius
            offset: const Offset(2, 5), // Offset in x and y direction
          ),
        ],
        borderRadius: BorderRadius.circular(10), // Match button's border radius
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Button color
          minimumSize: const Size(180, 50), // Adjust size
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners
          ),
          elevation: 0, // Remove default elevation to avoid double shadows
        ),
      ),
    );
  }
}
