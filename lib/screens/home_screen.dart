// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
// import 'package:fl_chart/fl_chart.dart';
// import '../models/scan_snapshot.dart';
// import '../services/bluetooth_service.dart';
// import '../services/permission_service.dart';
// import '../services/data_service.dart';
// import '../utils/helpers.dart';
// import '../utils/logger.dart';
// import '../utils/constants.dart';
// import '../widgets/filter_widget.dart';
// import '../widgets/chart_widget.dart';

// /// Pure UI component for the home screen
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
//   // Services
//   final BluetoothService _bluetoothService = BluetoothService();
//   final PermissionService _permissionService = PermissionService();
//   final DataService _dataService = DataService();

//   // UI State
//   bool _hasError = false;
//   String _errorMessage = '';
//   bool _backgroundScanningEnabled = false;
//   Timer? _intervalTimer;

//   // Filters
//   int _minRssiDbm = -100;
//   bool _onlyNamed = false;
//   bool _onlyConnectable = false;

//   // Stream subscriptions
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
//   StreamSubscription<List<ScanResult>>? _scanResultsSub;
//   StreamSubscription<bool>? _isScanningSub;
//   StreamSubscription<String>? _errorSub;
//   StreamSubscription<List<ScanSnapshot>>? _snapshotsSub;

//   // UI Data
//   List<ScanSnapshot> _snapshots = [];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeServices();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _intervalTimer?.cancel();
//     _adapterStateSub?.cancel();
//     _scanResultsSub?.cancel();
//     _isScanningSub?.cancel();
//     _errorSub?.cancel();
//     _snapshotsSub?.cancel();
//     super.dispose();
//   }

//   /// Initialize all services and set up streams
//   Future<void> _initializeServices() async {
//     try {
//       // Initialize Bluetooth service
//       await _bluetoothService.initialize();

//       // Request permissions
//       final hasPermissions = await _permissionService.requestPermissions();
//       if (!hasPermissions) {
//         _setError('Permissions are required for Bluetooth scanning');
//         return;
//       }

//       // Set up stream subscriptions
//       _setupStreamSubscriptions();

//       // Start interval scanning (includes immediate first scan)
//       _startIntervalScanning();
//     } catch (e) {
//       AppLogger.error('Failed to initialize services', e);
//       _setError('Failed to initialize: $e');
//     }
//   }

//   /// Set up all stream subscriptions
//   void _setupStreamSubscriptions() {
//     // Bluetooth adapter state
//     _adapterStateSub = _bluetoothService.adapterStateStream.listen((state) {
//       if (state == BluetoothAdapterState.on) {
//         _clearError();
//         // Start scanning when Bluetooth turns on
//         _runIntervalScan();
//       } else if (state == BluetoothAdapterState.off) {
//         _setError('Bluetooth is turned off');
//       }
//     });

//     // Scan results
//     _scanResultsSub = _bluetoothService.scanResultsStream.listen((results) {
//       _dataService.processScanResults(results);
//     });

//     // Scanning state
//     _isScanningSub = _bluetoothService.isScanningStream.listen((isScanning) {
//       // Update UI if needed
//     });

//     // Errors
//     _errorSub = _bluetoothService.errorStream.listen((error) {
//       _setError(error);
//     });

//     // Snapshots data
//     _snapshotsSub = _dataService.snapshotsStream.listen((snapshots) {
//       setState(() {
//         _snapshots = snapshots;
//       });
//     });
//   }

//   /// Start interval scanning
//   void _startIntervalScanning() {
//     _intervalTimer?.cancel();

//     // Start the first scan immediately
//     _runIntervalScan();

//     // Then set up the periodic timer for every 5 minutes
//     _intervalTimer = Timer.periodic(
//       Duration(seconds: AppConstants.defaultScanIntervalSeconds),
//       (_) => _runIntervalScan(),
//     );

//     AppLogger.info(
//       'Interval scanning started - scans every ${AppConstants.defaultScanIntervalSeconds} seconds',
//     );
//   }

//   /// Run a single scan as part of interval
//   Future<void> _runIntervalScan() async {
//     if (!_bluetoothService.isBluetoothOn) return;

//     try {
//       await _bluetoothService.startScan(
//         activeSec: AppConstants.defaultActiveScanSeconds,
//       );
//     } catch (e) {
//       AppLogger.error('Interval scan failed', e);
//       _dataService.recordError('interval_scan', e.toString());
//     }
//   }

//   /// Handle app lifecycle changes
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.paused) {
//       if (_backgroundScanningEnabled) {
//         AppLogger.info('App going to background - background scanning enabled');
//       } else {
//         AppLogger.info('App going to background - stopping scans');
//         _bluetoothService.stopScan();
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       AppLogger.info('App resumed - resuming scans');
//       if (_bluetoothService.isBluetoothOn) {
//         _runIntervalScan();
//       }
//     }
//   }

//   /// Toggle background scanning
//   void _toggleBackgroundScanning() {
//     setState(() {
//       _backgroundScanningEnabled = !_backgroundScanningEnabled;
//     });

//     if (_backgroundScanningEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Background scanning enabled - app will continue scanning when minimized',
//           ),
//           duration: Duration(
//             seconds: AppConstants.backgroundScanEnabledDuration,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Background scanning disabled'),
//           duration: Duration(
//             seconds: AppConstants.backgroundScanDisabledDuration,
//           ),
//         ),
//       );
//     }
//   }

//   /// Set error state
//   void _setError(String message) {
//     setState(() {
//       _hasError = true;
//       _errorMessage = message;
//     });
//   }

//   /// Clear error state
//   void _clearError() {
//     setState(() {
//       _hasError = false;
//       _errorMessage = '';
//     });
//   }

//   /// Show Bluetooth state information
//   void _showBluetoothStateInfo() {
//     final state = _bluetoothService.isBluetoothOn ? 'ON' : 'OFF';
//     final adapter = _bluetoothService.adapterState.toString();
//     final scanState = _bluetoothService.isScanning ? 'SCANNING' : 'IDLE';

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Bluetooth State: $state\nAdapter State: $adapter\nScan State: $scanState',
//         ),
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredDevices = _dataService.getFilteredDevices(
//       minRssi: _minRssiDbm,
//       onlyNamed: _onlyNamed,
//       onlyConnectable: _onlyConnectable,
//     );

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bluetooth Scanner'),
//         actions: [
//           IconButton(
//             tooltip: 'Filters',
//             onPressed: () {
//               FilterWidget.showFiltersBottomSheet(
//                 context,
//                 minRssi: _minRssiDbm,
//                 onlyNamed: _onlyNamed,
//                 onlyConnectable: _onlyConnectable,
//                 onChanged:
//                     ({int? minRssi, bool? onlyNamed, bool? onlyConnectable}) {
//                       setState(() {
//                         if (minRssi != null) _minRssiDbm = minRssi;
//                         if (onlyNamed != null) _onlyNamed = onlyNamed;
//                         if (onlyConnectable != null) {
//                           _onlyConnectable = onlyConnectable;
//                         }
//                       });
//                     },
//               );
//             },
//             icon: const Icon(Icons.filter_list),
//           ),
//           IconButton(
//             tooltip: _backgroundScanningEnabled
//                 ? 'Disable background scanning'
//                 : 'Enable background scanning',
//             onPressed: _toggleBackgroundScanning,
//             icon: Icon(
//               _backgroundScanningEnabled
//                   ? Icons.pause_circle_outline
//                   : Icons.play_circle_outline,
//               color: _backgroundScanningEnabled ? Colors.green : null,
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Error banner
//             if (_hasError)
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   border: Border.all(color: Colors.red.shade200),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.error_outline, color: Colors.red.shade700),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _errorMessage,
//                             style: TextStyle(
//                               color: Colors.red.shade700,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close, size: 20),
//                           onPressed: _clearError,
//                           color: Colors.red.shade700,
//                         ),
//                       ],
//                     ),
//                     // Error statistics
//                     if (_dataService.errorTypeCount.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8),
//                         child: Text(
//                           'Scan Success Rate: ${_dataService.scanSuccessRate.toStringAsFixed(1)}% '
//                           '(${_dataService.totalScansSuccessful}/${_dataService.totalScansAttempted})',
//                           style: TextStyle(
//                             color: Colors.red.shade600,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             _MetricsHeader(
//               deviceCount: filteredDevices.length,
//               avgRssi: filteredDevices.isEmpty
//                   ? null
//                   : filteredDevices.values.reduce((a, b) => a + b) /
//                         filteredDevices.length,
//             ),
//             // Device list
//             SizedBox(
//               height: MediaQuery.of(context).size.height * 0.45,
//               child: ListView.separated(
//                 padding: const EdgeInsets.symmetric(horizontal: 8),
//                 itemCount: filteredDevices.length,
//                 separatorBuilder: (context, index) => const SizedBox(height: 4),
//                 itemBuilder: (context, index) {
//                   final deviceId = filteredDevices.keys.elementAt(index);
//                   final rssi = filteredDevices[deviceId]!;
//                   final deviceName = _dataService.getDeviceName(deviceId);

//                   return Card(
//                     elevation: 1,
//                     child: ListTile(
//                       leading: Icon(
//                         Icons.bluetooth,
//                         color: AppHelpers.getRssiColor(rssi),
//                       ),
//                       title: Text(
//                         deviceName,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('ID: ${deviceId.toString()}'),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.signal_cellular_alt,
//                                 size: 12,
//                                 color: AppHelpers.getRssiColor(rssi),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 AppHelpers.formatRssi(rssi),
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w500,
//                                   color: AppHelpers.getRssiColor(rssi),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       trailing: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppHelpers.getRssiColor(rssi).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           rssi.toString(),
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: AppHelpers.getRssiColor(rssi),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//             // Charts
//             SizedBox(
//               height: 280,
//               child: LineChartWidget(
//                 title: 'Devices over time',
//                 points: _snapshots
//                     .map(
//                       (s) => FlSpot(
//                         s.timestamp.millisecondsSinceEpoch.toDouble(),
//                         s.deviceCount.toDouble(),
//                       ),
//                     )
//                     .toList(),
//                 yMin: 0,
//                 yMax: (_snapshots.isEmpty
//                     ? null
//                     : (_snapshots
//                                   .map((s) => s.deviceCount)
//                                   .reduce((a, b) => a > b ? a : b) +
//                               5)
//                           .toDouble()),
//                 yInterval: 10,
//                 xLabelFormat: 'H:mm',
//               ),
//             ),
//             SizedBox(
//               height: 280,
//               child: LineChartWidget(
//                 title: 'Average RSSI (dBm)',
//                 points: _snapshots
//                     .where((s) => s.deviceCount > 0)
//                     .map(
//                       (s) => FlSpot(
//                         s.timestamp.millisecondsSinceEpoch.toDouble(),
//                         s.avgRssi,
//                       ),
//                     )
//                     .toList(),
//                 yMin: -100,
//                 yMax: -20,
//                 yInterval: 20,
//                 xLabelFormat: 'H:mm',
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MetricsHeader extends StatelessWidget {
//   final int deviceCount;
//   final double? avgRssi;
//   const _MetricsHeader({required this.deviceCount, required this.avgRssi});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         children: [
//           _Chip(label: 'Devices', value: '$deviceCount'),
//           const SizedBox(width: 8),
//           _Chip(
//             label: 'Avg RSSI',
//             value: avgRssi == null ? '—' : '${avgRssi!.toStringAsFixed(1)} dBm',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   final String label;
//   final String value;
//   const _Chip({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Theme.of(context).colorScheme.surfaceContainerHighest,
//       ),
//       child: Row(
//         children: [
//           Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
//           Text(value),
//         ],
//       ),
//     );
//   }
// }
