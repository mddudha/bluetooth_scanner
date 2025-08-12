// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import '../utils/logger.dart';

// /// Service responsible for all Bluetooth operations
// class BluetoothService {
//   static final BluetoothService _instance = BluetoothService._internal();
//   factory BluetoothService() => _instance;
//   BluetoothService._internal();

//   // Stream controllers for state updates
//   final StreamController<BluetoothAdapterState> _adapterStateController =
//       StreamController<BluetoothAdapterState>.broadcast();
//   final StreamController<List<ScanResult>> _scanResultsController =
//       StreamController<List<ScanResult>>.broadcast();
//   final StreamController<bool> _isScanningController =
//       StreamController<bool>.broadcast();
//   final StreamController<String> _errorController =
//       StreamController<String>.broadcast();

//   // Subscriptions
//   StreamSubscription<List<ScanResult>>? _scanSub;
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

//   // State
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   bool _isScanning = false;

//   // Getters
//   Stream<BluetoothAdapterState> get adapterStateStream =>
//       _adapterStateController.stream;
//   Stream<List<ScanResult>> get scanResultsStream =>
//       _scanResultsController.stream;
//   Stream<bool> get isScanningStream => _isScanningController.stream;
//   Stream<String> get errorStream => _errorController.stream;
//   BluetoothAdapterState get adapterState => _adapterState;
//   bool get isScanning => _isScanning;

//   /// Initialize Bluetooth service
//   Future<void> initialize() async {
//     try {
//       // Check if Bluetooth is supported
//       if (!(await FlutterBluePlus.isSupported)) {
//         _errorController.add('Bluetooth is not supported on this device');
//         return;
//       }

//       AppLogger.info(
//         'Initializing Bluetooth service for ${Platform.isIOS ? 'iOS' : 'Android'}',
//       );

//       // Listen to Bluetooth state changes
//       _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
//         AppLogger.info('Bluetooth adapter state changed: $state');
//         _adapterState = state;
//         _adapterStateController.add(state);

//         // Clear error if Bluetooth turns on
//         if (state == BluetoothAdapterState.on) {
//           _listenScanResults();
//         }
//       });

//       // Get initial state
//       _adapterState = await FlutterBluePlus.adapterState.first;
//       _adapterStateController.add(_adapterState);

//       // Start listening to scan results immediately if Bluetooth is on
//       if (_adapterState == BluetoothAdapterState.on) {
//         _listenScanResults();
//       }
//     } catch (e) {
//       AppLogger.error('Failed to initialize Bluetooth service', e);
//       _errorController.add('Failed to initialize Bluetooth: $e');
//     }
//   }

//   /// Start listening to scan results
//   void _listenScanResults() {
//     _scanSub?.cancel();
//     _scanSub = FlutterBluePlus.scanResults.listen(
//       (results) {
//         AppLogger.info('Received ${results.length} scan results');
//         if (results.isNotEmpty) {
//           AppLogger.info(
//             'First device: ${results.first.device.platformName} (${results.first.rssi} dBm)',
//           );
//           // Log a few more devices for debugging
//           for (int i = 0; i < results.length && i < 3; i++) {
//             final result = results[i];
//             AppLogger.debug(
//               'Device $i: ${result.device.platformName} (${result.device.remoteId}) - ${result.rssi} dBm',
//             );
//           }
//         } else {
//           AppLogger.warning('No devices found in scan results');
//         }
//         _scanResultsController.add(results);
//       },
//       onError: (error) {
//         AppLogger.error('Error in scan results stream', error);
//         _errorController.add('Scan results error: $error');
//       },
//     );
//   }

//   /// Start a single scan
//   Future<void> startScan({required int activeSec}) async {
//     if (_isScanning) {
//       AppLogger.warning('Scan already in progress');
//       return;
//     }

//     try {
//       _isScanning = true;
//       _isScanningController.add(true);

//       AppLogger.info('Starting scan for $activeSec seconds');

//       // Stop any existing scan first
//       await FlutterBluePlus.stopScan();

//       // Start scan (works the same on both platforms)
//       await FlutterBluePlus.startScan(
//         timeout: Duration(seconds: activeSec),
//         androidUsesFineLocation: Platform.isAndroid,
//       );

//       AppLogger.info('Scan started successfully, waiting for results...');

//       // Wait for scan to complete
//       await Future.delayed(Duration(seconds: activeSec));

//       AppLogger.info('Scan completed');
//       _isScanning = false;
//       _isScanningController.add(false);
//     } catch (e) {
//       AppLogger.error('Scan failed', e);
//       _errorController.add('Scan failed: $e');
//       _isScanning = false;
//       _isScanningController.add(false);
//     }
//   }

//   /// Stop scanning
//   Future<void> stopScan() async {
//     try {
//       await FlutterBluePlus.stopScan();
//       _isScanning = false;
//       _isScanningController.add(false);
//       AppLogger.info('Scan stopped');
//     } catch (e) {
//       AppLogger.error('Failed to stop scan', e);
//     }
//   }

//   /// Check if Bluetooth is on
//   bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;

//   /// Get detailed Bluetooth state information for debugging
//   Future<Map<String, dynamic>> getBluetoothStateInfo() async {
//     try {
//       final state = await FlutterBluePlus.adapterState.first;
//       final isSupported = await FlutterBluePlus.isSupported;

//       return {
//         'adapterState': state.toString(),
//         'isSupported': isSupported,
//         'isOn': state == BluetoothAdapterState.on,
//         'platform': Platform.operatingSystem,
//       };
//     } catch (e) {
//       AppLogger.error('Error getting Bluetooth state info', e);
//       return {'error': e.toString(), 'platform': Platform.operatingSystem};
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     _scanSub?.cancel();
//     _adapterStateSub?.cancel();
//     _adapterStateController.close();
//     _scanResultsController.close();
//     _isScanningController.close();
//     _errorController.close();
//     FlutterBluePlus.stopScan();
//   }
// }
