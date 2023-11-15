import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'Item.dart';

class ItemPage extends StatefulWidget {
  @override
  _ItemPageState createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  CollectionReference itemCollection =
  FirebaseFirestore.instance.collection('item');

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs;

          if (docs == null || docs.isEmpty) {
            return Center(child: Text('No items available.'));
          }

          final keyValues = generateKey();
          final key = encrypt.Key(keyValues);
          final iv = encrypt.IV.fromLength(16);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));

          List<Item> itemList = [];

          docs.forEach((doc) {
            final encryptedItemName =
            encrypt.Encrypted.fromBase64(doc['itemName']);
            final encryptedItemDescription =
            encrypt.Encrypted.fromBase64(doc['itemDescription']);
            final encryptedItemImage =
            encrypt.Encrypted.fromBase64(doc['itemImage']);
            final encryptedItemAmount =
            encrypt.Encrypted.fromBase64(doc['itemAmount']);

            final decryptedItemName =
            encrypter.decrypt(encryptedItemName, iv: iv);
            final decryptedItemDescription =
            encrypter.decrypt(encryptedItemDescription, iv: iv);
            final decryptedItemImage =
            encrypter.decrypt(encryptedItemImage, iv: iv);
            final decryptedItemAmount =
            encrypter.decrypt(encryptedItemAmount, iv: iv);

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
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  title: Text(item.itemName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemDescription),
                      Text('Amount: ${item.itemAmount}'),
                    ],
                  ),
                  leading: Container(
                    height: 60,
                    width: 60,
                    child: Image.network(item.itemImage),
                  ),
                  // Add more details or customize the appearance as needed
                ),
              );
            },
          );

        },
      ),
    );
  }
}
