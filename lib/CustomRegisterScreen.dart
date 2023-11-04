import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CustomRegisterScreen extends StatefulWidget {
  @override
  _CustomRegisterScreenState createState() => _CustomRegisterScreenState();
}

class _CustomRegisterScreenState extends State<CustomRegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Hash the password with SHA-256
        final hashedPassword = hashPassword(_passwordController.text);

        // Create a user in Firebase Authentication
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: hashedPassword,
        );

        FirebaseFirestore db = FirebaseFirestore.instance;

        final data = {
          "email": _emailController.text,
          "password": hashedPassword,
          "role" : "admin"
        };

        db.collection("user").doc().set(data);

        // Successful registration logic
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        // Handle registration error and display a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration error: $e"),
          ),
        );
        print("Registration error: $e");
      }
    }
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacementNamed(context, '/sign-in');
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

                  Text(
                    "Create a New Account",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12.0),

                  TextButton(
                    onPressed: _navigateToLoginScreen,
                    child: Text.rich(
                      TextSpan(
                        text: "Already have an account? " , style: TextStyle(
                        color: Colors.grey,
                      ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.0), // Add vertical spacing

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: _emailValidator,
                  ),
                  SizedBox(height: 16.0),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: true,
                    validator: _passwordValidator,
                  ),
                  SizedBox(height: 16.0),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: true,
                    validator: _confirmPasswordValidator,
                  ),


                  SizedBox(height: 16.0),

                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _registerWithEmailAndPassword,
                      child: Text('Register',  style: TextStyle(
                        fontSize: 16, // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                      )),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
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
      ),
    );
  }
}