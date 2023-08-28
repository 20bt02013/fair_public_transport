import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'dart:core';

import 'home_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final String name;
  final int age;
  final int ewallet;
  final String category;
  final String email;

  const ProfileEditScreen({
    super.key,
    required this.name,
    required this.age,
    required this.ewallet,
    required this.category,
    required this.email,
  });
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String updatedName = '';
  int updatedAge = 0;
  int updatedEwallet = 0;
  String updatedCategory = '';
  File? updatedImage;
  String updatedEmail = '';

  //String? updatedCategory;
  //  File? _pickedImage;
  String? picUrl;

  @override
  void initState() {
    super.initState();
    // Initialize updatedCategory with the value from widget.category
    updatedName = widget.name;
    updatedAge = widget.age;
    updatedEwallet = widget.ewallet;
    updatedCategory = widget.category;
  }

  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _newEmailController.dispose();
    _newPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: widget.name, // Pass user data here
                    onChanged: (value) {
                      updatedName = value;
                    },
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextFormField(
                    initialValue: widget.email,
                    onChanged: (value) {
                      _newEmailController.text = value;
                    },
                    decoration: const InputDecoration(labelText: 'New Email'),
                  ),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Current Password'),
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    onChanged: (value) {
                      // Handle changes to the new password
                    },
                    decoration:
                        const InputDecoration(labelText: 'New Password'),
                  ),
                  TextFormField(
                    initialValue: widget.age.toString(), // Pass user data here
                    onChanged: (value) {
                      updatedAge = int.tryParse(value) ?? 0;
                    },
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  TextFormField(
                    initialValue: widget.ewallet.toString(),
                    onChanged: (value) {
                      setState(() {
                        updatedEwallet = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'E-wallet'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Category:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: getCategItems(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final items = snapshot.data?.docs
                              .map<String>((doc) => doc['name'] as String)
                              .toList() ??
                          [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            value: updatedCategory,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  updatedCategory = newValue;
                                  print(updatedCategory);
                                });
                              }
                            },
                            items: [
                              DropdownMenuItem<String>(
                                value: '',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Enter Category',
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...items.map<DropdownMenuItem<String>>(
                                (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value, // Show the category name here
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (updatedCategory == 'Pregnant' ||
                              updatedCategory == 'Handicapped (OKU)' ||
                              updatedCategory == 'Senior Citizen')
                            TextButton(
                              onPressed: () async {
                                final pickedImage =
                                    await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                );

                                if (pickedImage != null) {
                                  setState(() {
                                    updatedImage = File(pickedImage.path);
                                  });
                                }
                              },
                              child:
                                  const Text('Provide picture of prove or IC'),
                            ),
                          if (updatedImage != null)
                            Image.file(
                              updatedImage!,
                            ),
                        ],
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_newEmailController.text.isNotEmpty) {
                        try {
                          await FirebaseAuth.instance.currentUser!
                              .updateEmail(_newEmailController.text);

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update({
                            'email': _newEmailController.text,
                            // Add other fields to update here
                          });

                          await _uploadImage(
                              _newEmailController.text, updatedImage);

                          print(
                              'Email updated successfully in Firebase Authentication');
                        } catch (error) {
                          print(
                              'Error updating email in Firebase Authentication: $error');
                        }
                      }
                      if (_newPasswordController.text.isNotEmpty) {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final authCredential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: _currentPasswordController
                                  .text, // Use .text to get the value from the controller
                            );
                            await user
                                .reauthenticateWithCredential(authCredential);

                            await user
                                .updatePassword(_newPasswordController.text);
                          }
                        } catch (error) {
                          print('Error updating password: $error');
                        }
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({
                        'name': updatedName,
                        'age': updatedAge,
                        'ewallet': updatedEwallet,
                        'category': updatedCategory,
                        'imageUrl': picUrl
                        // Add other fields to update here
                      });

                      // ignore: use_build_context_synchronously
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> getCategItems() {
    return FirebaseFirestore.instance.collection('category').snapshots();
  }

  Future<void> _uploadImage(String userEmail, File? image) async {
    if (image != null) {
      final storageReference = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('proveImages/$userEmail');

      final uploadTask = storageReference.putFile(image);

      await uploadTask.whenComplete(() => null);

      final imageUrl = await storageReference.getDownloadURL();

      setState(() {
        picUrl = imageUrl;
      });
    }
  }
}
