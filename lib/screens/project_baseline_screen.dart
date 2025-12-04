import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ProjectBaselineScreen extends StatefulWidget {
  const ProjectBaselineScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectBaselineScreen()),
    );
  }

  @override
  State<ProjectBaselineScreen> createState() => _ProjectBaselineScreenState();
}

class _ProjectBaselineScreenState extends State<ProjectBaselineScreen> {
  static const List<String> _projectOptions = [
    'Cloud Migration Project',
    'Data Platform Refresh',
    'Mobile App Modernization',
  ];

  static const List<_BaselineHistoryEntry> _history = [
    _BaselineHistoryEntry(
      version: 'Baseline v1.0',
      date: 'Jan 15, 2023',
      approvedBy: 'Robert Chen',
      description: 'Initial project baseline',
    ),
    _BaselineHistoryEntry(
      version: 'Baseline v1.1',
      date: 'Mar 01, 2023',
      approvedBy: 'Robert Chen',
      description: 'Updated after requirements phase',
    ),
  ];

  static const List<_ScheduleVarianceRow> _scheduleVariance = [
    _ScheduleVarianceRow(
      label: 'Requirements Phase',
      varianceLabel: 'On time',
      progress: 0.25,
      tone: _VarianceTone.onTrack,
    ),
    _ScheduleVarianceRow(
      label: 'Design Phase',
      varianceLabel: 'On time',
      progress: 0.5,
      tone: _VarianceTone.onTrack,
    ),
    _ScheduleVarianceRow(
      label: 'Development Phase',
      varianceLabel: '+7 days',
      progress: 0.68,
      tone: _VarianceTone.behind,
    ),
    _ScheduleVarianceRow(
      label: 'Testing Phase',
      varianceLabel: '+8 days (planned)',
      progress: 0.42,
      tone: _VarianceTone.warning,
    ),
  ];

  static const List<_CostVarianceRow> _costVariance = [
    _CostVarianceRow(
      category: 'Hardware & Infrastructure',
      actual: '\$180,000',
      planned: '\$175,000',
    ),
    _CostVarianceRow(
      category: 'Software Licenses',
      actual: '\$95,000',
      planned: '\$85,000',
    ),
    _CostVarianceRow(
      category: 'Development Resources',
      actual: '\$325,000',
      planned: '\$300,000',
    ),
    _CostVarianceRow(
      category: 'Testing & QA',
      actual: '\$82,500',
      planned: '\$80,000',
    ),
  ];

  String _selectedProject = _projectOptions.first;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'Project Baseline'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildBaselineCards(context),
                        const SizedBox(height: 24),
                        _buildBaselineHistory(),
                        const SizedBox(height: 24),
                        _buildVarianceAnalysis(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Baseline',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor schedule, cost, and scope baselines to keep delivery commitments visible and actionable.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Update Baseline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildProjectDropdown(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _StatusChip(label: 'On Track', color: Color(0xFF047857)),
                _StatusChip(label: 'Start: Jan 15, 2023', color: Color(0xFF1F2937), inverted: true),
                _StatusChip(label: 'End: Dec 20, 2023', color: Color(0xFF1F2937), inverted: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          items: _projectOptions
              .map(
                (project) => DropdownMenuItem<String>(
                  value: project,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(project),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedProject = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBaselineCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite) {
          availableWidth = MediaQuery.of(context).size.width;
        }

        int columns;
        if (availableWidth >= 1080) {
          columns = 3;
        } else if (availableWidth >= 720) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;
        final double cardWidth = columns == 1
            ? availableWidth
            : (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: [
            SizedBox(width: cardWidth, child: _buildScheduleBaselineCard()),
            SizedBox(width: cardWidth, child: _buildCostBaselineCard()),
            SizedBox(width: cardWidth, child: _buildScopeBaselineCard()),
          ],
        );
      },
    );
  }

  Widget _buildScheduleBaselineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x331D4ED8), blurRadius: 24, offset: Offset(0, 20)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Schedule Baseline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._scheduleDetails.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detail.label,
                    style: const TextStyle(
                      color: Color(0xCCEFF6FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 14,
              color: const Color(0xFF60A5FA),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start',
                style: TextStyle(color: Color(0xCCEFF6FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Current Progress (68%)',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                'End',
                style: TextStyle(color: Color(0xCCEFF6FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBaselineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1F2937), size: 22),
              SizedBox(width: 10),
              Text(
                'Cost Baseline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._costDetails.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    detail.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Budget Variance',
                  style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w700),
                ),
                Text(
                  '+\$32,500 (5%)',
                  style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeBaselineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dashboard_customize_outlined, color: Color(0xFF1F2937), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Scope Baseline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildScopeStatRow('Last Baseline Date', 'Mar 01, 2023'),
                    _buildScopeStatRow('Original EPICs', '5'),
                    _buildScopeStatRow('Current EPICs', '6'),
                    _buildScopeStatRow('Original Features', '18'),
                    _buildScopeStatRow('Current Features', '22'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(label: 'On Track', color: Color(0xFF047857)),
                  SizedBox(height: 12),
                  Text(
                    'Start: Jan 15, 2023',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    'End: Dec 20, 2023',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.trending_up, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Text(
                  'Scope Change:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+1 EPIC, +4 Features',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineHistory() {
    return Container(
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Baseline History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 18),
          _buildHistoryHeaderRow(),
          const SizedBox(height: 12),
          ..._history.map((entry) => _buildHistoryRow(entry)),
        ],
      ),
    );
  }

  Widget _buildHistoryHeaderRow() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'Baseline Version',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            'Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Approved By',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            'Actions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(_BaselineHistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.version,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            child: Text(
              entry.date,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.approvedBy,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'View baseline',
              onPressed: () {},
              icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceAnalysis() {
    return Container(
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool singleColumn = constraints.maxWidth < 820;
          final schedule = _buildScheduleVarianceColumn();
          final cost = _buildCostVarianceColumn();

          if (singleColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                schedule,
                const SizedBox(height: 24),
                cost,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: schedule),
              const SizedBox(width: 24),
              Expanded(child: cost),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleVarianceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Variance Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 18),
        ..._scheduleVariance.map(
          (variance) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variance.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      variance.varianceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: variance.tone.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: variance.progress,
                    minHeight: 12,
                    color: variance.tone.barColor,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostVarianceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost Variance Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 18),
        ..._costVariance.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.category,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${row.actual} (planned: ${row.planned})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Variance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            Text(
              '+\$32,500 (5%)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _BaselineHistoryEntry {
  const _BaselineHistoryEntry({
    required this.version,
    required this.date,
    required this.approvedBy,
    required this.description,
  });

  final String version;
  final String date;
  final String approvedBy;
  final String description;
}

class _ScheduleVarianceRow {
  const _ScheduleVarianceRow({
    required this.label,
    required this.varianceLabel,
    required this.progress,
    required this.tone,
  });

  final String label;
  final String varianceLabel;
  final double progress;
  final _VarianceTone tone;
}

class _CostVarianceRow {
  const _CostVarianceRow({
    required this.category,
    required this.actual,
    required this.planned,
  });

  final String category;
  final String actual;
  final String planned;
}

Widget _buildScopeStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, this.inverted = false});

  final String label;
  final Color color;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final Color background = inverted ? const Color(0xFFF3F4F6) : color.withValues(alpha: 0.12);
    final Color foreground = inverted ? color : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class _VarianceTone {
  const _VarianceTone._(this.color, this.barColor);

  final Color color;
  final Color barColor;

  static const _VarianceTone onTrack = _VarianceTone._(Color(0xFF047857), Color(0xFF10B981));
  static const _VarianceTone warning = _VarianceTone._(Color(0xFFB45309), Color(0xFFFBBF24));
  static const _VarianceTone behind = _VarianceTone._(Color(0xFFB91C1C), Color(0xFFF87171));
}

class _ScheduleDetail {
  const _ScheduleDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class _CostDetail {
  const _CostDetail({required this.label, required this.value});

  final String label;
  final String value;
}

const List<_ScheduleDetail> _scheduleDetails = [
  _ScheduleDetail(label: 'Last Baseline Date', value: 'Mar 01, 2023'),
  _ScheduleDetail(label: 'Original Start Date', value: 'Jan 15, 2023'),
  _ScheduleDetail(label: 'Original End Date', value: 'Oct 15, 2023'),
  _ScheduleDetail(label: 'Current End Date', value: 'Oct 30, 2023'),
  _ScheduleDetail(label: 'Schedule Variance', value: '+15 days'),
];

const List<_CostDetail> _costDetails = [
  _CostDetail(label: 'Last Baseline Date', value: 'Mar 01, 2023'),
  _CostDetail(label: 'Original Budget', value: '\$650,000'),
  _CostDetail(label: 'Current Budget', value: '\$682,500'),
  _CostDetail(label: 'Spent to Date', value: '\$423,500'),
  _CostDetail(label: 'Budget Variance', value: '+\$32,500 (5%)'),
];
