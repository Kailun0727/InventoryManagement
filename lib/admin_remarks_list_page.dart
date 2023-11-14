import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:inventory_management/Remark.dart';

class AdminRemarksListPage extends StatefulWidget {
  const AdminRemarksListPage({Key? key}) : super(key: key);

  @override
  State<AdminRemarksListPage> createState() => _AdminRemarksListPageState();
}

class _AdminRemarksListPageState extends State<AdminRemarksListPage> {
  CollectionReference remarkCollection =
  FirebaseFirestore.instance.collection('remark');

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

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  void updateStatus(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to update the status of this remark? '),
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
                      //function to update the status
                      Future<void> updateStatus(String id) async {
                        try {
                          //find the matching remark and update the status
                          await remarkCollection.doc(id).update({
                            'remarkStatus': 'checked',
                          });


                          Navigator.pop(context);

                          print('Remark status updated successfully.');
                        } catch (e) {
                          print('Error updating item. $e');
                        }
                      }
                      updateStatus(id);
                      showSnackBar(context, 'Remark status updated successfully! ');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Inventory Management App'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'Remark List',
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
                //connect to Firestore and access the 'remark' documents
                stream: remarkCollection.snapshots(),
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

                  //call Remark from cloud Firestore
                  List<Remark> remarkList = []; //call the remark model class
                  docs.forEach((doc) {
                    final encryptedRemarkUser = encrypt.Encrypted.fromBase64(doc['remarkUser']);
                    final encryptedRemarkTime = encrypt.Encrypted.fromBase64(doc['remarkTime']);
                    final encryptedRemarkMessage = encrypt.Encrypted.fromBase64(doc['remarkMessage']);

                    final decryptedRemarkUser = encrypter.decrypt(encryptedRemarkUser, iv: iv);
                    final decryptedRemarkTime = encrypter.decrypt(encryptedRemarkTime, iv: iv);
                    final decryptedRemarkMessage = encrypter.decrypt(encryptedRemarkMessage, iv: iv);

                    //create a Remark object using documents stored in Firestore
                    Remark remark = Remark(
                      id: doc.id,
                      remarkUser: decryptedRemarkUser,
                      remarkTime: decryptedRemarkTime,
                      remarkMessage: decryptedRemarkMessage,
                      remarkStatus: doc['remarkStatus'],
                    );
                    remarkList.add(remark);

                  });

                  return ListView.builder(
                      itemCount: remarkList.length,
                      itemBuilder: (context, index) {
                        Remark remark = remarkList[index];
                        return ListTile(
                          leading: Icon(Icons.pending),
                          title: Text(remark.remarkMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          subtitle: Text('${remark.remarkTime} by ${remark.remarkUser}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          trailing: Text(remark.remarkStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: remark.remarkStatus == 'unchecked'
                                    ? Colors.redAccent
                                    : Colors.green,
                              )
                          ),
                          onTap: (){
                            //on tap action
                            if(remark.remarkStatus != 'checked') {
                              updateStatus(remark.id);
                            }
                            else {}
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
