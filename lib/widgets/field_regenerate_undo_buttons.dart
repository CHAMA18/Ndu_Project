import 'package:flutter/material.dart';

/// Reusable field-level regenerate and undo buttons
/// Shows on hover over text fields that have AI-generated content
class FieldRegenerateUndoButtons extends StatelessWidget {
  const FieldRegenerateUndoButtons({
    super.key,
    required this.onRegenerate,
    required this.onUndo,
    required this.canUndo,
    this.isLoading = false,
    this.size = 16,
  });

  final VoidCallback onRegenerate;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isLoading;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: isLoading
              ? SizedBox(
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                )
              : const Icon(Icons.refresh, size: 16, color: Color(0xFF2563EB)),
          tooltip: 'Regenerate this field',
          onPressed: isLoading ? null : onRegenerate,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: Icon(
            Icons.undo,
            size: size,
            color: canUndo ? const Color(0xFF6B7280) : Colors.grey,
          ),
          tooltip: 'Undo last change',
          onPressed: canUndo ? onUndo : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

/// Wrapper widget that shows regenerate/undo buttons on hover
class HoverableFieldControls extends StatefulWidget {
  const HoverableFieldControls({
    super.key,
    required this.child,
    required this.onRegenerate,
    required this.onUndo,
    required this.canUndo,
    this.isAiGenerated = false,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback onRegenerate;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isAiGenerated;
  final bool isLoading;

  @override
  State<HoverableFieldControls> createState() => _HoverableFieldControlsState();
}

class _HoverableFieldControlsState extends State<HoverableFieldControls> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isAiGenerated) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          widget.child,
          if (_isHovering)
            Positioned(
              right: 8,
              top: 8,
              child: FieldRegenerateUndoButtons(
                onRegenerate: widget.onRegenerate,
                onUndo: widget.onUndo,
                canUndo: widget.canUndo,
                isLoading: widget.isLoading,
              ),
            ),
        ],
      ),
    );
  }
}
