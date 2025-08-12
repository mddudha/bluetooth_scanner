// import 'dart:async';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import '../models/scan_snapshot.dart';
// import '../utils/constants.dart';
// import '../utils/logger.dart';

// /// Service responsible for managing scan data and statistics
// class DataService {
//   static final DataService _instance = DataService._internal();
//   factory DataService() => _instance;
//   DataService._internal();

//   // Device data storage
//   final Map<String, int> _rssiByDevice = {};
//   final Map<String, String> _nameByDevice = {};
//   final Map<String, bool> _connectableByDevice = {};

//   // Stream controllers
//   final StreamController<Map<String, int>> _devicesController =
//       StreamController<Map<String, int>>.broadcast();
//   final StreamController<List<ScanSnapshot>> _snapshotsController =
//       StreamController<List<ScanSnapshot>>.broadcast();

//   // Statistics
//   int _totalScansSuccessful = 0;
//   int _totalScansAttempted = 0;
//   final Map<String, int> _errorTypeCount = {};

//   // Snapshots
//   final List<ScanSnapshot> _snapshots = [];

//   // Getters
//   Stream<Map<String, int>> get devicesStream => _devicesController.stream;
//   Stream<List<ScanSnapshot>> get snapshotsStream => _snapshotsController.stream;
//   Map<String, int> get devices => Map.from(_rssiByDevice);
//   List<ScanSnapshot> get snapshots => List.from(_snapshots);
//   int get totalScansSuccessful => _totalScansSuccessful;
//   int get totalScansAttempted => _totalScansAttempted;
//   Map<String, int> get errorTypeCount => Map.from(_errorTypeCount);

//   /// Process scan results and update data
//   void processScanResults(List<ScanResult> results) {
//     try {
//       AppLogger.info('Processing ${results.length} scan results');

//       if (results.isEmpty) {
//         AppLogger.warning('No scan results to process');
//         // Still create a snapshot with 0 devices
//         _createSnapshot();
//         return;
//       }

//       for (final result in results) {
//         final deviceId = result.device.remoteId.toString();
//         final rssi = result.rssi;
//         final name = result.device.platformName.isNotEmpty
//             ? result.device.platformName
//             : 'Unknown Device';
//         final connectable = result.advertisementData.connectable;

//         _rssiByDevice[deviceId] = rssi;
//         _nameByDevice[deviceId] = name;
//         _connectableByDevice[deviceId] = connectable;

//         AppLogger.debug('Processed device: $name ($deviceId) - $rssi dBm');
//       }

//       AppLogger.info('Updated device data: ${_rssiByDevice.length} devices');
//       _devicesController.add(Map.from(_rssiByDevice));

//       // Create snapshot with current data
//       _createSnapshot();

//       // Record successful scan
//       _recordSuccessfulScan();
//     } catch (e) {
//       AppLogger.error('Error processing scan results', e);
//       _recordError('scan_processing', e.toString());
//     }
//   }

//   /// Create a snapshot of current data
//   void _createSnapshot() {
//     try {
//       final now = DateTime.now();
//       final deviceCount = _rssiByDevice.length;
//       final avgRssi = deviceCount > 0
//           ? _rssiByDevice.values.reduce((a, b) => a + b) / deviceCount
//           : 0.0;

//       final snapshot = ScanSnapshot(now, deviceCount, avgRssi);
//       _snapshots.add(snapshot);

//       // Keep only the last maxSnapshots
//       if (_snapshots.length > AppConstants.maxSnapshots) {
//         _snapshots.removeAt(0);
//       }

//       _snapshotsController.add(List.from(_snapshots));
//       AppLogger.info(
//         'Created snapshot: $deviceCount devices, avg RSSI: ${avgRssi.toStringAsFixed(1)}',
//       );
//     } catch (e) {
//       AppLogger.error('Error creating snapshot', e);
//     }
//   }

//   /// Record a successful scan
//   void _recordSuccessfulScan() {
//     _totalScansSuccessful++;
//     _totalScansAttempted++;
//   }

//   /// Record an error
//   void recordError(String errorType, String message) {
//     _recordError(errorType, message);
//   }

//   void _recordError(String errorType, String message) {
//     _totalScansAttempted++;
//     _errorTypeCount[errorType] = (_errorTypeCount[errorType] ?? 0) + 1;
//     AppLogger.error('Error recorded: $errorType - $message');
//   }

//   /// Get filtered devices based on criteria
//   Map<String, int> getFilteredDevices({
//     int minRssi = -100,
//     bool onlyNamed = false,
//     bool onlyConnectable = false,
//   }) {
//     try {
//       final filteredEntries = _rssiByDevice.entries.where((entry) {
//         final deviceId = entry.key;
//         final rssi = entry.value;

//         // RSSI filter
//         if (rssi < minRssi) return false;

//         // Named filter
//         if (onlyNamed && (_nameByDevice[deviceId]?.isEmpty ?? true)) {
//           return false;
//         }

//         // Connectable filter
//         if (onlyConnectable && !(_connectableByDevice[deviceId] ?? false)) {
//           return false;
//         }

//         return true;
//       }).toList();

//       // Sort by RSSI strength (strongest first)
//       filteredEntries.sort((a, b) => b.value.compareTo(a.value));

//       return Map.fromEntries(filteredEntries);
//     } catch (e) {
//       AppLogger.error('Error filtering devices', e);
//       return {};
//     }
//   }

//   /// Get device name
//   String getDeviceName(String deviceId) {
//     return _nameByDevice[deviceId] ?? 'Unknown Device';
//   }

//   /// Get device connectable status
//   bool isDeviceConnectable(String deviceId) {
//     return _connectableByDevice[deviceId] ?? false;
//   }

//   /// Clear all data
//   void clearData() {
//     _rssiByDevice.clear();
//     _nameByDevice.clear();
//     _connectableByDevice.clear();
//     _snapshots.clear();
//     _devicesController.add({});
//     _snapshotsController.add([]);
//     AppLogger.info('All data cleared');
//   }

//   /// Get scan success rate
//   double get scanSuccessRate {
//     if (_totalScansAttempted == 0) return 0.0;
//     return (_totalScansSuccessful / _totalScansAttempted) * 100;
//   }

//   /// Dispose resources
//   void dispose() {
//     _devicesController.close();
//     _snapshotsController.close();
//   }
// }
