# KGiTON BLE SDK Example

Simple example app demonstrating how to use the `kgiton_ble_sdk` package.

## Features Demonstrated

- 🔍 **Scanning**: Scan for BLE devices with customizable name filter
- 🔗 **Connection**: Connect and disconnect from devices
- 📋 **Service Discovery**: Discover services and characteristics
- 📖 **Read**: Read characteristic values
- ✍️ **Write**: Write text data to characteristics with input dialog
- 🔔 **Notify**: Subscribe to characteristic notifications
- 🔐 **Permissions**: Automatic runtime permission handling
- ⚙️ **Settings**: Quick access to app settings for permissions

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

1. **Grant Permissions**: The app will request necessary permissions on first launch
2. **Set Filter** (optional): Enter device name to filter scan results (e.g., "KGiTON")
3. **Tap "Scan"** to search for nearby BLE devices
4. **Tap "Connect"** on a device to establish connection
5. **Explore Services** and characteristics
6. **Interact**: 
   - Tap 📖 to read values
   - Tap ✍️ to write text (dialog will appear)
   - Tap 🔔 to enable notifications

## Permissions

The app automatically requests these permissions at runtime:

- `BLUETOOTH_SCAN` - Scan for BLE devices (Android 12+)
- `BLUETOOTH_CONNECT` - Connect to BLE devices (Android 12+)
- `ACCESS_FINE_LOCATION` - Required for BLE scanning on Android

**Note**: If permissions are denied permanently, the app provides a direct link to app settings.

## Features in Detail

### Permission Handling
- Automatic permission check on app start
- Runtime permission request with user-friendly dialogs
- Direct link to app settings for permanently denied permissions
- Visual permission status indicator

### Device Scanning
- Customizable device name filter
- Real-time device list updates
- RSSI signal strength display
- Clear/reset filter option

### Write Operations
- Interactive text input dialog
- Automatic text-to-bytes conversion
- Success/error feedback via SnackBar
- Example: Write "BUZZ" to trigger buzzer on KGiTON scale

### Service Explorer
- Expandable service list
- Characteristic properties display (Read/Write/Notify)
- Direct operation buttons for each capability
- UUID information for debugging

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
