import Flutter
import UIKit
import CoreBluetooth

public class KgitonBleSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kgiton_ble_sdk", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "kgiton_ble_sdk/events", binaryMessenger: registrar.messenger())
    let instance = KgitonBleSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
      // TODO: Implement iOS BLE scan
      result(nil)
    case "stopScan":
      result(nil)
    case "connect":
      result(nil)
    case "disconnect":
      result(nil)
    case "discoverServices":
      result([])
    case "setNotify":
      result(nil)
    case "write":
      result(nil)
    case "read":
      result([])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension KgitonBleSdkPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // TODO: Setup event stream
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
