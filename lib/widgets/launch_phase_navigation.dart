import 'package:flutter/material.dart';

/// Shared navigation footer used across the Launch Phase pages.
class LaunchPhaseNavigation extends StatelessWidget {
  const LaunchPhaseNavigation({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  static const _kAccentColor = Color(0xFFFFC812);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    final backButton = OutlinedButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, size: 18, color: _kAccentColor),
      label: Text(
        backLabel,
        style: const TextStyle(fontWeight: FontWeight.w600, color: _kAccentColor),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kAccentColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final nextButton = ElevatedButton.icon(
      onPressed: onNext,
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: Text(
        nextLabel,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kAccentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
    );

    if (isMobile) {
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
        backButton,
        const Spacer(),
        nextButton,
      ],
    );
  }
}
