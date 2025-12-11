import Flutter
import UIKit
import CoreBluetooth

public class KgitonBleSdkPlugin: NSObject, FlutterPlugin {
  private var bleManager: BleManager?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "kgiton_ble_sdk", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "kgiton_ble_sdk/events", binaryMessenger: registrar.messenger())
    let instance = KgitonBleSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Initialize BleManager if needed
    if bleManager == nil {
      bleManager = BleManager()
    }
    
    guard let manager = bleManager else {
      result(FlutterError(code: "INITIALIZATION_FAILED", message: "BLE Manager not initialized", details: nil))
      return
    }
    
    switch call.method {
    case "startScan":
      let args = call.arguments as? [String: Any]
      let nameFilter = args?["deviceNameFilter"] as? String
      let timeout = args?["timeoutSeconds"] as? Int ?? 15
      manager.startScan(nameFilter: nameFilter, timeoutSeconds: timeout, result: result)
      
    case "stopScan":
      manager.stopScan(result: result)
      
    case "connect":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "deviceId required", details: nil))
        return
      }
      manager.connect(deviceId: deviceId, result: result)
      
    case "disconnect":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "deviceId required", details: nil))
        return
      }
      manager.disconnect(deviceId: deviceId, result: result)
      
    case "discoverServices":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "deviceId required", details: nil))
        return
      }
      manager.discoverServices(deviceId: deviceId, result: result)
      
    case "setNotify":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            let serviceUuid = args["serviceUuid"] as? String,
            let characteristicUuid = args["characteristicUuid"] as? String,
            let enable = args["enable"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      manager.setNotify(deviceId: deviceId, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid, enable: enable, result: result)
      
    case "write":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            let serviceUuid = args["serviceUuid"] as? String,
            let characteristicUuid = args["characteristicUuid"] as? String,
            let data = args["data"] as? [Int] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      manager.write(deviceId: deviceId, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid, data: data, result: result)
      
    case "read":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            let serviceUuid = args["serviceUuid"] as? String,
            let characteristicUuid = args["characteristicUuid"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
        return
      }
      manager.read(deviceId: deviceId, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid, result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension KgitonBleSdkPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    if bleManager == nil {
      bleManager = BleManager()
    }
    bleManager?.setEventSink(events)
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    bleManager?.setEventSink(nil)
    return nil
  }
}
