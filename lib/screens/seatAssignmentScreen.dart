//import '../function/reuse.dart';
//import 'home_screen.dart';
//import 'cuba.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

class SeatAssignmentScreen extends StatefulWidget {
  final String selectedOrderId;
  final String passselectedLocation;
  final String passselectedDestination;
  final String passtrainDocId;

  const SeatAssignmentScreen({
    Key? key,
    required this.selectedOrderId,
    required this.passselectedLocation,
    required this.passselectedDestination,
    required this.passtrainDocId,
  }) : super(key: key);

  @override
  State<SeatAssignmentScreen> createState() => _SeatAssignmentScreenState();
}

class _SeatAssignmentScreenState extends State<SeatAssignmentScreen> {
  late List<bool> seatSelections;
  int? selectedSeat;
  bool? isSeatConfirmed;
  List<Map<String, dynamic>> allSeatInfo = []; // To store all seat info

  @override
  void initState() {
    super.initState();
    seatSelections = List.generate(8, (index) => false);
    fetchIsSeatConfirmedAndSelectedSeat(); // Fetch the isSeatConfirmed value from Firestore
    fetchAllSeatInfo();
  }

  // Method to fetch the isSeatConfirmed & SelectedSeat value from Firestore
  Future<void> fetchIsSeatConfirmedAndSelectedSeat() async {
    final selectedLocation = widget.passselectedLocation;
    final selectedDestination = widget.passselectedDestination;
    final trainDocId = widget.passtrainDocId;

    try {
      final seatDocs = await FirebaseFirestore.instance
          .collection('locations')
          .doc(selectedLocation)
          .collection('destinations')
          .doc(selectedDestination)
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
    final selectedLocation = widget.passselectedLocation;
    final selectedDestination = widget.passselectedDestination;
    final trainDocId = widget.passtrainDocId;

    try {
      final seatDocs = await FirebaseFirestore.instance
          .collection('locations')
          .doc(selectedLocation)
          .collection('destinations')
          .doc(selectedDestination)
          .collection('Trains')
          .doc(trainDocId)
          .collection('Seats')
          .get();

      final seatInfoList = seatDocs.docs
          .map((doc) => {
                'isSeatConfirmed': doc['isSeatConfirmed'] ?? false,
                'seatNumber': doc['seatNumber'],
                'passengerId': doc['passengerId'],
              })
          .toList();

      setState(() {
        allSeatInfo = seatInfoList; // Store all seat info in state
      });
    } catch (error) {
      print('Error fetching seat information: $error');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSeatsStream() {
    final selectedLocation = widget.passselectedLocation;
    final selectedDestination = widget.passselectedDestination;
    final trainDocId = widget.passtrainDocId;

    return FirebaseFirestore.instance
        .collection('locations')
        .doc(selectedLocation)
        .collection('destinations')
        .doc(selectedDestination)
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
      onSeatButtonPressed: onSeatButtonPressed,
    );
  }

  // Function to build the Confirm or Modify button based on isSeatConfirmed
  Widget buildConfirmationButton() {
    final bool isConfirmed = isSeatConfirmed ?? false;

    return !isConfirmed
        ? ElevatedButton(
            onPressed: selectedSeat != null ? confirmSeat : null,
            child: Text("Confirm Seat"),
          )
        : ElevatedButton(
            onPressed: modifySeat,
            child: Text("Modify Seat"),
          );
  }

  Future<Map<String, dynamic>> fetchSelectedOrder(
      String selectedOrderId,
      String passselectedLocation,
      String passselectedDestination,
      String passtrainDocId) async {
    try {
      // Fetch the selected order details from Firestore
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc(passselectedLocation)
          .collection('destinations')
          .doc(passselectedDestination)
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

  Future<void> updateSeatConfirmationStatus(bool isConfirmed) async {
    final selectedLocation = widget.passselectedLocation;
    final selectedDestination = widget.passselectedDestination;
    final trainDocId = widget.passtrainDocId;

    try {
      final trainDocRef = FirebaseFirestore.instance
          .collection('locations')
          .doc(selectedLocation)
          .collection('destinations')
          .doc(selectedDestination)
          .collection('Trains')
          .doc(trainDocId);

      await trainDocRef.update({
        'isSeatConfirmed': isConfirmed,
      });

      // Update the local state variable
      setState(() {
        isSeatConfirmed = isConfirmed;
      });
    } catch (error) {
      print('Error updating seat confirmation status: $error');
    }
  }

  Future<void> onSeatButtonPressed(int seatNumber, bool isSelected) async {
    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passselectedLocation,
        widget.passselectedDestination,
        widget.passtrainDocId,
      );

      final selectedLocation = orderData['location'];
      final selectedDestination = orderData['destination'];

      if (selectedLocation != null && selectedDestination != null) {
        if (isSeatConfirmed == true) {
          print("Seat already confirmed. Use 'Modify' to change the seat.");
          return;
        }

        final batch = FirebaseFirestore.instance.batch();

        // Update the previously selected seat (if any)
        if (selectedSeat != null) {
          final prevSeatDocRef = FirebaseFirestore.instance
              .collection('locations')
              .doc(selectedLocation)
              .collection('destinations')
              .doc(selectedDestination)
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
            },
            SetOptions(merge: true),
          );
        }

        final seatDocRef = FirebaseFirestore.instance
            .collection('locations')
            .doc(selectedLocation)
            .collection('destinations')
            .doc(selectedDestination)
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
        widget.passselectedLocation,
        widget.passselectedDestination,
        widget.passtrainDocId,
      );

      final selectedLocation = orderData['location'];
      final selectedDestination = orderData['destination'];

      if (selectedLocation != null && selectedDestination != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Update the previously selected seat (if any)
        if (selectedSeat != null) {
          final prevSeatDocRef = FirebaseFirestore.instance
              .collection('locations')
              .doc(selectedLocation)
              .collection('destinations')
              .doc(selectedDestination)
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
            },
            SetOptions(merge: true),
          );
        }

        final seatDocRef = FirebaseFirestore.instance
            .collection('locations')
            .doc(selectedLocation)
            .collection('destinations')
            .doc(selectedDestination)
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
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        // Update the isSeatConfirmed status in Firestore
        await updateSeatConfirmationStatus(true);

        // Update local state to reflect the confirmation
        setState(() {
          isSeatConfirmed = true;
        });

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
        widget.passselectedLocation,
        widget.passselectedDestination,
        widget.passtrainDocId,
      );

      final selectedLocation = orderData['location'];
      final selectedDestination = orderData['destination'];

      if (selectedLocation != null && selectedDestination != null) {
        final batch = FirebaseFirestore.instance.batch();

        // Update the isSeatConfirmed status in Firestore
        batch.set(
          FirebaseFirestore.instance
              .collection('locations')
              .doc(selectedLocation)
              .collection('destinations')
              .doc(selectedDestination)
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: 15.0, top: 20.0),
                                  child: Text(
                                    'Choose your seat.. $isSeatConfirmed \n ${widget.selectedOrderId} \n $selectedSeat',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // ... Display order details ...

                                // StreamBuilder for seat buttons
                                StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>>(
                                  stream: getSeatsStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      final seatDocs =
                                          snapshot.data?.docs ?? [];

                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Loop through all seatDocs and build seat buttons
                                            for (final doc in seatDocs)
                                              buildSeatButton(doc),
                                            // Display Confirm or Modify button based on isSeatConfirmed
                                            buildConfirmationButton(),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                                // ... Display other UI elements ...
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
  final Function(int, bool) onSeatButtonPressed;

  const SeatButton({
    required this.seatNumber,
    required this.isSelected,
    required this.isSeatConfirmed,
    required this.selectedOrderId,
    required this.isSelectable,
    required this.passengerId, // Receive passengerId
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

// SeatWidget(
// seatNumber: 1,
// seatSelections:
// seatSelections,
// selectedSeat: selectedSeat,
// onSeatSelected:
// (seatNumber) {
// setState(() {
// selectedSeat =
// seatNumber;
// });
// },
// ),

// class SeatWidget extends StatefulWidget {
//   final int seatNumber;
//   final List<bool> seatSelections;
//   final int? selectedSeat;
//   final Function(int) onSeatSelected;
//
//   const SeatWidget({
//     Key? key,
//     required this.seatNumber,
//     required this.seatSelections,
//     required this.selectedSeat,
//     required this.onSeatSelected,
//   }) : super(key: key);
//
//   @override
//   _SeatWidgetState createState() => _SeatWidgetState();
// }

// class _SeatWidgetState extends State<SeatWidget> {
//   @override
//   Widget build(BuildContext context) {
//     bool isSelected = widget.seatSelections[widget.seatNumber - 1];
//     isSelected = isSelected && widget.seatNumber == widget.selectedSeat;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           widget.seatSelections[widget.seatNumber - 1] = !isSelected;
//           widget.onSeatSelected(widget.seatNumber);
//         });
//
//         try {
//           // Update the seat number in Firestore
//           FirebaseFirestore.instance
//               .collection('locations')
//               .doc(widget.passselectedLocation)
//               .collection('destinations')
//               .doc(widget.passselectedDestination)
//               .collection('Trains')
//               .doc(widget.passtrainDocId)
//               .collection('Seats')
//               .doc(widget.selectedOrderId)
//               .set(
//             {'seatNumber': widget.seatNumber},
//             SetOptions(merge: true),
//           );
//         } catch (error) {
//           print('Error updating seat number: $error');
//         }
//       },
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.red : Colors.green,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: Colors.white,
//             width: 2,
//           ),
//         ),
//         child: Center(
//           child: Text(
//             widget.seatNumber.toString(),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// void updateSeatSelection(int seatNumber) {
//   setState(() {
//     if (selectedSeat == seatNumber) {
//       selectedSeat = null;
//       seatSelections[seatNumber - 1] = false;
//     } else {
//       selectedSeat = seatNumber;
//       seatSelections[seatNumber - 1] = true;
//     }
//   });
// }

// Row(
// mainAxisAlignment:
// MainAxisAlignment.spaceBetween,
// children: [
// Column(
// mainAxisAlignment:
// MainAxisAlignment.center,
// crossAxisAlignment:
// CrossAxisAlignment.start,
// children: [
// First four seats on the left
// Replace with your seat widgets
// Seat 1
// const SizedBox(height: 10),
// SeatWidget(
// seatNumber: 1,
// seatSelections:
// seatSelections,
// selectedSeat: selectedSeat,
// onSeatSelected:
// (seatNumber) {
// setState(() {
// selectedSeat =
// seatNumber;
// });
// },
// ),
// Seat 2
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 2,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// // Seat 3
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 3,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// // Seat 4
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 4,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// ],
// ),
// const Column(
// mainAxisAlignment:
// MainAxisAlignment.center,
// crossAxisAlignment:
// CrossAxisAlignment.end,
// children: [
// Seat 5
// SizedBox(height: 10),
// SeatWidget(
//   seatNumber: 5,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// // Seat 6
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 6,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// // Seat 7
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 7,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// // Seat 8
// const SizedBox(height: 5),
// SeatWidget(
//   seatNumber: 8,
//   seatSelections:
//       seatSelections,
//   selectedSeat: selectedSeat,
//   onSeatSelected:
//       (seatNumber) {
//     setState(() {
//       selectedSeat =
//           seatNumber;
//     });
//   },
// ),
// ],
// ),
// ],
// ),

//Center(
//   child: Container(
//     width:
//         MediaQuery.of(context).size.width * 0.4,
//     height: 45,
//     margin:
//         const EdgeInsets.fromLTRB(0, 10, 0, 20),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(30),
//       border: Border.all(
//         color: Colors.white70,
//         width: 2,
//         style: BorderStyle.solid,
//       ),
//     ),
//     child: ElevatedButton(
//       onPressed: () {
//         // selectSeat(context);
//       },
//       style: ButtonStyle(
//         backgroundColor:
//             MaterialStateProperty.resolveWith(
//           (states) {
//             if (states.contains(
//                 MaterialState.pressed)) {
//               return Colors.blue.shade200;
//             }
//             return Colors.blueGrey;
//           },
//         ),
//         shape: MaterialStateProperty.all<
//             OutlinedBorder>(
//           const StadiumBorder(),
//         ),
//       ),
//       child: const Text(
//         'Choose your seat',
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//     ),
//   ),
// ),
