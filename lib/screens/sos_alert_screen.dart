import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/user_context.dart';
import '../services/ble_connection_provider.dart';

class SosAlertScreen extends StatefulWidget {
  final Future<void> Function()? onSosCleared;
  
  const SosAlertScreen({
    super.key,
    this.onSosCleared,
  });

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  late AudioPlayer _player;
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _pin = '';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    try {
      await _player.setAudioSource(
        AudioSource.asset('assets/sounds/emergency_alarm.mp3'),
      );
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(1.0);
      await _player.play();
    } catch (e) {
      // Audio error
    }
  }

  Future<void> _stopAlarm() async {
    try {
      await _player.stop();
      await _player.dispose();
    } catch (e) {
      // Error stopping
    }
  }

  @override
  void dispose() {
    // We do NOT reset provider state here automatically because 
    // we want the provider's clearSos() to handle the logic vs user just back-navigating.
    // But if the screen is popping, we might want to ensure sound stops.
    _stopAlarm();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  Future<void> _onPinChanged() async {
      _pin = _controllers.map((c) => c.text).join();
      
      if (_pin.length == 4) {
        if (_pin == '1111') {
           // Correct PIN
           if (mounted) setState(() => _isClearing = true);
           
           try {
             // Stop alarm immediately for UX 
             await _player.stop();
             
             // Use provider to send K and clear state
             // This uses the persistent connection
             await Provider.of<BleConnectionProvider>(context, listen: false).clearSos();
             
             // Also update UserContext for legacy compatibility if needed
             if (mounted) {
                Provider.of<UserContext>(context, listen: false).setIsSosScreenShowing(false);
             }
             
             if (mounted) {
               Navigator.of(context).pop();
             }
           } catch (e) {
             print('Error clearing SOS via provider: $e');
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to clear SOS: $e')),
                );
                setState(() => _isClearing = false);
             }
           }
        } else {
          // Wrong PIN
          for (var c in _controllers) {
            c.clear();
          }
          _pin = '';
          _focusNodes[0].requestFocus();
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent back button
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              if (_isClearing)
                 const Column(
                   children: [
                     CircularProgressIndicator(color: Colors.white),
                     SizedBox(height: 16),
                     Text('Deactivating Alarm...', style: TextStyle(color: Colors.white)),
                   ],
                 )
              else ...[
                const Text(
                  'Enter PIN to stop alarm',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 50,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 2),
                          ),
                          fillColor: Colors.white24,
                          filled: true,
                        ),
                        onChanged: (value) async {
                          // Move to next field if current field is filled
                          if (value.isNotEmpty && index < _controllers.length - 1) {
                            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                          }
                          // Move to previous if backspacing
                          if (value.isEmpty && index > 0) {
                             FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                          }
                          // Check PIN
                          await _onPinChanged();
                        },
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}