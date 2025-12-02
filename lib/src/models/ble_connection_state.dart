/// BLE Connection State
enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting;

  bool get isConnected => this == BleConnectionState.connected;
  bool get isDisconnected => this == BleConnectionState.disconnected;
}
