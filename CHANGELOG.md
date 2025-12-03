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

## [1.1.0] - 2025-12-03

### Added - Robustness Improvements 🛡️

#### Error Handling
- **Custom Exception Types**: Comprehensive exception hierarchy
  - `BleException` - Base exception for all BLE errors
  - `BleScanException` - Scan operation failures
  - `BleConnectionException` - Connection failures with device context
  - `BleServiceDiscoveryException` - Service discovery errors
  - `BleCharacteristicException` - Characteristic operation errors
  - `BleTimeoutException` - Operation timeout errors
  - `BleNotAvailableException` - Bluetooth unavailable errors
  - `BlePermissionException` - Permission denial errors
- All exceptions include original error and stack trace for debugging

#### Retry Logic & Resilience
- **RetryPolicy Configuration**: Flexible retry policies
  - Exponential backoff strategy
  - Configurable max attempts (default: 3)
  - Configurable initial delay and backoff multiplier
  - Custom retry conditions with `retryIf` predicate
  - Pre-defined policies: `defaultPolicy`, `aggressivePolicy`, `noRetry`
- **RetryExecutor**: Automatic retry mechanism for all BLE operations
  - Retry with timeout support
  - Smart backoff to prevent overwhelming the device
  - Operation-specific retry configuration

#### Connection Stability
- **Auto-Reconnection**: Automatic reconnection on unexpected disconnect
  - Configurable reconnection attempts (default: 3)
  - Exponential backoff between attempts
  - Reconnection state events
- **Connection Timeout**: Configurable timeout for connection attempts (default: 10s)
- **Keep-Alive Mechanism**: 
  - Periodic ping to detect connection issues
  - Configurable keep-alive interval (default: 30s)
  - Idle timeout detection (default: 60s)
  - Automatic disconnect on connection loss
- **ConnectionConfig**: Three pre-configured profiles
  - `production`: Balanced reliability (auto-reconnect + keep-alive)
  - `development`: Minimal features for testing
  - `aggressive`: Maximum reliability for critical applications

#### Data Validation & Sanitization
- **BleDataValidator**: Comprehensive input validation
  - Device ID format validation (MAC, UUID)
  - UUID format validation (16-bit and 128-bit)
  - Characteristic ID format validation
  - Byte array validation (0-255 range)
  - Timeout duration validation
  - Device name sanitization
- **ChecksumCalculator**: Data integrity verification
  - XOR checksum calculation and validation
  - Sum checksum calculation and validation
  - Automatic checksum appending
- **BleDataSanitizer**: Safe data handling
  - MTU limit enforcement (default: 512 bytes)
  - Null terminator removal
  - Data padding to required length
  - Safe string-to-bytes conversion
  - Safe bytes-to-string with fallback

#### Logging & Debugging
- **Structured Logging**: Optional debug logging
  - Enable/disable logging via constructor
  - Operation tracking (connect, disconnect, read, write, etc.)
  - Error and warning messages
  - Performance tracking
- All critical operations logged for troubleshooting

#### Testing
- **Unit Tests**: 31 tests covering core functionality
  - Data validation tests (10 tests)
  - Checksum calculation tests (4 tests)
  - Data sanitization tests (7 tests)
  - Retry policy tests (5 tests)
  - Connection configuration tests (3 tests)
- **100% pass rate** on all unit tests

### Changed

#### API Improvements
- SDK constructor now accepts configuration parameters:
  ```dart
  KgitonBleSdk({
    ConnectionConfig connectionConfig = ConnectionConfig.production,
    RetryPolicy retryPolicy = RetryPolicy.defaultPolicy,
    bool enableLogging = false,
  })
  ```
- All operations now throw specific exception types instead of generic errors
- Operations automatically include retry logic
- Connection operations include automatic reconnection management

#### Internal Improvements
- All write operations validate and sanitize data before transmission
- All read operations include timeout and retry logic
- Connection state changes trigger reconnection if configured
- Keep-alive automatically starts on successful connection
- Activity tracking for idle timeout detection

### Fixed
- Hardcoded Kotlin version (1.9.22) to prevent gradle dependency errors
- Escaped dollar signs in string interpolation throughout kgiton_scale_service.dart

### Documentation
- Updated exports to include new utilities and exceptions
- Added API documentation for all new classes and methods

## [Unreleased]

### Planned for v1.2.0
- [ ] Complete iOS implementation with CoreBluetooth
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
