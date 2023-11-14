import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:inventory_management/admin_update_user_page.dart';

import 'User.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({Key? key}) : super(key: key);

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  CollectionReference userCollection =
  FirebaseFirestore.instance.collection('user');
  String maskedPassword = '******';

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'User List',
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.black,
                  thickness: 2.0,
                  height: 20.0,
                ),
              ],
            ),
          ),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                //connect to Firestore and access the 'user' documents
                stream: userCollection.snapshots(),
                builder: (context, snapshot) {
                  if(!snapshot.hasData){
                    return const Center(
                        child: CircularProgressIndicator()  //a loading indicator
                    );
                  }

                  //use ?. to safely access docs property
                  final docs = snapshot.data?.docs;
                  final keyValues = generateKey();
                  final key = encrypt.Key(keyValues);
                  final iv = encrypt.IV.fromLength(16);
                  final encrypter = encrypt.Encrypter(encrypt.AES(key));

                  if(docs == null || docs.isEmpty){
                    return Center(child: const Text('No data available')); //handle case where no documents are retrieved
                  }

                  //call User from cloud Firestore
                  List<User> userList = []; //call the User model class
                  docs.forEach((doc) {
                    final encryptedEmail = encrypt.Encrypted.fromBase64(doc['email']);

                    final decryptedEmail = encrypter.decrypt(encryptedEmail, iv: iv);

                    //create a Item object using documents stored in Firestore
                    User user = User(
                      id: doc.id,
                      email: decryptedEmail,
                      password: doc['password'],
                      role: doc['role'],
                    );
                    userList.add(user);

                  });

                  return ListView.builder(
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        User user = userList[index];
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text(user.email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          subtitle: Text(maskedPassword,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          trailing: Text(user.role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          onTap: (){
                            //on tap action
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AdminUpdateUserPage(user: userList[index])
                                )
                            );
                          },
                        );
                      }
                  );
                },
              )
          ),
        ],
      ),
    );
  }
}
