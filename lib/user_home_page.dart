import 'package:flutter/material.dart';
import 'package:inventory_management/user_item_page.dart';
import 'package:inventory_management/user_remark_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0; // Index of the selected tab

  // List of pages to be displayed in the bottom navigation bar
  final List<Widget> _pages = [
    ItemPage(),    // Replace with your ItemPage widget
    RemarkPage(),  // Replace with your RemarkPage widget
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Update the selected tab when a tab is tapped
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Remarks',
          ),
        ],
      ),
    );
  }
}
