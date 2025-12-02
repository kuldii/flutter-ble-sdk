package com.kgiton.kgiton_ble_sdk

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class KgitonBleSdkPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bleManager: BleManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kgiton_ble_sdk")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "kgiton_ble_sdk/events")
        
        bleManager = BleManager(flutterPluginBinding.applicationContext)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                bleManager.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                bleManager.setEventSink(null)
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScan" -> {
                val filter = call.argument<String?>("deviceNameFilter")
                val timeout = call.argument<Int>("timeoutSeconds") ?: 15
                bleManager.startScan(filter, timeout, result)
            }
            "stopScan" -> {
                bleManager.stopScan(result)
            }
            "connect" -> {
                val deviceId = call.argument<String>("deviceId")!!
                bleManager.connect(deviceId, result)
            }
            "disconnect" -> {
                val deviceId = call.argument<String>("deviceId")!!
                bleManager.disconnect(deviceId, result)
            }
            "discoverServices" -> {
                val deviceId = call.argument<String>("deviceId")!!
                bleManager.discoverServices(deviceId, result)
            }
            "setNotify" -> {
                val deviceId = call.argument<String>("deviceId")!!
                val serviceUuid = call.argument<String>("serviceUuid")!!
                val charUuid = call.argument<String>("characteristicUuid")!!
                val enable = call.argument<Boolean>("enable")!!
                bleManager.setNotify(deviceId, serviceUuid, charUuid, enable, result)
            }
            "write" -> {
                val deviceId = call.argument<String>("deviceId")!!
                val serviceUuid = call.argument<String>("serviceUuid")!!
                val charUuid = call.argument<String>("characteristicUuid")!!
                val data = call.argument<List<Int>>("data")!!
                bleManager.write(deviceId, serviceUuid, charUuid, data, result)
            }
            "read" -> {
                val deviceId = call.argument<String>("deviceId")!!
                val serviceUuid = call.argument<String>("serviceUuid")!!
                val charUuid = call.argument<String>("characteristicUuid")!!
                bleManager.read(deviceId, serviceUuid, charUuid, result)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        bleManager.cleanup()
    }
}
