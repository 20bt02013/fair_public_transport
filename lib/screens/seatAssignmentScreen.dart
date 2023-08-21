//import '../function/reuse.dart';
//import 'home_screen.dart';
//import 'cuba.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

class SeatAssignmentScreen extends StatefulWidget {
  final String selectedOrderId;
  final String passselectedLocation;
  final String passselectedDestination;
  final String passtrainDocId;
  final int passAge;
  final String passCategory;
  final int passTraveltime;
  final String passPath;

  const SeatAssignmentScreen(
      {Key? key,
      required this.selectedOrderId,
      required this.passselectedLocation,
      required this.passselectedDestination,
      required this.passtrainDocId,
      required this.passAge,
      required this.passCategory,
      required this.passTraveltime,
      required this.passPath})
      : super(key: key);

  @override
  State<SeatAssignmentScreen> createState() => _SeatAssignmentScreenState();
}

class _SeatAssignmentScreenState extends State<SeatAssignmentScreen> {
  late List<bool> seatSelections;
  int? selectedSeat;
  bool? isSeatConfirmed;
  List<Map<String, dynamic>> allSeatInfo = []; // To store all seat info
  bool? allSeatsOccupied;

  @override
  void initState() {
    super.initState();
    seatSelections = List.generate(4, (index) => false);
    fetchIsSeatConfirmedAndSelectedSeat(); // Fetch the isSeatConfirmed value from Firestore
    fetchAllSeatInfo();
    createSeatsCollectionIfNotExists();
  }

  // Method to fetch the isSeatConfirmed & SelectedSeat value from Firestore
  Future<void> fetchIsSeatConfirmedAndSelectedSeat() async {
    final trainDocId = widget.passtrainDocId;
    final path = widget.passPath;

    try {
      final seatDocs = await FirebaseFirestore.instance
          .collection('paths')
          .doc(path)
          .collection('Trains')
          .doc(trainDocId)
          .collection('Seats')
          .where('passengerId', isEqualTo: widget.selectedOrderId)
          .limit(1)
          .get();

      if (seatDocs.docs.isNotEmpty) {
        final seatDoc = seatDocs.docs.first;
        setState(() {
          isSeatConfirmed = seatDoc['isSeatConfirmed'] ?? false;
          selectedSeat = seatDoc['seatNumber'];
        });
      } else {
        setState(() {
          isSeatConfirmed = false;
          selectedSeat = null;
        });
      }
    } catch (error) {
      print('Error fetching isSeatConfirmed and selectedSeat values: $error');
      setState(() {
        isSeatConfirmed = false;
        selectedSeat = null;
      });
    }
  }

  Future<void> fetchAllSeatInfo() async {
    final trainDocId = widget.passtrainDocId;
    final path = widget.passPath;

    try {
      final seatDocs = await FirebaseFirestore.instance
          .collection('paths')
          .doc(path)
          .collection('Trains')
          .doc(trainDocId)
          .collection('Seats')
          .get();

      final seatInfoList = seatDocs.docs
          .map((doc) => {
                'isSeatConfirmed': doc['isSeatConfirmed'] ?? false,
                'seatNumber': doc['seatNumber'],
                'passengerId': doc['passengerId'],
                'timeConfirm': doc['timeConfirm'],
                //'isSelected': doc['isSelected'],
                'category': doc['category'],
              })
          .toList();

      setState(() {
        allSeatInfo = seatInfoList; // Store all seat info in state
      });
    } catch (error) {
      print('Error fetching seat information: $error');
    }
  }

  Future<void> createSeatsCollectionIfNotExists() async {
    final path = widget.passPath;
    final trainDocId = widget.passtrainDocId;

    try {
      final seatsCollectionRef = FirebaseFirestore.instance
          .collection('paths')
          .doc(path)
          .collection('Trains')
          .doc(trainDocId)
          .collection('Seats');

      // Check if the Seats collection already exists
      final seatsCollectionSnapshot = await seatsCollectionRef.get();

      if (seatsCollectionSnapshot.size == 0) {
        // If the collection is empty, create documents numbered from 1 to 4
        final batch = FirebaseFirestore.instance.batch();

        for (int seatNumber = 1; seatNumber <= 4; seatNumber++) {
          final seatDocRef = seatsCollectionRef.doc(seatNumber.toString());

          batch.set(
            seatDocRef,
            {
              'seatNumber': seatNumber,
              'passengerId': 'Not occupied',
              'isSelected': false,
              'isSeatConfirmed': false,
              'timeConfirm': null,
              'category': 'Unknown'
            },
          );
        }

        // Commit the batch to create the documents
        await batch.commit();
        print('Seats collection created with documents.');

        await fetchAllSeatInfo();
      }
    } catch (error) {
      print('Error creating Seats collection: $error');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSeatsStream() {
    final trainDocId = widget.passtrainDocId;
    final path = widget.passPath;

    return FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('Seats')
        .snapshots();
  }

  Widget buildSeatButton(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final int seatNumber = doc['seatNumber'];
    final bool isSelected = doc['isSelected'];
    final bool isSeatConfirmed = doc['isSeatConfirmed'];
    final String passengerId = doc['passengerId'];
    final String category = doc['category'];
    final String selectedOrderId = widget.selectedOrderId;

    bool isSelectable = true; // Determine whether the seat is selectable

    if (isSeatConfirmed && passengerId != widget.selectedOrderId) {
      isSelectable = false;
    }

    return SeatButton(
      seatNumber: seatNumber,
      isSelected: isSelected,
      isSeatConfirmed: isSeatConfirmed,
      isSelectable: isSelectable,
      selectedOrderId: selectedOrderId,
      passengerId: passengerId, // Pass passengerId to SeatButton
      category: category,
      onSeatButtonPressed: onSeatButtonPressed,
    );
  }

  Future<Map<String, dynamic>> fetchSelectedOrder(
      String selectedOrderId, String passPath, String passtrainDocId) async {
    try {
      // Fetch the selected order details from Firestore
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('paths')
          .doc(passPath)
          .collection('Trains')
          .doc(passtrainDocId)
          .collection('passengers')
          .doc(selectedOrderId)
          .get();

      if (orderSnapshot.exists) {
        return orderSnapshot.data() as Map<String, dynamic>;
      } else {
        // Return an empty map if the order doesn't exist
        return {};
      }
    } catch (e) {
      print('Error fetching selected order: $e');
      return {};
    }
  }

  Future<void> onSeatButtonPressed(int seatNumber, bool isSelected) async {
    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passPath,
        widget.passtrainDocId,
      );

      final path = orderData['path'];
      final trainDocId = orderData['trainDocId'];

      if (path != null && trainDocId != null) {
        if (isSeatConfirmed == true) {
          print("Seat already confirmed. Use 'Modify' to change the seat.");
          return;
        }

        final batch = FirebaseFirestore.instance.batch();

        // Update the previously selected seat (if any)
        if (selectedSeat != null) {
          final prevSeatDocRef = FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(selectedSeat.toString());

          batch.set(
            prevSeatDocRef,
            {
              'passengerId': 'Not occupied',
              'isSelected': false,
              'isSeatConfirmed': false,
              'timeConfirm': null,
              'category': 'Unknown',
            },
            SetOptions(merge: true),
          );
        }

        final seatDocRef = FirebaseFirestore.instance
            .collection('paths')
            .doc(path)
            .collection('Trains')
            .doc(widget.passtrainDocId)
            .collection('Seats')
            .doc(seatNumber.toString());

        batch.set(
          seatDocRef,
          {
            'seatNumber': seatNumber,
            'passengerId': isSelected ? widget.selectedOrderId : 'Not occupied',
            'isSelected': isSelected,
            'isSeatConfirmed':
                false, // Always set to false when selecting a seat,
            'timeConfirm': null,
            'category': 'Unknown',
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        // Update local state to reflect the selection
        setState(() {
          selectedSeat = isSelected ? seatNumber : null;
          seatSelections[seatNumber - 1] = isSelected;
        });
      }
    } catch (error) {
      print('Error updating seat number: $error');
    }
  }

  Future<void> standUp() async {
    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passPath,
        widget.passtrainDocId,
      );

      final path = orderData['path'];
      final trainDocId = orderData['trainDocId'];

      if (path != null && trainDocId != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Update the isSeatConfirmed status in Firestore to false
        batch.set(
          FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(selectedSeat.toString()),
          {
            'passengerId': 'Not occupied',
            'isSelected': false,
            'isSeatConfirmed': false,
            'timeConfirm': null,
            'category': 'Unknown',
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        // Update local state to reflect the unconfirmation
        setState(() {
          isSeatConfirmed = false;
        });

        // Fetch updated seat information from Firestore
        await fetchAllSeatInfo(); // refresh allSeatInfo

        // Update the state of allSeatsOccupied
        setState(() {
          allSeatsOccupied = allSeatInfo
              .every((seatInfo) => seatInfo['isSeatConfirmed'] == true);
        });

        print("Stand Up");
      }
    } catch (error) {
      print('Error standing up: $error');
    }
  }

  // Show the replacement dialog
  //showReplacementDialog(context);

  // // You might also want to update the previously occupied seat
  // if (selectedSeat != null) {
  //   FirebaseFirestore.instance
  //       .collection('paths')
  //       .doc(path)
  //       .collection('Trains')
  //       .doc(widget.passtrainDocId)
  //       .collection('Seats')
  //       .doc(selectedSeat.toString())
  //       .update({
  //     'passengerId': 'Not occupied',
  //     'isSelected': false,
  //     'isSeatConfirmed': false,
  //     'timeConfirm': null,
  //     'category': 'Unknown',
  //   });
  // }

  // Function to build the Confirm or Modify button based on isSeatConfirmed
  Future<Widget> buildConfirmationButton() async {
    final bool isConfirmed = isSeatConfirmed ?? false;

    final String category = widget.passCategory;
    final String path = widget.passPath;

    // Check if all seats are occupied
    final bool allSeatsOccupied =
        allSeatInfo.every((seatInfo) => seatInfo['isSeatConfirmed'] == true);

    final bool hasSamePassengerId = allSeatInfo
        .any((seatInfo) => seatInfo['passengerId'] == widget.selectedOrderId);

    print('allSeatsOccupied: $allSeatsOccupied');

    if (!isConfirmed) {
      if (allSeatsOccupied &&
          !hasSamePassengerId &&
          (category == "Pregnant" ||
              category == "Handicapped (OKU)" ||
              category == "Senior Citizen" ||
              category == "Health Issue")) {
        // Find the earliest timeConfirm among all seats
        DateTime earliestTimeConfirm = DateTime.now();
        int? earliestSeatNumber;

        // Find the earliest confirm seat among occupied seats
        for (final seatInfo in allSeatInfo) {
          final DateTime? timeConfirm = seatInfo['timeConfirm']?.toDate();
          final String seatCategory = seatInfo['category'];

          if ((seatCategory != "Pregnant" &&
                  seatCategory != "Handicapped (OKU)" &&
                  seatCategory != "Senior Citizen" &&
                  seatCategory != "Health Issue") &&
              timeConfirm != null &&
              timeConfirm.isBefore(earliestTimeConfirm)) {
            earliestTimeConfirm = timeConfirm;
            earliestSeatNumber = seatInfo['seatNumber'];
          }
        }

        if (earliestSeatNumber != null) {
          // Update the earliest seat's passengerId with widget.selectedOrderId
          FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(earliestSeatNumber.toString())
              .update({
            'passengerId': widget.selectedOrderId,
            'isSelected': true,
            'isSeatConfirmed': true,
            'timeConfirm': DateTime.now(),
            'category': widget.passCategory,
          });

          // Update local state and other necessary operations
          setState(() {
            selectedSeat = earliestSeatNumber;
            isSeatConfirmed = true;
            // Perform other necessary operations
          });
        }
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white60,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                "$earliestSeatNumber $category",
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () async {
                  await fetchAllSeatInfo();
                  standUp();
                },
                child: const Text("Stand"),
              ),
            ],
          ),
        );
      } else if (!allSeatsOccupied &&
          (category == "Pregnant" ||
              category == "Handicapped (OKU)" ||
              category == "Senior Citizen" ||
              category == "Health Issue")) {
        return ElevatedButton(
          onPressed: selectedSeat != null ? confirmSeat : null,
          child: const Text("Confirm Seat"),
        );
      } else if (allSeatsOccupied) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white60,
          ),
          padding: const EdgeInsets.all(8),
          child: const Text(
            "Sorry all seat is occupied",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: selectedSeat != null ? confirmSeat : null,
          child: const Text("Confirm Seat"),
        );
      }
    } else {
      return Column(
        children: [
          allSeatsOccupied
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white60,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      const Text(
                        "All seats are occupied,\nCannot modify",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(
                        onPressed: standUp,
                        child: const Text("Stand"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: modifySeat,
                      child: const Text("Modify Seat"),
                    ),
                    ElevatedButton(
                      onPressed: standUp,
                      child: const Text("Stand"),
                    ),
                  ],
                ),
        ],
      );
    }
  }

  // void showReplacementDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Seat Replacement'),
  //         content: Text(
  //             'Sorry, please stand...\nYour seat has been given to a priority individual.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Close the dialog
  //             },
  //             child: Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Function to handle seat confirmation
  Future<void> confirmSeat() async {
    if (selectedSeat == null) {
      print("Please select a seat before confirming.");
      return;
    }
    print(selectedSeat);

    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passPath,
        widget.passtrainDocId,
      );

      final path = orderData['path'];
      final trainDocId = orderData['trainDocId'];

      final DateTime now = DateTime.now();

      if (path != null && trainDocId != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Update the previously selected seat (if any)
        if (selectedSeat != null) {
          final prevSeatDocRef = FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(selectedSeat.toString());

          batch.set(
            prevSeatDocRef,
            {
              'passengerId': 'Not occupied',
              'isSelected': false,
              'isSeatConfirmed': false,
              'timeConfirm': 'no passenger',
              'category': 'Unknown',
            },
            SetOptions(merge: true),
          );
        }

        final seatDocRef = FirebaseFirestore.instance
            .collection('paths')
            .doc(path)
            .collection('Trains')
            .doc(widget.passtrainDocId)
            .collection('Seats')
            .doc(selectedSeat!.toString());

        batch.set(
          seatDocRef,
          {
            'seatNumber': selectedSeat,
            'passengerId': widget.selectedOrderId,
            'isSelected': true,
            'isSeatConfirmed': true,
            'timeConfirm': now,
            'category': widget.passCategory,
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        // Update local state to reflect the confirmation
        setState(() {
          isSeatConfirmed = true;
        });

        // Fetch updated seat information from Firestore
        await fetchAllSeatInfo(); // refresh allSeatInfo

        print("Seat Confirmed");
      }
    } catch (error) {
      print('Error confirming seat: $error');
    }
  }

  void modifySeat() async {
    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passPath,
        widget.passtrainDocId,
      );

      final path = orderData['path'];
      final trainDocId = orderData['trainDocId'];

      if (path != null && trainDocId != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Check if all seats are confirmed
        final bool allSeatsConfirmed = allSeatInfo
            .every((seatInfo) => seatInfo['isSeatConfirmed'] == true);

        if (allSeatsConfirmed) {
          print("Sorry all seats are occupied, Cannot modify");
          return;
        }

        // Update the isSeatConfirmed status in Firestore
        batch.set(
          FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(selectedSeat.toString()),
          {
            'isSeatConfirmed': false,
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        // Update local state to reflect the modification
        setState(() {
          isSeatConfirmed = false;
        });

        // Fetch updated seat information from Firestore
        await fetchAllSeatInfo(); // refresh allSeatInfo

        print("Modify Seat");
      }
    } catch (error) {
      print('Error modifying seat: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          SingleChildScrollView(
            child: Column(
              children: [
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
                              fontSize: 20,
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
                          top: MediaQuery.of(context).size.height * 0.01),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0, top: 20.0),
                                      child: Text(
                                        'Choose your seat.. $isSeatConfirmed \n ${widget.selectedOrderId} \n $selectedSeat ${widget.passCategory}   '
                                        'age:${widget.passAge}  Ttime:${widget.passTraveltime} path:${widget.passPath} train:${widget.passtrainDocId} $allSeatsOccupied',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Container(
                                        width: 180, // Adjust width as needed
                                        height: 450, // Adjust height as needed
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(70),
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            const Positioned(
                                              top:
                                                  10, // Adjust position as needed
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Text(
                                                  'Front',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Positioned(
                                              bottom:
                                                  10, // Adjust position as needed
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Text(
                                                  'Back',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom:
                                                  40, // Adjust position as needed
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: FutureBuilder<Widget>(
                                                  future:
                                                      buildConfirmationButton(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      // Future is still loading, return a placeholder or loading indicator
                                                      return CircularProgressIndicator(); // You can replace this with your loading widget
                                                    } else if (snapshot
                                                        .hasError) {
                                                      // Future has encountered an error, handle it here
                                                      return Text(
                                                          'Error: ${snapshot.error}');
                                                    } else {
                                                      // Future has completed successfully, return the widget
                                                      return snapshot.data ??
                                                          Container(); // Return an empty container if data is null
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            // StreamBuilder and seat buttons
                                            StreamBuilder<
                                                QuerySnapshot<
                                                    Map<String, dynamic>>>(
                                              stream: getSeatsStream(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  final seatDocs =
                                                      snapshot.data?.docs ?? [];
                                                  final leftColumnSeats =
                                                      seatDocs.take(2);
                                                  final rightColumnSeats =
                                                      seatDocs.skip(2).take(2);

                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          for (final doc
                                                              in leftColumnSeats)
                                                            buildSeatButton(
                                                                doc),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          width:
                                                              10), // Add spacing between columns
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          for (final doc
                                                              in rightColumnSeats)
                                                            buildSeatButton(
                                                                doc),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SeatButton extends StatelessWidget {
  final int seatNumber;
  final bool isSelected;
  final bool isSeatConfirmed;
  final bool isSelectable;
  final String passengerId; // Add passengerId parameter
  final String selectedOrderId;
  final String category;
  final Function(int, bool) onSeatButtonPressed;

  const SeatButton({
    required this.seatNumber,
    required this.isSelected,
    required this.isSeatConfirmed,
    required this.selectedOrderId,
    required this.isSelectable,
    required this.passengerId, // Receive passengerId
    required this.category,
    required this.onSeatButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isSelectable) {
          onSeatButtonPressed(seatNumber, !isSelected);
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSeatConfirmed && passengerId == selectedOrderId
              ? Colors.black
              : isSeatConfirmed
                  ? Colors.red
                  : isSelected
                      ? Colors.lightBlueAccent
                      : Colors.green,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            seatNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
