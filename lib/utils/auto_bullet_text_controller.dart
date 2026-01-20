import 'package:flutter/material.dart';

/// Mixin that adds auto-bullet point functionality to TextEditingController
/// Automatically inserts "• " at the start of the field and after every newline
class AutoBulletTextController extends TextEditingController {
  AutoBulletTextController({String? text}) : super(text: text) {
    _setupListener();
  }

  void _setupListener() {
    addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final currentText = text;
    final selection = this.selection;
    
    // If field is empty, insert bullet at start
    if (currentText.isEmpty) {
      value = const TextEditingValue(
        text: '• ',
        selection: TextSelection.collapsed(offset: 2),
      );
      return;
    }
    
    // Check if we need to add bullet after newline
    final textBeforeCursor = currentText.substring(0, selection.baseOffset);
    final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');
    
    if (lastNewlineIndex != -1) {
      // Check if there's already a bullet after this newline
      final afterNewline = textBeforeCursor.substring(lastNewlineIndex + 1);
      if (afterNewline.trim().isEmpty && !afterNewline.startsWith('• ')) {
        // Insert bullet after newline
        final newText = currentText.substring(0, lastNewlineIndex + 1) +
            '• ' +
            currentText.substring(selection.baseOffset);
        final newOffset = selection.baseOffset + 2;
        
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
        return;
      }
    }
    
    // Ensure first character is bullet if field has content but doesn't start with bullet
    if (currentText.isNotEmpty && !currentText.startsWith('• ')) {
      // Only add if it's a new field (no newlines yet)
      if (!currentText.contains('\n')) {
        value = TextEditingValue(
          text: '• $currentText',
          selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    removeListener(_handleTextChange);
    super.dispose();
  }
}

/// Extension to easily add auto-bullet functionality to existing controllers
extension AutoBulletExtension on TextEditingController {
  /// Attaches auto-bullet listener to this controller
  void enableAutoBullet() {
    addListener(_autoBulletListener);
  }

  /// Removes auto-bullet listener from this controller
  void disableAutoBullet() {
    removeListener(_autoBulletListener);
  }

  void _autoBulletListener() {
    final currentText = text;
    final selection = this.selection;
    
    // If field is empty, insert bullet at start
    if (currentText.isEmpty) {
      value = const TextEditingValue(
        text: '• ',
        selection: TextSelection.collapsed(offset: 2),
      );
      return;
    }
    
    // Check if we need to add bullet after newline
    final textBeforeCursor = currentText.substring(0, selection.baseOffset);
    final lastNewlineIndex = textBeforeCursor.lastIndexOf('\n');
    
    if (lastNewlineIndex != -1) {
      // Check if there's already a bullet after this newline
      final afterNewline = textBeforeCursor.substring(lastNewlineIndex + 1);
      if (afterNewline.trim().isEmpty && !afterNewline.startsWith('• ')) {
        // Insert bullet after newline
        final newText = currentText.substring(0, lastNewlineIndex + 1) +
            '• ' +
            currentText.substring(selection.baseOffset);
        final newOffset = selection.baseOffset + 2;
        
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
        return;
      }
    }
    
    // Ensure first character is bullet if field has content but doesn't start with bullet
    if (currentText.isNotEmpty && !currentText.contains('\n') && !currentText.startsWith('• ')) {
      value = TextEditingValue(
        text: '• $currentText',
        selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
      );
    }
  }
}
