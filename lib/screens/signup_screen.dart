import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../function/reuse.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final TextEditingController _categoryTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Disable resizing when the keyboard pops up
      body: Stack(
        children: [
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
              'Fair Public\nTransport',
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
                child: Row(
                  children: const [
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
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.15),
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
                      height: MediaQuery.of(context).size.height * 0.9 * 0.65,
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
                            padding:
                                const EdgeInsets.only(left: 10.0, top: 10.0),
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
                          const SizedBox(height: 20),
                          reuseInfoTextField('Enter Username', Icons.person,
                              false, _userNameTextController),
                          const SizedBox(height: 20),
                          reuseInfoTextField('Enter Category', Icons.category,
                              false, _categoryTextController),
                          const SizedBox(height: 20),
                          reuseTextField('Enter Email Address', Icons.email,
                              false, _emailTextController),
                          const SizedBox(height: 20),
                          reuseTextField(
                              'Enter Password',
                              Icons.lock_open_outlined,
                              true,
                              _passwordTextController),
                          const SizedBox(height: 30),
                          logInSignUpBtn(context, false, () {
                            // final user = User(
                            //     name: _userNameTextController.text,
                            //     category: _categoryTextController);
                            //
                            // createUser(user);

                            FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                    email: _emailTextController.text,
                                    password: _passwordTextController.text)
                                .then((value) {
                              print("Successfully Created New Account!");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            }).onError((error, stackTrace) {
                              print("Error ${error.toString()}");
                            });
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
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
