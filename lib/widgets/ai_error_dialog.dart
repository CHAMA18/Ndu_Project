import 'package:flutter/material.dart';
import 'package:ndu_project/openai/openai_config.dart';

String _friendlyMessage(Object error) {
  if (error is OpenAiNotConfiguredException) {
    return 'OpenAI API key is not configured. Please add a valid API key in Settings to enable AI features.';
  }

  final message = error.toString();
  final lower = message.toLowerCase();

  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'The AI took too long to respond. Please try again in a moment.';
  }
  if (lower.contains('rate limit') || lower.contains('429')) {
    return 'AI rate limit reached. Please wait a moment and try again.';
  }
  if (lower.contains('401') ||
      lower.contains('api key') && lower.contains('invalid') ||
      lower.contains('rejected')) {
    return 'The API key was rejected. Please verify your OpenAI configuration in Settings.';
  }
  if (lower.contains('cors')) {
    return 'A connection issue was detected. Please check your OpenAI proxy endpoint configuration.';
  }
  if (lower.contains('quota') || lower.contains('billing')) {
    return 'Your OpenAI account has exceeded its usage quota. Please check your billing plan.';
  }

  return 'Something went wrong with the AI assistant. Please try again.';
}

Future<void> showAiErrorDialog(
  BuildContext context, {
  required Object error,
  VoidCallback? onRetry,
  String? title,
  String? customMessage,
}) async {
  final theme = Theme.of(context);
  final message = customMessage ?? _friendlyMessage(error);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title ?? 'AI Assistant',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Dismiss'),
        ),
      ],
    ),
  );
}
