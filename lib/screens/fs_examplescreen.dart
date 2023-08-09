import 'dart:core';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SignUpScreenExample extends StatefulWidget {
  const SignUpScreenExample({Key? key}) : super(key: key);

  @override
  State<SignUpScreenExample> createState() => _SignUpScreenExampleState();
}

class _SignUpScreenExampleState extends State<SignUpScreenExample> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _ewalletController = TextEditingController();
  String _selectedCategory = '';

  Stream<QuerySnapshot> getItems() {
    return FirebaseFirestore.instance.collection('category').snapshots();
  }

  Future<void> _signupAndSubmitData(BuildContext context) async {
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String name = _nameController.text;
    final String category = _selectedCategory;
    final int age = int.tryParse(_ageController.text) ?? 0;
    final int ewallet = int.tryParse(_ewalletController.text) ?? 0;

    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        category.isEmpty ||
        age == 0 ||
        ewallet == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please complete all the fields.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Step 1: Create user with email and password
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Store additional user data to Firestore
      final CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');
      await usersCollection.doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'category': category,
        'age': age,
        'ewallet': ewallet,
      });

      // Success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content:
              const Text('User account created and data stored successfully.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                _emailController.clear();
                _passwordController.clear();
                _nameController.clear();
                _categoryController.clear();
                _ageController.clear();
                _ewalletController.clear();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignInScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuthExceptions with specific error messages
      if (e.code == 'weak-password') {
        // Display the specific error message for weak password
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'The given password is invalid. [Password should be at least 6 characters]'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        // Display the specific error message for email already in use
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'The email address is already in use by another account.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        // Handle other FirebaseAuthExceptions with a generic error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to create user account or store data.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      // Handle other exceptions or errors (if any)
      // Show a snackbar, toast, or dialog with a generic error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to create user account or store data.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16.0),
          StreamBuilder<QuerySnapshot>(
            stream: getItems(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Select category'),
                      ),
                      ...items.map<DropdownMenuItem<String>>(
                        (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_selectedCategory == 'Pregnant')
                    TextButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedImage = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (pickedImage != null) {
                          // Handle the picked image here
                          // You can upload the image to your desired location
                          // or perform any other operations on the image
                          //final imagePath = pickedImage.path;
                          // ...
                        }
                      },
                      child: const Text('Upload Picture of Proof'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            obscureText: false,
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _ewalletController,
            decoration: const InputDecoration(labelText: 'E-wallet'),
            obscureText: false,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => _signupAndSubmitData(context),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
