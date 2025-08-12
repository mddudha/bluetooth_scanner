import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const BluetoothScannerApp());
}

class BluetoothScannerApp extends StatelessWidget {
  const BluetoothScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

void _showFiltersBottomSheet(
  BuildContext context, {
  required int minRssi,
  required bool onlyNamed,
  required bool onlyConnectable,
  required void Function({int? minRssi, bool? onlyNamed, bool? onlyConnectable})
  onChanged,
}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      int tempRssi = minRssi;
      bool tempNamed = onlyNamed;
      bool tempConn = onlyConnectable;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Min RSSI (dBm)'),
                    Text('$tempRssi dBm'),
                  ],
                ),
                Slider(
                  value: tempRssi.toDouble(),
                  min: -100,
                  max: 0,
                  divisions: 100,
                  label: '$tempRssi',
                  onChanged: (v) => setModalState(() => tempRssi = v.round()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only named devices'),
                  value: tempNamed,
                  onChanged: (v) => setModalState(() => tempNamed = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only connectable devices'),
                  value: tempConn,
                  onChanged: (v) => setModalState(() => tempConn = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        onChanged(
                          minRssi: tempRssi,
                          onlyNamed: tempNamed,
                          onlyConnectable: tempConn,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class ScanSnapshot {
  final DateTime timestamp;
  final int deviceCount;
  final double avgRssi;

  ScanSnapshot(this.timestamp, this.deviceCount, this.avgRssi);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Map<DeviceIdentifier, int> _rssiByDevice = {};
  final Map<DeviceIdentifier, String> _nameByDevice = {};
  final Map<DeviceIdentifier, bool> _connectableByDevice = {};
  final List<ScanSnapshot> _snapshots = [];

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  Timer? _intervalTimer;
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // Error handling states
  bool _hasError = false;
  String _errorMessage = '';
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  // Enhanced error tracking
  int _totalScansAttempted = 0;
  int _totalScansSuccessful = 0;
  final Map<String, int> _errorTypeCount = {};

  // Filters
  int _minRssiDbm = -100; // show devices with RSSI >= this value
  bool _onlyNamed = false;
  bool _onlyConnectable = false;

  // Background scanning
  bool _backgroundScanningEnabled = false;

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    if (rssi >= -85) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPermissionsAndScan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intervalTimer?.cancel();
    _scanSub?.cancel();
    _adapterStateSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App going to background
      if (_backgroundScanningEnabled) {
        print('App going to background - background scanning enabled');
        // Continue scanning in background
      } else {
        print('App going to background - stopping scans');
        FlutterBluePlus.stopScan();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground
      print('App resumed - resuming scans');
      if (_adapterState == BluetoothAdapterState.on) {
        _runOneScan(activeSec: 10);
      }
    }
  }

  void _toggleBackgroundScanning() {
    setState(() {
      _backgroundScanningEnabled = !_backgroundScanningEnabled;
    });

    if (_backgroundScanningEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Background scanning enabled - app will continue scanning when minimized',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background scanning disabled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initPermissionsAndScan() async {
    try {
      // Check if Bluetooth is supported first
      if (!(await FlutterBluePlus.isSupported)) {
        _setErrorWithType(
          'Bluetooth is not supported on this device',
          'bluetooth_unsupported',
        );
        return;
      }

      // Listen to Bluetooth state changes
      _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
        print('Bluetooth adapter state changed: $state');
        setState(() => _adapterState = state);

        // Clear error if Bluetooth turns on
        if (state == BluetoothAdapterState.on) {
          _clearError();
          _listenScanResults();
          _startIntervalScanning();
        } else if (state == BluetoothAdapterState.off) {
          _setErrorWithType('Bluetooth is turned off', 'bluetooth_off');
        }
      });

      // Try to get initial Bluetooth state with timeout
      try {
        _adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 10),
        );
        print('Initial Bluetooth state: $_adapterState');
      } catch (e) {
        print('Timeout getting Bluetooth state: $e');
        _setErrorWithType(
          'Unable to detect Bluetooth state',
          'bluetooth_state_unknown',
        );
        return;
      }

      final ok = await _ensurePermissions();
      if (!ok) {
        _setErrorWithType(
          'Please grant all required permissions in Settings',
          'permissions_denied',
        );
        return;
      }

      if (_adapterState == BluetoothAdapterState.on) {
        _clearError();
        _listenScanResults();
        _startIntervalScanning();
      } else {
        _setErrorWithType('Please turn on Bluetooth', 'bluetooth_off');
      }
    } catch (e) {
      print('Error initializing: $e');
      _setErrorWithType(
        'Initialization failed: ${e.toString()}',
        'initialization_error',
      );
    }
  }

  void _setError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _consecutiveFailures++;
    });
  }

  void _clearError() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _consecutiveFailures = 0;
    });
  }

  // Enhanced error handling methods
  void _setErrorWithType(String message, String errorType) {
    _errorTypeCount[errorType] = (_errorTypeCount[errorType] ?? 0) + 1;
    _setError(message);

    // Log error for debugging
    print(
      'Error [$errorType]: $message (Count: ${_errorTypeCount[errorType]})',
    );
  }

  void _handleNetworkError(String operation) {
    _setErrorWithType(
      'Network connectivity issue during $operation. Please check your connection.',
      'network_error',
    );
  }

  void _handleDeviceError(String operation, String details) {
    _setErrorWithType(
      'Device error during $operation: $details',
      'device_error',
    );
  }

  void _handleDataCorruptionError(String dataType) {
    _setErrorWithType(
      'Data corruption detected in $dataType. Clearing corrupted data.',
      'data_corruption',
    );

    // Clear potentially corrupted data
    if (dataType == 'scan_results') {
      _rssiByDevice.clear();
      _nameByDevice.clear();
      _connectableByDevice.clear();
    } else if (dataType == 'snapshots') {
      _snapshots.clear();
    }
  }

  void _handleMemoryError() {
    _setErrorWithType(
      'Memory usage high. Cleaning up old data.',
      'memory_error',
    );

    // Force cleanup
    _cleanupOldData();
  }

  void _handlePlatformSpecificError(String platform, String operation) {
    _setErrorWithType(
      'Platform-specific error on $platform during $operation. Please restart the app.',
      'platform_error',
    );
  }

  // Enhanced success tracking
  void _recordSuccessfulScan() {
    _totalScansSuccessful++;
    _consecutiveFailures = 0;

    if (_hasError && _errorMessage.contains('scan')) {
      _clearError();
    }
  }

  // Enhanced data validation
  bool _validateDeviceData(ScanResult result) {
    try {
      // Validate device ID
      if (result.device.remoteId.str.isEmpty) {
        print('Invalid device: Empty ID');
        return false;
      }

      // Validate RSSI range
      if (result.rssi < -100 || result.rssi > 0) {
        print('Invalid RSSI: ${result.rssi}');
        return false;
      }

      // Validate advertisement data
      if (result.advertisementData == null) {
        print('Invalid device: No advertisement data');
        return false;
      }

      return true;
    } catch (e) {
      print('Data validation error: $e');
      return false;
    }
  }

  // Enhanced memory management
  void _checkMemoryUsage() {
    try {
      // Check if we have too many devices
      if (_rssiByDevice.length > 2000) {
        _handleMemoryError();
        return;
      }

      // Check if snapshots are too large
      if (_snapshots.length > 200) {
        _handleMemoryError();
        return;
      }

      // Check for memory leaks in error tracking
      if (_errorTypeCount.length > 50) {
        _errorTypeCount.clear();
        print('Cleared error tracking due to size');
      }
    } catch (e) {
      print('Memory check error: $e');
    }
  }

  void _cleanupOldData() {
    // Remove old snapshots to prevent memory issues
    if (_snapshots.length > 100) {
      _snapshots.removeRange(0, _snapshots.length - 100);
    }

    // Remove old device data to prevent memory leaks
    if (_rssiByDevice.length > 1000) {
      final sortedDevices = _rssiByDevice.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Keep only the strongest signals
      final devicesToRemove = sortedDevices.take(_rssiByDevice.length - 500);
      for (final device in devicesToRemove) {
        _rssiByDevice.remove(device.key);
        _nameByDevice.remove(device.key);
        _connectableByDevice.remove(device.key);
      }
    }
  }

  Future<bool> _ensurePermissions() async {
    try {
      final reqs = <Permission>[
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];

      // Check current statuses with timeout
      final statuses = await reqs.request().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Permission request timed out');
        },
      );

      // Log permission statuses
      print('Location permission: ${statuses[Permission.locationWhenInUse]}');
      print('Bluetooth scan permission: ${statuses[Permission.bluetoothScan]}');
      print(
        'Bluetooth connect permission: ${statuses[Permission.bluetoothConnect]}',
      );

      // Check for permanently denied permissions
      final permanentlyDenied = statuses.values.any(
        (s) => s.isPermanentlyDenied,
      );
      if (permanentlyDenied) {
        print('Some permissions are permanently denied: $statuses');
        return false;
      }

      final allGranted = statuses.values.every(
        (s) => s.isGranted || s.isLimited,
      );
      if (!allGranted) {
        print('Some permissions were denied: $statuses');
      }

      return allGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  void _listenScanResults() {
    _scanSub = FlutterBluePlus.scanResults.listen(
      (results) {
        try {
          print('Scan results received: ${results.length} devices');
          _totalScansAttempted++;

          // Check memory usage before processing
          _checkMemoryUsage();

          // Validate results
          if (results.isEmpty) {
            print('No devices found in scan');
            _recordSuccessfulScan(); // Still a successful scan
            return;
          }

          int validDevices = 0;
          for (final r in results) {
            // Use enhanced data validation
            if (!_validateDeviceData(r)) {
              continue;
            }
            validDevices++;

            _rssiByDevice[r.device.remoteId] = r.rssi;
            _connectableByDevice[r.device.remoteId] =
                r.advertisementData.connectable;

            // Get device name from multiple sources
            final platformName = r.device.platformName;
            final advName = r.advertisementData.advName;
            final localName = r.advertisementData.localName;

            // Try to get name from advertisement data
            String? deviceName;
            if (platformName.isNotEmpty) {
              deviceName = platformName;
            } else if (advName.isNotEmpty) {
              deviceName = advName;
            } else if (localName.isNotEmpty) {
              deviceName = localName;
            }

            // If we found a name, store it
            if (deviceName != null && deviceName.isNotEmpty) {
              _nameByDevice[r.device.remoteId] = deviceName;
            }

            // Use device name or fallback to ID
            final displayName =
                deviceName ??
                "Unknown (${r.device.remoteId.str.substring(0, 8)}...)";

            print('''
Device found:
  Name: $displayName
  ID: ${r.device.remoteId}
  RSSI: ${r.rssi}
  Platform Name: ${platformName.isNotEmpty ? platformName : 'empty'}
  Advertisement Name: ${advName.isNotEmpty ? advName : 'empty'}
  Local Name: ${localName.isNotEmpty ? localName : 'empty'}
  Connectable: ${r.advertisementData.connectable}
''');
          }

          // Record successful scan with validation info
          _recordSuccessfulScan();
          print(
            'Processed $validDevices valid devices out of ${results.length} total',
          );

          setState(() {});
        } catch (e) {
          print('Error processing scan results: $e');
          _handleDataCorruptionError('scan_results');
        }
      },
      onError: (error) {
        print('Scan error: $error');
        print('Error details: ${error.toString()}');

        // Enhanced error categorization
        String errorType = 'scan_error';
        String errorMessage = 'Scan failed: ${error.toString()}';

        if (error.toString().contains('timeout')) {
          errorType = 'scan_timeout';
          errorMessage = 'Scan timed out. Please try again.';
        } else if (error.toString().contains('permission')) {
          errorType = 'scan_permission_error';
          errorMessage = 'Permission error during scan. Please check settings.';
        } else if (error.toString().contains('bluetooth')) {
          errorType = 'bluetooth_scan_error';
          errorMessage = 'Bluetooth scan error. Please restart Bluetooth.';
        }

        _setErrorWithType(errorMessage, errorType);
        _consecutiveFailures++;

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          _setErrorWithType(
            'Too many scan failures. Please restart the app.',
            'max_failures_reached',
          );
        }
      },
    );
  }

  void _startIntervalScanning({int periodSec = 300, int activeSec = 10}) {
    _runOneScan(activeSec: activeSec);
    _intervalTimer = Timer.periodic(Duration(seconds: periodSec), (_) {
      // Only continue scanning if background scanning is enabled or app is in foreground
      if (_backgroundScanningEnabled ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _runOneScan(activeSec: activeSec);
      }
    });
  }

  // Add data points more frequently for smoother graphs
  void _addDataPoint() {
    final now = DateTime.now();
    final count = _rssiByDevice.length;
    double avg = 0;

    if (count > 0) {
      final validRssiValues = _rssiByDevice.values
          .where((rssi) => rssi >= -100 && rssi <= 0)
          .toList();

      if (validRssiValues.isNotEmpty) {
        avg = validRssiValues.reduce((a, b) => a + b) / validRssiValues.length;
      }
    }

    _snapshots.add(ScanSnapshot(now, count, avg));

    // Keep only last 50 points for cleaner graphs
    if (_snapshots.length > 50) {
      _snapshots.removeRange(0, _snapshots.length - 50);
    }

    setState(() {});
  }

  Future<void> _runOneScan({required int activeSec}) async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      print('Starting new scan...');
      _rssiByDevice.clear();

      // Check if Bluetooth is supported
      if (!(await FlutterBluePlus.isSupported)) {
        _setErrorWithType(
          'Bluetooth is not supported on this device',
          'bluetooth_unsupported',
        );
        return;
      }

      // Check if device is in airplane mode (Bluetooth might be disabled)
      try {
        final isOn = await FlutterBluePlus.isOn;
        if (!isOn) {
          _setErrorWithType(
            'Bluetooth is turned off. Please enable Bluetooth.',
            'bluetooth_off',
          );
          return;
        }
      } catch (e) {
        print('Error checking Bluetooth state: $e');
        // On Android, this might be a permission issue
        if (e.toString().contains('permission')) {
          _setErrorWithType(
            'Bluetooth permission denied. Please grant permissions.',
            'bluetooth_permission_denied',
          );
        } else {
          _setErrorWithType(
            'Unable to check Bluetooth state',
            'bluetooth_state_unknown',
          );
        }
        return;
      }

      // Get current Bluetooth state with timeout
      try {
        _adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 5),
        );
        print('Current Bluetooth state: $_adapterState');
      } catch (e) {
        print('Timeout getting Bluetooth state: $e');
        _setErrorWithType(
          'Unable to detect Bluetooth state',
          'bluetooth_state_unknown',
        );
        return;
      }

      if (_adapterState != BluetoothAdapterState.on) {
        print('Bluetooth is not on: $_adapterState');
        _setErrorWithType(
          'Bluetooth is ${_adapterState.toString().split('.').last}',
          'bluetooth_state_not_on',
        );
        return;
      }

      // Validate scan duration
      if (activeSec < 1 || activeSec > 60) {
        print('Invalid scan duration: $activeSec seconds');
        _setError('Invalid scan duration');
        return;
      }

      // Start scanning
      try {
        await FlutterBluePlus.startScan(
          timeout: Duration(seconds: activeSec),
          androidUsesFineLocation: true,
        );

        print('Scan started successfully');

        // Wait for scan to complete (shorter delay for better responsiveness)
        await Future<void>.delayed(Duration(milliseconds: 500));

        // Add data point to graphs
        _addDataPoint();

        // Cleanup old data
        _cleanupOldData();

        // Clear error on successful scan
        if (_hasError && _errorMessage.contains('scan')) {
          _clearError();
        }
        _recordSuccessfulScan();
      } catch (e) {
        print('Scan start error: $e');
        if (e.toString().contains('timeout')) {
          _setError('Scan timed out. Please try again.');
        } else {
          _setError('Scan failed: ${e.toString()}');
        }
      }
    } catch (e) {
      print('Scan error: $e');
      _setError('Scan error: ${e.toString()}');
      _consecutiveFailures++;

      // Stop scanning after too many failures
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _setError('Too many scan failures. Please restart the app.');
      }
    } finally {
      _isScanning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _rssiByDevice.entries.where((e) {
      final id = e.key;
      final rssi = e.value;
      if (rssi < _minRssiDbm) return false;
      if (_onlyNamed && !_nameByDevice.containsKey(id)) return false;
      if (_onlyConnectable && (_connectableByDevice[id] != true)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
        actions: [
          // Retry button when there's an error
          if (_hasError)
            IconButton(
              tooltip: 'Retry',
              onPressed: () {
                _clearError();
                _initPermissionsAndScan();
              },
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: _isScanning ? 'Scanning...' : 'Manual scan (10s)',
            onPressed: _isScanning ? null : () => _runOneScan(activeSec: 10),
            icon: _isScanning
                ? const Icon(Icons.radar)
                : const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: () {
              _showFiltersBottomSheet(
                context,
                minRssi: _minRssiDbm,
                onlyNamed: _onlyNamed,
                onlyConnectable: _onlyConnectable,
                onChanged:
                    ({int? minRssi, bool? onlyNamed, bool? onlyConnectable}) {
                      setState(() {
                        if (minRssi != null) _minRssiDbm = minRssi;
                        if (onlyNamed != null) _onlyNamed = onlyNamed;
                        if (onlyConnectable != null)
                          _onlyConnectable = onlyConnectable;
                      });
                    },
              );
            },
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: _backgroundScanningEnabled
                ? 'Disable background scanning'
                : 'Enable background scanning',
            onPressed: _toggleBackgroundScanning,
            icon: Icon(
              _backgroundScanningEnabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: _backgroundScanningEnabled ? Colors.green : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Error banner
            if (_hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _clearError,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                    // Error statistics (only show if there are multiple errors)
                    if (_errorTypeCount.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Scan Success Rate: ${_totalScansAttempted > 0 ? ((_totalScansSuccessful / _totalScansAttempted) * 100).toStringAsFixed(1) : '0'}% '
                          '(${_totalScansSuccessful}/${_totalScansAttempted})',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            _MetricsHeader(
              deviceCount: devices.length,
              avgRssi: devices.isEmpty
                  ? null
                  : devices.map((e) => e.value).reduce((a, b) => a + b) /
                        devices.length,
            ),

            // Fixed-height device list (~55% of screen), with its own scroll
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: ListView.separated(
                primary: false,
                physics: const BouncingScrollPhysics(),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (context, i) {
                  final id = devices[i].key;
                  final rssi = devices[i].value;
                  final name = _nameByDevice[id];
                  final displayName =
                      name ?? 'Unknown (${id.str.substring(0, 8)}...)';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        vertical: -1,
                        horizontal: -1,
                      ),
                      leading: Icon(
                        _connectableByDevice[id] == true
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name != null ? id.str : 'No name broadcast',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.signal_cellular_alt,
                                size: 12,
                                color: _getRssiColor(rssi),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rssi dBm',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getRssiColor(rssi),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRssiColor(rssi).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$rssi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRssiColor(rssi),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280, // Increased height
              child: _LineChart(
                title: 'Devices over time',
                points: _snapshots
                    .map(
                      (s) => FlSpot(
                        s.timestamp.millisecondsSinceEpoch.toDouble(),
                        s.deviceCount.toDouble(),
                      ),
                    )
                    .toList(),
                yMin: 0,
                yMax: (_snapshots.isEmpty
                    ? null
                    : (_snapshots
                                  .map((s) => s.deviceCount)
                                  .reduce((a, b) => a > b ? a : b) +
                              5)
                          .toDouble()),
                yInterval: 10,
                xLabelFormat: 'H:mm',
              ),
            ),
            SizedBox(
              height: 280, // Increased height
              child: _LineChart(
                title: 'Average RSSI (dBm)',
                points: _snapshots
                    .where((s) => s.deviceCount > 0)
                    .map(
                      (s) => FlSpot(
                        s.timestamp.millisecondsSinceEpoch.toDouble(),
                        s.avgRssi,
                      ),
                    )
                    .toList(),
                yMin: -100,
                yMax: -20,
                yInterval: 20,
                xLabelFormat: 'H:mm',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MetricsHeader extends StatelessWidget {
  final int deviceCount;
  final double? avgRssi;
  const _MetricsHeader({required this.deviceCount, required this.avgRssi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Chip(label: 'Devices', value: '$deviceCount'),
          const SizedBox(width: 8),
          _Chip(
            label: 'Avg RSSI',
            value: avgRssi == null ? '—' : '${avgRssi!.toStringAsFixed(1)} dBm',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final String title;
  final List<FlSpot> points;
  final double? yMin;
  final double? yMax;
  final Color? color;
  final double? yInterval;
  final String? xLabelFormat;

  const _LineChart({
    required this.title,
    required this.points,
    this.yMin,
    this.yMax,
    this.color,
    this.yInterval,
    this.xLabelFormat,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat(xLabelFormat ?? 'H:mm');
    final lineColor = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Reduced horizontal padding
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16,
          ), // Increased internal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16, // Increased title font size
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8), // Increased spacing
              SizedBox(
                height: 200, // Increased chart height
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ), // Add margin around chart
                  child: LineChart(
                    LineChartData(
                      minX: points.isEmpty ? 0 : points.first.x,
                      maxX: points.isEmpty ? 1 : points.last.x,
                      minY: yMin,
                      maxY: yMax,
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItems: (touchedSpots) => touchedSpots.map((
                            t,
                          ) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              t.x.toInt(),
                            );
                            return LineTooltipItem(
                              '${fmt.format(dt)}\n${t.y.toStringAsFixed(1)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: (yMax != null && yMin != null)
                            ? ((yMax! - yMin!) / 3).clamp(1, double.infinity)
                            : null,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                35, // Increased to prevent overlapping
                            interval: points.length < 2
                                ? null
                                : (points.last.x - points.first.x) /
                                      3, // More spacing between labels
                            getTitlesWidget: (value, meta) {
                              final dt = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                ), // Add padding to prevent overlap
                                child: Text(
                                  fmt.format(dt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                30, // Increased to prevent overlapping
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                ), // Add padding to prevent overlap
                                child: Text(
                                  value.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: points,
                          isCurved: false, // Straight lines instead of curves
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          barWidth: 2, // Thinner lines
                          color: lineColor,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                lineColor.withOpacity(0.15),
                                lineColor.withOpacity(0.01),
                              ],
                            ),
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
      ),
    );
  }
}
