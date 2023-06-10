// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class UserRepository extends GetxController {
//   static UserRepository get instance => Get.find();
//
//   final _db = FirebaseFirestore.instance;
//
//   createUser(UserModel user) async {
//     await _db
//         .collection("Users")
//         .add(user.toJson())
//         .whenComplete(
//           () => Get.snackbar("Success", "Your account has been created.",
//               snackPosition: SnackPosition.BOTTOM,
//               backgroundColor: Colors.green.withOpacity(0.1),
//               colorText: Colors.blue),
//         )
//         .catchError((error, stackTrace) {
//       Get.snackbar("Error", "Something went wrong, Try again!",
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.redAccent.withOpacity(0.1),
//           colorText: Colors.red);
//       print(error.toString());
//     });
//   }
// }
//
// class UserRepository extends GetxController {
//   static UserRepository get instance => Get.find();
//
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   Future<void> createUser(UserModel user) async {
//     try {
//       final DocumentReference docRef =
//           await _db.collection("Users").add(user.toJson());
//       Get.snackbar("Success", "Your account has been created.",
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green.withOpacity(0.1),
//           colorText: Colors.blue);
//       print("User created with ID: ${docRef.id}");
//     } catch (error, stackTrace) {
//       Get.snackbar("Error", "Something went wrong, Try again!",
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.redAccent.withOpacity(0.1),
//           colorText: Colors.red);
//       print("Error creating user: ${error.toString()}");
//     }
//   }
// }
