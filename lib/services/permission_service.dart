// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
// import '../utils/logger.dart';

// /// Service responsible for handling all permissions
// class PermissionService {
//   static final PermissionService _instance = PermissionService._internal();
//   factory PermissionService() => _instance;
//   PermissionService._internal();

//   /// Request all required permissions for Bluetooth scanning
//   Future<bool> requestPermissions() async {
//     try {
//       AppLogger.info('Requesting permissions...');

//       // Request location permission (required for Bluetooth scanning on both platforms)
//       final locationStatus = await Permission.locationWhenInUse.request();
//       if (locationStatus != PermissionStatus.granted) {
//         AppLogger.error('Location permission denied');
//         return false;
//       }

//       // Platform-specific Bluetooth permissions
//       if (Platform.isAndroid) {
//         // Android requires separate Bluetooth permissions
//         final bluetoothScanStatus = await Permission.bluetoothScan.request();
//         if (bluetoothScanStatus != PermissionStatus.granted) {
//           AppLogger.error('Bluetooth scan permission denied');
//           return false;
//         }

//         final bluetoothConnectStatus = await Permission.bluetoothConnect
//             .request();
//         if (bluetoothConnectStatus != PermissionStatus.granted) {
//           AppLogger.error('Bluetooth connect permission denied');
//           return false;
//         }
//       } else if (Platform.isIOS) {
//         // iOS uses location permission for Bluetooth scanning
//         // Additional location permission for background scanning
//         final locationAlwaysStatus = await Permission.locationAlways.request();
//         if (locationAlwaysStatus != PermissionStatus.granted) {
//           AppLogger.warning(
//             'Location always permission not granted - background scanning may be limited',
//           );
//         }
//       }

//       AppLogger.info('All permissions granted');
//       return true;
//     } catch (e) {
//       AppLogger.error('Error requesting permissions', e);
//       return false;
//     }
//   }

//   /// Check if all required permissions are granted
//   Future<bool> hasAllPermissions() async {
//     try {
//       final locationStatus = await Permission.locationWhenInUse.status;

//       if (Platform.isAndroid) {
//         final bluetoothScanStatus = await Permission.bluetoothScan.status;
//         final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

//         return locationStatus == PermissionStatus.granted &&
//             bluetoothScanStatus == PermissionStatus.granted &&
//             bluetoothConnectStatus == PermissionStatus.granted;
//       } else if (Platform.isIOS) {
//         // iOS only needs location permission for Bluetooth scanning
//         return locationStatus == PermissionStatus.granted;
//       }

//       return false;
//     } catch (e) {
//       AppLogger.error('Error checking permissions', e);
//       return false;
//     }
//   }

//   /// Get permission status messages
//   Future<String> getPermissionStatusMessage() async {
//     try {
//       final locationStatus = await Permission.locationWhenInUse.status;

//       if (locationStatus != PermissionStatus.granted) {
//         return 'Location permission is required for Bluetooth scanning';
//       }

//       if (Platform.isAndroid) {
//         final bluetoothScanStatus = await Permission.bluetoothScan.status;
//         final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

//         if (bluetoothScanStatus != PermissionStatus.granted) {
//           return 'Bluetooth scan permission is required';
//         }
//         if (bluetoothConnectStatus != PermissionStatus.granted) {
//           return 'Bluetooth connect permission is required';
//         }
//       }

//       return 'All permissions granted';
//     } catch (e) {
//       AppLogger.error('Error getting permission status', e);
//       return 'Error checking permissions';
//     }
//   }

//   /// Open app settings if permissions are denied
//   Future<void> openAppSettings() async {
//     try {
//       await openAppSettings();
//       AppLogger.info('Opened app settings');
//     } catch (e) {
//       AppLogger.error('Failed to open app settings', e);
//     }
//   }
// }
