import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Item.dart';
import 'package:inventory_management/admin_update_item.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AdminItemListPage extends StatefulWidget {
  const AdminItemListPage({Key? key}) : super(key: key);

  @override
  State<AdminItemListPage> createState() => _AdminItemListPageState();
}

class _AdminItemListPageState extends State<AdminItemListPage> {
  CollectionReference itemCollection =
  FirebaseFirestore.instance.collection('item');

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
                    'Item List',
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
                //connect to Firestore and access the 'item' documents
                stream: itemCollection.snapshots(),
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

                  //call Item from cloud Firestore
                  List<Item> itemList = []; //call the Item model class
                  docs.forEach((doc) {
                    final encryptedItemName = encrypt.Encrypted.fromBase64(doc['itemName']);
                    final encryptedItemDescription = encrypt.Encrypted.fromBase64(doc['itemDescription']);
                    final encryptedItemImage = encrypt.Encrypted.fromBase64(doc['itemImage']);
                    final encryptedItemAmount = encrypt.Encrypted.fromBase64(doc['itemAmount']);

                    final decryptedItemName = encrypter.decrypt(encryptedItemName, iv: iv);
                    final decryptedItemDescription = encrypter.decrypt(encryptedItemDescription, iv: iv);
                    final decryptedItemImage = encrypter.decrypt(encryptedItemImage, iv: iv);
                    final decryptedItemAmount = encrypter.decrypt(encryptedItemAmount, iv: iv);
                    //create a Item object using documents stored in Firestore
                    Item item = Item(
                      id: doc.id,
                      itemName: decryptedItemName,
                      itemDescription: decryptedItemDescription,
                      itemImage: decryptedItemImage,
                      itemAmount: decryptedItemAmount,
                    );
                    itemList.add(item);

                  });

                  return ListView.builder(
                      itemCount: itemList.length,
                      itemBuilder: (context, index) {
                        Item item = itemList[index];
                        return ListTile(
                          leading: Container(
                              height: 60,
                              width: 60,
                              child: Image.network(item.itemImage)
                          ),
                          title: Text(item.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          subtitle: Text(item.itemDescription,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          trailing: Text('Amount: ${item.itemAmount}',
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
                                    builder: (context) => AdminUpdateItemPage(item: itemList[index])
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
