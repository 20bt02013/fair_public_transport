import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:typed_data/src/typed_buffer.dart';
// import 'package:typed_data/src/typed_buffer.dart';
import '../function/reuse.dart';
import 'signin_screen.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'dart:convert';
// import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameTextController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = '';
  String category = '';
  int ewallet = 0;
  int deductedAmount = 0;
  bool paymentMade = false;

  String? selectedCurrentItem;
  String? selectedDestinItem;

  Stream<QuerySnapshot> getItems() {
    return FirebaseFirestore.instance.collection('locations').snapshots();
  }

  StreamSubscription<QuerySnapshot>? destinationsSubscription;

  Stream<QuerySnapshot> getDestinItems(String? selectedCurrentItem) {
    destinationsSubscription?.cancel(); // Cancel the previous subscription

    if (selectedCurrentItem != null && selectedCurrentItem.isNotEmpty) {
      final stream = FirebaseFirestore.instance
          .collection('locations')
          .doc(selectedCurrentItem)
          .collection('destinations')
          .snapshots();

      destinationsSubscription =
          stream.listen((_) {}); // Store the new subscription
      return stream;
    } else {
      // Return an empty stream or handle the error case
      return const Stream<QuerySnapshot>.empty();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final DocumentSnapshot userSnapshot =
        await usersCollection.doc(userId).get();

    if (userSnapshot.exists) {
      final Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name'];
        category = userData['category'];
        ewallet = userData['ewallet'];
      });
    }
  }

  Future<void> deductFromWallet(int price) async {
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    final DocumentSnapshot userSnapshot =
        await usersCollection.doc(userId).get();

    if (userSnapshot.exists) {
      final Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      final int currentWallet = userData['ewallet'] as int;

      if (currentWallet >= price) {
        final int updatedWallet = currentWallet - price;

        await usersCollection.doc(userId).update({'ewallet': updatedWallet});

        setState(() {
          ewallet = updatedWallet;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Successfully deducted from your wallet.'),
            actions: [
              TextButton(
                child: const Text('Refund'),
                onPressed: () async {
                  if (paymentMade && deductedAmount > 0) {
                    final int refundAmount = deductedAmount;
                    deductedAmount = 0; // Reset the deducted amount
                    paymentMade = false; // Set paymentMade to false
                    print('Current e-wallet balance:  $paymentMade');
                    final int updatedWallet = ewallet + refundAmount;
                    await usersCollection
                        .doc(userId)
                        .update({'ewallet': updatedWallet});

                    setState(() {
                      ewallet = updatedWallet;
                    });
                  }
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('CONFIRM'),
                onPressed: () {
                  setState(() {
                    deductedAmount = 0; // Reset the deducted amount
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    }
  }

  void showPreviousOrdersDialog(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingPercentage = 0.1;
    final double paddingVertical = screenHeight * paddingPercentage;
    final double paddingHorizontal = screenWidth * paddingPercentage;

    showDialog(
      context: context,
      builder: (context) => SafeArea(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Previous Orders'),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(
              vertical: paddingVertical,
              horizontal: paddingHorizontal,
            ),
            child: Container(
              // Add your UI to display the previous orders here
              child: Text('List of previous orders'),
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text('Open Gate'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                image: AssetImage('assets/images/home.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0),
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
                  FirebaseAuth.instance.signOut().then((value) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Success'),
                        content: const Text('Log out successfully.'),
                        actions: [
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
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
                  });
                },
                child: const Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.login_outlined),
                      onPressed: null,
                    ),
                    Text(
                      'LOG OUT',
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
                    const SizedBox(height: 10),
                    Text(
                      'Fair Public\nTransport',
                      style: GoogleFonts.blinker(
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.white60,
                              offset: Offset(2.0, 2.0),
                            ),
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.white10,
                              offset: Offset(-2.0, -2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.9 * 0.65,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.85),
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
                                'Ride Safely    Ride Comfortably \n    Enjoy the journey',
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
                            reuseTextField(
                                '$userName: $category\n\n${user?.uid}',
                                Icons.person,
                                false,
                                _usernameTextController),
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
                                        .map<String>(
                                            (doc) => doc['name'] as String)
                                        .toList() ??
                                    [];

                                return Container(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Location: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: selectedCurrentItem,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedCurrentItem = newValue;
                                            selectedDestinItem =
                                                null; // Reset the destination value when the current location changes
                                          });
                                        },
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child:
                                                Text('Select current location'),
                                          ),
                                          ...items
                                              .map<DropdownMenuItem<String>>(
                                            (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),

                            StreamBuilder<QuerySnapshot>(
                              stream: getDestinItems(selectedCurrentItem),
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
                                        .map<String>(
                                            (doc) => doc['name'] as String)
                                        .toList() ??
                                    [];

                                return Container(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Destination: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: selectedDestinItem,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedDestinItem = newValue;
                                          });
                                        },
                                        items: [
                                          if (selectedCurrentItem == null)
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                  'Select current location first'),
                                            )
                                          else
                                            ...items
                                                .map<DropdownMenuItem<String>>(
                                              (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      if (selectedDestinItem != null)
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('locations')
                                              .doc(selectedCurrentItem)
                                              .collection('destinations')
                                              .doc(selectedDestinItem)
                                              .snapshots(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<DocumentSnapshot>
                                                  snapshot) {
                                            if (snapshot.hasError) {
                                              return Text(
                                                  'Error: ${snapshot.error}');
                                            }

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }

                                            final data = snapshot.data?.data()
                                                as Map<String, dynamic>?;

                                            if (data == null) {
                                              return const Text(
                                                  'Destination data not found');
                                            }

                                            final travelTimeInMinutes =
                                                data['Travel Time'] as int?;
                                            final travelTimeHours =
                                                (travelTimeInMinutes ?? 0) ~/
                                                    60;
                                            final travelTimeMinutes =
                                                (travelTimeInMinutes ?? 0) % 60;

                                            String formattedTravelTime = '';

                                            if (travelTimeHours > 0) {
                                              formattedTravelTime +=
                                                  '${travelTimeHours}h ';
                                            }

                                            formattedTravelTime +=
                                                '${travelTimeMinutes}min';

                                            final price = data['Price'] as int?;

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Travel Time:',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          formattedTravelTime,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      width: 30,
                                                    ), // Add spacing between columns
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Price:',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'RM ${price ?? 'N/A'}',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                                Center(
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    height: 45,
                                                    margin: const EdgeInsets
                                                        .fromLTRB(0, 10, 0, 20),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30),
                                                      border: Border.all(
                                                        color: Colors.white70,
                                                        width: 2,
                                                        style:
                                                            BorderStyle.solid,
                                                      ),
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        int currentBalance =
                                                            ewallet;

                                                        if (price != null &&
                                                            currentBalance >=
                                                                price) {
                                                          await deductFromWallet(
                                                              price);
                                                          deductedAmount =
                                                              price; // Store the deducted amount
                                                          paymentMade =
                                                              true; // Set paymentMade to true

                                                          // print(
                                                          //     'Current e-wallet balance: $currentBalance');
                                                        } else {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              title: const Text(
                                                                  'Insufficient Balance'),
                                                              content: Text(
                                                                  'You do not have enough balance in your e-wallet. Current e-wallet balance: $currentBalance. The price is $price'),
                                                              actions: [
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                          'OK'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStateProperty
                                                                .resolveWith(
                                                          (states) {
                                                            if (states.contains(
                                                                MaterialState
                                                                    .pressed)) {
                                                              return Colors.blue
                                                                  .shade200;
                                                            }
                                                            return Colors
                                                                .blueGrey;
                                                          },
                                                        ),
                                                        shape: MaterialStateProperty
                                                            .all<
                                                                OutlinedBorder>(
                                                          const StadiumBorder(),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Pay Now',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Rest of your code
                          ],
                        ),
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
          Positioned(
            bottom: 30,
            left: 30,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet),
                  onPressed: () {
                    // Do something when the icon is pressed
                  },
                ),
                Text(
                  'RM $ewallet', // Add the ewallet value after 'RM'
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.reorder_outlined),
                      onPressed: () {
                        // Do something when the icon is pressed
                        showPreviousOrdersDialog(context);
                      },
                    ),
                    const Text(
                      'ORDERS', // Add the ewallet value after 'RM'
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stream<DocumentSnapshot> getItem() {
//   String docId =
//       'currents'; // Replace 'your_document_id' with the specific document ID you want to retrieve
//   return FirebaseFirestore.instance
//       .collection('locations')
//       .doc(docId)
//       .snapshots();
// }

// StreamBuilder<DocumentSnapshot>(
//   stream: getItem(),
//   builder: (
//     BuildContext context,
//     AsyncSnapshot<DocumentSnapshot> snapshot,
//   ) {
//     if (snapshot.hasError) {
//       return Text('Error: ${snapshot.error}');
//     }
//
//     if (snapshot.connectionState ==
//         ConnectionState.waiting) {
//       return CircularProgressIndicator();
//     }
//
//     if (!snapshot.hasData ||
//         !snapshot.data!.exists) {
//       return Text('Document not found');
//     }
//
//     final itemData = snapshot.data!.data()
//         as Map<String, dynamic>;
//
//     // List all the fields in the itemData map
//     final fields = itemData.entries.map((entry) {
//       //final field = entry.key;
//       final value = entry.value;
//       return ' $value';
//     }).toList();
//
//     return Column(
//       children: [
//         DropdownButton<String>(
//           value: selectedCurrentItem,
//           onChanged: (String? newValue) {
//             setState(() {
//               selectedCurrentItem = newValue;
//             });
//           },
//           items: fields
//               .map<DropdownMenuItem<String>>(
//                   (String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value),
//             );
//           }).toList(),
//         ),
//         // Add any additional UI elements or widgets as needed
//       ],
//     );
//   },
// ),

// StreamBuilder<QuerySnapshot>(
//   stream: getItems(),
//   builder: (
//     BuildContext context,
//     AsyncSnapshot<QuerySnapshot> snapshot,
//   ) {
//     if (snapshot.hasError) {
//       return Text('Error: ${snapshot.error}');
//     }
//
//     if (snapshot.connectionState ==
//         ConnectionState.waiting) {
//       return CircularProgressIndicator();
//     }
//
//     final items = snapshot.data!.docs
//         .map<String>((doc) => doc['name'] as String)
//         .toList();
//
//     return Container(
//       padding: const EdgeInsets.only(
//           left:
//               10), // Set the desired left padding here
//       child: Row(
//         children: [
//           const Text(
//             'Select\nDestination: ',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(width: 50),
//           DropdownButton<String>(
//             value: selectedDestinItem,
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedDestinItem = newValue;
//               });
//             },
//             items: items
//                 .map<DropdownMenuItem<String>>(
//                     (String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   },
// ),
