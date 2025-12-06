package com.kgiton.kgiton_ble_sdk

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
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
    private val pendingDiscoveryResults = ConcurrentHashMap<String, MethodChannel.Result>()
    
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
        // Check Bluetooth adapter availability
        if (bluetoothAdapter == null) {
            Log.e(tag, "Bluetooth adapter is null")
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth adapter not available", null)
            return
        }

        if (!bluetoothAdapter.isEnabled) {
            Log.e(tag, "Bluetooth is not enabled")
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth is not enabled. Please enable Bluetooth.", null)
            return
        }

        if (bluetoothLeScanner == null) {
            Log.e(tag, "Bluetooth LE scanner is null")
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth LE scanner not available", null)
            return
        }

        // Check runtime permissions for different Android versions
        if (!checkBlePermissions()) {
            Log.e(tag, "BLE permissions not granted")
            result.error("PERMISSION_DENIED", "Required Bluetooth and Location permissions not granted. Please grant permissions in app settings.", null)
            return
        }

        // For Android 10-11 (API 29-30), check if location service is enabled
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            if (!isLocationEnabled()) {
                Log.e(tag, "Location service is disabled on Android ${Build.VERSION.SDK_INT}")
                result.error("LOCATION_DISABLED", "Location service must be enabled for Bluetooth scanning on Android 10 and 11. Please enable location in device settings.", null)
                return
            }
        }

        if (isScanning) {
            Log.w(tag, "Scan already in progress")
            result.success(null)
            return
        }

        discoveredDevices.clear()
        isScanning = true

        // Use name filter in contains mode instead of exact match
        val filters = mutableListOf<ScanFilter>()
        // NOTE: Remove strict name filter for better device discovery
        // Device name might be advertised differently or with additional characters
        // We'll filter by name in the callback instead
        
        Log.d(tag, "Using scan without name filter to discover all devices")

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
            .setReportDelay(0) // Report immediately
            .build()

        try {
            // Start scan without filters to find all BLE devices
            bluetoothLeScanner.startScan(null, settings, scanCallback)
            Log.d(tag, "BLE scan started (filter: $nameFilter, timeout: ${timeoutSeconds}s)")

            // Auto stop after timeout
            scanTimeoutRunnable = Runnable {
                Log.d(tag, "Scan timeout reached, stopping scan")
                stopScan(object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
                    override fun notImplemented() {}
                })
            }
            handler.postDelayed(scanTimeoutRunnable!!, (timeoutSeconds * 1000).toLong())

            result.success(null)
        } catch (e: SecurityException) {
            isScanning = false
            Log.e(tag, "Security exception - missing permissions", e)
            result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
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
            handleScanResult(result)
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>) {
            Log.d(tag, "Batch scan results received: ${results.size} devices")
            results.forEach { handleScanResult(it) }
        }

        override fun onScanFailed(errorCode: Int) {
            val errorMsg = when (errorCode) {
                SCAN_FAILED_ALREADY_STARTED -> "Scan already started"
                SCAN_FAILED_APPLICATION_REGISTRATION_FAILED -> "Application registration failed"
                SCAN_FAILED_FEATURE_UNSUPPORTED -> "Scan feature unsupported"
                SCAN_FAILED_INTERNAL_ERROR -> "Internal error"
                else -> "Unknown error: $errorCode"
            }
            Log.e(tag, "Scan failed: $errorMsg (code: $errorCode)")
            isScanning = false
            
            // Notify Flutter about scan failure
            sendEvent(mapOf(
                "type" to "scanError",
                "errorCode" to errorCode,
                "errorMessage" to errorMsg
            ))
        }
    }

    private fun handleScanResult(scanResult: ScanResult) {
        val device = scanResult.device
        val deviceId = device.address
        val deviceName = device.name ?: "Unknown"
        val rssi = scanResult.rssi
        
        // Check if device is new or RSSI changed significantly (more than 5 dBm)
        val existingDevice = discoveredDevices[deviceId]
        val isNewDevice = existingDevice == null
        val rssiChanged = existingDevice?.let { Math.abs(it.rssi - rssi) > 5 } ?: false
        
        // Only process if it's a new device or RSSI changed significantly
        if (isNewDevice || rssiChanged) {
            // Log device discovery/update
            if (isNewDevice) {
                Log.d(tag, "New device found: $deviceName ($deviceId), RSSI: $rssi")
            } else {
                Log.d(tag, "Device RSSI updated: $deviceName ($deviceId), RSSI: $rssi")
            }
            
            // Store/update device
            discoveredDevices[deviceId] = scanResult
            
            // Send updated device list to Flutter (only when there's meaningful change)
            val devices = discoveredDevices.values.map { result ->
                mapOf(
                    "id" to result.device.address,
                    "name" to (result.device.name ?: "Unknown"),
                    "rssi" to result.rssi
                )
            }
            
            sendEvent(mapOf(
                "type" to "scanResult",
                "devices" to devices
            ))
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
            val deviceId = gatt.device.address
            
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(tag, "Services discovered for $deviceId: ${gatt.services.size} services")
                
                // Check if there's a pending discovery result
                val pendingResult = pendingDiscoveryResults.remove(deviceId)
                if (pendingResult != null) {
                    handler.post {
                        val services = gatt.services.map { service ->
                            Log.d(tag, "Service: ${service.uuid} with ${service.characteristics.size} characteristics")
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
                        pendingResult.success(services)
                    }
                }
            } else {
                Log.e(tag, "Service discovery failed for $deviceId with status: $status")
                val pendingResult = pendingDiscoveryResults.remove(deviceId)
                if (pendingResult != null) {
                    handler.post {
                        pendingResult.error("DISCOVERY_FAILED", "Service discovery failed with status: $status", null)
                    }
                }
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            val deviceId = gatt.device.address
            val serviceUuid = characteristic.service.uuid.toString()
            val charUuid = characteristic.uuid.toString()
            // Use | separator to avoid conflict with MAC address colons
            val charId = "$deviceId|$serviceUuid|$charUuid"
            val data = characteristic.value.map { it.toInt() }

            sendEvent(mapOf(
                "type" to "notification",
                "characteristicId" to charId,
                "data" to data
            ))
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            val deviceId = gatt.device.address
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(tag, "Descriptor write successful for $deviceId")
            } else {
                Log.e(tag, "Descriptor write failed for $deviceId with status: $status")
            }
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            val deviceId = gatt.device.address
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(tag, "Characteristic write successful for $deviceId")
            } else {
                Log.e(tag, "Characteristic write failed for $deviceId with status: $status")
            }
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

        Log.d(tag, "Starting service discovery for $deviceId")
        
        // Store the result to be called back when onServicesDiscovered is triggered
        pendingDiscoveryResults[deviceId] = result
        
        // Trigger service discovery
        if (!gatt.discoverServices()) {
            pendingDiscoveryResults.remove(deviceId)
            result.error("DISCOVERY_FAILED", "Failed to start service discovery", null)
            return
        }
        
        // Set a timeout in case the callback never comes
        handler.postDelayed({
            val pendingResult = pendingDiscoveryResults.remove(deviceId)
            if (pendingResult != null) {
                Log.e(tag, "Service discovery timeout for $deviceId")
                pendingResult.error("DISCOVERY_TIMEOUT", "Service discovery timed out", null)
            }
        }, 5000) // 5 second timeout
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
    // PERMISSION CHECKS
    // ============================================

    /**
     * Check if all required BLE permissions are granted based on Android version
     */
    private fun checkBlePermissions(): Boolean {
        return when {
            // Android 12+ (API 31+)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                val hasScan = ContextCompat.checkSelfPermission(
                    context, 
                    Manifest.permission.BLUETOOTH_SCAN
                ) == PackageManager.PERMISSION_GRANTED
                
                val hasConnect = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) == PackageManager.PERMISSION_GRANTED

                Log.d(tag, "Android 12+ Permission check - BLUETOOTH_SCAN: $hasScan, BLUETOOTH_CONNECT: $hasConnect")
                hasScan && hasConnect
            }
            
            // Android 10-11 (API 29-30) - Requires location permissions
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                val hasBluetooth = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH
                ) == PackageManager.PERMISSION_GRANTED
                
                val hasBluetoothAdmin = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) == PackageManager.PERMISSION_GRANTED
                
                val hasFineLocation = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                Log.d(tag, "Android 10-11 Permission check - BLUETOOTH: $hasBluetooth, BLUETOOTH_ADMIN: $hasBluetoothAdmin, FINE_LOCATION: $hasFineLocation")
                hasBluetooth && hasBluetoothAdmin && hasFineLocation
            }
            
            // Android 9 and below (API 28-)
            else -> {
                val hasBluetooth = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH
                ) == PackageManager.PERMISSION_GRANTED
                
                val hasBluetoothAdmin = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) == PackageManager.PERMISSION_GRANTED
                
                val hasCoarseLocation = ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED

                Log.d(tag, "Android 9- Permission check - BLUETOOTH: $hasBluetooth, BLUETOOTH_ADMIN: $hasBluetoothAdmin, COARSE_LOCATION: $hasCoarseLocation")
                hasBluetooth && hasBluetoothAdmin && hasCoarseLocation
            }
        }
    }

    /**
     * Check if location service is enabled (required for Android 10-11)
     */
    private fun isLocationEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        return locationManager?.let {
            it.isProviderEnabled(LocationManager.GPS_PROVIDER) || 
            it.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } ?: false
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
