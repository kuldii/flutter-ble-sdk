import Foundation
import CoreBluetooth
import Flutter

class BleManager: NSObject {
    private var centralManager: CBCentralManager?
    private var eventSink: FlutterEventSink?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    private var peripheralDelegates: [String: PeripheralDelegate] = [:]
    
    private var isScanning = false
    private var scanTimer: Timer?
    private var deviceNameFilter: String?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }
    
    private func sendEvent(_ event: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
    
    // MARK: - Scanning
    
    func startScan(nameFilter: String?, timeoutSeconds: Int, result: @escaping FlutterResult) {
        guard let centralManager = centralManager else {
            result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth manager not initialized", details: nil))
            return
        }
        
        guard centralManager.state == .poweredOn else {
            result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is not powered on. Current state: \(centralManager.state.rawValue)", details: nil))
            return
        }
        
        if isScanning {
            result(nil)
            return
        }
        
        deviceNameFilter = nameFilter
        discoveredPeripherals.removeAll()
        isScanning = true
        
        // Start scanning for all peripherals
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        print("[KgitonBLE] Started scanning (filter: \(nameFilter ?? "none"), timeout: \(timeoutSeconds)s)")
        
        // Auto stop after timeout
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeoutSeconds), repeats: false) { [weak self] _ in
            self?.stopScan { _ in }
        }
        
        result(nil)
    }
    
    func stopScan(result: @escaping FlutterResult) {
        guard isScanning else {
            result(nil)
            return
        }
        
        centralManager?.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
        print("[KgitonBLE] Stopped scanning")
        result(nil)
    }
    
    // MARK: - Connection
    
    func connect(deviceId: String, result: @escaping FlutterResult) {
        guard let peripheral = discoveredPeripherals[deviceId] ?? connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found: \(deviceId)", details: nil))
            return
        }
        
        guard let centralManager = centralManager else {
            result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth manager not initialized", details: nil))
            return
        }
        
        let delegate = PeripheralDelegate(bleManager: self)
        peripheralDelegates[deviceId] = delegate
        peripheral.delegate = delegate
        
        centralManager.connect(peripheral, options: nil)
        print("[KgitonBLE] Connecting to device: \(deviceId)")
        
        result(nil)
    }
    
    func disconnect(deviceId: String, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not connected: \(deviceId)", details: nil))
            return
        }
        
        centralManager?.cancelPeripheralConnection(peripheral)
        print("[KgitonBLE] Disconnecting from device: \(deviceId)")
        
        result(nil)
    }
    
    // MARK: - Services & Characteristics
    
    func discoverServices(deviceId: String, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_CONNECTED", message: "Device not connected: \(deviceId)", details: nil))
            return
        }
        
        // Store result callback in delegate
        if let delegate = peripheralDelegates[deviceId] {
            delegate.discoverServicesResult = result
        }
        
        peripheral.discoverServices(nil)
        print("[KgitonBLE] Discovering services for device: \(deviceId)")
    }
    
    func setNotify(deviceId: String, serviceUuid: String, characteristicUuid: String, enable: Bool, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_CONNECTED", message: "Device not connected", details: nil))
            return
        }
        
        guard let characteristic = findCharacteristic(peripheral: peripheral, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid) else {
            result(FlutterError(code: "CHARACTERISTIC_NOT_FOUND", message: "Characteristic not found", details: nil))
            return
        }
        
        peripheral.setNotifyValue(enable, for: characteristic)
        print("[KgitonBLE] Set notify \(enable) for characteristic: \(characteristicUuid)")
        
        result(nil)
    }
    
    func write(deviceId: String, serviceUuid: String, characteristicUuid: String, data: [Int], result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_CONNECTED", message: "Device not connected", details: nil))
            return
        }
        
        guard let characteristic = findCharacteristic(peripheral: peripheral, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid) else {
            result(FlutterError(code: "CHARACTERISTIC_NOT_FOUND", message: "Characteristic not found", details: nil))
            return
        }
        
        let bytes = data.map { UInt8($0) }
        let writeData = Data(bytes)
        
        peripheral.writeValue(writeData, for: characteristic, type: .withResponse)
        print("[KgitonBLE] Writing \(bytes.count) bytes to characteristic: \(characteristicUuid)")
        
        result(nil)
    }
    
    func read(deviceId: String, serviceUuid: String, characteristicUuid: String, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripherals[deviceId] else {
            result(FlutterError(code: "DEVICE_NOT_CONNECTED", message: "Device not connected", details: nil))
            return
        }
        
        guard let characteristic = findCharacteristic(peripheral: peripheral, serviceUuid: serviceUuid, characteristicUuid: characteristicUuid) else {
            result(FlutterError(code: "CHARACTERISTIC_NOT_FOUND", message: "Characteristic not found", details: nil))
            return
        }
        
        // Store result callback in delegate
        if let delegate = peripheralDelegates[deviceId] {
            delegate.readResults[characteristicUuid] = result
        }
        
        peripheral.readValue(for: characteristic)
        print("[KgitonBLE] Reading from characteristic: \(characteristicUuid)")
    }
    
    // MARK: - Helper Methods
    
    private func findCharacteristic(peripheral: CBPeripheral, serviceUuid: String, characteristicUuid: String) -> CBCharacteristic? {
        guard let services = peripheral.services else { return nil }
        
        for service in services {
            if service.uuid.uuidString.lowercased() == serviceUuid.lowercased() {
                guard let characteristics = service.characteristics else { continue }
                
                for characteristic in characteristics {
                    if characteristic.uuid.uuidString.lowercased() == characteristicUuid.lowercased() {
                        return characteristic
                    }
                }
            }
        }
        
        return nil
    }
    
    func cleanup() {
        stopScan { _ in }
        
        for (_, peripheral) in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        
        connectedPeripherals.removeAll()
        peripheralDelegates.removeAll()
        discoveredPeripherals.removeAll()
    }
}

// MARK: - CBCentralManagerDelegate

extension BleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[KgitonBLE] Bluetooth state: \(central.state.rawValue)")
        
        var stateString: String
        switch central.state {
        case .poweredOn:
            stateString = "poweredOn"
        case .poweredOff:
            stateString = "poweredOff"
        case .resetting:
            stateString = "resetting"
        case .unauthorized:
            stateString = "unauthorized"
        case .unsupported:
            stateString = "unsupported"
        case .unknown:
            stateString = "unknown"
        @unknown default:
            stateString = "unknown"
        }
        
        sendEvent([
            "type": "bluetoothState",
            "state": stateString
        ])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        
        // Apply name filter if specified
        if let filter = deviceNameFilter, !filter.isEmpty {
            if !deviceName.lowercased().contains(filter.lowercased()) {
                return
            }
        }
        
        // Store peripheral
        discoveredPeripherals[deviceId] = peripheral
        
        print("[KgitonBLE] Discovered device: \(deviceName) (\(deviceId))")
        
        // Send discovery event
        sendEvent([
            "type": "deviceDiscovered",
            "deviceId": deviceId,
            "name": deviceName,
            "rssi": RSSI.intValue
        ])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString
        
        connectedPeripherals[deviceId] = peripheral
        
        print("[KgitonBLE] Connected to device: \(deviceId)")
        
        sendEvent([
            "type": "connectionState",
            "deviceId": deviceId,
            "state": "connected"
        ])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        
        connectedPeripherals.removeValue(forKey: deviceId)
        peripheralDelegates.removeValue(forKey: deviceId)
        
        print("[KgitonBLE] Disconnected from device: \(deviceId)")
        
        sendEvent([
            "type": "connectionState",
            "deviceId": deviceId,
            "state": "disconnected"
        ])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        
        print("[KgitonBLE] Failed to connect to device: \(deviceId), error: \(error?.localizedDescription ?? "unknown")")
        
        sendEvent([
            "type": "connectionState",
            "deviceId": deviceId,
            "state": "disconnected"
        ])
    }
}

// MARK: - PeripheralDelegate

class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    weak var bleManager: BleManager?
    var discoverServicesResult: FlutterResult?
    var readResults: [String: FlutterResult] = [:]
    
    init(bleManager: BleManager) {
        self.bleManager = bleManager
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("[KgitonBLE] Error discovering services: \(error.localizedDescription)")
            discoverServicesResult?(FlutterError(code: "DISCOVER_FAILED", message: error.localizedDescription, details: nil))
            discoverServicesResult = nil
            return
        }
        
        guard let services = peripheral.services else {
            discoverServicesResult?([])
            discoverServicesResult = nil
            return
        }
        
        // Discover characteristics for each service
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("[KgitonBLE] Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        // Check if all services have been processed
        guard let services = peripheral.services else { return }
        
        var allCharacteristicsDiscovered = true
        for svc in services {
            if svc.characteristics == nil {
                allCharacteristicsDiscovered = false
                break
            }
        }
        
        // If all characteristics discovered, send result
        if allCharacteristicsDiscovered {
            let servicesData = services.map { service -> [String: Any] in
                let characteristics = service.characteristics?.map { char -> [String: Any] in
                    var properties: [String] = []
                    if char.properties.contains(.read) { properties.append("read") }
                    if char.properties.contains(.write) { properties.append("write") }
                    if char.properties.contains(.writeWithoutResponse) { properties.append("writeWithoutResponse") }
                    if char.properties.contains(.notify) { properties.append("notify") }
                    if char.properties.contains(.indicate) { properties.append("indicate") }
                    
                    return [
                        "uuid": char.uuid.uuidString,
                        "properties": properties
                    ]
                } ?? []
                
                return [
                    "uuid": service.uuid.uuidString,
                    "isPrimary": service.isPrimary,
                    "characteristics": characteristics
                ]
            }
            
            discoverServicesResult?(servicesData)
            discoverServicesResult = nil
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let charUuid = characteristic.uuid.uuidString
        
        if let error = error {
            print("[KgitonBLE] Error reading characteristic: \(error.localizedDescription)")
            readResults[charUuid]?(FlutterError(code: "READ_FAILED", message: error.localizedDescription, details: nil))
            readResults.removeValue(forKey: charUuid)
            return
        }
        
        guard let data = characteristic.value else {
            // If this was a read operation, return empty data
            if let result = readResults[charUuid] {
                result([])
                readResults.removeValue(forKey: charUuid)
            }
            return
        }
        
        let bytes = [UInt8](data)
        
        // If this was a read operation, return the data
        if let result = readResults[charUuid] {
            result(bytes)
            readResults.removeValue(forKey: charUuid)
            return
        }
        
        // Otherwise, it's a notification
        bleManager?.sendEvent([
            "type": "characteristicChanged",
            "deviceId": peripheral.identifier.uuidString,
            "characteristicUuid": charUuid,
            "data": bytes
        ])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[KgitonBLE] Error writing characteristic: \(error.localizedDescription)")
        } else {
            print("[KgitonBLE] Successfully wrote to characteristic: \(characteristic.uuid.uuidString)")
        }
    }
}
