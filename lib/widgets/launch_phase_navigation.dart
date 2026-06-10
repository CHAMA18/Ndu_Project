import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/proceed_confirmation_gate.dart';

/// Shared navigation footer used across the Launch Phase pages.
/// Supports built-in loading state on the Next button.
class LaunchPhaseNavigation extends StatefulWidget {
  const LaunchPhaseNavigation({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.nextEnabled = true,
    super.key,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool nextEnabled;

  static const _kAccentColor = Color(0xFFFFC812);

  @override
  State<LaunchPhaseNavigation> createState() => _LaunchPhaseNavigationState();
}

class _LaunchPhaseNavigationState extends State<LaunchPhaseNavigation> {
  bool _isNavigatingNext = false;

  Future<void> _handleNextTap(BuildContext context) async {
    if (_isNavigatingNext) return;

    if (!widget.nextEnabled) {
      final continueAnyway = await showProceedWithoutReviewDialog(
        context,
        title: 'Please confirm you have reviewed and understood this step',
        message:
            'You have not confirmed this page yet. You can continue now and return to update missing information later, or stay and complete it now.',
      );
      if (!continueAnyway) return;
    }

    if (!mounted) return;
    setState(() => _isNavigatingNext = true);

    // Let the UI render the loading spinner before executing the callback
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;
    widget.onNext();

    // Keep the spinner visible briefly so the user sees the feedback
    // before the navigation transition takes over
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isNavigatingNext = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = LaunchPhaseNavigation._kAccentColor;

    final backButton = OutlinedButton.icon(
      onPressed: _isNavigatingNext ? null : widget.onBack,
      icon: Icon(
        Icons.arrow_back,
        size: 18,
        color: _isNavigatingNext
            ? accentColor.withOpacity(0.4)
            : accentColor,
      ),
      label: Text(
        widget.backLabel,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _isNavigatingNext
              ? accentColor.withOpacity(0.4)
              : accentColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: _isNavigatingNext
              ? accentColor.withOpacity(0.3)
              : accentColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final nextButton = ElevatedButton.icon(
      onPressed: _isNavigatingNext ? null : () => _handleNextTap(context),
      icon: _isNavigatingNext
          ? Container()
          : const Icon(Icons.arrow_forward, size: 18),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isNavigatingNext
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.nextLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                widget.nextLabel,
                key: const ValueKey('idle'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accentColor.withOpacity(0.5),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              backButton,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: nextButton),
            ],
          );
        }

        return Row(
          children: [
            Flexible(child: backButton),
            const SizedBox(width: 16),
            const Spacer(),
            Flexible(child: nextButton),
          ],
        );
      },
    );
  }
}
