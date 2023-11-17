import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';

class RemarkPage extends StatefulWidget {
  final Object? userData;

  const RemarkPage({Key? key, this.userData}) : super(key: key);

  @override
  State<RemarkPage> createState() => _RemarkPageState();
}

class _RemarkPageState extends State<RemarkPage> {
  Object? userData;
  CollectionReference remarkCollection = FirebaseFirestore.instance.collection('remark');

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remark Page'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: remarkCollection
            .where('remarkUser', isEqualTo: _getUserEmail(userData))
            .where('remarkStatus', isEqualTo: 'unchecked')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final remarkDocs = snapshot.data?.docs;

          if (remarkDocs == null || remarkDocs.isEmpty) {
            return Center(child: Text('No unchecked remarks available.'));
          }

          final keyValues = generateKey();
          final key = encrypt.Key(keyValues);
          final iv = encrypt.IV.fromLength(16);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));

          List<String> remarkList = [];

          remarkDocs.forEach((doc) {
            final encryptedRemarkMessage = encrypt.Encrypted.fromBase64(doc['remarkMessage']);
            final encryptedRemarkTime = encrypt.Encrypted.fromBase64(doc['remarkTime']);
            final encryptedRemarkUser = encrypt.Encrypted.fromBase64(doc['remarkUser']);

            final decryptedRemarkMessage = encrypter.decrypt(encryptedRemarkMessage, iv: iv);
            final decryptedRemarkTime = encrypter.decrypt(encryptedRemarkTime, iv: iv);
            final decryptedRemarkUser = encrypter.decrypt(encryptedRemarkUser, iv: iv);

            String remark = 'Message: $decryptedRemarkMessage\nTime: $decryptedRemarkTime\nUser: $decryptedRemarkUser';
            remarkList.add(remark);
          });

          return ListView.builder(
            itemCount: remarkList.length,
            itemBuilder: (context, index) {
              return InkWell(
                onLongPress: () {
                  _editRemark(context, remarkDocs[index].id, remarkList[index]);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(remarkList[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getUserEmail(Object? userData) {
    if (userData != null && userData is Map<String, dynamic>) {
      // Assuming 'email' is the key for the user email in userData
      return userData['email'] ?? 'DEFAULT_EMAIL';
    }
    return 'DEFAULT_EMAIL';
  }

  void _editRemark(BuildContext context, String remarkId, String currentRemark) {
    TextEditingController _editedRemarkController = TextEditingController(text: _extractMessage(currentRemark));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Remark'),
          content: TextField(
            controller: _editedRemarkController,
            decoration: InputDecoration(labelText: 'Enter your edited remark'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Perform the action with the edited remark
                String editedRemarkMessage = _editedRemarkController.text;

                // Encrypt data
                final keyValues = generateKey();
                final key = encrypt.Key(keyValues);
                final iv = encrypt.IV.fromLength(16);
                final encrypter = encrypt.Encrypter(encrypt.AES(key));

                final encryptedEditedRemarkMessage = encrypter.encrypt(editedRemarkMessage, iv: iv);

                // Save the edited remark to Firebase
                await remarkCollection.doc(remarkId).update({
                  'remarkMessage': encryptedEditedRemarkMessage.base64,
                  'remarkTime': encrypter.encrypt(DateTime.now().toLocal().toString(), iv: iv).base64,
                });

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _extractMessage(String currentRemark) {
    // Extract the message from the formatted remark string
    int messageIndex = currentRemark.indexOf('Message:');
    int timeIndex = currentRemark.indexOf('Time:');
    return currentRemark.substring(messageIndex + 'Message:'.length, timeIndex).trim();
  }


}
