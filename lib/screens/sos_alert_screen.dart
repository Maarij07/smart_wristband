import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/user_context.dart';

class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key});

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  late AudioPlayer _player;
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _pin = '';

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
      // Audio error: \$e
    }
  }

  Future<void> _stopAlarm() async {
    try {
      await _player.stop();
      await _player.dispose();
    } catch (e) {
      // Error stopping/disposing player: \$e
    }
  }

  @override
  void dispose() {
    // Reset the SOS screen flag when screen is disposed
    final userContext = Provider.of<UserContext>(context, listen: false);
    userContext.setIsSosScreenShowing(false);
    
    _stopAlarm();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 80, color: Colors.white),
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
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white24,
                      filled: true,
                    ),
                    onChanged: (value) {
                      _pin = _controllers.map((c) => c.text).join();
                      
                      // Move to next field if current field is filled
                      if (value.isNotEmpty && index < _controllers.length - 1) {
                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                      }
                      
                      // Move to previous field if current field is cleared and empty
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }
                      
                      if (_pin.length == 4) {
                        if (_pin == '1111') {
                          // Send confirmation signal back to wristband
                          final userContext = Provider.of<UserContext>(context, listen: false);
                          
                          // Reset the SOS screen flag BEFORE popping
                          userContext.setIsSosScreenShowing(false);
                          
                          // Add a small delay before sending K signal to ensure proper timing
                          Future.delayed(const Duration(milliseconds: 100), () {
                            userContext.confirmWristbandSos();
                          });
                          
                          // Use WidgetsBinding to ensure proper cleanup before popping
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _stopAlarm();
                            Navigator.pop(context);
                          });
                        } else {
                          for (var c in _controllers) {
                            c.clear();
                          }
                          _pin = '';
                        }
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}