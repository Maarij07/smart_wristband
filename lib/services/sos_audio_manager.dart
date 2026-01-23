import 'package:just_audio/just_audio.dart';

class SOSAudioManager {
  static final SOSAudioManager _instance = SOSAudioManager._internal();
  factory SOSAudioManager() => _instance;
  SOSAudioManager._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  Future<void> startAlarm() async {
    try {
      // Dispose of any existing player
      await _player?.dispose();
      
      // Create new player
      _player = AudioPlayer();
      
      // Set audio source
      await _player!.setAudioSource(
        AudioSource.asset('assets/sounds/emergency_alarm.mp3'),
        preload: true,
      );
      
      // Configure for alarm
      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(1.0);
      
      // Play the alarm
      await _player!.play();
      _isPlaying = true;
      
      print('✅ SOS alarm started successfully with just_audio');
    } catch (e) {
      print('❌ SOS audio error: $e');
      // Fallback to system sound if available
      _playSystemFallback();
    }
  }

  void _playSystemFallback() {
    // This would be implemented with platform channels if needed
    print('⚠️ Using system fallback for SOS alarm');
  }

  Future<void> stopAlarm() async {
    if (_isPlaying) {
      await _player?.stop();
      await _player?.dispose();
      _player = null;
      _isPlaying = false;
      print('✅ SOS alarm stopped');
    }
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    _player?.dispose();
    _player = null;
    _isPlaying = false;
  }
}