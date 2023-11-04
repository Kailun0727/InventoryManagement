
import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  Future<void> _signInWithEmailAndPassword() async {
    try {
      // Hash the password with SHA-256
      final hashedPassword = hashPassword(_passwordController.text);

      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: hashedPassword,
      );

      final user = FirebaseAuth.instance.currentUser;

      if(user!=null) {
        // Navigate to the home page on successful login
        Navigator.pushReplacementNamed(context, '/home');
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
