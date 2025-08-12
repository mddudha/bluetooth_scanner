// import 'package:flutter/material.dart';
// import 'constants.dart';

// /// Utility functions for the Bluetooth scanner app
// class AppHelpers {
//   /// Returns a color based on RSSI signal strength
//   static Color getRssiColor(int rssi) {
//     if (rssi >= AppConstants.excellentRssiThreshold) return Colors.green;
//     if (rssi >= AppConstants.goodRssiThreshold) return Colors.orange;
//     if (rssi >= AppConstants.poorRssiThreshold) return Colors.yellow.shade700;
//     return Colors.red;
//   }

//   /// Formats RSSI value for display
//   static String formatRssi(int rssi) {
//     return '$rssi dBm';
//   }

//   /// Formats device count for display
//   static String formatDeviceCount(int count) {
//     return count.toString();
//   }

//   /// Formats timestamp for display
//   static String formatTimestamp(DateTime timestamp) {
//     return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
//   }
// }
