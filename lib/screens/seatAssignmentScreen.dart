import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeatAssignmentScreen extends StatefulWidget {
  const SeatAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<SeatAssignmentScreen> createState() => _SeatAssignmentScreenState();
}

class _SeatAssignmentScreenState extends State<SeatAssignmentScreen> {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  String _realTimeData = ''; // Variable to store real-time data input

  Future<void> assignSeats() async {
    // Step 1: Retrieve Firestore data
    final QuerySnapshot querySnapshot = await _usersCollection.get();

    // Step 2: Process real-time data input
    if (_realTimeData.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Missing Information'),
          content: Text('Please enter the real-time data.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // Step 3: Perform seat assignment logic
    // Assign user to a specific seat based on Firestore data and real-time data input
    String assignedSeat = ''; // Placeholder for assigned seat

    // Step 4: Update Firestore with seat assignment
    // Update the assigned seat for the user in Firestore
    // You can use the user's document reference to update the 'seat' field
    DocumentReference userDocument = querySnapshot.docs[0].reference;
    await userDocument.update({'seat': assignedSeat});

    // Step 5: Display the seat assignment result to the user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seat Assignment Result'),
        content: Text('Assigned seat: $assignedSeat'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seat Assignment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _realTimeData = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Real-time Data',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: assignSeats,
              child: Text('Assign Seat'),
            ),
          ],
        ),
      ),
    );
  }
}
