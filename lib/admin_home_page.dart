import 'package:flutter/material.dart';
import 'package:inventory_management/CustomLoginScreen.dart';
import 'package:inventory_management/admin_add_item_page.dart';
import 'package:inventory_management/admin_item_list_page.dart';
import 'package:inventory_management/admin_user_list_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform logout
                // Navigate to the sign-in page and prevent going back
                Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (Route<dynamic> route) => false);
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Inventory Management App'),
        actions: <Widget>[
          Row(
            children: [
              IconButton(
                onPressed: (){
                  //on press action
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminAddItemPage()
                      )
                  );
                },
                icon: Icon(Icons.add),
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  // Show the logout confirmation dialog
                  _showLogoutDialog();
                },
              ),
            ],
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminItemListPage(),
          AdminUserListPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem> [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
