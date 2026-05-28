import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class PlanningPhaseHeader extends StatelessWidget {
  const PlanningPhaseHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onForward,
    this.showNavigationButtons = true,
    this.showImportButton = true,
    this.showContentButton = true,
    this.onImportPressed,
    this.onContentPressed,
    this.breadcrumbPhase,
    this.breadcrumbTitle,
    this.showExportPdf = true,
    this.showAiAssist = true,
    this.onExportPdf,
    this.onAiAssist,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final bool showNavigationButtons;
  final bool showImportButton;
  final bool showContentButton;
  final VoidCallback? onImportPressed;
  final VoidCallback? onContentPressed;
  final String? breadcrumbPhase;
  final String? breadcrumbTitle;
  final bool showExportPdf;
  final bool showAiAssist;
  final VoidCallback? onExportPdf;
  final VoidCallback? onAiAssist;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UnifiedPhaseHeader(
          title: title,
          breadcrumbPhase: breadcrumbPhase,
          breadcrumbTitle: breadcrumbTitle,
          showDrawerButton: true,
          onBackPressed: showNavigationButtons
              ? onBack ?? () => Navigator.maybePop(context)
              : null,
          onForwardPressed: showNavigationButtons ? onForward : null,
          showActivityLogAction: true,
        ),
        if (showImportButton || showContentButton || showExportPdf || showAiAssist) ...[
          if (isMobile)
            const SizedBox(height: 12)
          else
            const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (showImportButton)
                  _YellowButton(
                    label: 'Import',
                    icon: Icons.upload_outlined,
                    onPressed: onImportPressed ?? () {},
                  ),
                if (showContentButton)
                  _WhiteButton(
                    label: 'Content',
                    icon: Icons.download_outlined,
                    onPressed: onContentPressed ?? () {},
                  ),
                if (showExportPdf)
                  _WhiteButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: onExportPdf ?? () => _defaultExportPdf(context),
                  ),
                if (showAiAssist)
                  _AiAssistButton(
                    label: 'AI Assist',
                    icon: Icons.auto_awesome,
                    onPressed: onAiAssist ?? () => _defaultAiAssist(context),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _defaultExportPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export PDF coming soon for this section.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _defaultAiAssist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Assist will generate content for this section.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton(
      {required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AiAssistButton extends StatelessWidget {
  const _AiAssistButton(
      {required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4154F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
