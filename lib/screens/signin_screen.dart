import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:fairpublictransport/function/reuse.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'fs_examplescreen.dart';
import 'seatAssignmentScreen.dart';
//import 'test_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
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
            top: MediaQuery.of(context).size.height * 0.07,
            left: MediaQuery.of(context).size.width * 0.09,
            child: IconButton(
              icon: const Icon(Icons.nfc),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreenExample()));
                // Do something when the icon is pressed
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.07,
            left: MediaQuery.of(context).size.width * 0.5 - 24,
            child: IconButton(
              icon: const Icon(Icons.accessible),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SeatAssignmentScreen()));
                // Do something when the icon is pressed
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.09,
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
          Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
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
                              'Please enter your detail to log in...',
                              style: GoogleFonts.blinker(
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 90),
                          reuseTextField('Enter Email Address', Icons.person,
                              false, _emailTextController),
                          const SizedBox(height: 20),
                          reuseTextField(
                              'Enter Password',
                              Icons.lock_open_outlined,
                              true,
                              _passwordTextController),
                          const SizedBox(height: 30),
                          logInSignUpBtn(context, true, () {
                            FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: _emailTextController.text,
                                    password: _passwordTextController.text)
                                .then((value) {
                              print("Log in successfully!");
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HomeScreen()));
                            }).catchError((error, stackTrace) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${error.toString()}'),
                                ),
                              );
                              if ((error.code == 'user-not-found' ||
                                      error.code == 'invalid-email' ||
                                      error.code == 'email-already-in-use' ||
                                      error.code == 'too-many-requests') &&
                                  _emailTextController.text.isNotEmpty) {
                                _emailTextController.clear();
                                _passwordTextController.clear();
                              } else if (error.code == 'wrong-password') {
                                _passwordTextController.clear();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unknown Error'),
                                  ),
                                );
                              }
                            });
                          }),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: signUpOption(),
                            ),
                          ),
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()));
                // Do something when the icon is pressed
              },
            ),
          ),
        ],
      ),
    );
  }

  Center signUpOption() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account?  ",
            style: TextStyle(color: Colors.white60),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: const Text(
              "Sign Up",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
