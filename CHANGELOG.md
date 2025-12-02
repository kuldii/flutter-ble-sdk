# Changelog

All notable changes to the KGiTON BLE SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-02

### Added

#### Core Features
- Initial release of KGiTON BLE SDK
- Bluetooth Low Energy connectivity for KGiTON Scale devices
- Proprietary Commercial License - Authorization required from PT KGiTON

#### Android Platform (✅ Production Ready)
- Full native BLE implementation using Android Bluetooth LE APIs
- Device scanning with optional name filtering
- Device connection and disconnection management
- Service and characteristic discovery
- Characteristic read operations
- Characteristic write operations
- Notification subscription and streaming
- RSSI signal strength monitoring
- Connection state tracking and events
- Thread-safe operation with concurrent device management
- Automatic scan timeout handling
- Memory-efficient device caching

#### iOS Platform (🚧 In Development)
- Basic plugin structure and interface
- Event channel setup
- Placeholder implementations
- *Full CoreBluetooth integration coming in future release*

#### Dart API
- Clean, intuitive API design
- Stream-based reactive programming model
- Strong typing with comprehensive models:
  - `BleDevice` - Represents a Bluetooth device
  - `BleService` - Represents a GATT service
  - `BleCharacteristic` - Represents a GATT characteristic
  - `BleConnectionState` - Connection state enumeration
- Characteristic ID format: `deviceId:serviceUuid:characteristicUuid`
- Multiple simultaneous device connections support
- Resource management with `dispose()` method

#### Documentation
- Comprehensive README with examples
- API reference documentation
- Quick start guide
- Platform configuration instructions
- Best practices and troubleshooting guide
- Architecture documentation

#### Example Application
- Complete example app demonstrating SDK usage
- Device scanning interface
- Connection management
- Service/characteristic browsing
- Read/write/notify operations
- Real-time data monitoring

### Platform Support

| Platform | Version | Status |
|----------|---------|--------|
| Android | API 21+ (Android 5.0+) | ✅ Full Support |
| iOS | iOS 12.0+ | 🚧 In Development |
| Dart | SDK ≥3.10.0 | ✅ |
| Flutter | ≥3.0.0 | ✅ |

### Technical Details

- **Package Size**: ~50 KB
- **Dependencies**: Flutter SDK + plugin_platform_interface only
- **Architecture**: Plugin pattern with platform channels
- **Thread Safety**: Yes (Android)
- **Memory Management**: Automatic cleanup on disconnect

### Known Limitations

- iOS implementation is not yet complete (stub methods only)
- Android-only functionality for current release
- Requires runtime permission handling by application
- BLE 4.2 throughput limitations apply

### Migration Notes

This is the initial release. No migration required.

---

## [Unreleased]

### Planned for v1.1.0
- [ ] Complete iOS implementation with CoreBluetooth
- [ ] Enhanced error handling and error types
- [ ] Connection retry mechanism
- [ ] MTU negotiation support
- [ ] Bond management (pairing)
- [ ] Background operation support

### Planned for v1.2.0
- [ ] BLE 5.0 feature support
- [ ] Extended advertising
- [ ] Multiple advertising sets
- [ ] Periodic advertising sync
- [ ] Performance optimizations

### Planned for Future
- [ ] Unit tests
- [ ] Integration tests
- [ ] CI/CD pipeline
- [ ] Flutter web support consideration
- [ ] Desktop platform support (Windows/macOS/Linux)

---

## Release Information

**Current Stable Version**: 1.0.0  
**Release Date**: December 2, 2025  
**License**: Proprietary Commercial  
**Maintainer**: PT KGiTON

---

## Version History Summary

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-12-02 | Initial commercial release with Android support |

---

For detailed API documentation, see [README.md](README.md).

For support and bug reports, visit: https://github.com/kuldii/flutter-ble-sdk/issues
