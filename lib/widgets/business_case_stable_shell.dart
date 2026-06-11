import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

/// Stable shell for Business Case screens that prevents the header from
/// overlapping the sidebar. Follows the same proven pattern as
/// [DesignPhaseStableShell] but adds [DraggableSidebar] support.
///
/// **Desktop layout:**
/// ```
/// Row [
///   DraggableSidebar,      ← fixed-width sidebar + drag handle
///   Expanded → Column [    ← header constrained to content area
///     UnifiedPhaseHeader,
///     headerBottom,
///     Expanded(child),
///   ],
/// ]
/// ```
///
/// **Mobile layout:**
/// ```
/// Scaffold(
///   drawer: MobileSidebarDrawer,
///   body: SafeArea → Column [
///     UnifiedPhaseHeader,
///     headerBottom,
///     Expanded(Stack [child, KazAiChatBubble]),
///   ],
/// )
/// ```
class BusinessCaseStableShell extends StatelessWidget {
  const BusinessCaseStableShell({
    super.key,
    required this.activeLabel,
    required this.child,
    this.headerBottom,
    this.breadcrumbPhase,
    this.breadcrumbTitle,
    this.showExportPdf = false,
    this.showAiAssist = false,
    this.onExportPdf,
    this.onAiAssist,
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
    this.scaffoldKey,
    this.floatingOverlay,
  });

  /// The label for the active sidebar item.
  final String activeLabel;

  /// The main content area (scrollable body of the screen).
  final Widget child;

  /// Optional widget rendered directly below the header (e.g. action buttons).
  final Widget? headerBottom;

  /// Breadcrumb phase label (e.g. "Initiation Phase").
  final String? breadcrumbPhase;

  /// Breadcrumb page title (e.g. "Risk Identification").
  final String? breadcrumbTitle;

  /// Show Export PDF button in the header.
  final bool showExportPdf;

  /// Show AI Assist button in the header.
  final bool showAiAssist;

  /// Callback for Export PDF button.
  final VoidCallback? onExportPdf;

  /// Callback for AI Assist button.
  final VoidCallback? onAiAssist;

  /// Show activity log action in the header.
  final bool showActivityLogAction;

  /// Callback for activity log action.
  final VoidCallback? onOpenActivityLog;

  /// Optional scaffold key for drawer control.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Optional overlay widget to render in a Stack above the content
  /// (e.g. AdminEditToggle, loading overlays).
  final Widget? floatingOverlay;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return _buildMobile(context);
    }
    return _buildDesktop(context);
  }

  // ─── Desktop: sidebar + header inside Expanded ─────────────────────────
  Widget _buildDesktop(BuildContext context) {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            // Main layout: sidebar | content (header + body)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar — fixed width, never overlaps header
                DraggableSidebar(
                  openWidth: sidebarWidth,
                  child: InitiationLikeSidebar(
                    activeItemLabel: activeLabel,
                    showHeader: true,
                  ),
                ),
                // Content area — header is INSIDE Expanded so it respects
                // the remaining width after the sidebar
                Expanded(
                  child: Column(
                    children: [
                      UnifiedPhaseHeader(
                        title: breadcrumbTitle ?? activeLabel,
                        breadcrumbPhase: breadcrumbPhase,
                        breadcrumbTitle: breadcrumbTitle,
                        scaffoldKey: scaffoldKey,
                        showDrawerButton: false,
                        showActivityLogAction: showActivityLogAction,
                        onOpenActivityLog: onOpenActivityLog,
                        showExportPdf: showExportPdf,
                        showAiAssist: showAiAssist,
                        onExportPdf: onExportPdf,
                        onAiAssist: onAiAssist,
                      ),
                      if (headerBottom != null) headerBottom!,
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
            // Floating overlays (positioned above content)
            if (floatingOverlay != null) floatingOverlay!,
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  // ─── Mobile: drawer + header at top ─────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: MobileSidebarDrawer(
        sidebar: InitiationLikeSidebar(
          activeItemLabel: activeLabel,
          showHeader: true,
        ),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            UnifiedPhaseHeader(
              title: breadcrumbTitle ?? activeLabel,
              breadcrumbPhase: breadcrumbPhase,
              breadcrumbTitle: breadcrumbTitle,
              scaffoldKey: scaffoldKey,
              showDrawerButton: true,
              showActivityLogAction: showActivityLogAction,
              onOpenActivityLog: onOpenActivityLog,
              showExportPdf: showExportPdf,
              showAiAssist: showAiAssist,
              onExportPdf: onExportPdf,
              onAiAssist: onAiAssist,
            ),
            if (headerBottom != null) headerBottom!,
            Expanded(
              child: Stack(
                children: [
                  child,
                  const KazAiChatBubble(positioned: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
