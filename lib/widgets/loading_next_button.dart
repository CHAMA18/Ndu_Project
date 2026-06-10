import 'package:flutter/material.dart';

/// A reusable "Next" button with built-in loading state.
///
/// When pressed, the button immediately shows a [CircularProgressIndicator]
/// spinner next to the label, disables itself to prevent double-taps, and
/// then invokes the [onPressed] callback after one frame so the user sees
/// the loading indicator before any heavy work (e.g. Firebase save + navigation)
/// begins.
///
/// Usage — drop-in replacement for inline `ElevatedButton` Next buttons:
/// ```dart
/// LoadingNextButton(onPressed: _handleNext)
/// ```
class LoadingNextButton extends StatefulWidget {
  const LoadingNextButton({
    super.key,
    required this.onPressed,
    this.label = 'Next',
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 22,
    this.padding,
    this.elevation = 0,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.showArrow = false,
    this.isLoading = false,
  });

  /// Callback invoked when the button is pressed.
  /// If this is a `Future<void> Function()`, the button will stay in loading
  /// state until the future completes.  If it is a synchronous `VoidCallback`,
  /// the spinner is shown for a brief period (~400 ms) to give the user
  /// feedback before navigation takes over.
  final dynamic Function() onPressed;

  /// Button label text. Defaults to 'Next'.
  final String label;

  /// Background color. Defaults to the project's standard gold/yellow.
  final Color? backgroundColor;

  /// Foreground (text + icon) color. Defaults to near-black.
  final Color? foregroundColor;

  /// Border radius. Defaults to 22 (pill shape).
  final double borderRadius;

  /// Inner padding. Defaults to symmetric(34, 16).
  final EdgeInsetsGeometry? padding;

  /// Elevation. Defaults to 0.
  final double elevation;

  /// Font size for the label. Defaults to 16.
  final double fontSize;

  /// Font weight for the label. Defaults to w700.
  final FontWeight fontWeight;

  /// Whether to show a right arrow icon next to the label.
  final bool showArrow;

  /// External loading state — when true the button shows the spinner
  /// regardless of its own internal state.
  final bool isLoading;

  @override
  State<LoadingNextButton> createState() => _LoadingNextButtonState();
}

class _LoadingNextButtonState extends State<LoadingNextButton> {
  bool _isNavigating = false;

  bool get _showLoading => widget.isLoading || _isNavigating;

  static const _defaultBg = Color(0xFFFFC812);
  static const _defaultFg = Color(0xFF111827);

  Future<void> _handlePress() async {
    if (_showLoading) return;
    setState(() => _isNavigating = true);

    // Let the UI render the loading spinner before executing the callback
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Support both sync VoidCallback and async Future<void> Function()
    final result = widget.onPressed();

    // If the callback returns a Future, await it
    if (result is Future) {
      try {
        await result;
      } catch (_) {
        // Errors are handled by the caller
      }
    }

    // Keep the spinner visible briefly so the user sees the feedback
    // before the navigation transition takes over
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? _defaultBg;
    final fgColor = widget.foregroundColor ?? _defaultFg;
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 34, vertical: 16);

    return ElevatedButton(
      onPressed: _showLoading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        disabledForegroundColor: fgColor.withOpacity(0.5),
        padding: effectivePadding,
        elevation: widget.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _showLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fgColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      color: fgColor.withOpacity(0.6),
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                    ),
                  ),
                  if (widget.showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
