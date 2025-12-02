# KGiTON BLE SDK Example

Simple example app demonstrating how to use the `kgiton_ble_sdk` package.

## Features Demonstrated

- 🔍 **Scanning**: Scan for BLE devices with optional name filter
- 🔗 **Connection**: Connect and disconnect from devices
- 📋 **Service Discovery**: Discover services and characteristics
- 📖 **Read**: Read characteristic values
- ✍️ **Write**: Write data to characteristics
- 🔔 **Notify**: Subscribe to characteristic notifications

## Getting Started

### Prerequisites

1. **Android Device** with BLE support (API 21+)
2. **Permissions**: The app requests Bluetooth and Location permissions at runtime

### Running the Example

```bash
cd example
flutter pub get
flutter run
```

### Usage

1. **Tap "Scan"** to search for nearby BLE devices
2. **Tap "Connect"** on a device to establish connection
3. **Explore Services** and characteristics
4. **Tap buttons** to read, write, or subscribe to notifications

## Permissions

The app requires these permissions (already configured in AndroidManifest.xml):

- `BLUETOOTH` / `BLUETOOTH_ADMIN` - Basic Bluetooth operations
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` - Android 12+ BLE operations
- `ACCESS_FINE_LOCATION` - Required for BLE scanning on Android

## Screenshots

The example app demonstrates:
- Device list with RSSI values
- Connection status indicator
- Service and characteristic explorer
- Read/Write/Notify operations

## Code Structure

```
lib/
  main.dart - Main example app with:
    - Scan functionality
    - Connection management
    - Service discovery
    - Characteristic operations
```

## Testing with KGiTON Scale

To test with actual KGiTON Scale device:

1. Power on your KGiTON Scale
2. Run the example app
3. Tap "Scan" - the scale should appear as "KGiTON..."
4. Connect to the device
5. Explore weight characteristics and enable notifications

## Notes

- This example is for **Android only** (iOS implementation coming soon)
- Make sure Bluetooth is enabled on your device
- Location services must be enabled for BLE scanning
- Grant all requested permissions for full functionality
