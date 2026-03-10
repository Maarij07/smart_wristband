import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'ble_foreground_service.dart';

class BleConnectionProvider extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  // Auto-reconnect state
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _savedDeviceId;
  bool _userDisconnected = false; // Distinguishes intentional vs dropped disconnects

  // SOS-specific state
  DateTime? _lastSosTime;
  bool _isSosScreenActive = false;

  // Callbacks for UI events
  Function(String signal)? onSignalReceived;

  // UUIDs
  static const String SERVICE_UUID = '12345678-04d2-162e-04d2-56789abcdef0';
  static const String NOTIFY_CHAR_UUID = '12345678-04d2-162e-04d2-56789abcdef2';
  static const String WRITE_CHAR_UUID = '12345678-04d2-162e-04d2-56789abcdef1';

  static const String _prefDeviceIdKey = 'ble_device_id';

  // Getters
  bool get isConnected =>
      _connectionState == BluetoothConnectionState.connected;
  BluetoothDevice? get device => _device;
  bool get isSosScreenActive => _isSosScreenActive;
  bool get isReconnecting =>
      _reconnectTimer != null && _reconnectTimer!.isActive;

  // ─────────────────────────────────────────────────────────────────────────
  // Persistence helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDeviceIdKey, id);
    _savedDeviceId = id;
  }

  Future<void> _clearSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDeviceIdKey);
    _savedDeviceId = null;
  }

  Future<String?> _loadSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefDeviceIdKey);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API: auto-reconnect on app startup
  // ─────────────────────────────────────────────────────────────────────────

  /// Called once from main.dart after the app is ready.
  /// Loads the last connected device ID and tries to reconnect.
  Future<void> attemptAutoReconnect() async {
    final savedId = await _loadSavedDeviceId();
    if (savedId == null) {
      debugPrint('📭 No saved device ID — skipping auto-reconnect');
      return;
    }

    debugPrint('📱 Saved device found: $savedId — attempting auto-reconnect');
    _savedDeviceId = savedId;
    _reconnectAttempts = 0;
    _userDisconnected = false;
    await connectToDevice(savedId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection management
  // ─────────────────────────────────────────────────────────────────────────

  /// Initialize connection state from an already-connected device
  /// (called from ConnectWristbandScreen after it physically connects).
  Future<void> initializeConnectionFromDevice(
      BluetoothDevice connectedDevice) async {
    try {
      _device = connectedDevice;
      _userDisconnected = false;

      _connectionSubscription = _device!.connectionState.listen(
        _handleConnectionStateChange,
        onError: (e) => debugPrint('❌ Connection state error: $e'),
      );

      final currentState = await _device!.connectionState.first;
      _connectionState = currentState;

      if (_connectionState == BluetoothConnectionState.connected) {
        await _setupCharacteristics();
        await _saveDeviceId(connectedDevice.remoteId.toString());
        await BleForegroundService.start();
        await BleForegroundService.updateNotification(
            connectedDevice.platformName.isEmpty
                ? 'wristband'
                : connectedDevice.platformName);
        _reconnectAttempts = 0;
        debugPrint('✅ Provider synchronized with connected device');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize connection: $e');
    }
  }

  /// Connect to a device by ID and set up listeners.
  Future<bool> connectToDevice(String deviceId) async {
    try {
      // Cancel any pending reconnect timer
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Only disconnect if we have an existing different connection
      if (_device != null &&
          _device!.remoteId.toString() != deviceId &&
          isConnected) {
        await _device!.disconnect();
      }

      _device = BluetoothDevice.fromId(deviceId);
      _userDisconnected = false;

      // Cancel old connection subscription if any
      await _connectionSubscription?.cancel();
      _connectionSubscription = _device!.connectionState.listen(
        _handleConnectionStateChange,
        onError: (e) => debugPrint('❌ Connection state error: $e'),
      );

      await _device!.connect(license: License.free, autoConnect: false);
      debugPrint('🔗 Connecting to $deviceId...');

      await _device!.connectionState
          .firstWhere((s) => s == BluetoothConnectionState.connected)
          .timeout(const Duration(seconds: 15));

      await _setupCharacteristics();
      await _saveDeviceId(deviceId);
      await BleForegroundService.start();
      await BleForegroundService.updateNotification(
          _device!.platformName.isEmpty ? 'wristband' : _device!.platformName);

      _reconnectAttempts = 0;
      debugPrint('✅ Connected to $deviceId');
      return true;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      // Don't call _cleanup() here — let the connection state listener handle it
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Characteristics
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _setupCharacteristics() async {
    if (_device == null) return;

    try {
      final services = await _device!.discoverServices();

      _notifyCharacteristic = null;
      _writeCharacteristic = null;

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();

            if (charUuid == NOTIFY_CHAR_UUID.toLowerCase()) {
              _notifyCharacteristic = char;
              await char.setNotifyValue(true);
              _dataSubscription = char.lastValueStream.listen(
                _handleIncomingData,
                onError: (e) => debugPrint('❌ Data stream error: $e'),
              );
              debugPrint('✅ Notify characteristic set (RX)');
            }

            if (charUuid == WRITE_CHAR_UUID.toLowerCase()) {
              _writeCharacteristic = char;
              debugPrint('✅ Write characteristic set (TX)');
            }
          }
        }
      }

      if (_notifyCharacteristic == null || _writeCharacteristic == null) {
        if (_notifyCharacteristic == null) {
          debugPrint('❌ Notify characteristic not found');
        }
        if (_writeCharacteristic == null) {
          debugPrint('❌ Write characteristic not found');
        }
        throw Exception('Required characteristics not found');
      }
    } catch (e) {
      debugPrint('❌ Setup characteristics failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Incoming data
  // ─────────────────────────────────────────────────────────────────────────

  void _handleIncomingData(List<int> data) {
    if (data.isEmpty) return;

    final signal = String.fromCharCode(data[0]);
    debugPrint('📥 Received: $signal');

    if (signal == 'X') {
      _handleSosSignal();
    } else {
      onSignalReceived?.call(signal);
    }
  }

  void _handleSosSignal() {
    if (_lastSosTime != null) {
      final elapsed = DateTime.now().difference(_lastSosTime!);
      if (elapsed.inSeconds < 3) {
        debugPrint('⏳ SOS ignored — cooldown active');
        return;
      }
    }

    if (_isSosScreenActive) {
      debugPrint('⚠️ SOS already active, ignoring');
      return;
    }

    _lastSosTime = DateTime.now();
    _isSosScreenActive = true;
    notifyListeners();
  }

  void triggerManualSos() => _handleSosSignal();

  // ─────────────────────────────────────────────────────────────────────────
  // SOS clearance
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> clearSos() async {
    try {
      debugPrint('🚨 clearSos() called');

      if (_writeCharacteristic == null) {
        debugPrint('❌ Write characteristic null — attempting refresh');
        await _setupCharacteristics();
        if (_writeCharacteristic == null) {
          throw Exception('Write characteristic not available after refresh');
        }
      }

      final bytes = [0x4B]; // 'K'
      final useNoResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(bytes, withoutResponse: useNoResponse);

      await Future.delayed(const Duration(milliseconds: 200));

      _isSosScreenActive = false;
      _lastSosTime = DateTime.now();
      notifyListeners();

      debugPrint('✅ SOS cleared (sent K)');
    } catch (e) {
      debugPrint('❌ Failed to clear SOS: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Send data
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> sendData(String data) async {
    if (_writeCharacteristic == null) {
      debugPrint('Write characteristic not available');
      return;
    }

    try {
      final bytes = data.codeUnits;
      final useNoResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(bytes, withoutResponse: useNoResponse);
      debugPrint('✅ Sent: $data');
    } catch (e) {
      debugPrint('❌ Write failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connection state handling + auto-reconnect
  // ─────────────────────────────────────────────────────────────────────────

  void _handleConnectionStateChange(BluetoothConnectionState state) {
    _connectionState = state;
    debugPrint('🔗 Connection state: $state');

    if (state == BluetoothConnectionState.disconnected) {
      _cleanupCharacteristics();

      if (_userDisconnected || _savedDeviceId == null) {
        // Intentional disconnect — full cleanup, no reconnect
        _fullCleanup();
      } else {
        // Unexpected drop — schedule reconnect
        _scheduleReconnect();
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnect attempts reached — giving up');
      _fullCleanup();
      return;
    }

    final backoffSeconds = (1 << _reconnectAttempts).clamp(1, 30);
    debugPrint(
        '🔄 Reconnecting in ${backoffSeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () async {
      _reconnectAttempts++;
      if (_savedDeviceId != null && !_userDisconnected) {
        await connectToDevice(_savedDeviceId!);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Disconnect (user-initiated)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _userDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _dataSubscription?.cancel();
      await _connectionSubscription?.cancel();

      if (_device != null && isConnected) {
        await _device!.disconnect();
      }

      await _clearSavedDeviceId();
      await BleForegroundService.stop();
      _fullCleanup();

      debugPrint('🔌 Disconnected by user');
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cleanup helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Cancel characteristic subscriptions and null out characteristics.
  /// Keeps _device alive for potential reconnect.
  void _cleanupCharacteristics() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _notifyCharacteristic = null;
    _writeCharacteristic = null;
  }

  /// Full cleanup — nulls out everything including device.
  void _fullCleanup() {
    _cleanupCharacteristics();
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _device = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _connectionState = BluetoothConnectionState.disconnected;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Diagnostics
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> diagnosticReport() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 BLE DIAGNOSTIC REPORT');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 Device: ${_device?.platformName} (${_device?.remoteId})');
    debugPrint('🔗 State: $_connectionState');
    debugPrint('💾 Saved ID: $_savedDeviceId');
    debugPrint('🔄 Reconnect attempts: $_reconnectAttempts/$_maxReconnectAttempts');
    debugPrint('🚨 SOS active: $_isSosScreenActive');
    if (_notifyCharacteristic != null) {
      debugPrint('✅ Notify: ${_notifyCharacteristic!.uuid}');
    } else {
      debugPrint('❌ Notify: NULL');
    }
    if (_writeCharacteristic != null) {
      debugPrint('✅ Write: ${_writeCharacteristic!.uuid}');
    } else {
      debugPrint('❌ Write: NULL');
    }
    debugPrint('═══════════════════════════════════════\n');
  }

  @override
  void dispose() {
    // Cancel timers and subscriptions synchronously.
    // Do NOT call disconnect() here — that clears the saved device ID in
    // SharedPreferences, which would break auto-reconnect on the next launch.
    _reconnectTimer?.cancel();
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    // Disconnect the BLE transport without touching persistence.
    _device?.disconnect();
    super.dispose();
  }
}
