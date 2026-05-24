import 'dart:async';
import 'package:flutter/foundation.dart';

// Conditional import: web bridge on web, stub on native
import 'voice_input_web_bridge_stub.dart'
    if (dart.library.js_interop) 'voice_input_web_bridge_web.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Cross-platform voice input service.
///
/// - **Web**: Uses the browser's Web Speech API directly via dart:js_interop,
///   bypassing the `speech_to_text` web plugin which has a known issue with
///   `_SpeechRecognition` constructor in release mode.
/// - **Mobile/Desktop**: Uses the `speech_to_text` package which wraps
///   platform-native speech recognition.
class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  // Native (speech_to_text) instance
  stt.SpeechToText? _speech;

  // Web Speech Recognition JS object
  dynamic _webRecognition;

  bool _initialized = false;
  bool _isAvailable = false;
  bool _isListening = false;
  String _currentText = '';
  String _previousText = '';

  final StreamController<VoiceResult> _resultController =
      StreamController<VoiceResult>.broadcast();
  final StreamController<VoiceStatus> _statusController =
      StreamController<VoiceStatus>.broadcast();

  // --- Getters ---

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get currentText => _currentText;
  String get previousText => _previousText;
  Stream<VoiceResult> get onResult => _resultController.stream;
  Stream<VoiceStatus> get onStatusChanged => _statusController.stream;

  // --- Initialization ---

  Future<bool> initialize() async {
    if (_initialized) return _isAvailable;

    if (kIsWeb) {
      return _initializeWeb();
    } else {
      return _initializeNative();
    }
  }

  // ===================== WEB =====================

  Future<bool> _initializeWeb() async {
    try {
      _isAvailable = webVoiceInit(this);
    } catch (e) {
      debugPrint('[VoiceInputService] Web init failed: $e');
      _isAvailable = false;
    }
    _initialized = true;
    return _isAvailable;
  }

  /// Stores the web SpeechRecognition JS object (called from web bridge).
  void setWebRecognition(dynamic recognition) {
    _webRecognition = recognition;
  }

  /// Callback from web bridge: result received
  void onWebResult(String text, bool isFinal) {
    _currentText = text;
    final fullText = _buildFullText();
    if (!_resultController.isClosed) {
      _resultController.add(VoiceResult(text: fullText, isFinal: isFinal));
    }
    if (isFinal) {
      _isListening = false;
      if (!_statusController.isClosed) {
        _statusController.add(VoiceStatus.stopped);
      }
    }
  }

  /// Callback from web bridge: error occurred
  void onWebError(String error) {
    debugPrint('[VoiceInputService] Web error: $error');
    _isListening = false;
    if (!_statusController.isClosed) {
      _statusController.add(VoiceStatus.error);
    }
  }

  /// Callback from web bridge: recognition ended
  void onWebEnd() {
    _isListening = false;
    if (!_statusController.isClosed) {
      _statusController.add(VoiceStatus.stopped);
    }
  }

  // ===================== NATIVE =====================

  Future<bool> _initializeNative() async {
    try {
      _speech = stt.SpeechToText();
      _isAvailable = await _speech!.initialize(
        onError: _onNativeError,
        onStatus: _onNativeStatus,
        debugLogging: false,
      );
    } catch (e) {
      debugPrint('[VoiceInputService] Native init failed: $e');
      _isAvailable = false;
    }
    _initialized = true;
    return _isAvailable;
  }

  void _onNativeError(SpeechRecognitionError error) {
    debugPrint('[VoiceInputService] Error: ${error.errorMsg} (permanent: ${error.permanent})');
    if (error.permanent) {
      _isListening = false;
      if (!_statusController.isClosed) {
        _statusController.add(VoiceStatus.error);
      }
    }
  }

  void _onNativeStatus(String status) {
    switch (status) {
      case 'listening':
        _isListening = true;
        if (!_statusController.isClosed) {
          _statusController.add(VoiceStatus.listening);
        }
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        if (!_statusController.isClosed) {
          _statusController.add(VoiceStatus.stopped);
        }
        break;
    }
  }

  void _onNativeResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;
    final fullText = _buildFullText();
    if (!_resultController.isClosed) {
      _resultController.add(VoiceResult(
        text: fullText,
        isFinal: result.finalResult,
      ));
    }
  }

  // ===================== LISTENING =====================

  Future<bool> startListening({
    String existingText = '',
    String? localeId,
  }) async {
    if (_isListening) return true;

    if (!_initialized) {
      await initialize();
    }

    if (!_isAvailable) {
      debugPrint('[VoiceInputService] Speech recognition not available');
      return false;
    }

    _previousText = existingText;
    _currentText = '';
    _isListening = true;
    _statusController.add(VoiceStatus.listening);

    if (kIsWeb) {
      return webVoiceStart(_webRecognition, localeId);
    } else {
      return _startNativeListening(localeId: localeId);
    }
  }

  Future<bool> _startNativeListening({
    String? localeId,
  }) async {
    try {
      await _speech!.listen(
        onResult: _onNativeResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      debugPrint('[VoiceInputService] Native startListening failed: $e');
      _isListening = false;
      _statusController.add(VoiceStatus.stopped);
      return false;
    }
  }

  Future<String> stopListening() async {
    if (!_isListening) return _currentText;

    if (kIsWeb) {
      webVoiceStop(_webRecognition);
    } else {
      try {
        _speech?.stop();
      } catch (e) {
        debugPrint('[VoiceInputService] Native stop error: $e');
      }
    }

    _isListening = false;
    _statusController.add(VoiceStatus.stopped);

    final fullText = _buildFullText();
    _resultController.add(VoiceResult(text: fullText, isFinal: true));
    return fullText;
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;

    if (kIsWeb) {
      webVoiceAbort(_webRecognition);
    } else {
      try {
        _speech?.cancel();
      } catch (e) {
        debugPrint('[VoiceInputService] Native cancel error: $e');
      }
    }

    _isListening = false;
    _currentText = '';
    _statusController.add(VoiceStatus.stopped);
  }

  String _buildFullText() {
    if (_previousText.isEmpty) return _currentText;
    if (_currentText.isEmpty) return _previousText;

    final separator = _previousText.endsWith(' ') || _previousText.endsWith('\n')
        ? ''
        : ' ';
    return '$_previousText$separator$_currentText';
  }

  void dispose() {
    _resultController.close();
    _statusController.close();
    if (kIsWeb) {
      webVoiceAbort(_webRecognition);
    } else {
      try {
        _speech?.cancel();
      } catch (_) {}
    }
  }
}

/// Result of a voice recognition session
class VoiceResult {
  final String text;
  final bool isFinal;

  const VoiceResult({required this.text, required this.isFinal});
}

/// Status of the voice input service
enum VoiceStatus {
  listening,
  stopped,
  error,
}
