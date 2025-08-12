# Bluetooth Scanner App

A Flutter application for scanning and monitoring Bluetooth Low Energy (BLE) devices with real-time signal strength tracking and data visualization.

## 🚀 Features

- **Real-time BLE Scanning**: Continuously scan for nearby Bluetooth devices
- **Signal Strength Monitoring**: Track RSSI (Received Signal Strength Indicator) values
- **Data Visualization**: Interactive charts showing signal strength over time
- **Device Filtering**: Filter devices by type (connectable, non-connectable)
- **Background Scanning**: Enable/disable continuous background scanning
- **Cross-platform**: Works on both Android and iOS devices
- **Permission Management**: Automatic handling of Bluetooth and location permissions

## 📱 Platform Support & Considerations

### **Android:**
- **Permissions**: Requires `ACCESS_FINE_LOCATION` for BLE scanning (Android requirement)
- **Bluetooth Permissions**: `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` for Android 12+
- **Background Scanning**: Supported with foreground service capabilities
- **Performance**: Optimized for Android's Bluetooth stack

### **iOS:**
- **Permissions**: Requires `NSBluetoothAlwaysUsageDescription` and location permissions
- **Background Limitations**: iOS restricts background Bluetooth scanning
- **Privacy**: Strict permission requirements for Bluetooth access
- **Performance**: Optimized for iOS CoreBluetooth framework

### **Cross-Platform Considerations:**
- **Permission Handling**: Platform-specific permission requests with unified interface
- **Error Handling**: Different error types and recovery strategies per platform
- **UI Adaptation**: Material Design 3 with platform-specific theming
- **Testing**: Requires physical devices (Bluetooth scanning not available in simulators)

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode (for platform-specific builds)
- Physical device for testing (Bluetooth scanning doesn't work on simulators)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repository-url>
   cd bluetooth_scanner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**

   **For iOS:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

   **For Android:**
   - Ensure Android SDK is properly configured
   - Enable developer options and USB debugging on your device

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Scan Intervals

The app uses configurable scan intervals defined in `lib/utils/constants.dart`:

- **Active Scan Duration**: 10 seconds
- **Background Scan Interval**: 5 minutes
- **Max Consecutive Failures**: 3 attempts

### Permissions

The app automatically requests necessary permissions:

**Android:**
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION` (required for BLE scanning)

**iOS:**
- `NSBluetoothAlwaysUsageDescription`
- `NSLocationWhenInUseUsageDescription`

## 📊 Usage

1. **Launch the app** - Scanning starts automatically
2. **Grant permissions** when prompted
3. **View devices** - See detected BLE devices with signal strength
4. **Use filters** - Toggle between all devices and connectable devices
5. **Monitor charts** - View signal strength trends over time
6. **Background scanning** - Toggle continuous background monitoring

## 🏗️ Architecture & Implementation Approach

The app follows a **modular service-oriented architecture** with clear separation of concerns:

### **Core Architecture:**
```
lib/
├── main.dart                 # App entry point & MaterialApp setup
├── models/
│   └── scan_snapshot.dart    # Data models for time-series data
├── screens/
│   └── home_screen.dart      # Main UI with state management
├── services/
│   ├── bluetooth_service.dart    # BLE operations & adapter state
│   ├── data_service.dart         # Data management & snapshots
│   └── permission_service.dart   # Cross-platform permissions
├── utils/
│   ├── constants.dart        # App constants & configuration
│   ├── helpers.dart          # Utility functions
│   └── logger.dart           # Centralized logging
└── widgets/
    ├── chart_widget.dart     # Data visualization with fl_chart
    └── filter_widget.dart    # Reusable UI components
```

### **Implementation Approach:**

1. **Service Layer Pattern**: Each major functionality is encapsulated in a dedicated service class
2. **Stream-Based Architecture**: Real-time data flow using Dart Streams for reactive UI updates
3. **Singleton Services**: Ensures single instances for Bluetooth, Data, and Permission services
4. **Error Handling**: Comprehensive error tracking with type-based categorization
5. **Memory Management**: Automatic cleanup of old data to prevent memory leaks
6. **Platform Abstraction**: Platform-specific code isolated in permission handling

## 🔋 Battery Optimization

The app implements several battery optimization strategies:

- **Adaptive scanning intervals**: 10-second active scans with 5-minute background intervals
- **Memory management**: Automatic cleanup of old snapshots (max 50) and device data (max 2000 devices)
- **Background processing**: Efficient lifecycle management with app state detection
- **Smart permission handling**: Platform-specific permission requests to avoid unnecessary system calls
- **Error recovery**: Automatic retry logic with exponential backoff for failed scans
- **Data validation**: Prevents memory leaks and data corruption

## 🐛 Troubleshooting

### Common Issues

1. **"No space left on device"**
   ```bash
   flutter clean
   rm -rf ~/Library/Developer/Xcode/DerivedData
   xcrun simctl delete unavailable
   ```

2. **iOS build issues**
   ```bash
   cd ios && pod install && cd ..
   flutter pub get
   ```

3. **Bluetooth not working on simulator**
   - Use a physical device for testing
   - BLE scanning requires real hardware

4. **Permission denied**
   - Check device settings
   - Ensure location services are enabled (Android)
   - Verify Bluetooth permissions in iOS Settings

### Debug Mode

Enable detailed logging by setting `debugMode = true` in `lib/utils/logger.dart`.

## 📈 Performance Considerations

- **Memory Management**: Automatic cleanup of old scan data with configurable limits
- **CPU Usage**: Optimized scanning intervals (10s active, 5min background) to minimize battery drain
- **Storage**: Efficient data structures for large device lists with automatic pruning
- **Network**: No internet connectivity required - all data stored locally
- **Error Recovery**: Automatic retry logic with exponential backoff for failed operations
- **Data Validation**: Prevents memory leaks and data corruption with comprehensive validation

## 🛡️ Error Handling & Edge Cases

The app implements comprehensive error handling:

- **Bluetooth State Errors**: Handles adapter state changes and connection failures
- **Permission Errors**: Graceful handling of denied permissions with user guidance
- **Memory Errors**: Automatic cleanup when memory usage is high
- **Platform Errors**: Platform-specific error handling for iOS/Android differences
- **Data Corruption**: Validation and recovery from corrupted scan data
- **Network Errors**: Handles connectivity issues during Bluetooth operations
- **Timeout Errors**: Configurable timeouts for all async operations

## 🔒 Security

- **Local Data Only**: All data is stored locally on the device
- **No Cloud Sync**: No data is transmitted to external servers
- **Permission Minimalism**: Only requests necessary permissions
- **Secure Storage**: Uses Flutter's secure storage for sensitive data

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review the code comments for implementation details
- Create an issue in the repository

---

**Note**: This app requires physical devices for testing as Bluetooth scanning functionality is not available in simulators.
