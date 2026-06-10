import 'package:flutter/material.dart';
import 'package:ndu_project/utils/business_case_navigation.dart';
import 'package:ndu_project/widgets/proceed_confirmation_gate.dart';

/// Navigation buttons for Business Case screens with built-in loading state.
class BusinessCaseNavigationButtons extends StatefulWidget {
  final String currentScreen;
  final EdgeInsets? padding;
  final Future<void> Function()? onNext;
  final Future<void> Function()? onBack;
  final Future<void> Function()? onSkip;
  final String skipLabel;
  final bool isNextEnabled;
  final bool showReviewGate;
  final bool reviewConfirmed;
  final ValueChanged<bool>? onReviewChanged;
  final ScrollController? reviewScrollController;
  final String reviewLabel;

  const BusinessCaseNavigationButtons({
    super.key,
    required this.currentScreen,
    this.padding,
    this.onNext,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Skip',
    this.isNextEnabled = true,
    this.showReviewGate = false,
    this.reviewConfirmed = false,
    this.onReviewChanged,
    this.reviewScrollController,
    this.reviewLabel =
        'I confirm that I have reviewed all information on this page before proceeding.',
  });

  @override
  State<BusinessCaseNavigationButtons> createState() =>
      _BusinessCaseNavigationButtonsState();
}

class _BusinessCaseNavigationButtonsState
    extends State<BusinessCaseNavigationButtons> {
  bool _isNavigatingNext = false;
  bool _isNavigatingBack = false;
  bool _isNavigatingSkip = false;

  Future<void> _handleNextTap(
    BuildContext context,
    Future<void> Function() proceed,
  ) async {
    final needsReview =
        !widget.isNextEnabled || (widget.showReviewGate && !widget.reviewConfirmed);
    if (needsReview) {
      final continueAnyway = await showProceedWithoutReviewDialog(
        context,
        title: 'Confirm your information before proceeding',
        message:
            'You have not confirmed this step yet. You can continue now and return later to update missing information, or stay and complete it now.',
      );
      if (!continueAnyway) return;
    }
    if (!mounted) return;
    setState(() => _isNavigatingNext = true);
    try {
      await proceed();
    } finally {
      if (mounted) {
        setState(() => _isNavigatingNext = false);
      }
    }
  }

  Future<void> _handleBackTap(
    Future<void> Function() proceed,
  ) async {
    if (_isNavigatingBack) return;
    setState(() => _isNavigatingBack = true);
    try {
      await proceed();
    } finally {
      if (mounted) {
        setState(() => _isNavigatingBack = false);
      }
    }
  }

  Future<void> _handleSkipTap(
    Future<void> Function() proceed,
  ) async {
    if (_isNavigatingSkip) return;
    setState(() => _isNavigatingSkip = true);
    try {
      await proceed();
    } finally {
      if (mounted) {
        setState(() => _isNavigatingSkip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrevious = BusinessCaseNavigation.hasPrevious(widget.currentScreen);
    final hasNext = BusinessCaseNavigation.hasNext(widget.currentScreen);
    final Future<void> Function() handleBack = widget.onBack == null
        ? () async =>
            BusinessCaseNavigation.navigateBack(context, widget.currentScreen)
        : () async => await widget.onBack!();
    final Future<void> Function() handleNext = widget.onNext == null
        ? () async =>
            BusinessCaseNavigation.navigateForward(context, widget.currentScreen)
        : () async => await widget.onNext!();
    final hasSkip = widget.onSkip != null;
    final handleSkip = widget.onSkip == null ? null : () async => await widget.onSkip!();

    return Container(
      width: double.infinity,
      padding:
          widget.padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasPrevious)
                _NavigationButton(
                  icon: Icons.arrow_back_ios_new,
                  label: 'Back',
                  onPressed: _isNavigatingBack
                      ? null
                      : () {
                          _handleBackTap(handleBack);
                        },
                  isForward: false,
                  isLoading: _isNavigatingBack,
                )
              else
                const Spacer(),
              Flexible(child: Row(
                children: [
                  if (hasSkip)
                    _NavigationButton(
                      icon: Icons.skip_next_rounded,
                      label: widget.skipLabel,
                      onPressed: _isNavigatingSkip
                          ? null
                          : () {
                              _handleSkipTap(handleSkip!);
                            },
                      isForward: true,
                      minWidth: 120,
                      isLoading: _isNavigatingSkip,
                    ),
                  if (hasSkip && hasNext) const SizedBox(width: 12),
                  if (hasNext)
                    _NavigationButton(
                      icon: Icons.arrow_forward_ios,
                      label: 'Next',
                      onPressed: _isNavigatingNext
                          ? null
                          : () {
                              _handleNextTap(context, handleNext);
                            },
                      isForward: true,
                      minWidth: 120,
                      isLoading: _isNavigatingNext,
                    )
                  else
                    const Spacer(),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isForward;
  final double? minWidth;
  final bool isLoading;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isForward,
    this.minWidth,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFC812);
    const primaryText = Color(0xFF1A1D1F);
    const cardBorder = Color(0xFFE4E7EC);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isForward ? accentColor : Colors.white,
        foregroundColor: primaryText,
        disabledBackgroundColor:
            isForward ? accentColor.withOpacity(0.4) : Colors.white,
        disabledForegroundColor: primaryText.withOpacity(0.45),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: minWidth == null ? null : Size(minWidth!, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: onPressed == null
                ? cardBorder
                : (isForward ? accentColor : cardBorder),
            width: 1,
          ),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isForward) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryText.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryText.withOpacity(0.6),
                    ),
                  ),
                  if (isForward) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryText.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isForward) ...[
                    Icon(icon, size: 18, color: primaryText),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  if (isForward) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: primaryText),
                  ],
                ],
              ),
      ),
    );
  }
}
