import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class ProjectPlanScreen extends StatefulWidget {
  const ProjectPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectPlanScreen()),
    );
  }

  @override
  State<ProjectPlanScreen> createState() => _ProjectPlanScreenState();
}

class _ProjectPlanScreenState extends State<ProjectPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedProject = 'Cloud Migration Project';

  static const List<_Deliverable> _deliverables = [
    _Deliverable(id: 'D-001', name: 'Requirements Document', phase: 'Planning', dueDate: 'Feb 28, 2023', status: 'Completed', owner: 'Sarah Johnson'),
    _Deliverable(id: 'D-002', name: 'System Architecture Design', phase: 'Design', dueDate: 'Apr 15, 2023', status: 'Completed', owner: 'Mark Taylor'),
    _Deliverable(id: 'D-003', name: 'Database Schema', phase: 'Design', dueDate: 'Apr 30, 2023', status: 'In Progress', owner: 'Jennifer Lee'),
    _Deliverable(id: 'D-004', name: 'UI/UX Design Mockups', phase: 'Design', dueDate: 'May 15, 2023', status: 'In Progress', owner: 'Michael Wong'),
    _Deliverable(id: 'D-005', name: 'Test Plan', phase: 'Testing', dueDate: 'Jul 1, 2023', status: 'Not Started', owner: 'Laura Smith'),
  ];

  static const List<_CommunicationPlan> _communications = [
    _CommunicationPlan(meetingType: 'Status Update', frequency: 'Weekly', attendees: 'Project Team', purpose: 'Review progress, discuss blockers, plan for the week'),
    _CommunicationPlan(meetingType: 'Steering Committee', frequency: 'Monthly', attendees: 'Executive Sponsors, Project Manager', purpose: 'Review project status, budget, timeline, risks'),
    _CommunicationPlan(meetingType: 'Technical Sync', frequency: 'Bi-weekly', attendees: 'Technical Team', purpose: 'Discuss technical challenges and solutions'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 36;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Plan'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isMobile),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'AI Notes',
                          sectionLabel: 'Project Plan',
                          noteKey: 'planning_project_plan_notes',
                          checkpoint: 'project_plan',
                          description: 'Summarize the project plan, key deliverables, and alignment checkpoints.',
                        ),
                        const SizedBox(height: 24),
                        _ProjectPlanOverviewCard(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _buildTabBar(),
                        const SizedBox(height: 24),
                        _KeyDeliverablesCard(deliverables: _deliverables, isMobile: isMobile),
                        const SizedBox(height: 24),
                        _CommunicationPlanCard(communications: _communications, isMobile: isMobile),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Project Plan',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const Spacer(),
                    _buildExportButton(),
                    const SizedBox(width: 8),
                    _buildEditPlanButton(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProjectDropdown(),
                const SizedBox(height: 12),
                _buildStatusBadges(),
              ],
            )
          : Row(
              children: [
                const Text(
                  'Project Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(width: 32),
                _buildProjectDropdown(),
                const Spacer(),
                _buildStatusBadges(),
                const SizedBox(width: 16),
                _buildExportButton(),
                const SizedBox(width: 10),
                _buildEditPlanButton(),
              ],
            ),
    );
  }

  Widget _buildProjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: 'Cloud Migration Project', child: Text('Cloud Migration Project')),
            DropdownMenuItem(value: 'ERP Implementation', child: Text('ERP Implementation')),
            DropdownMenuItem(value: 'Mobile App Development', child: Text('Mobile App Development')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedProject = value);
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('On Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            const Text('Start Jan 15, 2023', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            const Text('End Dec 28, 2023', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.file_download_outlined, size: 18),
      label: const Text('Export'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildEditPlanButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Edit Plan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 2,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Resources'),
          Tab(text: 'Tasks'),
          Tab(text: 'Budget'),
          Tab(text: 'Risks'),
        ],
      ),
    );
  }
}

class _Deliverable {
  const _Deliverable({
    required this.id,
    required this.name,
    required this.phase,
    required this.dueDate,
    required this.status,
    required this.owner,
  });

  final String id;
  final String name;
  final String phase;
  final String dueDate;
  final String status;
  final String owner;
}

class _CommunicationPlan {
  const _CommunicationPlan({
    required this.meetingType,
    required this.frequency,
    required this.attendees,
    required this.purpose,
  });

  final String meetingType;
  final String frequency;
  final String attendees;
  final String purpose;
}

class _ProjectPlanOverviewCard extends StatelessWidget {
  const _ProjectPlanOverviewCard({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Plan Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 24),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectDetails(),
                    const SizedBox(height: 24),
                    _buildProjectObjectives(),
                    const SizedBox(height: 24),
                    _buildProjectScope(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildProjectDetails()),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildProjectObjectives()),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _buildProjectScope()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Project Name:', 'Cloud Migration Project'),
        const SizedBox(height: 10),
        _buildDetailRow('Project Manager:', 'Alex Johnson'),
        const SizedBox(height: 10),
        _buildDetailRow('Sponsor:', 'Sarah Williams, CTO'),
        const SizedBox(height: 10),
        _buildDetailRow('Methodology:', 'Hybrid (Agile/Waterfall)'),
        const SizedBox(height: 10),
        _buildDetailRow('Start Date:', 'January 15, 2023'),
        const SizedBox(height: 10),
        _buildDetailRow('End Date:', 'December 28, 2023'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectObjectives() {
    const objectives = [
      'Complete migration of all enterprise applications to cloud',
      'Ensure 99.9% uptime during and after migration',
      'Reduce operational IT costs by 30%',
      'Improve disaster recovery capabilities with RPO < 15min',
      'Enhance security posture with zero critical vulnerabilities',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Objectives',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        ...objectives.map((obj) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  Expanded(
                    child: Text(obj, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildProjectScope() {
    const scopes = [
      'All enterprise applications (42 total)',
      'Customer data warehouse',
      'Internal collaboration tools',
      'Security systems and monitoring',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Scope',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Complete migration of the following to cloud-based services:',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        ...scopes.map((scope) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  Expanded(
                    child: Text(scope, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _KeyDeliverablesCard extends StatelessWidget {
  const _KeyDeliverablesCard({required this.deliverables, required this.isMobile});

  final List<_Deliverable> deliverables;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: const Text(
              'Key Deliverables',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaWidth = MediaQuery.of(context).size.width;
              final bool hasBoundedWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
              final double tableWidth = hasBoundedWidth ? constraints.maxWidth : mediaWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  horizontalMargin: 28,
                  columnSpacing: 48,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Deliverable')),
                    DataColumn(label: Text('Phase')),
                    DataColumn(label: Text('Due Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Owner')),
                  ],
                  rows: deliverables.map((d) => DataRow(
                    cells: [
                      DataCell(Text(d.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(d.name)),
                      DataCell(Text(d.phase)),
                      DataCell(Text(d.dueDate)),
                      DataCell(_StatusBadge(status: d.status)),
                      DataCell(Text(d.owner)),
                    ],
                  )).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'in progress':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFCA8A04);
        break;
      case 'not started':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _CommunicationPlanCard extends StatelessWidget {
  const _CommunicationPlanCard({required this.communications, required this.isMobile});

  final List<_CommunicationPlan> communications;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: const Text(
              'Communication Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaWidth = MediaQuery.of(context).size.width;
              final bool hasBoundedWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
              final double tableWidth = hasBoundedWidth ? constraints.maxWidth : mediaWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  horizontalMargin: 28,
                  columnSpacing: 48,
                  columns: const [
                    DataColumn(label: Text('Meeting Type')),
                    DataColumn(label: Text('Frequency')),
                    DataColumn(label: Text('Attendees')),
                    DataColumn(label: Text('Purpose')),
                  ],
                  rows: communications.map((c) => DataRow(
                    cells: [
                      DataCell(Text(c.meetingType, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(c.frequency)),
                      DataCell(Text(c.attendees)),
                      DataCell(SizedBox(width: 300, child: Text(c.purpose, softWrap: true))),
                    ],
                  )).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
