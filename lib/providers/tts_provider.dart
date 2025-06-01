import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsProvider extends ChangeNotifier {
  static const String _speechRateKey = 'speech_rate';
  static const String _pitchKey = 'pitch';
  static const String _volumeKey = 'volume';
  
  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isSupported = false;
  
  // TTS parameters with default values
  double _speechRate = 0.5; // Default speech rate (0.0 - 1.0)
  double _pitch = 1.0;     // Default pitch (0.5 - 2.0)
  double _volume = 1.0;    // Default volume (0.0 - 1.0)
  
  TtsProvider() {
    _initTts();
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isSupported => _isSupported;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  
  Future<void> _initTts() async {
    try {
      // Only support Android and iOS platforms
      if (!Platform.isAndroid && !Platform.isIOS) {
        _isSupported = false;
        _isInitialized = true;
        notifyListeners();
        debugPrint("TTS not supported on this platform - only Android and iOS are supported");
        return;
      }
      
      _flutterTts = FlutterTts();
      _isSupported = true;
      
      // Always use Chinese language
      await _flutterTts?.setLanguage("zh-CN");
      
      // Load saved preferences
      await _loadPreferences();
      
      // Apply settings
      await _flutterTts?.setSpeechRate(_speechRate);
      await _flutterTts?.setPitch(_pitch);
      await _flutterTts?.setVolume(_volume);
      
      // Setup completion listener
      _flutterTts?.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
      
      // Setup error listener
      _flutterTts?.setErrorHandler((error) {
        _isSpeaking = false;
        notifyListeners();
        debugPrint("TTS Error: $error");
      });
      
      _flutterTts?.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
      
      _flutterTts?.setPauseHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
      
      _flutterTts?.setContinueHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isSupported = false;
      _isInitialized = true;
      notifyListeners();
      debugPrint("TTS initialization error: $e");
    }
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
    _pitch = prefs.getDouble(_pitchKey) ?? 1.0;
    _volume = prefs.getDouble(_volumeKey) ?? 1.0;
  }
  
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, _speechRate);
    await prefs.setDouble(_pitchKey, _pitch);
    await prefs.setDouble(_volumeKey, _volume);
  }
  
  // Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0 || !_isSupported) return;
    
    _speechRate = rate;
    await _flutterTts?.setSpeechRate(rate);
    await _savePreferences();
    notifyListeners();
  }
  
  // Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0 || !_isSupported) return;
    
    _pitch = pitch;
    await _flutterTts?.setPitch(pitch);
    await _savePreferences();
    notifyListeners();
  }
  
  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0 || !_isSupported) return;
    
    _volume = volume;
    await _flutterTts?.setVolume(volume);
    await _savePreferences();
    notifyListeners();
  }
  
  // Speak Chinese text
  Future<void> speak(String text) async {
    if (!_isInitialized) await _initTts();
    
    if (!_isSupported) {
      debugPrint("TTS not supported on this platform. Text: $text");
      return;
    }
    
    try {
      // Ensure Chinese language is set
      await _flutterTts?.setLanguage("zh-CN");
      
      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }
      
      _isSpeaking = true;
      notifyListeners();
      
      // Speak the text
      await _flutterTts?.speak(text);
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint("Error speaking: $e");
    }
  }
  
  // Stop speaking
  Future<void> stop() async {
    if (_isSpeaking && _isSupported) {
      try {
        await _flutterTts?.stop();
      } catch (e) {
        debugPrint("Error stopping TTS: $e");
      } finally {
        _isSpeaking = false;
        notifyListeners();
      }
    }
  }
  
  @override
  void dispose() {
    if (_isSupported) {
      _flutterTts?.stop();
    }
    super.dispose();
  }
}