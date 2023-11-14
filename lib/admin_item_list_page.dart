import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Item.dart';
import 'package:inventory_management/admin_remarks_list_page.dart';
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
  CollectionReference collectionReference =
  FirebaseFirestore.instance.collection('remark');

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  int calculateUncheckedStatusCount(List<QueryDocumentSnapshot> notifications) {
    int uncheckedStatusCount = 0;

    for (final notification in notifications) {
      final status = notification['remarkStatus'] as String;
      if (status == 'unchecked') {
        uncheckedStatusCount++;
      }
    }

    return uncheckedStatusCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Padding(
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
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 56.0,
            right: 24.0,
            child: StreamBuilder<QuerySnapshot>(
              stream: collectionReference.snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  int newNotificationsCount = calculateUncheckedStatusCount(snapshot.data!.docs);

                  return Stack(
                    children: [
                      FloatingActionButton(
                        onPressed: () {
                          // Your press action for the floating action button
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AdminRemarksListPage()
                              )
                          );
                        },
                        child: const Icon(Icons.description), // Replace with your desired icon
                      ),
                      if (newNotificationsCount > 0)
                        Positioned(
                          top: 0, // Adjust the top value to move the badge upwards
                          right: 0, // Adjust the right value to move the badge to the right
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              newNotificationsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                    ],
                  );
                }
                return FloatingActionButton(
                  onPressed: () {
                    //on press action
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminRemarksListPage()
                        )
                    );
                  },
                  child: const Icon(Icons.description),
                );
              },
            ),
          )
        ]
      ),
    );
  }
}
