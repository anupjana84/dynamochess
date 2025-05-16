import 'dart:convert';

import 'package:dynamochess/models/network_model.dart';
import 'package:dynamochess/screens/login_screen.dart';
import 'package:dynamochess/utils/api_call.dart';
import 'package:dynamochess/utils/api_list.dart';
import 'package:dynamochess/widgets/center_circular.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Adjust import path
import 'package:dynamochess/widgets/bacground.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  String? _selectedCountry = 'United States';
  bool _isLoading = false;

  final List<String> countries = [
    'India',
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Brazil',
    'South Africa'
  ];

  // Regex Patterns
  final RegExp _nameRegex = RegExp(r'^[a-zA-Z ]+$');
  final RegExp _emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');
  // 8+ chars, 1 upper, 1 lower, 1 digit

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _save();
      // Simulate successful registration
      // Get.snackbar("Success", "Registration successful!");
      // Get.back(); // Go back to login screen
    }
  }

  Future<void> _save() async {
    _isLoading = true;
    setState(() {});
    Map<String, dynamic> data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'mobile': _phoneController.text,
      'password': _passwordController.text,
      'country': _selectedCountry ?? "",
      'referral': _referralController.text,
    };
    // print(data);
    final NetworkResponse response =
        await ApiCall.postApiCall(ApiList.register, body: data);
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
            // Use the message as-is if it's not a MongoDB error
            errorMessage = rawMessage;
          }
        }
      } catch (e) {
        // Fallback: raw error message
        errorMessage = response.errorMessage;
      }
    }

    if (response.isSuccess) {
      Get.snackbar("Success", "Registration successful!");
      Future.delayed(
          const Duration(seconds: 1), () => Get.to(const LoginScreen()));
    } else {
      Get.snackbar("Error", errorMessage, backgroundColor: Colors.red);
    }

    _isLoading = false;
    setState(() {});
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
                        _buildNameField(),
                        SizedBox(height: sizedBoxHeight),
                        _buildPhoneField(),
                        SizedBox(height: sizedBoxHeight),
                        _buildEmailField(),
                        SizedBox(height: sizedBoxHeight),
                        _buildPasswordField(),
                        SizedBox(height: sizedBoxHeight),
                        _buildCountrySelector(),
                        SizedBox(height: sizedBoxHeight),
                        _buildReferralField(),
                        SizedBox(height: sizedBoxHeight * 2),
                        _buildRegisterButton(context),
                        SizedBox(height: sizedBoxHeight),
                        TextButton(
                          onPressed: Get.back,
                          child: const Text(
                            "Already have an account? Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF0B561B),
      ),
      child: TextFormField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Full Name',
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.person, color: Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          errorStyle: TextStyle(
            color: Colors.white, // White error text
            fontSize: 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Name is required';
          } else if (value.length < 2) {
            return 'Name must be at least 2 characters';
          } else if (!_nameRegex.hasMatch(value)) {
            return 'Only alphabets and spaces allowed';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF0B561B),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Phone Number',
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.phone, color: Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          errorStyle: TextStyle(
            color: Colors.white, // White error text
            fontSize: 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Phone number is required';
          } else if (value.length < 10) {
            return 'Phone number must be at least 10 digits';
          } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Only digits allowed';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
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
          prefixIcon: Icon(Icons.email, color: Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          errorStyle: TextStyle(
            color: Colors.white, // White error text
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
    );
  }

  Widget _buildPasswordField() {
    return Container(
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
          prefixIcon: const Icon(Icons.lock, color: Colors.white),
          suffixIcon: IconButton(
            icon: Icon(
              _isObscured ? Icons.visibility_off : Icons.visibility,
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          errorStyle: const TextStyle(
            color: Colors.white, // White error text
            fontSize: 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          } else if (!_passwordRegex.hasMatch(value)) {
            return 'At least 8 characters, 1 uppercase, 1 lowercase, 1 number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF0B561B),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCountry,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue;
          });
        },
        items: countries.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.language, color: Colors.white),
          hintText: 'Select Country',
          hintStyle: TextStyle(color: Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 0),
          errorStyle: TextStyle(
            color: Colors.white, // White error text
            fontSize: 14,
          ),
        ),
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF0B561B),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a country';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildReferralField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF0B561B),
      ),
      child: TextFormField(
        controller: _referralController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Referral Code (Optional)',
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.code, color: Colors.white),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          errorStyle: TextStyle(
            color: Colors.white, // White error text
            fontSize: 14,
          ),
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty && value.length < 6) {
            return 'Referral code must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // return Padding(
    //   padding: const EdgeInsets.only(left: 45.0, right: 45.0),
    //   child: Visibility(
    //     visible: !_isLoading,
    //     replacement: const CenteredProgressIndicator(),
    //     child: ElevatedButton(
    //       style: ElevatedButton.styleFrom(
    //           backgroundColor: Colors.white,
    //           fixedSize: const Size(double.maxFinite, 45)),
    //       onPressed: () {
    //         _submitForm();
    //       },
    //       child: const Text(
    //         'Login',
    //         style: TextStyle(
    //             color: Colors.amber,
    //             fontSize: 18.0,
    //             fontWeight: FontWeight.bold),
    //       ),
    //     ),
    //   ),
    // );
    // const SizedBox(
    //   height: 20,
    // );
    // RichText(
    //   text: TextSpan(
    //     style: const TextStyle(
    //       color: Color(0XffC7D4DD),
    //       fontWeight: FontWeight.w600,
    //       letterSpacing: 0.4,
    //     ),
    //     text: "Don't Have an account? ",
    //     children: [
    //       TextSpan(
    //         text: 'Sign Up',
    //         style: const TextStyle(color: Colors.white),
    //         recognizer: TapGestureRecognizer()
    //           ..onTap = _goToRegister,
    //       )
    //     ],
    //   ),
    // ),
    //       ],
    //     ),
    //   ),
    // )

    return Padding(
        padding: const EdgeInsets.only(left: 8.0),
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
            child: Visibility(
              visible: !_isLoading,
              replacement: const CircularProgressIndicator(),
              child: ElevatedButton.icon(
                onPressed: _submitForm,
                label: const Text(
                  "Register",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.app_registration, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(screenWidth * 0.8, screenHeight * 0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ));
  }
}
