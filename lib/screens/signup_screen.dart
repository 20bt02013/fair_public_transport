import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../function/reuse.dart';
import 'dart:core';
import 'signin_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _ewalletController = TextEditingController();
  String _selectedCategory = '';

  File? _pickedImage;
  String? picUrl;

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

      // Image upload logic
      if (_selectedCategory == 'Pregnant') {
        await _uploadImage(email);
      }

      // Image upload logic
      if (_pickedImage != null) {
        final userEmail = email; // Use the email from the text field

        firebase_storage.Reference storageReference = firebase_storage
            .FirebaseStorage.instance
            .refFromURL('gs://fairpublictransport-zaff.appspot.com/')
            .child('proveImages/$userEmail');

        firebase_storage.UploadTask uploadTask =
            storageReference.putFile(File(_pickedImage!.path));

        await uploadTask.whenComplete(() => null);

        // Get the download URL of the uploaded image
        picUrl = await storageReference.getDownloadURL();
      }

      // Step 2: Store additional user data to Firestore
      final CollectionReference usersCollection =
          FirebaseFirestore.instance.collection('users');
      await usersCollection.doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'category': category,
        'age': age,
        'ewallet': ewallet,
        'imageUrl': picUrl
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

  // Create a function to handle the image upload
  Future<void> _uploadImage(String userEmail) async {
    if (_pickedImage != null) {
      firebase_storage.Reference storageReference = firebase_storage
          .FirebaseStorage.instance
          .refFromURL('gs://fairpublictransport-zaff.appspot.com/')
          .child('proveImages/$userEmail');

      firebase_storage.UploadTask uploadTask =
          storageReference.putFile(File(_pickedImage!.path));

      await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      String imageUrl = await storageReference.getDownloadURL();

      setState(() {
        picUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ... Existing widgets ...
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.09,
            left: MediaQuery.of(context).size.width * 0.09,
            child: IconButton(
              icon: const Icon(Icons.nfc),
              onPressed: () {
                // Do something when the icon is pressed
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            right: MediaQuery.of(context).size.width * 0.09,
            child: Text(
              'Fair Public\nTransport\n20BT02013\'s',
              style: GoogleFonts.blinker(
                textStyle: const TextStyle(
                  color: Color(0xff343341),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded),
                      onPressed: null,
                    ),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xff343341),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(), // Optional: Add physics for iOS-style bouncing effect
              padding: const EdgeInsets.fromLTRB(
                  16.0, 100.0, 16.0, 16.0), // Adjust padding as needed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Up',
                    style: GoogleFonts.blinker(
                      textStyle: const TextStyle(
                        color: Color(0xff343341),
                        fontSize: 55,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                          child: Text(
                            'Please enter your detail...',
                            style: GoogleFonts.blinker(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        reuseInfoTextField(
                          'Enter Username',
                          Icons.person,
                          false,
                          _nameController,
                        ),
                        const SizedBox(height: 20),
                        // ... Other text fields ...

                        reuseTextField(
                          'Enter Email Address',
                          Icons.email,
                          false,
                          _emailController,
                        ),
                        const SizedBox(height: 20),
                        reuseTextField(
                          'Enter Password',
                          Icons.lock_open_outlined,
                          true,
                          _passwordController,
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<QuerySnapshot>(
                          stream: getItems(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                              color:
                                                  Colors.black.withOpacity(0.9),
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
                                if (_selectedCategory == 'Pregnant' ||
                                    _selectedCategory == 'Handicapped (OKU)' ||
                                    _selectedCategory == 'Senior Citizen')
                                  TextButton(
                                    onPressed: () async {
                                      final pickedImage =
                                          await ImagePicker().pickImage(
                                        source: ImageSource.gallery,
                                      );

                                      if (pickedImage != null) {
                                        setState(() {
                                          _pickedImage = File(pickedImage.path);
                                        });
                                      }
                                    },
                                    child: const Text(
                                        'Provide picture of prove or IC'),
                                  ),
                                if (_pickedImage != null)
                                  Image.file(
                                    _pickedImage!,
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        reuseTextField(
                          'Enter Age',
                          Icons.accessibility_new_sharp,
                          false,
                          _ageController,
                        ),
                        const SizedBox(height: 20),
                        reuseTextField(
                          'E-Wallet',
                          Icons.wallet,
                          false,
                          _ewalletController,
                        ),
                        const SizedBox(height: 20),
                        logInSignUpBtn(
                          context,
                          false,
                          () {
                            // Perform the sign-up action here
                            _signupAndSubmitData(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 35,
            child: IconButton(
              icon: const Icon(Icons.tram_outlined),
              onPressed: () {
                // Do something when the icon is pressed
              },
            ),
          ),
        ],
      ),
    );
  }
}
