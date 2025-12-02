# KGiTON BLE SDK

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)](https://github.com/kuldii/flutter-ble-sdk)

Official Bluetooth Low Energy SDK for KGiTON Scale devices.

## Overview

**KGiTON BLE SDK** is a lightweight, production-ready Flutter plugin for connecting to KGiTON Scale devices via Bluetooth Low Energy. Built with native Android and iOS implementations for optimal performance.

### Key Features

- 🔷 **Minimal & Lightweight** - Small footprint (~50KB)
- 🔐 **Commercial License** - Proprietary software by PT KGiTON
- 📱 **Native Performance** - Direct Android/iOS BLE API integration
- 🎯 **Purpose-Built** - Optimized specifically for KGiTON Scale devices
- 🔄 **Reactive Streams** - Modern Dart Stream-based API
- ⚡ **Production Ready** - Tested and reliable

## Platform Support

| Platform | Status | Version |
|----------|--------|---------|
| Android | ✅ Full Support | API 21+ |
| iOS | 🚧 In Development | iOS 12+ |

## Installation

⚠️ **IMPORTANT**: This SDK requires authorization from PT KGiTON.

📋 **[Read Authorization Guide](AUTHORIZATION.md)** for licensing information.

### For Authorized Users

Contact PT KGiTON for access credentials, then add to your `pubspec.yaml`:

```yaml
dependencies:
  kgiton_ble_sdk:
    git:
      url: https://github.com/kuldii/flutter-ble-sdk.git
      # Use provided access token
```

Then run:

```bash
flutter pub get
```

### License Required

To obtain a license and access credentials:
- Email: support@kgiton.com
- Subject: "KGiTON BLE SDK License Request"
- Include: Company name, intended use case, contact information

## Platform Configuration

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    
    <!-- Declare BLE requirement -->
    <uses-feature 
        android:name="android.hardware.bluetooth_le" 
        android:required="true" />
    
    <application>
        ...
    </application>
</manifest>
```

**Minimum SDK**: API 21 (Android 5.0)

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to KGiTON Scale devices</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location permission for Bluetooth scanning</string>
```

**Minimum Version**: iOS 12.0

## Quick Start

```dart
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

// Initialize SDK
final ble = KgitonBleSdk();

// Scan for KGiTON devices
ble.scanResults.listen((devices) {
  for (var device in devices) {
    print('Found: ${device.name} (${device.rssi} dBm)');
  }
});

await ble.startScan(
  deviceNameFilter: 'KGiTON',
  timeout: Duration(seconds: 10),
);

// Connect to device
await ble.connect(deviceId);

// Monitor connection state
ble.connectionState.listen((states) {
  print('Connection state: ${states[deviceId]}');
});

// Discover services
final services = await ble.discoverServices(deviceId);

// Enable notifications
String charId = '$deviceId:$serviceUuid:$characteristicUuid';
await ble.setNotify(charId, true);

// Listen to notifications
ble.notificationStream(charId).listen((data) {
  print('Received: ${String.fromCharCodes(data)}');
});

// Write data
await ble.write(charId, 'HELLO'.codeUnits);

// Read data
List<int> data = await ble.read(charId);

// Disconnect
await ble.disconnect(deviceId);

// Cleanup
ble.dispose();
```

## API Documentation

### Core Class: `KgitonBleSdk`

#### Scanning Methods

| Method | Description |
|--------|-------------|
| `startScan({String? deviceNameFilter, Duration? timeout})` | Start BLE device scanning with optional name filter |
| `stopScan()` | Stop active scanning |
| `scanResults` → `Stream<List<BleDevice>>` | Stream of discovered devices |

#### Connection Methods

| Method | Description |
|--------|-------------|
| `connect(String deviceId)` | Connect to a BLE device |
| `disconnect(String deviceId)` | Disconnect from a BLE device |
| `getConnectionState(String deviceId)` → `BleConnectionState` | Get current connection state |
| `connectionState` → `Stream<Map<String, BleConnectionState>>` | Stream of connection state changes |

#### Service & Characteristic Methods

| Method | Description |
|--------|-------------|
| `discoverServices(String deviceId)` → `Future<List<BleService>>` | Discover all services and characteristics |
| `getCharacteristic(String deviceId, String serviceUuid, String charUuid)` | Get specific characteristic |

#### Data Operations

| Method | Description |
|--------|-------------|
| `read(String characteristicId)` → `Future<List<int>>` | Read data from characteristic |
| `write(String characteristicId, List<int> data)` | Write data to characteristic |
| `setNotify(String characteristicId, bool enable)` | Enable/disable notifications |
| `notificationStream(String characteristicId)` → `Stream<List<int>>` | Stream of notification data |

#### Lifecycle

| Method | Description |
|--------|-------------|
| `dispose()` | Clean up all resources and close streams |

### Data Models

#### `BleDevice`

```dart
class BleDevice {
  final String id;        // Device MAC address or UUID
  final String name;      // Device name
  final int rssi;         // Signal strength (dBm)
}
```

#### `BleService`

```dart
class BleService {
  final String uuid;                            // Service UUID
  final List<BleCharacteristic> characteristics; // List of characteristics
}
```

#### `BleCharacteristic`

```dart
class BleCharacteristic {
  final String uuid;         // Characteristic UUID
  final String serviceUuid;  // Parent service UUID
  final bool canRead;        // Supports read operation
  final bool canWrite;       // Supports write operation
  final bool canNotify;      // Supports notifications
}
```

#### `BleConnectionState`

```dart
enum BleConnectionState {
  disconnected,   // Not connected
  connecting,     // Connection in progress
  connected,      // Successfully connected
  disconnecting,  // Disconnection in progress
}
```

## Usage Examples

### Example 1: Simple Device Scanner

```dart
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

class DeviceScanner {
  final ble = KgitonBleSdk();
  
  Future<void> scanDevices() async {
    // Listen to scan results
    ble.scanResults.listen((devices) {
      print('Found ${devices.length} devices');
      for (var device in devices) {
        print('- ${device.name}: ${device.id}');
      }
    });
    
    // Start scanning with filter
    await ble.startScan(
      deviceNameFilter: 'KGiTON',
      timeout: Duration(seconds: 15),
    );
  }
  
  void dispose() {
    ble.dispose();
  }
}
```

### Example 2: Connect and Read Data

```dart
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

class ScaleConnection {
  final ble = KgitonBleSdk();
  
  Future<void> connectAndRead(String deviceId) async {
    // Connect
    await ble.connect(deviceId);
    
    // Wait for connection
    await ble.connectionState.firstWhere(
      (states) => states[deviceId] == BleConnectionState.connected,
    );
    
    // Discover services
    final services = await ble.discoverServices(deviceId);
    print('Found ${services.length} services');
    
    // Find and read from a characteristic
    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.canRead) {
          String charId = '$deviceId:${service.uuid}:${char.uuid}';
          List<int> data = await ble.read(charId);
          print('Read: ${String.fromCharCodes(data)}');
        }
      }
    }
    
    // Disconnect
    await ble.disconnect(deviceId);
  }
}
```

### Example 3: Real-time Weight Monitoring

```dart
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

class WeightMonitor {
  final ble = KgitonBleSdk();
  
  Future<void> startMonitoring(
    String deviceId,
    String serviceUuid,
    String characteristicUuid,
  ) async {
    // Connect to device
    await ble.connect(deviceId);
    
    // Discover services
    await ble.discoverServices(deviceId);
    
    // Build characteristic ID
    String charId = '$deviceId:$serviceUuid:$characteristicUuid';
    
    // Listen to weight updates
    ble.notificationStream(charId).listen((data) {
      String weight = String.fromCharCodes(data);
      print('Weight: $weight kg');
    });
    
    // Enable notifications
    await ble.setNotify(charId, true);
    
    print('Monitoring started...');
  }
  
  Future<void> stopMonitoring(String deviceId) async {
    await ble.disconnect(deviceId);
    ble.dispose();
  }
}
```

## Error Handling

Always wrap BLE operations in try-catch blocks:

```dart
try {
  await ble.connect(deviceId);
} catch (e) {
  print('Connection failed: $e');
}

try {
  await ble.write(charId, data);
} catch (e) {
  print('Write failed: $e');
}
```

## Best Practices

1. **Always dispose**: Call `ble.dispose()` when done to free resources
2. **Check permissions**: Request Bluetooth and location permissions at runtime
3. **Handle disconnections**: Listen to `connectionState` stream for unexpected disconnects
4. **Timeout scans**: Always set a timeout for scanning operations
5. **Validate UUIDs**: Ensure service and characteristic UUIDs are correct
6. **Test on real devices**: BLE emulators have limitations

## Troubleshooting

### Android Issues

**Problem**: Scan returns no devices

**Solution**: 
- Check permissions are granted at runtime
- Ensure Bluetooth is enabled
- Verify location services are enabled (required for BLE scanning)

**Problem**: Connection fails immediately

**Solution**:
- Check device is in range and powered on
- Verify device is not connected to another app
- Try removing and re-pairing the device

### iOS Issues

**Problem**: iOS implementation not complete

**Solution**: 
- iOS support is currently in development
- Android implementation is fully functional and production-ready

## Architecture

```
┌─────────────────────────────────────┐
│         Flutter Application         │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       KgitonBleSdk (Dart)           │
│  • Streams                          │
│  • State Management                 │
│  • API Layer                        │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│    Platform Interface (Dart)        │
│  • Abstract Methods                 │
│  • MethodChannel Bridge             │
└────────────┬────────────┬───────────┘
             │            │
    ┌────────▼─────┐  ┌──▼──────────┐
    │   Android    │  │     iOS     │
    │  BleManager  │  │ (Stub)      │
    │  (Kotlin)    │  │ (Swift)     │
    └────────┬─────┘  └──┬──────────┘
             │            │
    ┌────────▼─────┐  ┌──▼──────────┐
    │  Android     │  │ CoreBluetooth│
    │  BLE API     │  │   Framework  │
    └──────────────┘  └──────────────┘
```

## Performance

- **Scan Latency**: < 1 second to detect nearby devices
- **Connection Time**: 1-3 seconds typical
- **Data Throughput**: Up to 20 KB/s (BLE 4.2 limit)
- **Memory Footprint**: < 2 MB runtime
- **Package Size**: ~50 KB

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Contributing

⚠️ **Closed Source Project**

This is proprietary software. External contributions are not accepted.

For bug reports or feature requests from authorized users:
1. Contact PT KGiTON support team
2. Provide detailed description and use case
3. Include your license information

## License

**PROPRIETARY SOFTWARE - ALL RIGHTS RESERVED**

This software is the proprietary property of PT KGiTON and is protected by copyright law.

### Usage Restrictions

- ❌ **NOT Open Source** - Source code is confidential
- ❌ **NOT Free to Use** - Requires explicit authorization from PT KGiTON
- ❌ **NO Redistribution** - Cannot be shared or distributed
- ❌ **NO Modifications** - Cannot be altered or reverse-engineered
- ✅ **Commercial License Available** - Contact PT KGiTON for licensing

### License Summary

Copyright (c) 2025 PT KGiTON. All Rights Reserved.

This SDK may only be used by individuals or organizations explicitly authorized 
by PT KGiTON. Unauthorized use, reproduction, or distribution is strictly 
prohibited and may result in legal action.

See [LICENSE](LICENSE) file for complete terms and conditions.

## Support

- **GitHub**: https://github.com/kuldii/flutter-ble-sdk
- **Issues**: https://github.com/kuldii/flutter-ble-sdk/issues
- **Email**: support@kgiton.com
- **Website**: https://kgiton.com

## About PT KGiTON

PT KGiTON is a leading provider of smart scale solutions for industrial and commercial applications. Our products combine precision measurement with modern connectivity.

---

**Made with ❤️ by PT KGiTON**

*Version 1.0.0 - December 2, 2025*
