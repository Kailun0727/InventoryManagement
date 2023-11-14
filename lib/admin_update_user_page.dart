import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';

import 'User.dart';
import 'admin_home_page.dart';

class AdminUpdateUserPage extends StatefulWidget {
  final User user;
  const AdminUpdateUserPage({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUpdateUserPage> createState() => _AdminUpdateUserPageState();
}

class _AdminUpdateUserPageState extends State<AdminUpdateUserPage> {
  String role = 'user'; //default selection
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  CollectionReference userCollection =
  FirebaseFirestore.instance.collection('user');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    email.text = widget.user.email;
  }

  void showSnackBar(BuildContext context, content) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String snackBarContent = content;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(snackBarContent),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool checkControllerField() {
    return email.text.isNotEmpty &&
        password.text.isNotEmpty;
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

  String hashPassword(String password) {
    final passwordBytes = utf8.encode(password);
    final hashedPassword = sha256.convert(passwordBytes).toString();
    return hashedPassword;
  }

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  void deleteUser(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to delete this user? '),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: () async {
                      //function to delete a user
                      try {
                        //perform delete menu item actions
                        await userCollection.doc(id).delete();
                      } catch (e) {
                        print('Error deleting user. : $e');
                      }

                      // ignore: use_build_context_synchronously
                      showSnackBar(context, 'User deleted successfully! ');

                      // ignore: use_build_context_synchronously
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminHomePage()
                          )
                      );
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )),
              ],
            ),
          ],
        );
      },
    );
  }

  void updateUser(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to update this user? '),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: () async {
                      //function to update a user
                      if (checkControllerField()) {
                        //all fields were filled
                        Future<void> updateUser(
                            String email,
                            String password,
                            String role,
                            ) async {
                          try {
                            final keyValues = generateKey();
                            final key = encrypt.Key(keyValues);
                            final iv = encrypt.IV.fromLength(16);
                            final encrypter = encrypt.Encrypter(encrypt.AES(key));

                            final encryptedEmail = encrypter.encrypt(email, iv: iv);
                            final hashedPassword = hashPassword(password);

                            //find the matching user and update the status
                            await userCollection.doc(widget.user.id).update({
                              'email': encryptedEmail.base64,
                              'password': hashedPassword,
                              'role': role,
                            });

                            print('User updated successfully.');
                          } catch (e) {
                            print('Error updating item. $e');
                          }
                        }

                        updateUser(
                          email.text,
                          password.text,
                          role.toString(),
                        );
                        showSnackBar(context, 'User updated successfully! ');

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminHomePage()));
                      } else {
                        showSnackBar(context, 'Please fill in every field ');
                      }
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> roleTypes = ['admin', 'user'];
    List<DropdownMenuItem<String>> dropdownItems =
    roleTypes.map((String roleType) {
      return DropdownMenuItem<String>(
        value: roleType,
        child: Text(roleType),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Inventory Management App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Update User',
                        style: TextStyle(
                          fontSize: 24.0, // Adjust the font size as needed
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.black, // Set the color of the divider
                      thickness: 2.0, // Set the thickness of the divider
                      height: 20.0, // Set the height of the divider
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: email,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: _emailValidator, // Set the email validator here
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: _passwordValidator, // Set the email validator here
                      obscureText: true, // Hide password characters
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a Role: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          hint: const Text('Select a Food Type'),
                          value: role,
                          items: dropdownItems,
                          onChanged: (String? newValue) {
                            setState(() {
                              role = newValue!;
                            });
                          },
                        ),
                        const Spacer()
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              deleteUser(widget.user.id);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            )),
                        ElevatedButton(
                          onPressed: () {
                            //on press action
                            updateUser(widget.user.id);
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
