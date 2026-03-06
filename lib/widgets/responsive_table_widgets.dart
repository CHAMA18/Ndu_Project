import 'package:flutter/material.dart';

/// Responsive wrapper for data tables with horizontal scroll support
class ResponsiveDataTableWrapper extends StatefulWidget {
  final Widget child;
  final double? minWidth;
  final double? maxHeight;

  const ResponsiveDataTableWrapper({
    super.key,
    required this.child,
    this.minWidth,
    this.maxHeight,
  });

  @override
  State<ResponsiveDataTableWrapper> createState() =>
      _ResponsiveDataTableWrapperState();
}

class _ResponsiveDataTableWrapperState extends State<ResponsiveDataTableWrapper> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _canScrollRight = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_updateScrollIndicators);
    _verticalController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollIndicators());
  }

  @override
  void dispose() {
    _horizontalController
      ..removeListener(_updateScrollIndicators)
      ..dispose();
    _verticalController
      ..removeListener(_updateScrollIndicators)
      ..dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!mounted) return;
    final h = _horizontalController.hasClients
        ? _horizontalController.position
        : null;
    final v =
        _verticalController.hasClients ? _verticalController.position : null;
    final canRight = h != null &&
        h.maxScrollExtent > 0 &&
        h.pixels < h.maxScrollExtent - 1;
    final canDown =
        v != null && v.maxScrollExtent > 0 && v.pixels < v.maxScrollExtent - 1;
    if (canRight != _canScrollRight || canDown != _canScrollDown) {
      setState(() {
        _canScrollRight = canRight;
        _canScrollDown = canDown;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalChild = SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minWidth ?? constraints.maxWidth,
            ),
            child: widget.child,
          ),
        );

        final tableContent = widget.maxHeight == null
            ? horizontalChild
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight!),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: horizontalChild,
                  ),
                ),
              );

        return Stack(
          children: [
            Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.depth == 0 &&
                  notification.metrics.axis == Axis.horizontal,
              child: tableContent,
            ),
            if (_canScrollRight)
              Positioned(
                top: 0,
                right: 0,
                bottom: widget.maxHeight == null ? 0 : 18,
                child: IgnorePointer(
                  child: Container(
                    width: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0x00FFFFFF), Color(0xFFF8FAFC)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_canScrollDown)
              Positioned(
                left: 0,
                right: 18,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Color(0xFFF8FAFC)],
                      ),
                    ),
                  ),
                ),
              ),
            if (_canScrollRight)
              const Positioned(
                right: 8,
                bottom: 2,
                child: Text(
                  'Scroll to see more ->',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Truncated cell for data tables with tooltip
class TruncatedTableCell extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final double? maxWidth;

  const TruncatedTableCell({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget =Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (text.length > 30) {
      return Tooltip(
        message: text,
        child: maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: textWidget,
              )
            : textWidget,
      );
    }

    return maxWidth != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: textWidget,
          )
        : textWidget;
  }
}
