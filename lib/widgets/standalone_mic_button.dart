import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ndu_project/services/voice_input_service.dart';

/// A standalone microphone button for speech-to-text transcription.
///
/// Unlike the mic icon inside [VoiceTextField], this is a prominent,
/// free-floating button that can be placed anywhere in the UI — typically
/// below or next to an "Import Doc" section.
///
/// When tapped, it requests microphone permission and starts listening.
/// Recognized speech is appended to the linked [TextEditingController].
/// The button provides rich visual feedback:
/// - **Idle**: Outlined mic icon with subtle border
/// - **Listening**: Filled mic with pulsing gold glow animation
/// - **Error**: Brief red flash with tooltip
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     // Import doc section
///     _ImportDocButton(...),
///     const SizedBox(height: 8),
///     // Mic button below import section
///     StandaloneMicButton(controller: myTextController),
///   ],
/// )
/// ```
class StandaloneMicButton extends StatefulWidget {
  const StandaloneMicButton({
    super.key,
    required this.controller,
    this.onChanged,
    this.label = 'Voice Input',
    this.showLabel = true,
    this.iconSize = 22,
    this.size = 44,
  });

  /// The text controller to append transcribed speech to.
  final TextEditingController controller;

  /// Called when the controller text changes from voice input.
  final ValueChanged<String>? onChanged;

  /// Optional label displayed next to the mic icon.
  final String label;

  /// Whether to show the label text next to the icon.
  final bool showLabel;

  /// Size of the mic icon.
  final double iconSize;

  /// Overall size of the button.
  final double size;

  @override
  State<StandaloneMicButton> createState() => _StandaloneMicButtonState();
}

class _StandaloneMicButtonState extends State<StandaloneMicButton>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService.instance;
  StreamSubscription<VoiceResult>? _resultSubscription;
  StreamSubscription<VoiceStatus>? _statusSubscription;
  bool _isListening = false;
  bool _voiceAvailable = true;

  // Animation controllers for the listening state
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkAvailability();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await _voiceService.initialize();
      if (mounted && available != _voiceAvailable) {
        setState(() => _voiceAvailable = available);
      }
    } catch (e) {
      debugPrint('[StandaloneMicButton] Availability check failed: $e');
      if (mounted) {
        setState(() => _voiceAvailable = false);
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
      _cleanupSubscriptions();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_voiceAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? 'Voice input unavailable. Use Chrome, Edge, or Safari and allow microphone access.'
                : 'Speech recognition is not available on this device.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final started = await _voiceService.startListening(
      existingText: widget.controller.text,
    );

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb
                ? 'Voice input unavailable. Use Chrome, Edge, or Safari and allow microphone access.'
                : 'Speech recognition is not available on this device.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _resultSubscription = _voiceService.onResult.listen((result) {
      if (!mounted) return;
      final text = result.text;
      widget.controller.text = text;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
      widget.onChanged?.call(text);

      if (result.isFinal) {
        if (mounted) setState(() => _isListening = false);
        _cleanupSubscriptions();
      }
    });

    _statusSubscription = _voiceService.onStatusChanged.listen((status) {
      if (status == VoiceStatus.stopped || status == VoiceStatus.error) {
        if (mounted) setState(() => _isListening = false);
        _cleanupSubscriptions();
      }
    });

    if (mounted) setState(() => _isListening = true);
  }

  void _cleanupSubscriptions() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mic button with animations
        GestureDetector(
          onTap: _toggleVoiceInput,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rippleController]),
            builder: (context, child) {
              return SizedBox(
                width: widget.size + 16,
                height: widget.size + 16,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple effect when listening
                    if (_isListening) ...[
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, _) {
                          final progress = _rippleController.value;
                          return Container(
                            width: widget.size * (1 + progress * 0.6),
                            height: widget.size * (1 + progress * 0.6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFB800)
                                    .withOpacity(0.3 * (1 - progress)),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    // Main button
                    Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? const Color(0xFFFFB800)
                              : Colors.white,
                          border: Border.all(
                            color: _isListening
                                ? const Color(0xFFFFB800)
                                : const Color(0xFFD1D5DB),
                            width: _isListening ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            if (_isListening)
                              BoxShadow(
                                color:
                                    const Color(0xFFFFB800).withOpacity(0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_outlined,
                          color: _isListening
                              ? Colors.white
                              : const Color(0xFFFFB800),
                          size: widget.iconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Label
        if (widget.showLabel) ...[
          const SizedBox(height: 6),
          Text(
            _isListening ? 'Listening...' : widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: _isListening ? FontWeight.w700 : FontWeight.w500,
              color: _isListening
                  ? const Color(0xFFFFB800)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }
}
