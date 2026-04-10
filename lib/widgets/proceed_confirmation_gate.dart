import 'package:flutter/material.dart';

Future<bool> showProceedWithoutReviewDialog(
  BuildContext context, {
  String title = 'Review Not Confirmed',
  String message =
      'You have not confirmed this page yet. You can continue now and complete the missing information later, or stay and update it now.',
  String stayLabel = 'Add Info Now',
  String continueLabel = 'Continue Anyway',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 13.5, height: 1.35),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(stayLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC812),
            foregroundColor: const Color(0xFF111827),
          ),
          child: Text(continueLabel),
        ),
      ],
    ),
  );

  return result ?? false;
}

/// Standard review gate shown before users can continue from AI-heavy or
/// detail-heavy pages.
class ProceedConfirmationGate extends StatefulWidget {
  const ProceedConfirmationGate({
    super.key,
    required this.value,
    required this.onChanged,
    this.scrollController,
    this.label =
        'I confirm that I have reviewed all information on this page before proceeding.',
    this.padding = EdgeInsets.zero,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final ScrollController? scrollController;
  final String label;
  final EdgeInsetsGeometry padding;

  @override
  State<ProceedConfirmationGate> createState() =>
      _ProceedConfirmationGateState();
}

class _ProceedConfirmationGateState extends State<ProceedConfirmationGate> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_updateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didUpdateWidget(covariant ProceedConfirmationGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_updateVisibility);
      widget.scrollController?.addListener(_updateVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_updateVisibility);
    super.dispose();
  }

  void _updateVisibility() {
    final controller = widget.scrollController;
    var nextVisible = true;
    if (controller != null && controller.hasClients) {
      final position = controller.position;
      final hasOverflow = position.maxScrollExtent > 1;
      final isAtBottom = position.pixels >= position.maxScrollExtent - 8;
      nextVisible = !hasOverflow || isAtBottom;
    }

    if (nextVisible != _isVisible && mounted) {
      setState(() => _isVisible = nextVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: !_isVisible
          ? const SizedBox.shrink()
          : Padding(
              key: const ValueKey('proceed-confirmation-gate'),
              padding: widget.padding,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: widget.value,
                      onChanged: (value) => widget.onChanged(value ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
