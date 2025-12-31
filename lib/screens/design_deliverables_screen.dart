import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';

class DesignDeliverablesScreen extends StatelessWidget {
  const DesignDeliverablesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignDeliverablesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Design Deliverables'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Track design artifacts, approvals, and delivery readiness.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'AI Notes',
                              sectionLabel: 'Design Deliverables',
                              noteKey: 'design_deliverables_notes',
                              checkpoint: 'design_deliverables',
                              description: 'Summarize key deliverables, approvals, and handoff criteria.',
                            ),
                            const SizedBox(height: 24),
                            const _MetricsRow(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(width: halfWidth, child: const _DeliverablePipelineCard()),
                                SizedBox(width: halfWidth, child: const _ApprovalStatusCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _DesignDeliverablesTable(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(width: halfWidth, child: const _DesignDependenciesCard()),
                                SizedBox(width: halfWidth, child: const _DesignHandoffCard()),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => DesignPhaseScreen.open(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Next', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Design Deliverables',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Text('Product manager', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _MetricCard(label: 'Active Deliverables', value: '14', accent: Color(0xFF2563EB)),
        _MetricCard(label: 'In Review', value: '5', accent: Color(0xFFF59E0B)),
        _MetricCard(label: 'Approved', value: '6', accent: Color(0xFF10B981)),
        _MetricCard(label: 'At Risk', value: '2', accent: Color(0xFFEF4444)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _DeliverablePipelineCard extends StatelessWidget {
  const _DeliverablePipelineCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deliverable Pipeline',
      subtitle: 'Progress across design stages.',
      child: Column(
        children: const [
          _PipelineRow(label: 'Discovery & Research', value: 'Complete'),
          _PipelineRow(label: 'Wireframes', value: 'In Review'),
          _PipelineRow(label: 'UI Design', value: 'In Progress'),
          _PipelineRow(label: 'Prototype', value: 'Pending'),
        ],
      ),
    );
  }
}

class _ApprovalStatusCard extends StatelessWidget {
  const _ApprovalStatusCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Approval Status',
      subtitle: 'Stakeholder sign-offs and gating items.',
      child: Column(
        children: const [
          _ChecklistRow(text: 'Product team sign-off scheduled for May 15'),
          _ChecklistRow(text: 'Engineering alignment review pending'),
          _ChecklistRow(text: 'QA usability testing complete'),
          _ChecklistRow(text: 'Brand compliance approval complete'),
        ],
      ),
    );
  }
}

class _DesignDeliverablesTable extends StatelessWidget {
  const _DesignDeliverablesTable();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deliverables Register',
      subtitle: 'Track key artifacts and readiness.',
      child: Column(
        children: const [
          _RegisterHeader(),
          SizedBox(height: 10),
          _RegisterRow(name: 'Wireframe Pack', owner: 'UX Team', status: 'In Review', due: 'May 12', risk: 'Medium'),
          _RegisterRow(name: 'UI Kit v2', owner: 'Design Ops', status: 'Approved', due: 'May 5', risk: 'Low'),
          _RegisterRow(name: 'Prototype', owner: 'Product', status: 'In Progress', due: 'May 20', risk: 'High'),
          _RegisterRow(name: 'User Journey Maps', owner: 'Research', status: 'Approved', due: 'Apr 30', risk: 'Low'),
        ],
      ),
    );
  }
}

class _DesignDependenciesCard extends StatelessWidget {
  const _DesignDependenciesCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Dependencies',
      subtitle: 'Items that unblock delivery.',
      child: Column(
        children: const [
          _BulletRow(text: 'API contract updates required for error states.'),
          _BulletRow(text: 'Content strategy inputs due before final UI polish.'),
          _BulletRow(text: 'Analytics instrumentation specs pending data team review.'),
        ],
      ),
    );
  }
}

class _DesignHandoffCard extends StatelessWidget {
  const _DesignHandoffCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Handoff Checklist',
      subtitle: 'Ensure delivery-ready assets.',
      child: Column(
        children: const [
          _ChecklistRow(text: 'Component specs documented and linked'),
          _ChecklistRow(text: 'Redlines and spacing guidelines attached'),
          _ChecklistRow(text: 'Accessibility notes included'),
          _ChecklistRow(text: 'Figma assets versioned and shared'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({required this.label, required this.value});

  final String label;
  final String value;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return const Color(0xFF10B981);
      case 'in review':
        return const Color(0xFFF59E0B);
      case 'in progress':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Text('Deliverable', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 110, child: Text('Owner', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 70, child: Text('Due', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 70, child: Text('Risk', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
      ],
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({
    required this.name,
    required this.owner,
    required this.status,
    required this.due,
    required this.risk,
  });

  final String name;
  final String owner;
  final String status;
  final String due;
  final String risk;

  Color _riskColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'in review':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
          SizedBox(width: 110, child: Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          SizedBox(width: 90, child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status)))),
          SizedBox(width: 70, child: Text(due, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          SizedBox(width: 70, child: Text(risk, style: TextStyle(fontSize: 12, color: _riskColor(risk)))),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}
