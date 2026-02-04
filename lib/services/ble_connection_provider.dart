import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleConnectionProvider extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;
  
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  
  // SOS-specific state
  DateTime? _lastSosTime;
  bool _isSosScreenActive = false;
  
  // Callbacks for UI events
  Function(String signal)? onSignalReceived;
  
  // UUIDs
  static const String SERVICE_UUID = '12345678-04d2-162e-04d2-56789abcdef0';
  static const String NOTIFY_CHAR_UUID = '12345678-04d2-162e-04d2-56789abcdef2';
  static const String WRITE_CHAR_UUID = '12345678-04d2-162e-04d2-56789abcdef1';

  // Getters
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  BluetoothDevice? get device => _device;
  bool get isSosScreenActive => _isSosScreenActive;
  
  /// Connect to a device and setup listeners
  Future<bool> connectToDevice(String deviceId) async {
    try {
      // Disconnect from previous device if any
      await disconnect();
      
      _device = BluetoothDevice.fromId(deviceId);
      
      // Listen to connection state changes
      _connectionSubscription = _device!.connectionState.listen(
        _handleConnectionStateChange,
        onError: (e) => debugPrint('❌ Connection state error: $e'),
      );
      
      // Connect
      await _device!.connect(license: License.free);
      debugPrint('🔗 Connecting to $deviceId...');
      
      // Wait for connection
      await _device!.connectionState
          .firstWhere((state) => state == BluetoothConnectionState.connected)
          .timeout(const Duration(seconds: 10));
      
      // Discover services and setup characteristics
      await _setupCharacteristics();
      
      debugPrint('✅ Connected and listening to $deviceId');
      return true;
      
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      await disconnect();
      return false;
    }
  }
  
  /// Setup BLE characteristics and start listening
  Future<void> _setupCharacteristics() async {
    if (_device == null) return;
    
    try {
      final services = await _device!.discoverServices();
      
      // Reset characteristics
      _notifyCharacteristic = null;
      _writeCharacteristic = null;

      // Find your service and characteristics
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            String charUuid = char.uuid.toString().toLowerCase();
            
            // Notify characteristic (receives data)
            if (charUuid == NOTIFY_CHAR_UUID.toLowerCase()) {
              _notifyCharacteristic = char;
              await char.setNotifyValue(true);
              
              // ⭐ Subscribe to incoming data
              _dataSubscription = char.lastValueStream.listen(
                _handleIncomingData,
                onError: (e) => debugPrint('❌ Data stream error: $e'),
              );
              debugPrint('✅ Notify characteristic set (RX): $charUuid');
            }
            
            // Write characteristic (sends data)
            if (charUuid == WRITE_CHAR_UUID.toLowerCase()) {
              _writeCharacteristic = char;
              debugPrint('✅ Write characteristic set (TX): $charUuid');
            }
          }
        }
      }
      
      if (_notifyCharacteristic == null || _writeCharacteristic == null) {
        // Fallback or error logging
        if (_notifyCharacteristic == null) debugPrint('❌ Notify characteristic not found ($NOTIFY_CHAR_UUID)');
        if (_writeCharacteristic == null) debugPrint('❌ Write characteristic not found ($WRITE_CHAR_UUID)');
        throw Exception('Required characteristics not found');
      }
      
    } catch (e) {
      debugPrint('❌ Setup characteristics failed: $e');
      rethrow;
    }
  }
  
  /// Handle incoming BLE data
  void _handleIncomingData(List<int> data) {
    if (data.isEmpty) return;
    
    final signal = String.fromCharCode(data[0]);
    debugPrint('📥 Received: $signal');
    
    // Handle SOS signal
    if (signal == 'X') {
      _handleSosSignal();
    } else {
      // Notify listeners about other signals
      onSignalReceived?.call(signal);
    }
  }
  
  /// Handle SOS signal with cooldown
  void _handleSosSignal() {
    // Cooldown check: ignore if SOS was triggered recently
    if (_lastSosTime != null) {
      final elapsed = DateTime.now().difference(_lastSosTime!);
      if (elapsed.inSeconds < 3) {
        debugPrint('⏳ SOS ignored - cooldown active (${elapsed.inSeconds}s)');
        return;
      }
    }
    
    // Ignore if SOS screen already active
    if (_isSosScreenActive) {
      debugPrint('⚠️ SOS already active, ignoring');
      return;
    }
    
    _lastSosTime = DateTime.now();
    _isSosScreenActive = true;
    notifyListeners(); // Trigger UI to show SOS screen
  }
  
  /// Trigger SOS Manually (e.g. from App Button)
  void triggerManualSos() {
    _handleSosSignal();
  }

  /// Diagnostic Report to debug BLE state
  Future<void> diagnosticReport() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 BLE DIAGNOSTIC REPORT');
    debugPrint('═══════════════════════════════════════');
    
    if (_device == null) {
      debugPrint('❌ Device: NULL');
      return;
    }
    
    debugPrint('📱 Device: ${_device!.platformName} (${_device!.remoteId})');
    
    // Check connection state
    try {
      final state = await _device!.connectionState.first;
      debugPrint('🔗 Connection: $state');
    } catch (e) {
      debugPrint('🔗 Connection state check failed: $e');
    }
    
    debugPrint('\n📋 Characteristics:');
    
    if (_notifyCharacteristic != null) {
      debugPrint('  ✅ Notify: ${_notifyCharacteristic!.uuid}');
      debugPrint('     Properties: ${_notifyCharacteristic!.properties}');
    } else {
      debugPrint('  ❌ Notify: NULL');
    }
    
    if (_writeCharacteristic != null) {
      debugPrint('  ✅ Write: ${_writeCharacteristic!.uuid}');
      debugPrint('     Properties: ${_writeCharacteristic!.properties}');
      debugPrint('     Can write: ${_writeCharacteristic!.properties.write}');
      debugPrint('     Can write without response: ${_writeCharacteristic!.properties.writeWithoutResponse}');
    } else {
      debugPrint('  ❌ Write: NULL');
    }
    
    debugPrint('\n🚨 SOS State:');
    debugPrint('  Active: $_isSosScreenActive');
    debugPrint('  Last time: $_lastSosTime');
    
    debugPrint('═══════════════════════════════════════\n');
  }

  /// Clear SOS and send acknowledgment
  Future<void> clearSos() async {
    try {
      debugPrint('🚨 clearSos() called');
      await diagnosticReport();
      
      // Validation checks
      if (_writeCharacteristic == null) {
        debugPrint('❌ Write characteristic is null - attempting refresh');
        // Try to recover by rescanning services
        await _setupCharacteristics();
        if (_writeCharacteristic == null) {
           throw Exception('Write characteristic not available even after refresh');
        }
      }
      
      // Prepare data - 'K'
      List<int> bytes = [0x4B]; 
      debugPrint('📤 Preparing to send: K (0x4B)');
      debugPrint('📝 Target Characteristic: ${_writeCharacteristic!.uuid}');
      
      // Determine write mode - prioritize withoutResponse if available (faster/default for this device)
      bool useWriteWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      debugPrint('✍️ Write mode: ${useWriteWithoutResponse ? "WITHOUT response" : "WITH response"}');
      
      // Execute write
      if (useWriteWithoutResponse) {
         await _writeCharacteristic!.write(bytes, withoutResponse: true);
      } else {
         await _writeCharacteristic!.write(bytes, withoutResponse: false);
      }
      
      debugPrint('✅ Sent SOS acknowledgment (K)');
      
      // Small delay to ensure transmission
      await Future.delayed(const Duration(milliseconds: 200));
      
      _isSosScreenActive = false;
      _lastSosTime = DateTime.now(); // Start cooldown
      notifyListeners();
      
      debugPrint('🎉 SOS cleared successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to clear SOS: $e');
      rethrow;
    }
  }
  
  /// Send custom data to device
  Future<void> sendData(String stringData) async {
    if (_writeCharacteristic == null) {
      debugPrint('Write characteristic not available');
      return;
    }
    
    try {
      List<int> bytes = stringData.codeUnits;
       if (_writeCharacteristic!.properties.writeWithoutResponse) {
           await _writeCharacteristic!.write(bytes, withoutResponse: true);
        } else {
           await _writeCharacteristic!.write(bytes, withoutResponse: false);
        }
      debugPrint('✅ Sent: $stringData');
    } catch (e) {
      debugPrint('❌ Write failed: $e');
      rethrow;
    }
  }
  
  /// Handle connection state changes
  void _handleConnectionStateChange(BluetoothConnectionState state) {
    _connectionState = state;
    debugPrint('🔗 Connection state: $state');
    
    if (state == BluetoothConnectionState.disconnected) {
      _cleanup();
    }
    
    notifyListeners();
  }
  
  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      await _connectionSubscription?.cancel();
      
      if (_device != null && isConnected) {
        await _device!.disconnect();
      }
      
      _cleanup();
      debugPrint('🔌 Disconnected');
      
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
  }
  
  /// Cleanup resources
  void _cleanup() {
    _dataSubscription = null;
    _connectionSubscription = null;
    _notifyCharacteristic = null;
    _writeCharacteristic = null;
    _device = null;
    _connectionState = BluetoothConnectionState.disconnected;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
