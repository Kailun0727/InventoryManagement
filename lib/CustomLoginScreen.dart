
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventory_management/CustomRegisterScreen.dart';

class CustomLoginScreen extends StatefulWidget {
  @override
  _CustomLoginScreenState createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TextEditingController for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String hashPassword(String password) {
    final passwordBytes = utf8.encode(password);
    final hashedPassword = sha256.convert(passwordBytes).toString();
    return hashedPassword;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }


  Future<void> _signInWithEmailAndPassword() async {
    try {
      // Hash the password with SHA-256
      final hashedPassword = hashPassword(_passwordController.text);

      // Sign in with email and hashed password
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: hashedPassword,
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Retrieve user data from Firestore
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection("user").doc(user.uid).get();

        if (userData.exists) {
          // Check the user's role
          String role = userData['role'];

          String email = userData['email'];

          final keyValues = generateKey();
          final key = encrypt.Key(keyValues);
          final iv = encrypt.IV.fromLength(16);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));

          final encryptedEmail = encrypt.Encrypted.fromBase64(email);

          final decryptedEmail = encrypter.decrypt(encryptedEmail, iv: iv);

          print("Original data in database : "+ email);
          print("After decrypt : " +decryptedEmail);


          // Redirect based on the user's role
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin-home');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Handle the case where user data does not exist
          print("User data not found");
        }
      }
    } catch (e) {
      // Handle login error and display a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid email or password"),
        ),
      );
      print("Login error: $e");
    }
  }

  void _navigateToRegisterScreen() {
    Navigator.pushNamed(context, '/register');
  }

  // New function to navigate to the "Forgot Password" page
  void _navigateToForgotPasswordScreen() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[



                    // Add the welcome message
                    Text(
                      "Welcome!", // Customize the message as needed
                      style: TextStyle(
                        fontSize: 24, // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16.0), // Add vertical spacing

                    TextButton(
                      onPressed: _navigateToRegisterScreen,
                      child: Text.rich(
                        TextSpan(
                          text: "Haven't created an account? " , style: TextStyle(
                          color: Colors.grey,
                        ),
                          children: <TextSpan>[
                            TextSpan(
                              text: "Register",
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    SizedBox(height: 32.0), // Add vertical spacing

                    // Email input field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: _emailValidator, // Set the email validator here
                    ),
                    SizedBox(height: 16.0), // Add vertical spacing

                    // Password input field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: _passwordValidator, // Set the email validator here
                      obscureText: true, // Hide password characters
                    ),

                    SizedBox(height: 12.0),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPasswordScreen,
                        child: Text("Forgot Password?"),
                      ),
                    ),

                    SizedBox(height: 12.0),

                    // Login button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signInWithEmailAndPassword,
                        child: Text('Login',  style: TextStyle(
                          fontSize: 16, // Adjust the font size as needed
                          fontWeight: FontWeight.bold,
                        )),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue, // Button background color
                          onPrimary: Colors.white, // Button text color
                          padding: EdgeInsets.all(16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )

    );
  }
}
