import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:inventory_management/admin_home_page.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'Item.dart';

class AdminUpdateItemPage extends StatefulWidget {
  final Item item;

  const AdminUpdateItemPage({Key? key, required this.item}) : super(key: key);

  @override
  State<AdminUpdateItemPage> createState() => _AdminUpdateItemPageState();
}

class _AdminUpdateItemPageState extends State<AdminUpdateItemPage> {
  final storage = FirebaseStorage.instance;
  final firestore = FirebaseFirestore.instance;
  String _filePath = '';
  String imageUrl = ''; //image link
  TextEditingController itemName = TextEditingController();
  TextEditingController itemDescription = TextEditingController();
  TextEditingController itemImage = TextEditingController();
  TextEditingController itemAmount = TextEditingController();
  CollectionReference itemCollection =
  FirebaseFirestore.instance.collection('item');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    itemName.text = widget.item.itemName;
    itemDescription.text = widget.item.itemDescription;
    itemImage.text = widget.item.itemImage;
    itemAmount.text = widget.item.itemAmount;
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

  Future<void> openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType
          .image,
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path!;
      });
    }
  }

  Future<void> uploadImage() async {
    if (_filePath.isNotEmpty) {
      Reference storageReference =
      storage.ref().child('images/${DateTime.now()}.png');
      UploadTask uploadTask = storageReference.putFile(File(_filePath));

      TaskSnapshot taskSnapshot = await uploadTask;
      imageUrl = await taskSnapshot.ref.getDownloadURL();

      await firestore.collection('images').add({'url': imageUrl});
      setState(() {
        _filePath = ''; // Reset the file path after upload.
        itemImage.text = imageUrl;
        print(imageUrl);
      });
    }
  }

  bool checkControllerField() {
    return itemName.text.isNotEmpty &&
        itemDescription.text.isNotEmpty &&
        itemImage.text.isNotEmpty &&
        itemAmount.text.isNotEmpty;
  }

  Uint8List generateKey() {
    return Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  }

  void deleteItem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to delete this item? '),
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
                      //function to delete an item
                      try {
                        //perform delete menu item actions
                        await itemCollection.doc(id).delete();
                      } catch (e) {
                        print('Error deleting item. : $e');
                      }

                      // ignore: use_build_context_synchronously
                      showSnackBar(context, 'Item deleted successfully! ');

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

  void updateItem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm to update this item? '),
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
                      //function to update an item
                      if (checkControllerField()) {
                        //all fields were filled
                        //function to update an item
                        Future<void> updateItem(
                            String itemName,
                            String itemDescription,
                            String itemImage,
                            String itemAmount,
                            ) async {
                          try {
                            final keyValues = generateKey();
                            final key = encrypt.Key(keyValues);
                            final iv = encrypt.IV.fromLength(16);
                            final encrypter = encrypt.Encrypter(encrypt.AES(key));

                            final encryptedItemName = encrypter.encrypt(itemName, iv: iv);
                            final encryptedItemDescription = encrypter.encrypt(itemDescription, iv: iv);
                            final encryptedItemImage = encrypter.encrypt(itemImage, iv: iv);
                            final encryptedItemAmount = encrypter.encrypt(itemAmount, iv: iv);

                            //find the matching item and update the status
                            await itemCollection.doc(widget.item.id).update({
                              'itemName': encryptedItemName.base64,
                              'itemDescription': encryptedItemDescription.base64,
                              'itemImage': encryptedItemImage.base64,
                              'itemAmount': encryptedItemAmount.base64,
                            });

                            print('Item updated successfully.');
                          } catch (e) {
                            print('Error updating item. $e');
                          }
                        }

                        updateItem(
                            itemName.text,
                            itemDescription.text,
                            itemImage.text.toString(),
                            itemAmount.text.toString(),
                        );
                        showSnackBar(context, 'Item updated successfully! ');

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
                        'Update Item',
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
                    TextField(
                      controller: itemName,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemDescription,
                      decoration: const InputDecoration(
                        labelText: 'Item Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemAmount,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Item Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(width: 1),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  ' Select an image:  ',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: openFilePicker,
                                  child: const Icon(Icons.source),
                                ),
                              ],
                            ),
                          ),
                          _filePath == ''
                              ? const Center(child: Text(''))
                              : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Selected file: $_filePath',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  uploadImage();
                                },
                                child: const Text('Upload Image'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: itemImage,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Item Image',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              deleteItem(widget.item.id);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            )),
                        ElevatedButton(
                          onPressed: () {
                            //on press action
                            updateItem(widget.item.id);
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
