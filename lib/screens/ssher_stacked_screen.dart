import 'package:flutter/material.dart';
import 'package:ndu_project/screens/ssher_components.dart';
import 'package:ndu_project/screens/ssher_add_safety_item_dialog.dart';
import 'package:ndu_project/screens/ssher_safety_full_view.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';

class SsherStackedScreen extends StatefulWidget {
  const SsherStackedScreen({super.key});

  @override
  State<SsherStackedScreen> createState() => _SsherStackedScreenState();
}

class _SsherStackedScreenState extends State<SsherStackedScreen> {
  final Color _safetyAccent = const Color(0xFF34A853);
  final Color _securityAccent = const Color(0xFFEF5350);
  final Color _healthAccent = const Color(0xFF1E88E5);
  final Color _environmentAccent = const Color(0xFF2E7D32);
  final Color _regulatoryAccent = const Color(0xFF8E24AA);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<List<Widget>> _safetyRows;
  late List<List<Widget>> _securityRows;
  late List<List<Widget>> _healthRows;
  late List<List<Widget>> _environmentRows;
  late List<List<Widget>> _regulatoryRows;

  @override
  void initState() {
    super.initState();
    // Initialize all SSHER sections with NO default data.
    // Users can add items via the "Add ... Item" actions.
    _safetyRows = [];
    _securityRows = [];
    _healthRows = [];
    _environmentRows = [];
    _regulatoryRows = [];
  }

  List<Widget> _buildRow({required int index, required String department, required String member, required String concern, required String riskLevel, required String mitigation}) {
    Widget risk;
    switch (riskLevel) {
      case 'Low':
        risk = const RiskBadge.low();
        break;
      case 'Medium':
        risk = const RiskBadge.medium();
        break;
      default:
        risk = const RiskBadge.high();
    }

    return [
      Text('$index', style: const TextStyle(fontSize: 12)),
      Text(department, style: const TextStyle(fontSize: 13)),
      Text(member, style: const TextStyle(fontSize: 13)),
      Text(concern, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
      risk,
      Text(mitigation, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      const ActionButtons(),
    ];
  }

  Future<void> _onAddSafetyItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _safetyAccent,
        icon: Icons.health_and_safety,
        heading: 'Add Safety Item',
        blurb: 'Provide details for the new safety record. Make sure risk level and mitigation strategy are accurate.',
        concernLabel: 'Safety Concern',
      ),
    );
    if (input == null) return;
    final nextIndex = _safetyRows.length + 1;
    setState(() {
      _safetyRows.add(_buildRow(
        index: nextIndex,
        department: input.department,
        member: input.teamMember,
        concern: input.concern,
        riskLevel: input.riskLevel,
        mitigation: input.mitigation,
      ));
    });
  }

  Future<void> _onAddSecurityItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _securityAccent,
        icon: Icons.shield_outlined,
        heading: 'Add Security Item',
        blurb: 'Capture the security exposure along with responsible contact and mitigation plan.',
        concernLabel: 'Security Concern',
      ),
    );
    if (input == null) return;
    final nextIndex = _securityRows.length + 1;
    setState(() {
      _securityRows.add(_buildRow(
        index: nextIndex,
        department: input.department,
        member: input.teamMember,
        concern: input.concern,
        riskLevel: input.riskLevel,
        mitigation: input.mitigation,
      ));
    });
  }

  Future<void> _onAddHealthItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _healthAccent,
        icon: Icons.volunteer_activism_outlined,
        heading: 'Add Health Item',
        blurb: 'Document the health-related concern and identify mitigation steps for your team.',
        concernLabel: 'Health Concern',
      ),
    );
    if (input == null) return;
    final nextIndex = _healthRows.length + 1;
    setState(() {
      _healthRows.add(_buildRow(
        index: nextIndex,
        department: input.department,
        member: input.teamMember,
        concern: input.concern,
        riskLevel: input.riskLevel,
        mitigation: input.mitigation,
      ));
    });
  }

  Future<void> _onAddEnvironmentItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _environmentAccent,
        icon: Icons.eco_outlined,
        heading: 'Add Environment Item',
        blurb: 'Log environmental impacts or sustainability risks to keep compliance in check.',
        concernLabel: 'Environmental Concern',
      ),
    );
    if (input == null) return;
    final nextIndex = _environmentRows.length + 1;
    setState(() {
      _environmentRows.add(_buildRow(
        index: nextIndex,
        department: input.department,
        member: input.teamMember,
        concern: input.concern,
        riskLevel: input.riskLevel,
        mitigation: input.mitigation,
      ));
    });
  }

  Future<void> _onAddRegulatoryItem() async {
    final input = await showDialog<SsherItemInput>(
      context: context,
      builder: (ctx) => AddSsherItemDialog(
        accentColor: _regulatoryAccent,
        icon: Icons.gavel_outlined,
        heading: 'Add Regulatory Item',
        blurb: 'Detail the compliance requirement and note the mitigation strategy.',
        concernLabel: 'Regulatory Requirement',
      ),
    );
    if (input == null) return;
    final nextIndex = _regulatoryRows.length + 1;
    setState(() {
      _regulatoryRows.add(_buildRow(
        index: nextIndex,
        department: input.department,
        member: input.teamMember,
        concern: input.concern,
        riskLevel: input.riskLevel,
        mitigation: input.mitigation,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'SSHER'),
                ),
                Expanded(
                  child: _buildMainContent(const EdgeInsets.all(24)),
                ),
              ],
            ),
            const KazAiChatBubble(),
            const AdminEditToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(EdgeInsetsGeometry padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(children: [
        // Plan Summary (from page 1)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.receipt_long, size: 18, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: EditableContentText(
                    contentKey: 'ssher_plan_summary_title',
                    fallback: 'SSHER Plan Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    category: 'ssher',
                  ),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: EditableContentText(
                contentKey: 'ssher_plan_summary_description',
                fallback: 'This SSHER plan encompasses comprehensive risk management across all operational domains. Safety protocols focus on workplace injury prevention and emergency response procedures. Security measures address both physical and cyber threats with multi-layered protection strategies. Health initiatives promote employee wellbeing and occupational health standards. Environmental considerations ensure sustainable practices and regulatory compliance. Regulatory frameworks maintain adherence to industry standards and legal requirements.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                category: 'ssher',
              ),
            ),
          ]),
        ),

        // Safety (from page 1)
        SsherSectionCard(
          leadingIcon: Icons.health_and_safety,
          accentColor: _safetyAccent,
          title: 'Safety',
          subtitle: 'Workplace safety protocols and risk management',
          detailsPlaceholder:
              'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems , and regular safety training programs for all personnel .',
          itemsLabel: '${_safetyRows.length} items',
          addButtonLabel: 'Add Safety Item',
          columns: const ['#', 'Department', 'Team Member', 'Safety Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _safetyRows,
          onFullView: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SafetyFullViewScreen(
                  columns: const ['#', 'Department', 'Team Member', 'Safety Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
                  initialRows: _safetyRows,
                  accentColor: _safetyAccent,
                  detailsText: 'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems , and regular safety training programs for all personnel .',
                  onAddItem: (input) {
                    final nextIndex = _safetyRows.length + 1;
                    setState(() {
                      _safetyRows.add(_buildRow(
                        index: nextIndex,
                        department: input.department,
                        member: input.teamMember,
                        concern: input.concern,
                        riskLevel: input.riskLevel,
                        mitigation: input.mitigation,
                      ));
                    });
                  },
                ),
              ),
            );
          },
          onAdd: _onAddSafetyItem,
        ),

        // Security (full table from page 2)
        SsherSectionCard(
          leadingIcon: Icons.shield_outlined,
          accentColor: _securityAccent,
          title: 'Security',
          subtitle: 'Physical and cyber security measures',
          detailsPlaceholder:
              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
          itemsLabel: '${_securityRows.length} items',
          addButtonLabel: 'Add Security Item',
          columns: const ['#', 'Department', 'Team Member', 'Security Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _securityRows,
          onAdd: _onAddSecurityItem,
        ),

        // Health (from page 2/3)
        SsherSectionCard(
          leadingIcon: Icons.volunteer_activism_outlined,
          accentColor: _healthAccent,
          title: 'Health',
          subtitle: 'Occupational health and wellness programs',
          detailsPlaceholder:
              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
          itemsLabel: '${_healthRows.length} items',
          addButtonLabel: 'Add Health Item',
          columns: const ['#', 'Department', 'Team Member', 'Health Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _healthRows,
          onAdd: _onAddHealthItem,
        ),

        // Environment (from page 3)
        SsherSectionCard(
          leadingIcon: Icons.eco_outlined,
          accentColor: _environmentAccent,
          title: 'Environment',
          subtitle: 'Environmental sustainability and compliance',
          detailsPlaceholder:
              'Environmental stewardship program including waste reduction initiatives, energy efficiency measures, carbon footprint monitoring, and sustainable resource management. Regular environmental impact assessments ensure compliance with regulations .',
          itemsLabel: '${_environmentRows.length} items',
          addButtonLabel: 'Add Environment Item',
          columns: const ['#', 'Department', 'Team Member', 'Environmental Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _environmentRows,
          onAdd: _onAddEnvironmentItem,
        ),

        // Regulatory (from page 4)
        SsherSectionCard(
          leadingIcon: Icons.gavel_outlined,
          accentColor: _regulatoryAccent,
          title: 'Regulatory',
          subtitle: 'Compliance and regulatory requirements',
          detailsPlaceholder:
              'EComprehensive regulatory compliance framework ensuring adherence to industry standards, legal requirements, and best practices. Regular audits documentation',
          itemsLabel: '${_regulatoryRows.length} items',
          addButtonLabel: 'Add Regulatory Item',
          columns: const ['#', 'Department', 'Team Member', 'Regulatory Requirement', 'Risk Level', 'Mitigation Strategy', 'Actions'],
          rows: _regulatoryRows,
          onAdd: _onAddRegulatoryItem,
        ),

        const SizedBox(height: 16),
      ]),
    );
  }
}

