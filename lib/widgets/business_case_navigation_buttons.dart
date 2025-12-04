import 'package:flutter/material.dart';
import 'package:ndu_project/utils/business_case_navigation.dart';

/// Navigation buttons for Business Case screens
class BusinessCaseNavigationButtons extends StatelessWidget {
  final String currentScreen;
  final EdgeInsets? padding;

  const BusinessCaseNavigationButtons({
    super.key,
    required this.currentScreen,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrevious = BusinessCaseNavigation.hasPrevious(currentScreen);
    final hasNext = BusinessCaseNavigation.hasNext(currentScreen);

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (hasPrevious)
            _NavigationButton(
              icon: Icons.arrow_back_ios_new,
              label: 'Back',
              onPressed: () => BusinessCaseNavigation.navigateBack(context, currentScreen),
              isForward: false,
            )
          else
            const SizedBox(width: 120),

          // Forward button
          if (hasNext)
            _NavigationButton(
              icon: Icons.arrow_forward_ios,
              label: 'Next',
              onPressed: () => BusinessCaseNavigation.navigateForward(context, currentScreen),
              isForward: true,
            )
          else
            const SizedBox(width: 120),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isForward;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isForward,
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
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isForward ? accentColor : cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
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
    );
  }
}
