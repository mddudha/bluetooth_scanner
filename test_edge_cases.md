# Bluetooth Scanner - Edge Case Testing Guide

## 🧪 **Complete Testing Strategy for Edge Cases**

### **1. Bluetooth Hardware Issues**

#### **Test: Bluetooth Not Supported**
```bash
# Simulate on iOS Simulator (Bluetooth not available)
flutter run -d "iPhone Simulator"
# Expected: Error banner "Bluetooth is not supported on this device"
```

#### **Test: Bluetooth Turned Off**
1. **On Physical Device:**
   - Turn off Bluetooth in Settings
   - Launch app
   - Expected: Error banner "Bluetooth is turned off"
   - Turn Bluetooth back on
   - Expected: Error clears, scanning starts

#### **Test: Airplane Mode**
1. **On Physical Device:**
   - Enable Airplane Mode
   - Launch app
   - Expected: Error about Bluetooth being unavailable
   - Disable Airplane Mode
   - Expected: App recovers automatically

### **2. Permission Issues**

#### **Test: Permission Denied**
1. **iOS:**
   - Go to Settings > Privacy & Security > Location Services
   - Find "Bluetooth Scanner" and set to "Never"
   - Launch app
   - Expected: Error "Please grant all required permissions in Settings"

2. **Android:**
   - Go to Settings > Apps > Bluetooth Scanner > Permissions
   - Deny Location permission
   - Launch app
   - Expected: Permission request dialog, then error if denied

#### **Test: Permanently Denied Permissions**
1. **iOS:**
   - Deny permission when prompted
   - Go to Settings and manually deny
   - Launch app
   - Expected: Error about permanently denied permissions

#### **Test: Permission Timeout**
```dart
// Add this test code temporarily to simulate timeout
Future<bool> _ensurePermissions() async {
  // Simulate slow permission request
  await Future.delayed(Duration(seconds: 35));
  // ... rest of method
}
```

### **3. Scanning Issues**

#### **Test: Scan Already Running**
1. **Manual Test:**
   - Tap play button rapidly multiple times
   - Expected: Only one scan runs, others are ignored
   - Check console logs for "Scan already running" messages

#### **Test: Scan Timeout**
```dart
// Temporarily modify scan duration to test
void _startIntervalScanning({int periodSec = 300, int activeSec = 10}) {
  _runOneScan(activeSec: 1); // Very short scan
  // ... rest of method
}
```

#### **Test: Consecutive Failures**
```dart
// Add this to simulate scan failures
Future<void> _runOneScan({required int activeSec}) async {
  // Simulate failure
  if (_consecutiveFailures >= 2) {
    throw Exception('Simulated scan failure');
  }
  // ... rest of method
}
```

### **4. Data Validation Issues**

#### **Test: Invalid RSSI Values**
```dart
// Add this to _listenScanResults to simulate invalid data
void _listenScanResults() {
  _scanSub = FlutterBluePlus.scanResults.listen(
    (results) {
      // Simulate invalid RSSI
      final fakeResult = ScanResult(
        device: results.first.device,
        advertisementData: results.first.advertisementData,
        rssi: 999, // Invalid RSSI
      );
      // Process fakeResult
    },
  );
}
```

#### **Test: Empty Device IDs**
```dart
// Simulate empty device ID
final fakeDevice = BluetoothDevice(
  remoteId: DeviceIdentifier(''), // Empty ID
  platformName: 'Test Device',
);
```

### **5. Memory Management**

#### **Test: Memory Cleanup**
```dart
// Add this to force memory cleanup
void _testMemoryCleanup() {
  // Add 200 fake snapshots
  for (int i = 0; i < 200; i++) {
    _snapshots.add(ScanSnapshot(DateTime.now(), i, -50.0));
  }
  
  // Add 1500 fake devices
  for (int i = 0; i < 1500; i++) {
    final fakeId = DeviceIdentifier('device_$i');
    _rssiByDevice[fakeId] = -50;
    _nameByDevice[fakeId] = 'Device $i';
  }
  
  _cleanupOldData();
  print('Snapshots after cleanup: ${_snapshots.length}');
  print('Devices after cleanup: ${_rssiByDevice.length}');
}
```

### **6. App Lifecycle Issues**

#### **Test: Background/Foreground Transitions**
1. **iOS:**
   - Start scanning
   - Press home button (app goes to background)
   - Check console logs for "App going to background"
   - Bring app back to foreground
   - Check console logs for "App resumed"

2. **Android:**
   - Start scanning
   - Press recent apps button
   - Swipe app away (force stop)
   - Relaunch app
   - Expected: App reinitializes properly

#### **Test: Background Scanning Toggle**
1. **Enable background scanning:**
   - Tap background scanning button (play icon)
   - Expected: Icon turns green, snackbar shows "Background scanning enabled"
   - Put app in background
   - Expected: Scanning continues (check logs)

2. **Disable background scanning:**
   - Tap background scanning button (pause icon)
   - Expected: Icon returns to normal, snackbar shows "Background scanning disabled"
   - Put app in background
   - Expected: Scanning stops (check logs)

### **7. UI Error Handling**

#### **Test: Error Banner Display**
```dart
// Add this method to test error display
void _testErrorDisplay() {
  _setError('Test error message');
  // Expected: Red error banner appears at top
}

void _testErrorClearing() {
  _setError('Test error');
  // Tap close button on error banner
  _clearError();
  // Expected: Error banner disappears
}
```

#### **Test: Retry Button**
1. **Simulate error:**
   - Turn off Bluetooth
   - Expected: Error banner with retry button appears
   - Tap retry button
   - Expected: App attempts to reinitialize

### **8. Network & System Issues**

#### **Test: Timeout Scenarios**
```dart
// Test various timeout scenarios
Future<void> _testTimeouts() async {
  // Test Bluetooth state timeout
  try {
    await FlutterBluePlus.adapterState.first.timeout(
      Duration(milliseconds: 100), // Very short timeout
    );
  } catch (e) {
    print('Timeout test passed: $e');
  }
  
  // Test permission timeout
  try {
    await _ensurePermissions().timeout(Duration(seconds: 1));
  } catch (e) {
    print('Permission timeout test passed: $e');
  }
}
```

### **9. User Experience Edge Cases**

#### **Test: Rapid Button Presses**
1. **Test play button:**
   - Tap play button 10 times rapidly
   - Expected: Only one scan starts, others ignored

2. **Test filter button:**
   - Open filters, change values rapidly
   - Expected: No crashes, smooth UI updates

#### **Test: Invalid User Input**
```dart
// Test filter validation
void _testFilterValidation() {
  // Test extreme RSSI values
  _minRssiDbm = -200; // Invalid
  _minRssiDbm = 100;  // Invalid
  
  // Test filter combinations
  _onlyNamed = true;
  _onlyConnectable = true;
  _minRssiDbm = -50;
}
```

### **10. Recovery Mechanisms**

#### **Test: Automatic Error Clearing**
```dart
// Test error clearing on success
void _testErrorRecovery() {
  _setError('Test error');
  
  // Simulate successful scan
  _rssiByDevice[DeviceIdentifier('test')] = -50;
  _listenScanResults();
  
  // Expected: Error clears automatically
}
```

## 🛠️ **Automated Testing Setup**

### **Create Test Widget**
```dart
// Add this to main.dart for testing
class _TestPanel extends StatelessWidget {
  final VoidCallback onTestError;
  final VoidCallback onTestMemory;
  final VoidCallback onTestTimeouts;
  
  const _TestPanel({
    required this.onTestError,
    required this.onTestMemory,
    required this.onTestTimeouts,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Test Panel', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onTestError,
                  child: Text('Test Error'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTestMemory,
                  child: Text('Test Memory'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTestTimeouts,
                  child: Text('Test Timeouts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Add Test Methods to HomeScreen**
```dart
// Add these methods to _HomeScreenState
void _testErrorDisplay() {
  _setError('This is a test error message');
}

void _testMemoryCleanup() {
  // Add test data
  for (int i = 0; i < 200; i++) {
    _snapshots.add(ScanSnapshot(DateTime.now(), i, -50.0));
  }
  for (int i = 0; i < 1500; i++) {
    final fakeId = DeviceIdentifier('test_device_$i');
    _rssiByDevice[fakeId] = -50;
  }
  
  _cleanupOldData();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Memory cleanup test completed')),
  );
}

void _testTimeouts() async {
  try {
    await FlutterBluePlus.adapterState.first.timeout(
      Duration(milliseconds: 100),
    );
  } catch (e) {
    _setError('Timeout test: $e');
  }
}
```

## 📱 **Manual Testing Checklist**

### **Pre-Test Setup:**
- [ ] Clean app installation
- [ ] Reset all permissions
- [ ] Clear app data
- [ ] Ensure Bluetooth is on
- [ ] Have multiple Bluetooth devices nearby

### **Test Scenarios:**
- [ ] **Normal Operation:** App starts, finds devices, shows charts
- [ ] **Bluetooth Off:** Turn off Bluetooth, check error handling
- [ ] **Permission Denied:** Deny permissions, check error messages
- [ ] **Background/Foreground:** Test app lifecycle handling
- [ ] **Memory Pressure:** Run app for extended period
- [ ] **Network Changes:** Test with WiFi on/off, airplane mode
- [ ] **Device Rotation:** Test UI responsiveness
- [ ] **Rapid Interactions:** Test button mashing, rapid filter changes

### **Expected Results:**
- [ ] No crashes or freezes
- [ ] Clear error messages
- [ ] Proper recovery from errors
- [ ] Smooth UI interactions
- [ ] Memory usage remains stable
- [ ] Background scanning works as expected

## 🚨 **Critical Edge Cases to Test**

1. **Bluetooth hardware failure during scan**
2. **App killed while scanning**
3. **Permission revoked while app is running**
4. **Device runs out of memory**
5. **Network connectivity loss**
6. **System Bluetooth service crashes**
7. **Multiple app instances**
8. **Device sleep/wake cycles**

This comprehensive testing strategy will ensure your app handles all edge cases gracefully! 🎯 