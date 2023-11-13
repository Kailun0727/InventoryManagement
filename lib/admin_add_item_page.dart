import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class AdminAddItemPage extends StatefulWidget {
  const AdminAddItemPage({Key? key}) : super(key: key);

  @override
  State<AdminAddItemPage> createState() => _AdminAddItemPageState();
}

class _AdminAddItemPageState extends State<AdminAddItemPage> {
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

  //function to create an item
  Future<void> createItem(
      String itemName,
      String itemDescription,
      String itemImage,
      String itemAmount,
      ) async {
    try {
      //check for duplicate item in menu
      final duplicateQuery = await itemCollection
          .where('itemName', isEqualTo: itemName)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        showSnackBar(context,
            'Item already exist. ');
      } else {
        //create new item
        await itemCollection.add({
          'itemName': itemName,
          'itemDescription': itemDescription,
          'itemImage': itemImage,
          'itemAmount': itemAmount,
        });

        showSnackBar(context,
            'Item added successfully!');
      }
    } catch (e) {
      print('Error adding item. $e');
      showSnackBar(context,
          'An error occurred while adding the item');
    }
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'Add New Item',
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
                            //function to add new item
                            if (checkControllerField()) {
                              //all fields were filled
                              createItem(
                                  itemName.text,
                                  itemDescription.text,
                                  itemImage.text,
                                  itemAmount.text,
                              );
                            } else {
                              showSnackBar(
                                  context, 'Please fill in every field');
                            }
                          },
                          child: const Text('Add Item'),
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
