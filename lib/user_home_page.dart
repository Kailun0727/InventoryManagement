import 'package:flutter/material.dart';
import 'package:inventory_management/user_item_page.dart';
import 'package:inventory_management/user_remark_page.dart';

class UserHomePage extends StatefulWidget {
  final Object? userData;

  const UserHomePage({Key? key, this.userData}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  Object? userData;
  int _currentIndex = 0; // Index of the selected tab
  List<Widget>? pages;

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  // List of pages to be displayed in the bottom navigation bar


  @override
  Widget build(BuildContext context) {
    pages = [
      ItemPage(userData: userData),    // Replace with your ItemPage widget
      RemarkPage(userData: userData),  // Replace with your RemarkPage widget
    ];

    return Scaffold(
      body: pages?[_currentIndex], // Display the selected page
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
