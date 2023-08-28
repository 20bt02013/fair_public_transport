// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:flutter/material.dart';
//
// class SeatWidget extends StatefulWidget {
//   final int seatNumber;
//   final List<bool> seatSelections;
//   final int? selectedSeat;
//   final Function(int) onSeatSelected; // Callback function
//
//   const SeatWidget({
//     Key? key,
//     required this.seatNumber,
//     required this.seatSelections,
//     required this.selectedSeat,
//     required this.onSeatSelected, // Pass the callback function
//   }) : super(key: key);
//
//   @override
//   _SeatWidgetState createState() => _SeatWidgetState();
// }
//
// class _SeatWidgetState extends State<SeatWidget> {
//   @override
//   Widget build(BuildContext context) {
//     bool isSelected = widget.seatSelections[widget.seatNumber - 1];
//     if (widget.selectedSeat != null) {
//       isSelected = isSelected && widget.seatNumber == widget.selectedSeat;
//     }
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           // Update the isSelected value for this seat
//           widget.seatSelections[widget.seatNumber - 1] =
//               !isSelected; // Toggle the seat selection
//           widget
//               .onSeatSelected(widget.seatNumber); // Call the callback function
//         });
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

// Widget build(BuildContext context) {
//   return Scaffold(
//     resizeToAvoidBottomInset: false,
//     body: Stack(
//       children: [
//         Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/images/bg.jpg'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//             child: Container(
//               color: Colors.black.withOpacity(0.1),
//             ),
//           ),
//         ),
//         SingleChildScrollView(
//           child: Column(
//             children: [
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: GestureDetector(
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.arrow_back_rounded),
//                           onPressed: null,
//                         ),
//                         Text(
//                           'Back',
//                           style: TextStyle(
//                             color: Color(0xff343341),
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: .5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(30, 0, 200, 10),
//                     child: IconButton(
//                       icon: const Icon(Icons.nfc),
//                       onPressed: () {
//                         // Do something when the icon is pressed
//                       },
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Fair Public\nTransport',
//                       style: GoogleFonts.blinker(
//                         textStyle: const TextStyle(
//                           color: Color(0xff343341),
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: .5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Center(
//                 child: Align(
//                   alignment: Alignment.topCenter,
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                         top: MediaQuery.of(context).size.height * 0.01),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Seat Assignment Page',
//                           style: GoogleFonts.blinker(
//                             textStyle: const TextStyle(
//                               color: Color(0xff343341),
//                               fontSize: 25,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: .5,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Container(
//                           width: MediaQuery.of(context).size.width * 0.8,
//                           decoration: BoxDecoration(
//                             color: Colors.blueGrey.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 spreadRadius: 4,
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Padding(
//                                 padding:
//                                 EdgeInsets.only(left: 15.0, top: 20.0),
//                                 child: Text(
//                                   'Choose your seat..',
//                                   style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               // ... Display order details ...
//
//                               // StreamBuilder for seat buttons
//                               StreamBuilder<
//                                   QuerySnapshot<Map<String, dynamic>>>(
//                                 stream: getSeatsStream(),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return const CircularProgressIndicator();
//                                   } else if (snapshot.hasError) {
//                                     return Text('Error: ${snapshot.error}');
//                                   } else {
//                                     final seatDocs =
//                                         snapshot.data?.docs ?? [];
//
//                                     return Padding(
//                                       padding: const EdgeInsets.all(16.0),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Column(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                             children: seatDocs
//                                                 .sublist(0, 1)
//                                                 .map(
//                                                   (doc) =>
//                                                   buildSeatButton(doc),
//                                             )
//                                                 .toList(),
//                                           ),
//                                           Column(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                             CrossAxisAlignment.end,
//                                             children: seatDocs
//                                                 .sublist(1, 2)
//                                                 .map(
//                                                   (doc) =>
//                                                   buildSeatButton(doc),
//                                             )
//                                                 .toList(),
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   }
//                                 },
//                               ),
//                               // ... Display other UI elements ...
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 15.0,
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.tram_outlined),
//                   onPressed: () {
//                     // Do something when the icon is pressed
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget build(BuildContext context) {
//   return Scaffold(
//     resizeToAvoidBottomInset: false,
//     body: Stack(
//       children: [
//         Container(
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/images/bg.jpg'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//             child: Container(
//               color: Colors.black.withOpacity(0.1),
//             ),
//           ),
//         ),
//         SingleChildScrollView(
//           child: Column(
//             children: [
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: GestureDetector(
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.arrow_back_rounded),
//                           onPressed: null,
//                         ),
//                         Text(
//                           'Back',
//                           style: TextStyle(
//                             color: Color(0xff343341),
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: .5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(30, 0, 200, 10),
//                     child: IconButton(
//                       icon: const Icon(Icons.nfc),
//                       onPressed: () {
//                         // Do something when the icon is pressed
//                       },
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Fair Public\nTransport',
//                       style: GoogleFonts.blinker(
//                         textStyle: const TextStyle(
//                           color: Color(0xff343341),
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: .5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Center(
//                 child: Align(
//                   alignment: Alignment.topCenter,
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                         top: MediaQuery.of(context).size.height * 0.01),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Seat Assignment Page',
//                           style: GoogleFonts.blinker(
//                             textStyle: const TextStyle(
//                               color: Color(0xff343341),
//                               fontSize: 25,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: .5,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Container(
//                           width: MediaQuery.of(context).size.width * 0.8,
//                           // height:
//                           //     MediaQuery.of(context).size.height * 0.9 * 0.65,
//                           decoration: BoxDecoration(
//                             color: Colors.blueGrey.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 spreadRadius: 4,
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Padding(
//                                 padding:
//                                 EdgeInsets.only(left: 15.0, top: 20.0),
//                                 child: Text(
//                                   'Choose your seat..',
//                                   style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               FutureBuilder<Map<String, dynamic>>(
//                                 future: fetchSelectedOrder(
//                                     widget.selectedOrderId,
//                                     widget.passselectedLocation,
//                                     widget.passselectedDestination,
//                                     widget.passtrainDocId),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return const CircularProgressIndicator();
//                                   } else if (snapshot.hasError) {
//                                     return Text('Error: ${snapshot.error}');
//                                   } else if (snapshot.data == null ||
//                                       snapshot.data!.isEmpty) {
//                                     return const Text('No order found');
//                                   } else {
//                                     final orderData = snapshot.data!;
//
//                                     final DateTime orderDate =
//                                     orderData['date']?.toDate()
//                                     as DateTime;
//                                     final orderDateUtc8 = orderDate
//                                         .add(const Duration(hours: 8));
//                                     final hour = orderDateUtc8.hour > 12
//                                         ? orderDateUtc8.hour - 12
//                                         : orderDateUtc8.hour;
//                                     final period =
//                                     orderDateUtc8.hour < 12 ? 'AM' : 'PM';
//
//                                     return Padding(
//                                       padding: const EdgeInsets.all(16.0),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                         children: [
//                                           const Text(
//                                             'Your Order:',
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           Text(
//                                               'Location: ${orderData['location']}'),
//                                           Text(
//                                               'Destination: ${orderData['destination']}'),
//                                           Text(
//                                             'Date: ${orderDateUtc8.day.toString().padLeft(2, '0')}-${orderDateUtc8.month.toString().padLeft(2, '0')}-${orderDateUtc8.year.toString()} \n ${hour.toString().padLeft(2, '0')}:${orderDateUtc8.minute.toString().padLeft(2, '0')} $period',
//                                           ),
//                                           Text(
//                                               'Passenger Id: ${widget.selectedOrderId}'),
//
//                                           // ... Display other order details ...
//                                         ],
//                                       ),
//                                     );
//                                   }
//                                 },
//                               ),
//                               Center(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 20,
//                                     horizontal: 70,
//                                   ),
//                                   child: Container(
//                                     width: double.infinity,
//                                     height: 500,
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue,
//                                       borderRadius:
//                                       BorderRadius.circular(100),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.grey.withOpacity(0.5),
//                                           spreadRadius: 2,
//                                           blurRadius: 5,
//                                           offset: const Offset(0, 3),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Stack(
//                                       alignment: Alignment.center,
//                                       children: [
//                                         const Positioned(
//                                           top: 20,
//                                           child: Text(
//                                             'Front',
//                                             style: TextStyle(
//                                               fontSize: 24,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                         const Positioned(
//                                           bottom: 20,
//                                           child: Text(
//                                             'Back',
//                                             style: TextStyle(
//                                               fontSize: 24,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                         Row(
//                                           mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             Column(
//                                               mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                               crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                               children: [
//                                                 // First four seats on the left
//                                                 // Replace with your seat widgets
//                                                 // Seat 1
//                                                 const SizedBox(height: 10),
//                                                 SeatButton(
//                                                   seatNumber: 1,
//                                                   isSelected:
//                                                   selectedSeat == 1,
//                                                   onSeatButtonPressed:
//                                                   onSeatButtonPressed,
//                                                 ),
//                                               ],
//                                             ),
//                                             Column(
//                                               mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                               crossAxisAlignment:
//                                               CrossAxisAlignment.end,
//                                               children: [
//                                                 // Seat 5
//                                                 const SizedBox(height: 10),
//                                                 SeatButton(
//                                                   seatNumber: 2,
//                                                   isSelected:
//                                                   selectedSeat == 2,
//                                                   onSeatButtonPressed:
//                                                   onSeatButtonPressed,
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 15.0,
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.tram_outlined),
//                   onPressed: () {
//                     // Do something when the icon is pressed
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }
