import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGiTON BLE SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bleSdk = KgitonBleSdk();
  final List<BleDevice> _devices = [];
  String? _connectedDeviceId;
  bool _isScanning = false;
  List<BleService> _services = [];
  
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  void _initBle() {
    // Listen to scan results
    _scanSubscription = _bleSdk.scanResults.listen((devices) {
      setState(() {
        _devices.clear();
        _devices.addAll(devices);
      });
    });

    // Listen to connection state
    _connectionSubscription = _bleSdk.connectionState.listen((stateMap) {
      final deviceId = _connectedDeviceId;
      if (deviceId != null && stateMap.containsKey(deviceId)) {
        final state = stateMap[deviceId]!;
        if (state.isDisconnected) {
          setState(() {
            _connectedDeviceId = null;
            _services.clear();
          });
          _showSnackBar('Device disconnected');
        } else if (state.isConnected) {
          _showSnackBar('Device connected');
          _discoverServices(deviceId);
        }
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });
    
    try {
      await _bleSdk.startScan(
        deviceNameFilter: 'KGiTON', // Filter for KGiTON devices
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      _showSnackBar('Scan error: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await _bleSdk.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectDevice(String deviceId) async {
    try {
      await _bleSdk.connect(deviceId);
      setState(() {
        _connectedDeviceId = deviceId;
      });
    } catch (e) {
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDeviceId != null) {
      try {
        await _bleSdk.disconnect(_connectedDeviceId!);
        setState(() {
          _connectedDeviceId = null;
          _services.clear();
        });
      } catch (e) {
        _showSnackBar('Disconnect error: $e');
      }
    }
  }

  Future<void> _discoverServices(String deviceId) async {
    try {
      final services = await _bleSdk.discoverServices(deviceId);
      setState(() {
        _services = services;
      });
    } catch (e) {
      _showSnackBar('Service discovery error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _bleSdk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('KGiTON BLE SDK Example'),
      ),
      body: Column(
        children: [
          // Control Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScan : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _connectedDeviceId != null ? _disconnectDevice : null,
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                    ),
                  ],
                ),
                if (_isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: LinearProgressIndicator(),
                  ),
                if (_connectedDeviceId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Chip(
                      avatar: const Icon(Icons.bluetooth_connected, color: Colors.green),
                      label: Text('Connected: $_connectedDeviceId'),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          
          // Device List
          Expanded(
            child: _connectedDeviceId == null
                ? _buildDeviceList()
                : _buildServiceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No devices found. Tap "Scan" to search.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
          subtitle: Text('ID: ${device.id}\nRSSI: ${device.rssi} dBm'),
          trailing: ElevatedButton(
            onPressed: () => _connectDevice(device.id),
            child: const Text('Connect'),
          ),
        );
      },
    );
  }

  Widget _buildServiceList() {
    if (_services.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: _services.length,
      itemBuilder: (context, serviceIndex) {
        final service = _services[serviceIndex];
        return ExpansionTile(
          leading: const Icon(Icons.settings_bluetooth),
          title: Text('Service'),
          subtitle: Text(service.uuid),
          children: service.characteristics.map((char) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              leading: const Icon(Icons.data_object, size: 20),
              title: Text('Characteristic'),
              subtitle: Text(
                '${char.uuid}\n'
                '${char.canRead ? '📖 Read ' : ''}'
                '${char.canWrite ? '✍️ Write ' : ''}'
                '${char.canNotify ? '🔔 Notify' : ''}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (char.canRead)
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () => _readCharacteristic(char),
                    ),
                  if (char.canWrite)
                    IconButton(
                      icon: const Icon(Icons.upload, size: 20),
                      onPressed: () => _writeCharacteristic(char),
                    ),
                  if (char.canNotify)
                    IconButton(
                      icon: const Icon(Icons.notifications_active, size: 20),
                      onPressed: () => _toggleNotify(char),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _readCharacteristic(BleCharacteristic char) async {
    try {
      final data = await _bleSdk.read(char.id);
      _showSnackBar('Read: ${data.join(', ')}');
    } catch (e) {
      _showSnackBar('Read error: $e');
    }
  }

  Future<void> _writeCharacteristic(BleCharacteristic char) async {
    try {
      // Example: Write [1, 2, 3]
      await _bleSdk.write(char.id, [1, 2, 3]);
      _showSnackBar('Write successful');
    } catch (e) {
      _showSnackBar('Write error: $e');
    }
  }

  Future<void> _toggleNotify(BleCharacteristic char) async {
    try {
      await _bleSdk.setNotify(char.id, true);
      _showSnackBar('Notifications enabled for ${char.uuid}');
      
      // Listen to notifications
      _bleSdk.notificationStream(char.id).listen((data) {
        _showSnackBar('Notification: ${data.join(', ')}');
      });
    } catch (e) {
      _showSnackBar('Notify error: $e');
    }
  }
}
