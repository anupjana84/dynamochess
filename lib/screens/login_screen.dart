import 'dart:convert';
import 'package:dynamochess/screens/dashboard_screen.dart';
import 'package:dynamochess/screens/home.dart';
import 'package:dynamochess/utils/api_call.dart';
import 'package:dynamochess/utils/api_list.dart';
import 'package:dynamochess/models/network_model.dart';
import 'package:dynamochess/widgets/bacground.dart';
import 'package:dynamochess/widgets/center_circular.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'], // Requested permissions
    clientId: 'YOUR_CLIENT_ID', // Optional (required for some platforms)
  );

  final RegExp _emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');

  // Future<void> _submitForm() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   final Map<String, dynamic> data = {
  //     'email': _emailController.text,
  //     'password': _passwordController.text,
  //   };

  //   final NetworkResponse response =
  //       await ApiCall.postApiCall(ApiList.login, body: data);

  //   String errorMessage = "Something went wrong";

  //   if (!response.isSuccess) {
  //     try {
  //       final errorData = jsonDecode(response.errorMessage);
  //       if (errorData is Map && errorData.containsKey('message')) {
  //         String rawMessage = errorData['message'];

  //         // Handle MongoDB E11000 duplicate key error
  //         if (rawMessage.startsWith('E11000')) {
  //           RegExp regExp = RegExp(r'dup key: \{ (\w+):');
  //           Match? match = regExp.firstMatch(rawMessage);
  //           if (match != null && match.groupCount >= 1) {
  //             String field = match.group(1)!;
  //             errorMessage = "This $field is already in use";
  //           } else {
  //             errorMessage = "This field is already in use";
  //           }
  //         } else {
  //           errorMessage = rawMessage;
  //         }
  //       }
  //     } catch (e) {
  //       errorMessage = response.errorMessage;
  //     }
  //   }

  //   if (response.isSuccess) {
  //     Get.snackbar("Success", "Login successful!");
  //     Future.delayed(Duration(seconds: 1), () {
  //       // Get.offAllNamed('/home'); // Navigate to home
  //       //  Get.offAll(() => const DashboardScreen());
  //     });
  //     print(response.responseData);
  //   } else {
  //     Get.snackbar("Error", errorMessage, backgroundColor: Colors.red);
  //   }

  //   setState(() => _isLoading = false);
  // }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    final NetworkResponse response =
        await ApiCall.postApiCall(ApiList.login, body: data);

    String errorMessage = "Something went wrong";

    if (!response.isSuccess) {
      try {
        final errorData = jsonDecode(response.errorMessage);
        if (errorData is Map && errorData.containsKey('message')) {
          String rawMessage = errorData['message'];
          // Handle MongoDB E11000 duplicate key error
          if (rawMessage.startsWith('E11000')) {
            RegExp regExp = RegExp(r'dup key: \{ (\w+):');
            Match? match = regExp.firstMatch(rawMessage);
            if (match != null && match.groupCount >= 1) {
              String field = match.group(1)!;
              errorMessage = "This $field is already in use";
            } else {
              errorMessage = "This field is already in use";
            }
          } else {
            errorMessage = rawMessage;
          }
        }
      } catch (e) {
        errorMessage = response.errorMessage;
      }
    }

    if (response.isSuccess) {
      // ✅ Save user data to local storage
      final responseData = response.responseData; // decode server response
      final userData = responseData['data'];

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save all fields
      prefs.setString('_id', userData['_id']);
      prefs.setString('role', userData['role']);
      prefs.setString('email', userData['email']);
      prefs.setString('name', userData['name']);
      prefs.setString('mobile', userData['mobile']);
      prefs.setString('countryIcon', userData['countryIcon']);
      prefs.setString('country', userData['country']);
      prefs.setInt('dynamoCoin', userData['dynamoCoin']);
      prefs.setInt('Rating', userData['Rating']);
      prefs.setString('token', userData['token']);

      Get.snackbar("Success", "Login successful!");
      final role = prefs.getString('_id');
      print(role);

      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => const HomeScreen()); // Navigate to dashboard
      });
    } else {
      Get.snackbar("Error", errorMessage, backgroundColor: Colors.red);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    //   final GoogleSignIn _googleSignIn = GoogleSignIn();

    //   try {
    //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    //     if (googleUser == null) return;

    //     final GoogleSignInAuthentication googleAuth =
    //         await googleUser.authentication;

    //     final Map<String, dynamic> data = {
    //       'token': googleAuth.idToken,
    //       'provider': 'google'
    //     };

    //     print(data);
    //     // final NetworkResponse response =
    //     //     await ApiCall.postApiCall(ApiList.googleLogin, body: data);

    //     // if (response.isSuccess) {
    //     //   Get.snackbar("Success", "Google login successful!");
    //     //   Get.offAllNamed('/home');
    //     // } else {
    //     //   String errorMessage = "Login failed";
    //     //   try {
    //     //     final errorData = jsonDecode(response.errorMessage);
    //     //     if (errorData is Map && errorData.containsKey('message')) {
    //     //       errorMessage = errorData['message'];
    //     //     }
    //     //   } catch (e) {
    //     //     errorMessage = response.errorMessage;
    //     //   }
    //     //   Get.snackbar("Error", errorMessage, backgroundColor: Colors.red);
    //     // }
    //   } catch (error) {
    //     Get.snackbar("Error", "Google sign-in failed",
    //         backgroundColor: Colors.red);
    //   }
    // }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // Get auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Extract tokens
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;
      print("idToken");
      print(idToken);
      print("idToken");

      if (idToken == null) {
        throw Exception('Google Sign-In failed: No ID token.');
      }

      // Send tokens to your backend for verification
      //await verifyWithBackend(idToken, accessToken);
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final double sizedBoxHeight = screenHeight * 0.02;

    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sizedBoxHeight * 2),
                  Image.asset(
                    'assets/images/logo_dynamo.png',
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.2,
                  ),
                  SizedBox(height: sizedBoxHeight * 2),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFF0B561B),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.white),
                              prefixIcon:
                                  Icon(Icons.email, color: Colors.white),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 10),
                              errorStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              } else if (!_emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: sizedBoxHeight),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0xFF0B561B),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.white),
                              prefixIcon:
                                  const Icon(Icons.lock, color: Colors.white),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 10),
                              errorStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              } else if (value.length < 8) {
                                return 'At least 8 characters,';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: sizedBoxHeight * 2),
                        const Text(
                          "Forgot Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizedBoxHeight * 2),
                        _buildLoginButton(context),
                        SizedBox(height: sizedBoxHeight),
                        const Text(
                          "Or",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: sizedBoxHeight),
                        ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: Image.asset(
                            'assets/images/google.png',
                            height: screenHeight * 0.04,
                          ),
                          label: const Text('Continue with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize:
                                Size(screenWidth * 0.8, screenHeight * 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Visibility(
        visible: !_isLoading,
        replacement: const CenteredProgressIndicator(),
        child: Container(
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
            onPressed: _submitForm,
            label: const Text(
              "Login",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.login, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(screenWidth * 0.8, screenHeight * 0.07),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.green.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}
