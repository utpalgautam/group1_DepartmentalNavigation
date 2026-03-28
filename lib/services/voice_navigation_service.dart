import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A cross-platform service that handles voice navigation instructions using flutter_tts.
class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._internal();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._internal() {
    _initTts();
  }

  late FlutterTts _flutterTts;
  bool _isVoiceEnabled = true;
  String? _lastSpokenInstruction;
  double? _lastSpokenDistance;

  bool get isVoiceEnabled => _isVoiceEnabled;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (onSpeechStateChanged != null) onSpeechStateChanged!();
    });

    // Configure TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for better clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (!kIsWeb) {
      // Mobile-specific config
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );
    }
  }

  VoidCallback? onSpeechStateChanged;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isVoiceEnabled = prefs.getBool('voice_navigation_enabled') ?? true;
  }

  Future<void> toggleVoice() async {
    _isVoiceEnabled = !_isVoiceEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_navigation_enabled', _isVoiceEnabled);
    
    if (_isVoiceEnabled) {
      speak("Voice navigation enabled.");
    } else {
      stop();
    }
  }

  /// Speaks a simple text message.
  void speak(String text) async {
    if (!_isVoiceEnabled) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error in TTS: $e');
    }
  }

  /// Stops any ongoing speech.
  void stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Logic for natural timing of navigation instructions.
  /// Decides whether to speak based on the current instruction and distance.
  void speakNavigationInstruction(String instruction, double distanceInMeters) {
    if (!_isVoiceEnabled) return;

    // 1. Threshold-based triggers
    bool shouldSpeak = false;
    String speechText = "";

    // Arrival detection
    if (distanceInMeters < 5.0 && _lastSpokenDistance != 0) {
      speechText = instruction; // "You have arrived"
      shouldSpeak = true;
      _lastSpokenDistance = 0;
    } 
    // Immediate turn/Next step
    else if (distanceInMeters < 15.0 && (_lastSpokenDistance == null || _lastSpokenDistance! > 15.0)) {
      speechText = instruction; // e.g., "Turn right"
      shouldSpeak = true;
      _lastSpokenDistance = 15.0;
    }
    // "In 20 meters..."
    else if (distanceInMeters <= 25.0 && distanceInMeters > 15.0 && (_lastSpokenDistance == null || _lastSpokenDistance! > 25.0)) {
       speechText = "In ${distanceInMeters.toStringAsFixed(0)} meters, $instruction";
       shouldSpeak = true;
       _lastSpokenDistance = 25.0;
    }
    // "In 50 meters..."
    else if (distanceInMeters <= 55.0 && distanceInMeters > 45.0 && (_lastSpokenDistance == null || _lastSpokenDistance! > 55.0)) {
       speechText = "In 50 meters, $instruction";
       shouldSpeak = true;
       _lastSpokenDistance = 55.0;
    }
    // New instruction (immediate alert if far away)
    else if (instruction != _lastSpokenInstruction && distanceInMeters > 60.0) {
       speechText = "In ${distanceInMeters.toStringAsFixed(0)} meters, $instruction";
       shouldSpeak = true;
       _lastSpokenDistance = distanceInMeters;
    }

    if (shouldSpeak) {
      _lastSpokenInstruction = instruction;
      speak(speechText);
    }
  }

  void resetLastSpoken() {
    _lastSpokenInstruction = null;
    _lastSpokenDistance = null;
  }
}
