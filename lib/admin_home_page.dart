import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Inventory Management App'),
        actions: <Widget>[
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
