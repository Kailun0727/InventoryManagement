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
  CollectionReference itemCollection = FirebaseFirestore.instance.collection('item');

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  void collectItem(Item item, int quantity) {
    if (quantity <= int.parse(item.itemAmount)) {
      int remainingQuantity = int.parse(item.itemAmount) - quantity;

      // Update the Firestore document with the new quantity
      itemCollection.doc(item.id).update({
        'itemAmount': remainingQuantity.toString(),
      });
    } else {
      // Insufficient quantity
      // You may want to show an error message to the user
      // For simplicity, we'll just print to the console
      print('Insufficient quantity available.');
    }
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
        title: Text('Item List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
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
              int amountToCollect = 0; // This will store the user's input
              TextEditingController _amountController = TextEditingController();


              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    ListTile(
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
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input field for the user to specify the quantity to collect
                        Container(
                          width: 60.0,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Amount'),
                            onChanged: (value) {
                              amountToCollect = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            // Validate input
                            if (amountToCollect <= 0) {
                              // Show an error Snackbar for negative or zero quantity
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a valid positive/numeric quantity.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else if (amountToCollect > int.parse(item.itemAmount)) {
                              // Show an error Snackbar for exceeding total available quantity
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Collection amount exceeds total available quantity.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              // Perform collection
                              int remainingQuantity = int.parse(item.itemAmount) - amountToCollect;

                              // Update the Firestore document with the new encrypted quantity
                              final keyValues = generateKey();
                              final key = encrypt.Key(keyValues);
                              final iv = encrypt.IV.fromLength(16);
                              final encrypter = encrypt.Encrypter(encrypt.AES(key));

                              itemCollection.doc(item.id).update({
                                'itemAmount': encrypter.encrypt(remainingQuantity.toString(), iv: iv).base64,
                              });

                              // Reset the input field to 0 after successful collection
                              setState(() {
                                _amountController.text = ''; // Clear the controller's text
                              });


                              // Show a success Snackbar or perform additional actions
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully collected $amountToCollect ${item.itemName}'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          child: Text('Collect'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
