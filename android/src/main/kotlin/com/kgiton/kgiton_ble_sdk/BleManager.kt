package com.kgiton.kgiton_ble_sdk

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@SuppressLint("MissingPermission")
class BleManager(private val context: Context) {
    private val tag = "KgitonBLE"
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val bluetoothLeScanner: BluetoothLeScanner? = bluetoothAdapter?.bluetoothLeScanner
    private val handler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private val connectedDevices = ConcurrentHashMap<String, BluetoothGatt>()
    private val discoveredDevices = mutableMapOf<String, ScanResult>()
    
    private var isScanning = false
    private var scanTimeoutRunnable: Runnable? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    private fun sendEvent(event: Map<String, Any>) {
        handler.post {
            eventSink?.success(event)
        }
    }

    // ============================================
    // SCANNING
    // ============================================

    fun startScan(nameFilter: String?, timeoutSeconds: Int, result: MethodChannel.Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not available or not enabled", null)
            return
        }

        if (isScanning) {
            result.success(null)
            return
        }

        discoveredDevices.clear()
        isScanning = true

        val filters = mutableListOf<ScanFilter>()
        if (!nameFilter.isNullOrEmpty()) {
            filters.add(ScanFilter.Builder().setDeviceName(nameFilter).build())
        }

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            bluetoothLeScanner?.startScan(filters, settings, scanCallback)
            Log.d(tag, "BLE scan started with filter: $nameFilter")

            // Auto stop after timeout
            scanTimeoutRunnable = Runnable {
                stopScan(object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                    override fun notImplemented() {}
                })
            }
            handler.postDelayed(scanTimeoutRunnable!!, (timeoutSeconds * 1000).toLong())

            result.success(null)
        } catch (e: Exception) {
            isScanning = false
            Log.e(tag, "Failed to start scan", e)
            result.error("SCAN_FAILED", e.message, null)
        }
    }

    fun stopScan(result: MethodChannel.Result) {
        if (!isScanning) {
            result.success(null)
            return
        }

        try {
            bluetoothLeScanner?.stopScan(scanCallback)
            isScanning = false
            scanTimeoutRunnable?.let { handler.removeCallbacks(it) }
            Log.d(tag, "BLE scan stopped")
            result.success(null)
        } catch (e: Exception) {
            Log.e(tag, "Failed to stop scan", e)
            result.error("STOP_SCAN_FAILED", e.message, null)
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val deviceId = device.address
            
            discoveredDevices[deviceId] = result
            
            // Send updated device list
            val devices = discoveredDevices.values.map { scanResult ->
                mapOf(
                    "id" to scanResult.device.address,
                    "name" to (scanResult.device.name ?: "Unknown"),
                    "rssi" to scanResult.rssi
                )
            }
            
            sendEvent(mapOf(
                "type" to "scanResult",
                "devices" to devices
            ))
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(tag, "Scan failed with error code: $errorCode")
            isScanning = false
        }
    }

    // ============================================
    // CONNECTION
    // ============================================

    fun connect(deviceId: String, result: MethodChannel.Result) {
        if (connectedDevices.containsKey(deviceId)) {
            result.success(null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(deviceId)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device $deviceId not found", null)
            return
        }

        try {
            sendConnectionState(deviceId, "connecting")
            val gatt = device.connectGatt(context, false, gattCallback)
            connectedDevices[deviceId] = gatt
            result.success(null)
        } catch (e: Exception) {
            Log.e(tag, "Failed to connect to $deviceId", e)
            sendConnectionState(deviceId, "disconnected")
            result.error("CONNECTION_FAILED", e.message, null)
        }
    }

    fun disconnect(deviceId: String, result: MethodChannel.Result) {
        val gatt = connectedDevices[deviceId]
        if (gatt == null) {
            result.success(null)
            return
        }

        try {
            sendConnectionState(deviceId, "disconnecting")
            gatt.disconnect()
            result.success(null)
        } catch (e: Exception) {
            Log.e(tag, "Failed to disconnect from $deviceId", e)
            result.error("DISCONNECT_FAILED", e.message, null)
        }
    }

    private fun sendConnectionState(deviceId: String, state: String) {
        sendEvent(mapOf(
            "type" to "connectionState",
            "deviceId" to deviceId,
            "state" to state
        ))
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val deviceId = gatt.device.address
            
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.d(tag, "Connected to $deviceId")
                    sendConnectionState(deviceId, "connected")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.d(tag, "Disconnected from $deviceId")
                    sendConnectionState(deviceId, "disconnected")
                    gatt.close()
                    connectedDevices.remove(deviceId)
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(tag, "Services discovered for ${gatt.device.address}")
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            val deviceId = gatt.device.address
            val serviceUuid = characteristic.service.uuid.toString()
            val charUuid = characteristic.uuid.toString()
            val charId = "$deviceId:$serviceUuid:$charUuid"
            val data = characteristic.value.map { it.toInt() }

            sendEvent(mapOf(
                "type" to "notification",
                "characteristicId" to charId,
                "data" to data
            ))
        }
    }

    // ============================================
    // SERVICES & CHARACTERISTICS
    // ============================================

    fun discoverServices(deviceId: String, result: MethodChannel.Result) {
        val gatt = connectedDevices[deviceId]
        if (gatt == null) {
            result.error("NOT_CONNECTED", "Device $deviceId is not connected", null)
            return
        }

        // Trigger service discovery
        if (!gatt.discoverServices()) {
            result.error("DISCOVERY_FAILED", "Failed to start service discovery", null)
            return
        }

        // Wait for services to be discovered (callback will be called)
        handler.postDelayed({
            val services = gatt.services.map { service ->
                mapOf(
                    "uuid" to service.uuid.toString(),
                    "characteristics" to service.characteristics.map { char ->
                        mapOf(
                            "uuid" to char.uuid.toString(),
                            "canRead" to (char.properties and BluetoothGattCharacteristic.PROPERTY_READ != 0),
                            "canWrite" to (char.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0),
                            "canNotify" to (char.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0)
                        )
                    }
                )
            }
            result.success(services)
        }, 1000)
    }

    fun setNotify(deviceId: String, serviceUuid: String, charUuid: String, enable: Boolean, result: MethodChannel.Result) {
        val gatt = connectedDevices[deviceId]
        if (gatt == null) {
            result.error("NOT_CONNECTED", "Device $deviceId is not connected", null)
            return
        }

        val service = gatt.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            result.error("SERVICE_NOT_FOUND", "Service $serviceUuid not found", null)
            return
        }

        val characteristic = service.getCharacteristic(UUID.fromString(charUuid))
        if (characteristic == null) {
            result.error("CHARACTERISTIC_NOT_FOUND", "Characteristic $charUuid not found", null)
            return
        }

        try {
            gatt.setCharacteristicNotification(characteristic, enable)
            
            // Enable notification on descriptor
            val descriptor = characteristic.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"))
            if (descriptor != null) {
                descriptor.value = if (enable) {
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                } else {
                    BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                }
                gatt.writeDescriptor(descriptor)
            }
            
            result.success(null)
        } catch (e: Exception) {
            Log.e(tag, "Failed to set notify", e)
            result.error("SET_NOTIFY_FAILED", e.message, null)
        }
    }

    fun write(deviceId: String, serviceUuid: String, charUuid: String, data: List<Int>, result: MethodChannel.Result) {
        val gatt = connectedDevices[deviceId]
        if (gatt == null) {
            result.error("NOT_CONNECTED", "Device $deviceId is not connected", null)
            return
        }

        val service = gatt.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            result.error("SERVICE_NOT_FOUND", "Service $serviceUuid not found", null)
            return
        }

        val characteristic = service.getCharacteristic(UUID.fromString(charUuid))
        if (characteristic == null) {
            result.error("CHARACTERISTIC_NOT_FOUND", "Characteristic $charUuid not found", null)
            return
        }

        try {
            val bytes = data.map { it.toByte() }.toByteArray()
            characteristic.value = bytes
            gatt.writeCharacteristic(characteristic)
            result.success(null)
        } catch (e: Exception) {
            Log.e(tag, "Failed to write", e)
            result.error("WRITE_FAILED", e.message, null)
        }
    }

    fun read(deviceId: String, serviceUuid: String, charUuid: String, result: MethodChannel.Result) {
        val gatt = connectedDevices[deviceId]
        if (gatt == null) {
            result.error("NOT_CONNECTED", "Device $deviceId is not connected", null)
            return
        }

        val service = gatt.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            result.error("SERVICE_NOT_FOUND", "Service $serviceUuid not found", null)
            return
        }

        val characteristic = service.getCharacteristic(UUID.fromString(charUuid))
        if (characteristic == null) {
            result.error("CHARACTERISTIC_NOT_FOUND", "Characteristic $charUuid not found", null)
            return
        }

        try {
            gatt.readCharacteristic(characteristic)
            // Result will be returned in callback
            result.success(characteristic.value.map { it.toInt() })
        } catch (e: Exception) {
            Log.e(tag, "Failed to read", e)
            result.error("READ_FAILED", e.message, null)
        }
    }

    // ============================================
    // CLEANUP
    // ============================================

    fun cleanup() {
        try {
            if (isScanning) {
                bluetoothLeScanner?.stopScan(scanCallback)
            }
            
            connectedDevices.values.forEach { gatt ->
                try {
                    gatt.disconnect()
                    gatt.close()
                } catch (e: Exception) {
                    Log.e(tag, "Error closing gatt", e)
                }
            }
            
            connectedDevices.clear()
            discoveredDevices.clear()
        } catch (e: Exception) {
            Log.e(tag, "Error during cleanup", e)
        }
    }
}
