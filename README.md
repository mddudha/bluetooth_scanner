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

## 📱 Platform Support

- **Android**: Full support with location permissions
- **iOS**: Full support with Bluetooth permissions
- **macOS**: Supported for development and testing

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

## 🏗️ Architecture

The app follows a modular architecture with separated concerns:

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── scan_snapshot.dart    # Data models
├── screens/
│   └── home_screen.dart      # Main UI
├── services/
│   ├── bluetooth_service.dart    # BLE operations
│   ├── data_service.dart         # Data management
│   └── permission_service.dart   # Permission handling
├── utils/
│   ├── constants.dart        # App constants
│   ├── helpers.dart          # Utility functions
│   └── logger.dart           # Logging utilities
└── widgets/
    ├── chart_widget.dart     # Data visualization
    └── filter_widget.dart    # UI components
```

## 🔋 Battery Optimization

The app implements several battery optimization strategies:

- **Adaptive scanning intervals** based on device activity
- **Efficient data storage** with automatic cleanup
- **Background processing** with minimal resource usage
- **Smart permission handling** to avoid unnecessary requests

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

- **Memory Management**: Automatic cleanup of old scan data
- **CPU Usage**: Optimized scanning intervals to minimize battery drain
- **Storage**: Efficient data structures for large device lists
- **Network**: No internet connectivity required

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
