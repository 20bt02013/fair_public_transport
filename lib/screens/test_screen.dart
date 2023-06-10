// import 'package:firebase_auth/firebase_auth.dart';
//import 'dart:ui';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fairpublictransport/reuse.dart';
// import 'signup_screen.dart';
// import 'home_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//
// const YOUR_ESP32_SERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
// const YOUR_ESP32_DEVICE_ID = '123'; //'YOUR_DEVICE_ID_HERE';
// const YOUR_ESP32_CHARACTERISTIC_ID = '234'; //'YOUR_CHARACTERISTIC_ID_HERE';
// const YOUR_DATA = [0x01, 0x02, 0x03];
//
// class TestScreen extends StatefulWidget {
//   const TestScreen({Key? key}) : super(key: key);
//
//   @override
//   State<TestScreen> createState() => _TestScreenState();
// }
//
// class _TestScreenState extends State<TestScreen> {
//   final _ble = FlutterReactiveBle();
//   BluetoothState _bluetoothState = BluetoothState.unknown;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkBluetoothState();
//   }
//
//   Future<void> _checkBluetoothState() async {
//     _ble.observeBluetoothState().listen((bluetoothState) {
//       _bluetoothState = bluetoothState;
//       setState(() {});
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             if (_bluetoothState != BluetoothState.on) {
//               // Bluetooth is off, show error message or enable Bluetooth
//               return;
//             }
//
//             final scanSubscription = _ble.scanForDevices(
//               withServices: [
//                 YOUR_ESP32_SERVICE_UUID,
//               ],
//               scanMode: ScanMode.lowLatency,
//             ).listen((device) {
//               // Handle discovered BLE devices
//             });
//
//             final deviceConnection = _ble
//                 .connectToDevice(id: YOUR_ESP32_DEVICE_ID)
//                 .listen((connectionState) {
//               // Handle connection state changes
//             });
//
//             final services = await deviceConnection
//                 .flatMap((_) => _ble.discoverAllServicesAndCharacteristics(
//                       deviceId: YOUR_ESP32_DEVICE_ID,
//                     ))
//                 .first;
//
//             final data = await _ble.readCharacteristic(
//               characteristicId: YOUR_ESP32_CHARACTERISTIC_ID,
//               deviceId: YOUR_ESP32_DEVICE_ID,
//             );
//
//             await _ble.writeCharacteristic(
//               characteristicId: YOUR_ESP32_CHARACTERISTIC_ID,
//               deviceId: YOUR_ESP32_DEVICE_ID,
//               value: YOUR_DATA,
//             );
//
//             scanSubscription.cancel();
//             deviceConnection.cancel();
//           },
//           style: ButtonStyle(
//             backgroundColor: MaterialStateProperty.resolveWith((states) {
//               if (states.contains(MaterialState.pressed)) {
//                 return Colors.blue.shade200;
//               }
//               return Colors.blueGrey;
//             }),
//             shape: MaterialStateProperty.all<OutlinedBorder>(
//               const StadiumBorder(),
//             ),
//           ),
//           child: Text(
//             _bluetoothState == BluetoothState.on
//                 ? 'Generate\nConnection'
//                 : 'Bluetooth is off',
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
