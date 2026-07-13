import 'package:flutter/material.dart';

/// A reusable widget that wraps any content section and adds an expand button.
/// When expanded, the content overlays the entire screen in a focused view.
/// Users can tap the expand button to pop out a section for focused work,
/// then collapse it back to its original position.
///
/// Usage:
/// ```dart
/// ExpandableSection(
///   title: 'Goal Details',
///   child: YourContentWidget(),
/// )
/// ```
class ExpandableSection extends StatefulWidget {
  /// The content to display inside the expandable section.
  final Widget child;

  /// Title shown in the expanded overlay header.
  final String? title;

  /// Whether the section starts expanded.
  final bool initiallyExpanded;

  /// Background color when expanded.
  final Color? expandedBackgroundColor;

  /// Accent color for the expand button and header.
  final Color accentColor;

  /// Whether to show the expand button. Defaults to true.
  final bool showExpandButton;

  /// Optional tooltip for the expand button.
  final String expandTooltip;

  const ExpandableSection({
    super.key,
    required this.child,
    this.title,
    this.initiallyExpanded = false,
    this.expandedBackgroundColor,
    this.accentColor = const Color(0xFFFFC107),
    this.showExpandButton = true,
    this.expandTooltip = 'Expand to full screen',
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_isExpanded) {
      _collapseSection();
    } else {
      _expandSection();
    }
  }

  void _expandSection() {
    setState(() => _isExpanded = true);
    _controller.forward();

    // Show full-screen overlay
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ExpandedOverlay(
            title: widget.title ?? 'Expanded View',
            accentColor: widget.accentColor,
            backgroundColor: widget.expandedBackgroundColor,
            animation: animation,
            onCollapse: _collapseSection,
            child: widget.child,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
          );
        },
      ),
    ).then((_) {
      // Handle back button press
      if (mounted && _isExpanded) {
        setState(() => _isExpanded = false);
        _controller.reverse();
      }
    });
  }

  void _collapseSection() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() => _isExpanded = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,

        // Expand button
        if (widget.showExpandButton)
          Positioned(
            top: 8,
            right: 8,
            child: _ExpandButton(
              isExpanded: _isExpanded,
              accentColor: widget.accentColor,
              tooltip: _isExpanded ? 'Collapse' : widget.expandTooltip,
              onPressed: _toggleExpand,
            ),
          ),
      ],
    );
  }
}

/// The expand button with hover effects.
class _ExpandButton extends StatefulWidget {
  final bool isExpanded;
  final Color accentColor;
  final String tooltip;
  final VoidCallback onPressed;

  const _ExpandButton({
    required this.isExpanded,
    required this.accentColor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_ExpandButton> createState() => _ExpandButtonState();
}

class _ExpandButtonState extends State<_ExpandButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.accentColor
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering
                  ? widget.accentColor
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                widget.isExpanded
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                size: 18,
                color: _isHovering
                    ? Colors.white
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-screen overlay shown when a section is expanded.
class _ExpandedOverlay extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Color? backgroundColor;
  final Animation<double> animation;
  final VoidCallback onCollapse;
  final Widget child;

  const _ExpandedOverlay({
    required this.title,
    required this.accentColor,
    this.backgroundColor,
    required this.animation,
    required this.onCollapse,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header bar
                _buildHeader(context),
                // Expanded content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Accent dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Collapse button
          IconButton(
            icon: const Icon(
              Icons.fullscreen_exit_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Collapse',
            onPressed: onCollapse,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience wrapper for adding expand functionality to any widget.
///
/// This is the recommended way to add expand/collapse to existing screens:
/// ```dart
/// SectionWithExpand(
///   title: 'Project Goals',
///   child: GoalsContentWidget(),
/// )
/// ```
class SectionWithExpand extends StatelessWidget {
  final Widget child;
  final String title;
  final Color accentColor;

  const SectionWithExpand({
    super.key,
    required this.child,
    required this.title,
    this.accentColor = const Color(0xFFFFC107),
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableSection(
      title: title,
      accentColor: accentColor,
      child: child,
    );
  }
}
