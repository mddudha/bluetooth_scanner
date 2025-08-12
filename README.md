# Bluetooth Scanner App

A Flutter application for scanning and monitoring Bluetooth Low Energy (BLE) devices with real-time signal strength tracking and data visualization.

## Features

- **Real-time BLE Scanning**: Continuously scan for nearby Bluetooth devices
- **Signal Strength Monitoring**: Track RSSI (Received Signal Strength Indicator) values
- **Data Visualization**: Interactive charts showing signal strength over time
- **Device Filtering**: Filter devices by type (connectable, non-connectable)
- **Background Scanning**: Enable/disable continuous background scanning
- **Cross-platform**: Works on both Android and iOS devices
- **Permission Management**: Automatic handling of Bluetooth and location permissions

## Platform Support & Considerations

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

## Setup Instructions

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

## Configuration

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

## Usage

1. **Launch the app** - Scanning starts automatically
2. **Grant permissions** when prompted
3. **View devices** - See detected BLE devices with signal strength
4. **Use filters** - Toggle between all devices and connectable devices
5. **Monitor charts** - View signal strength trends over time
6. **Background scanning** - Toggle continuous background monitoring

## Architecture & Implementation Approach

### Current Implementation: Single File Approach

The current implementation uses a single `main.dart` file for the following reasons:

1. **Speed and Clarity**: For rapid prototyping and demonstration purposes, having all code in one place provides immediate visibility into the complete app flow
2. **Local Short-lived Storage**: The app uses in-memory storage for scan data and snapshots, making a single file approach more efficient for this use case
3. **Development Focus**: The priority was on functionality and demonstrating Flutter's capabilities rather than architectural complexity

### Modular Structure (Planned)

The project includes a complete modular folder structure that has been prepared but is not currently active due to development priorities:

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

The modular structure will be activated in future iterations once the core functionality is fully stabilized.

### Implementation Approach:

1. **Service Layer Pattern**: Each major functionality is encapsulated in a dedicated service class
2. **Stream-Based Architecture**: Real-time data flow using Dart Streams for reactive UI updates
3. **Singleton Services**: Ensures single instances for Bluetooth, Data, and Permission services
4. **Error Handling**: Comprehensive error tracking with type-based categorization
5. **Memory Management**: Automatic cleanup of old data to prevent memory leaks
6. **Platform Abstraction**: Platform-specific code isolated in permission handling

## Edge Cases and Error Handling

The app implements comprehensive error handling and edge case management:

### Error Categories

- **Bluetooth State Errors**: Handles adapter state changes, connection failures, and unsupported devices
- **Permission Errors**: Graceful handling of denied permissions with user guidance and retry mechanisms
- **Memory Errors**: Automatic cleanup when memory usage is high, with configurable limits
- **Platform Errors**: Platform-specific error handling for iOS/Android differences
- **Data Corruption**: Validation and recovery from corrupted scan data with automatic cleanup
- **Network Errors**: Handles connectivity issues during Bluetooth operations
- **Timeout Errors**: Configurable timeouts for all async operations with retry logic

### Edge Case Handling

- **Device Limit Management**: Automatically prunes old device data when exceeding 2000 devices
- **Snapshot Management**: Limits scan snapshots to 50 points for optimal performance
- **Invalid Data Filtering**: Validates RSSI ranges (-100 to 0 dBm) and device identifiers
- **Background/Foreground Transitions**: Proper lifecycle management for scanning continuity
- **Permission Timeouts**: 30-second timeout for permission requests with fallback handling
- **Consecutive Failure Tracking**: Stops scanning after 3 consecutive failures to prevent resource waste
- **Memory Leak Prevention**: Automatic cleanup of error tracking data and old snapshots

### Error Recovery Mechanisms

- **Automatic Retry**: Failed scans are automatically retried with exponential backoff
- **State Recovery**: App state is restored when Bluetooth adapter state changes
- **Data Validation**: All incoming scan data is validated before processing
- **Graceful Degradation**: App continues functioning with reduced features when errors occur

## Battery Optimization

The app implements several battery optimization strategies:

- **Adaptive scanning intervals**: 10-second active scans with 5-minute background intervals
- **Memory management**: Automatic cleanup of old snapshots (max 50) and device data (max 2000 devices)
- **Background processing**: Efficient lifecycle management with app state detection
- **Smart permission handling**: Platform-specific permission requests to avoid unnecessary system calls
- **Error recovery**: Automatic retry logic with exponential backoff for failed scans
- **Data validation**: Prevents memory leaks and data corruption

## Known Issues

### Current Limitations

1. **Single File Architecture**: The app is currently implemented in a single file for development speed, which may impact maintainability for larger teams
2. **Memory Usage**: Large device lists can consume significant memory, though automatic cleanup is implemented
3. **Background Scanning**: iOS background scanning is limited by platform restrictions
4. **Device Persistence**: Device data is not persisted between app sessions (by design for privacy)

### Platform-Specific Issues

**Android:**
- Some devices may require location services to be enabled for Bluetooth scanning
- Background scanning may be affected by device-specific battery optimization settings

**iOS:**
- Background scanning is limited by iOS restrictions
- Permission requests may timeout on slower devices

## Common Issues and Troubleshooting

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

5. **Scan timeout errors**
   - Check Bluetooth adapter state
   - Ensure permissions are granted
   - Restart Bluetooth on the device

6. **Memory errors**
   - App automatically handles cleanup
   - Restart app if issues persist

### Debug Mode

Enable detailed logging by setting `debugMode = true` in `lib/utils/logger.dart`.

## Performance Considerations

- **Memory Management**: Automatic cleanup of old scan data with configurable limits
- **CPU Usage**: Optimized scanning intervals (10s active, 5min background) to minimize battery drain
- **Storage**: Efficient data structures for large device lists with automatic pruning
- **Network**: No internet connectivity required - all data stored locally
- **Error Recovery**: Automatic retry logic with exponential backoff for failed operations
- **Data Validation**: Prevents memory leaks and data corruption with comprehensive validation

## Security

- **Local Data Only**: All data is stored locally on the device
- **No Cloud Sync**: No data is transmitted to external servers
- **Permission Minimalism**: Only requests necessary permissions
- **Secure Storage**: Uses Flutter's secure storage for sensitive data

## Next Steps

### Immediate Priorities

1. **Modular Refactoring**: Activate the prepared modular structure for better maintainability
2. **Data Persistence**: Implement optional local storage for device history
3. **Enhanced Filtering**: Add more advanced filtering options (by device type, manufacturer, etc.)
4. **Export Functionality**: Add ability to export scan data for analysis

### Future Enhancements

1. **Cloud Integration**: Optional cloud sync for cross-device data sharing
2. **Advanced Analytics**: More sophisticated data analysis and reporting
3. **Device Management**: Ability to save and manage favorite devices
4. **Custom Scan Profiles**: User-defined scanning configurations
5. **API Integration**: Connect to external Bluetooth device databases
6. **Machine Learning**: Predictive analytics for device behavior patterns

### Technical Improvements

1. **Performance Optimization**: Further reduce battery consumption and memory usage
2. **Error Handling**: Enhanced error categorization and user guidance
3. **Testing**: Comprehensive unit and integration tests
4. **Documentation**: API documentation and developer guides
5. **Accessibility**: Improved accessibility features for users with disabilities

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the code comments for implementation details
- Create an issue in the repository

---

**Note**: This app requires physical devices for testing as Bluetooth scanning functionality is not available in simulators.
