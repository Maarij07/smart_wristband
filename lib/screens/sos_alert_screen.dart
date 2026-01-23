import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key});

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  late AudioPlayer _player;
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
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
      print('Audio error: $e');
    }
  }

  void _stopAlarm() {
    _player.stop();
    _player.dispose();
  }

  @override
  void dispose() {
    _stopAlarm();
    for (var c in _controllers) c.dispose();
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
                      if (_pin.length == 4) {
                        if (_pin == '1111') {
                          _stopAlarm();
                          Navigator.pop(context);
                        } else {
                          for (var c in _controllers) c.clear();
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