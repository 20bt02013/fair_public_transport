//import '../function/reuse.dart';
//import 'home_screen.dart';
//import 'cuba.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'dart:html';
//import 'package:google_fonts/google_fonts.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

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
  List<Map<String, dynamic>> allPassengersInfo =
      []; // To store all passengers info
  bool? allSeatsOccupied;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      seatListener; // Add this line

  DateTime? userArriveTime;
  DateTime? trainAriveTime;
  DateTime? trainDepartTime;

  late Timer _timer; // Timer instance for periodic checks

  int? passSeatTry;
  DateTime? passTimeTry;

  bool exitTrigger = false;
  bool? trainArrive = false;

  @override
  void initState() {
    super.initState();
    seatSelections = List.generate(4, (index) => false);
    listenToSeatChanges(); // Start listening to seat changes
    createSeatsCollectionIfNotExists();
    fetchSeatInfo(widget.selectedOrderId);
    fetchAllPassengerInfo(widget.passPath, widget.passtrainDocId);
    fetchUserArriveTime(widget.selectedOrderId);

    // Call handleTimer once immediately after creating the timer
    handleTimer();

    // Start a periodic timer that checks the conditions every minute
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      // Call the handleTimer function immediately to trigger it once
      handleTimer();
    });
  }

  void listenToSeatChanges() {
    final trainDocId = widget.passtrainDocId;
    final path = widget.passPath;

    final seatDocRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('Seats');

    seatListener = seatDocRef.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final seatInfoList = snapshot.docs.map((doc) {
          return {
            'isSeatConfirmed': doc['isSeatConfirmed'] ?? false,
            'seatNumber': doc['seatNumber'],
            'passengerId': doc['passengerId'],
            'timeConfirm': doc['timeConfirm'],
            'category': doc['category'],
            'replacement': doc['replacement'],
            'arriveTime': doc['arriveTime'],
            'waitingPassenger': doc['waitingPassenger'],
            'waitingPassengerCat': doc['waitingPassengerCat']
          };
        }).toList();

        bool hasSamePassengerId = false;

        for (final seatInfo in seatInfoList) {
          if (seatInfo['passengerId'] == widget.selectedOrderId) {
            setState(() {
              selectedSeat = seatInfo['seatNumber'];
              isSeatConfirmed = seatInfo['isSeatConfirmed'];
            });
            hasSamePassengerId = true;
            break;
          }
        }

        if (!hasSamePassengerId) {
          setState(() {
            isSeatConfirmed = false;
            selectedSeat = null;
          });
        }

        for (final seatInfo in seatInfoList) {
          if (seatInfo['replacement'] == widget.selectedOrderId) {
            final earliestSeatNumber =
                seatInfo['seatNumber']; // Make sure this value is available
            final path = widget.passPath;

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Seat Reassigned'),
                  content: Text(
                      'Sorry, please stand...\nYour seat (Seat $earliestSeatNumber) has been reassigned to a priority individual.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('paths')
                            .doc(path)
                            .collection('Trains')
                            .doc(widget.passtrainDocId)
                            .collection('Seats')
                            .doc(earliestSeatNumber.toString())
                            .update({
                          'replacement': null,
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('OK $earliestSeatNumber'),
                    ),
                  ],
                );
              },
            );
            break;
          }
        }

        setState(() {
          allSeatInfo = seatInfoList; // Update all seat info in state
        });
      }
    });
  }

  @override
  void dispose() {
    seatListener.cancel(); // Cancel the listener when the widget is disposed
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> handleTimer() async {
    final currentTime = DateTime.now();

    _checkArrivalConditions();

    print('checking the occurance');

    if (trainAriveTime != null && trainAriveTime!.isBefore(currentTime)) {
      FirebaseFirestore.instance
          .collection('paths')
          .doc(widget.passPath)
          .collection('Trains')
          .doc(widget.passtrainDocId)
          .collection('passengers')
          .doc(widget.selectedOrderId)
          .update({
        'trainArrive': true,
      });

      if (trainArrive == false) {
        final path = widget.passPath;
        final trainDocId = widget.passtrainDocId;

        final passengerDocRef = FirebaseFirestore.instance
            .collection('paths')
            .doc(path)
            .collection('Trains')
            .doc(trainDocId)
            .collection('passengers')
            .doc(widget.selectedOrderId);

        final snapshot = await passengerDocRef.get();

        if (snapshot.exists) {
          // Check if the document exists
          final passengerInfo = snapshot.data() as Map<String, dynamic>;

          final bool? fetchTrainArrive = passengerInfo['trainArrive'] as bool?;

          setState(() {
            trainArrive = fetchTrainArrive;
          });
        } else {
          print('uncessfull');
        }
      }
    }
  }

  void _checkArrivalConditions() {
    final now = DateTime.now();

    for (var passengerInfo in allPassengersInfo) {
      final passengerId = passengerInfo['passengerId'];
      final getArriveTime = passengerInfo['arriveTime'] as DateTime?;

      if (passengerId == widget.selectedOrderId &&
          getArriveTime != null &&
          getArriveTime.isBefore(now) &&
          exitTrigger == false) {
        for (var seatInfo in allSeatInfo) {
          if (seatInfo['passengerId'] == widget.selectedOrderId &&
              seatInfo['waitingPassenger'] != null) {
            // Do something when the conditions are met
            final newWaitingPassenger = seatInfo['waitingPassenger'];
            final newArriveTime = seatInfo['arriveTime'];
            final newCategory = seatInfo['waitingPassengerCat'];

            // Update seat information
            FirebaseFirestore.instance
                .collection('paths')
                .doc(widget.passPath)
                .collection('Trains')
                .doc(widget.passtrainDocId)
                .collection('Seats')
                .doc(selectedSeat.toString())
                .update({
              'passengerId': newWaitingPassenger,
              'category': newCategory,
              'arriveTime': newArriveTime,
              'seatNumber': selectedSeat,
              'isSelected': true,
              'isSeatConfirmed': true,
              'timeConfirm': now,
              'replacement': null,
              'waitingPassenger': null,
              'waitingPassengerCat': null,
            });

            // Delete passenger document
            final passengerDocRef = FirebaseFirestore.instance
                .collection('paths')
                .doc(widget.passPath)
                .collection('Trains')
                .doc(widget.passtrainDocId)
                .collection('passengers')
                .doc(passengerId);

            passengerDocRef.delete();

            // Update the order status to 'Finished'
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('orders')
                .doc(widget.selectedOrderId)
                .update({
              'status': 'Finished',
            });

            // Show a dialog or perform other actions
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Alert'),
                  content: const Text(
                      'Your ride has arrived!, There is waiting Passenger'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HomeScreen())); // Close the SeatAssignmentScreen
                      },
                      child: const Text('Exit'),
                    ),
                  ],
                );
              },
            );

            // Set exitTrigger
            setState(() {
              exitTrigger = true;
            });

            break; // Exit the loop after showing the dialog
          } else if (seatInfo['passengerId'] == widget.selectedOrderId &&
              seatInfo['waitingPassenger'] == null) {
            // Do something when the conditions are met
            removePassenger(passengerId); // Remove passenger from Firestore
            fetchAllPassengerInfo(
                widget.selectedOrderId, widget.passtrainDocId);

            // Show a dialog or perform other actions
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Alert'),
                  content: const Text(
                      'Your ride has arrived!, There is waiting Passenger'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HomeScreen())); // Close the SeatAssignmentScreen
                      },
                      child: const Text('Exit'),
                    ),
                  ],
                );
              },
            );

            // Set exitTrigger
            setState(() {
              exitTrigger = true;
            });

            break; // Exit the loop after showing the dialog
          }
        }
      } else {
        print(
            'OtherPassId:$passengerId CUrrent user ID:${widget.selectedOrderId} AT:$getArriveTime Now:$now');
      }
    }
  }

  Future<void> removePassenger(String passengerId) async {
    final trainDocId = widget.passtrainDocId;
    final path = widget.passPath;

    final passengerDocRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('passengers')
        .doc(passengerId);

    await passengerDocRef.delete();

    final seatsCollectionRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('Seats');

    final seatsQuerySnapshot = await seatsCollectionRef
        .where('passengerId', isEqualTo: widget.selectedOrderId)
        .get();

    if (seatsQuerySnapshot.docs.isNotEmpty) {
      final seatDocRef = seatsQuerySnapshot.docs[0].reference;

      // Update the seat document
      await seatDocRef.update({
        'seatNumber': selectedSeat,
        'passengerId': 'Not occupied',
        'isSelected': false,
        'isSeatConfirmed': false,
        'timeConfirm': null,
        'category': 'Unknown',
        'replacement': null,
        'arriveTime': null,
      });
    }

    // Update the order status to 'Finished'
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('orders')
        .doc(widget
            .selectedOrderId) // Assuming widget.selectedOrderId is the order's ID
        .update({
      'status': 'Finished',
    });
  }

  Future<void> fetchUserArriveTime(selectedOrderId) async {
    final path = widget.passPath;
    final trainDocId = widget.passtrainDocId;

    final passengerDocRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('passengers')
        .doc(selectedOrderId);

    final snapshot = await passengerDocRef.get();

    if (snapshot.exists) {
      // Check if the document exists
      final passengerInfo = snapshot.data() as Map<String, dynamic>;

      final Timestamp? fetchedArriveTimeTimestamp =
          passengerInfo['arriveTime'] as Timestamp?;
      final Timestamp? fetchedArriveTrainTimeTimestamp =
          passengerInfo['trainArriveTime'] as Timestamp?;
      final Timestamp? fetchedDepartTrainTimeTimestamp =
          passengerInfo['trainDepartTime'] as Timestamp?;

      final bool? fetchTrainArrive = passengerInfo['trainArrive'] as bool?;

      DateTime? fetchedArriveTime;
      DateTime? fetchedArriveTrainTime;
      DateTime? fetchedDepartTrainTime;

      if (fetchedArriveTimeTimestamp != null &&
          fetchedDepartTrainTimeTimestamp != null) {
        fetchedArriveTime = fetchedArriveTimeTimestamp.toDate();
        fetchedArriveTrainTime = fetchedArriveTrainTimeTimestamp?.toDate();
        fetchedDepartTrainTime = fetchedDepartTrainTimeTimestamp.toDate();
      }

      setState(() {
        userArriveTime = fetchedArriveTime?.subtract(Duration(seconds: 15));
        trainAriveTime = fetchedArriveTrainTime;
        trainDepartTime = fetchedDepartTrainTime;
        trainArrive = fetchTrainArrive;
      });
    } else {
      setState(() {
        userArriveTime = null;
      });
      print('fetchPassengerArrive $userArriveTime');
    }
  }

  Future<void> fetchSeatInfo(String selectedOrderId) async {
    final path = widget.passPath;
    final trainDocId = widget.passtrainDocId;

    final seatDocRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('Seats')
        .where('passengerId', isEqualTo: widget.selectedOrderId);

    final snapshot = await seatDocRef.get();

    if (snapshot.docs.isNotEmpty) {
      final seatInfo = snapshot.docs[0].data();

      final int? fetchedSeatNumber = seatInfo['seatNumber'] as int?;
      final bool? fetchedIsSeatConfirmed = seatInfo['isSeatConfirmed'] as bool?;

      setState(() {
        selectedSeat = fetchedSeatNumber;
        isSeatConfirmed = fetchedIsSeatConfirmed;
      });
    } else {
      print('fetchSeatInfo function');
      setState(() {
        selectedSeat = null;
        isSeatConfirmed = null;
      });
    }
  }

  Future<void> fetchAllPassengerInfo(String path, String trainDocId) async {
    final passengerCollectionRef = FirebaseFirestore.instance
        .collection('paths')
        .doc(path)
        .collection('Trains')
        .doc(trainDocId)
        .collection('passengers');

    final snapshot = await passengerCollectionRef.get();

    if (snapshot.docs.isNotEmpty) {
      allPassengersInfo = []; // Clear the list before populating it

      snapshot.docs.forEach((doc) {
        final passengerData = doc.data() as Map<String, dynamic>;
        final String passengerId = doc.id; // Get the document ID
        // final String? userId = passengerData['userId'] as String?;
        final Timestamp? arriveTimeTimestamp =
            passengerData['arriveTime'] as Timestamp?;

        DateTime? arriveTime;
        if (arriveTimeTimestamp != null) {
          arriveTime = arriveTimeTimestamp.toDate();
        }

        if (arriveTime != null) {
          allPassengersInfo.add({
            'passengerId': passengerId,
            // 'userId': userId,
            'arriveTime': arriveTime,
          });
        }
      });
    } else {
      print('No passengers found $path $trainDocId');
      allPassengersInfo = [];
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
              'category': 'Unknown',
              'replacement': null,
              'arriveTime': null,
              'waitingPassenger': null,
              'waitingPassengerCat': null
            },
          );
        }

        // Commit the batch to create the documents
        await batch.commit();
        print('Seats collection created with documents.');
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

    if (trainArrive == false) {
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

          // Reset fields when seat is deselected
          batch.set(
            prevSeatDocRef,
            {
              'passengerId': 'Not occupied', // Reset passengerId
              'isSelected': false,
              'isSeatConfirmed': false,
              'timeConfirm': null,
              'category': 'Unknown',
              'arriveTime': null
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
            'arriveTime': null
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

  // Function to handle standing up from a seat
  Future<void> standUp() async {
    if (selectedSeat == null) {
      print("No seat selected to stand up from.");
      return;
    }

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
        batch.update(
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
            'arriveTime': null
          },
        );

        // Commit the batch
        await batch.commit();

        // Update local state to reflect the unconfirmation
        setState(() {
          isSeatConfirmed = false;
          selectedSeat = null;
        });

        print("Stand Up");
      }
    } catch (error) {
      print('Error standing up: $error');
    }
  }

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
    final bool hasSameWaitingPassenger = allSeatInfo.any(
        (seatInfo) => seatInfo['waitingPassenger'] == widget.selectedOrderId);

    print('allSeatsOccupied: $allSeatsOccupied');

    if (!isConfirmed && trainArrive == true) {
      if (allSeatsOccupied &&
          !hasSamePassengerId &&
          exitTrigger == false &&
          (category == "Health Issues (Prenant, Fever, etc..)" ||
              category == "Handicapped (OKU)" ||
              category == "Senior Citizen")) {
        // Find the earliest timeConfirm among all seats
        DateTime earliestTimeConfirm = DateTime.now();
        int? earliestSeatNumber;
        String? removedPassenger;

        // Find the earliest confirm seat among occupied seats
        for (final seatInfo in allSeatInfo) {
          final DateTime? timeConfirm = seatInfo['timeConfirm']?.toDate();
          final String seatCategory = seatInfo['category'];
          final passengerRemoved = seatInfo['passengerId'];

          if ((seatCategory != "Handicapped (OKU)" &&
                  seatCategory != "Senior Citizen" &&
                  seatCategory != "Health Issues (Prenant, Fever, etc..)") &&
              timeConfirm != null &&
              timeConfirm.isBefore(earliestTimeConfirm)) {
            earliestTimeConfirm = timeConfirm;
            earliestSeatNumber = seatInfo['seatNumber'];
            removedPassenger = passengerRemoved;
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
            'replacement': removedPassenger,
            'arriveTime': userArriveTime
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
                "Is this necessary?? $earliestSeatNumber $category",
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () async {
                  standUp();
                },
                child: const Text("Stand"),
              ),
            ],
          ),
        );
      } else if (allSeatsOccupied &&
          !hasSamePassengerId &&
          !hasSameWaitingPassenger &&
          exitTrigger == false) {
        // Find the earliest timeConfirm among all seats
        DateTime? earliestArrivedSeat = userArriveTime;
        int? earliestArriveSeatNumber;

        // Find the earliest arrived seat among occupied seats
        for (final seatInfo in allSeatInfo) {
          final DateTime? seatedArriveTime = seatInfo['arriveTime']?.toDate();
          final waitingPassenger = seatInfo['waitingPassenger'];

          if (seatedArriveTime != null &&
              waitingPassenger == null &&
              seatedArriveTime.isBefore(earliestArrivedSeat!) &&
              // Check if the time difference is less than or equal to 20 minutes
              trainDepartTime!.difference(seatedArriveTime).inMinutes <= 20) {
            earliestArrivedSeat = seatedArriveTime;
            earliestArriveSeatNumber = seatInfo['seatNumber'];
            print(
                'working seat: $earliestArriveSeatNumber Time: $earliestArrivedSeat Start: $trainDepartTime seatedAT: $seatedArriveTime');
          } else if (seatedArriveTime != null &&
              waitingPassenger == null &&
              seatedArriveTime.isBefore(earliestArrivedSeat!) &&
              // Check if the time difference is less than or equal to 20 minutes
              trainDepartTime!.difference(seatedArriveTime).inMinutes > 20) {
            print(
                'more than 20 min standing check, Mula masuk train dan berdiri $trainDepartTime seatedArriveTime:$seatedArriveTime');
          }
        }

        if (earliestArriveSeatNumber != null) {
          FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(earliestArriveSeatNumber.toString())
              .update({
            'waitingPassenger': widget.selectedOrderId,
            'waitingPassengerCat': widget.passCategory
          });

          print('checking');
        }
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white60,
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            "Wait Up, Please wait for your seat number: $earliestArriveSeatNumber Time: $earliestArrivedSeat",
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        );
      } else if (allSeatsOccupied &&
          hasSameWaitingPassenger &&
          exitTrigger == false) {
        int? getSeatNumber;
        DateTime? getTimeAssign;

        for (final seatInfo in allSeatInfo) {
          final waitingPassenger = seatInfo['waitingPassenger'];
          final seatNumber = seatInfo['seatNumber'];
          final Timestamp assignTime = seatInfo['arriveTime'];

          if (waitingPassenger == widget.selectedOrderId) {
            getSeatNumber = seatNumber;
            getTimeAssign = assignTime.toDate();
          }
        }

        return ElevatedButton(
          onPressed: selectedSeat != null ? confirmSeat : null,
          child: Text(
              "hasSameWaitingPassenger Sorry all seat is occupied, Please wait for your seat: $getSeatNumber Time: $getTimeAssign"),
        );
      } else {
        return ElevatedButton(
          onPressed: selectedSeat != null ? confirmSeat : null,
          child: const Text("Confirm Seat"),
        );
      }
    } else if (!isConfirmed && trainArrive == false) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white60,
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          "Please wait for your train to arrive before the system allocates the best seat for you, or select a preferred seat if it is not full. Train:${widget.passtrainDocId} Train Arrive Time: $trainAriveTime",
          style:
              const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
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

  // Function to handle seat confirmation
  Future<void> confirmSeat() async {
    if (selectedSeat == null) {
      print("Please select a seat before confirming.");
      return;
    }

    try {
      final orderData = await fetchSelectedOrder(
        widget.selectedOrderId,
        widget.passPath,
        widget.passtrainDocId,
      );

      final path = orderData['path'];
      final trainDocId = orderData['trainDocId'];

      print("Selected Seat: $selectedSeat"); // Add this line
      print("Path: $path, Train Doc ID: $trainDocId"); // Add this line

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

          // Reset fields for the previously selected seat
          batch.set(
            prevSeatDocRef,
            {
              'passengerId': 'Not occupied',
              'isSelected': false,
              'isSeatConfirmed': false,
              'timeConfirm': null,
              'category': 'Unknown',
              'arriveTime': 'Unknown',
              //'arriveTime': null
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
            .doc(selectedSeat.toString());

        final DateTime now = DateTime.now();

        // Set fields for the selected seat when confirming
        batch.set(
          seatDocRef,
          {
            'seatNumber': selectedSeat,
            'passengerId': widget.selectedOrderId,
            'isSelected': true,
            'isSeatConfirmed': true,
            'timeConfirm': now,
            'category': widget.passCategory,
            'arriveTime': userArriveTime
          },
          SetOptions(merge: true),
        );

        // Commit the batch
        await batch.commit();

        print("Seat Confirmed");
      }
    } catch (error) {
      print('Error confirming seat: $error');
    }
  }

  // Function to handle modifying a seat
  void modifySeat() async {
    if (selectedSeat == null) {
      print("Please select a seat to modify.");
      return;
    }

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

        // Update the isSeatConfirmed status in Firestore
        batch.update(
          FirebaseFirestore.instance
              .collection('paths')
              .doc(path)
              .collection('Trains')
              .doc(widget.passtrainDocId)
              .collection('Seats')
              .doc(selectedSeat.toString()),
          {'isSeatConfirmed': false},
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
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const HomeScreen()));
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
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                          onTap: () {
                            // Perform the action for the second GestureDetector
                            // Somewhere in your code where you want to use the fetched passenger information
                            print('All Passengers Info:');
                            for (var passengerInfo in allPassengersInfo) {
                              final passengerId = passengerInfo['passengerId'];
                              final arriveTime = passengerInfo['arriveTime'];

                              print('Passenger ID: $passengerId');
                              print('Arrive Time: $arriveTime\n');

                              print('Waiting Passenger: $allSeatInfo');
                            }
                          },
                          child: const Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.accessibility),
                                onPressed: null,
                              ),
                              Text(
                                'Test',
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
                    ],
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
                                        'age:${widget.passAge}  Ttime:${widget.passTraveltime} path:${widget.passPath} train:${widget.passtrainDocId} \n ${widget.passselectedLocation} ${widget.passselectedDestination} AT:$userArriveTime exit:$exitTrigger  TrainArrive:$trainAriveTime TrainDeparture:$trainDepartTime ',
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
                                                      return const CircularProgressIndicator(); // You can replace this with your loading widget
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
                                    const SizedBox(height: 40),
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
    super.key,
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
