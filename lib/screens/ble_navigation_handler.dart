import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/ble_connection_provider.dart';
import 'sos_alert_screen.dart';

/// Wraps the entire app body and listens globally to [BleConnectionProvider].
/// When an SOS is triggered it pushes [SosAlertScreen] on the root navigator
/// regardless of which screen the user is currently on.
class BleNavigationHandler extends StatefulWidget {
  final Widget child;

  const BleNavigationHandler({super.key, required this.child});

  @override
  State<BleNavigationHandler> createState() => _BleNavigationHandlerState();
}

class _BleNavigationHandlerState extends State<BleNavigationHandler> {
  bool _isSosShowing = false;
  BleConnectionProvider? _bleProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<BleConnectionProvider>();
    if (_bleProvider != provider) {
      _bleProvider?.removeListener(_onBleChanged);
      _bleProvider = provider;
      _bleProvider!.addListener(_onBleChanged);
    }
  }

  @override
  void dispose() {
    _bleProvider?.removeListener(_onBleChanged);
    super.dispose();
  }

  void _onBleChanged() {
    if (_bleProvider == null || !mounted) return;

    if (_bleProvider!.isSosScreenActive && !_isSosShowing) {
      _showSosScreen();
    }
  }

  void _showSosScreen() {
    _isSosShowing = true;

    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => SosAlertScreen(
        onSosCleared: () async {
          await _bleProvider?.clearSos();
        },
      ),
    )).then((_) {
      _isSosShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
