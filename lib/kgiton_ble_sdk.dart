/// KGiTON BLE SDK
///
/// Minimal BLE SDK for KGiTON Scale devices
library kgiton_ble_sdk;

// Core SDK
export 'src/kgiton_ble_sdk.dart';

// Models
export 'src/models/ble_device.dart';
export 'src/models/ble_service.dart';
export 'src/models/ble_characteristic.dart';
export 'src/models/ble_connection_state.dart';

// Exceptions
export 'src/exceptions/ble_exceptions.dart';

// Utilities
export 'src/utils/retry_policy.dart';
export 'src/utils/connection_stability.dart';
export 'src/utils/data_validation.dart';
