
import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Admin Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
