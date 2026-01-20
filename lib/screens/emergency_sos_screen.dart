import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as audio_session_lib;
import '../utils/colors.dart';
import '../services/secure_storage_service.dart';

class EmergencySOSManager {
  static AudioPlayer? _audioPlayer;
  static bool _isPlaying = false;

  static Future<void> startEmergencyAlarm() async {
    if (_isPlaying) return;

    try {
      // Request audio session with system override capability
      final session = await audio_session_lib.AudioSession.instance;
      await session.configure(audio_session_lib.AudioSessionConfiguration(
        avAudioSessionCategory: audio_session_lib.AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: audio_session_lib.AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: audio_session_lib.AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: audio_session_lib.AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: audio_session_lib.AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: audio_session_lib.AndroidAudioAttributes(
          contentType: audio_session_lib.AndroidAudioContentType.music,
          flags: audio_session_lib.AndroidAudioFlags.none,
          usage: audio_session_lib.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: audio_session_lib.AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      await session.setActive(true);

      _audioPlayer = AudioPlayer();
      
      // Play emergency sound at maximum system volume
      await _audioPlayer!.setVolume(1.0); // Maximum volume
      
      // Loop the emergency sound
      await _audioPlayer!.play(
        AssetSource('sounds/emergency_alarm.mp3'), // You'll need to add this asset
        mode: PlayerMode.mediaPlayer, // Use system player for silent mode override
      );
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop); // Loop indefinitely

      _isPlaying = true;

      // Listen for when audio finishes to reset state
      _audioPlayer!.onPlayerComplete.listen((event) {
        // Restart the alarm if it ends (in case of any interruption)
        if (_isPlaying) {
          _audioPlayer!.play(
            AssetSource('sounds/emergency_alarm.mp3'),
            mode: PlayerMode.mediaPlayer,
          );
        }
      });

    } catch (e) {
      _isPlaying = false;
    }
  }

  static Future<void> stopEmergencyAlarm() async {
    try {
      if (_audioPlayer != null && _isPlaying) {
        await _audioPlayer!.stop();
        _audioPlayer!.dispose();
        _isPlaying = false;
      }
      
      // Reset audio session
      final session = await audio_session_lib.AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      // Error handling for stopping alarm
    }
  }

  static bool get isAlarmPlaying => _isPlaying;
}

// Enhanced Emergency SOS Screen with glass morphism effect
class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final TextEditingController _pinController = TextEditingController();
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String? _sosPin;
  bool _isAlarmPlaying = false;
  
  @override
  void initState() {
    super.initState();
    // Fetch SOS PIN from secure storage
    _loadSosPin();
    
    // Start emergency alarm when screen loads
    _startEmergencyAlarm();
  }
  
  Future<void> _loadSosPin() async {
    try {
      final pin = await SecureStorageService().getSosPin();
      if (pin != null) {
        setState(() {
          _sosPin = pin;
        });
      }
    } catch (e) {
      // Error loading SOS PIN
    }
  }

  void _startEmergencyAlarm() async {
    setState(() {
      _isAlarmPlaying = true;
    });
    await EmergencySOSManager.startEmergencyAlarm();
  }

  @override
  void dispose() {
    _stopEmergencyAlarm();
    _pinController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _stopEmergencyAlarm() {
    EmergencySOSManager.stopEmergencyAlarm();
    setState(() {
      _isAlarmPlaying = false;
    });
  }

  void _onPinChanged() {
    if (_pinController.text.length == 4) {
      if (_pinController.text == _sosPin) {
        // Correct PIN - stop emergency alarm and close screen
        _stopEmergencyAlarm();
        Navigator.pop(context); // Close the emergency screen
      } else {
        // Wrong PIN - show error but keep alarm running
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incorrect PIN. Please try again.',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.black,
          ),
        );
        // Clear the controller
        _pinController.clear();
        for (var node in _focusNodes) {
          node.requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background for glass morphism
      body: Stack(
        children: [
          // Red background
          Container(
            color: const Color(0xFFEF4444), // Red background
          ),
          
          // Glass morphism overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1), // Light transparent white for glass effect
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emergency icon with pulsing animation
                  AnimatedContainer(
                    width: 100,
                    height: 100,
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2), // Semi-transparent white
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.warning,
                      size: 50,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Emergency header
                  Text(
                    'EMERGENCY SOS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white, // White text for contrast
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instruction
                  Text(
                    'Enter your 4-digit SOS PIN to stop the alarm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // PIN Input Fields with glass morphism effect
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15), // Glass effect
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2), // Glass effect
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _pinController,
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white, // White text for PIN digits
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                              }
                              _onPinChanged();
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Alarm status
                  Text(
                    _isAlarmPlaying ? 'Emergency alarm is ringing...' : 'Alarm stopped',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}