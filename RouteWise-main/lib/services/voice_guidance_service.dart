import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _enabled = true;

  VoiceGuidanceService() {
    _initTts();
  }

  void updateSettings({required bool enabled}) {
    _enabled = enabled;
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoiceGuidanceService] init failed: $e');
      }
    }
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoiceGuidanceService] speak failed: $e');
      }
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VoiceGuidanceService] stop failed: $e');
      }
    }
  }
}
