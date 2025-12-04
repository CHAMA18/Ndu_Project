import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';

class SalvageDisposalTeamScreen extends StatefulWidget {
  const SalvageDisposalTeamScreen({super.key});

  static void open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SalvageDisposalTeamScreen()),
  );

  @override
  State<SalvageDisposalTeamScreen> createState() => _SalvageDisposalTeamScreenState();
}

class _SalvageDisposalTeamScreenState extends State<SalvageDisposalTeamScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Asset Inventory', 'Disposal Queue', 'Team Allocation'];

  final List<_TeamMember> _teamMembers = [
    _TeamMember('Sarah Mitchell', 'Team Lead', 'sarah.m@company.com', 'Active', 12, Colors.green),
    _TeamMember('James Rodriguez', 'Asset Specialist', 'james.r@company.com', 'Active', 8, Colors.green),
    _TeamMember('Emily Chen', 'Logistics Coordinator', 'emily.c@company.com', 'On Leave', 5, Colors.orange),
    _TeamMember('Michael Thompson', 'Disposal Technician', 'michael.t@company.com', 'Active', 15, Colors.green),
    _TeamMember('Lisa Park', 'Compliance Officer', 'lisa.p@company.com', 'Active', 9, Colors.green),
  ];

  final List<_DisposalItem> _disposalItems = [
    _DisposalItem('SVG-001', 'Server Equipment', 'Electronics', 'Pending Review', '\$12,500', 'High', Colors.red),
    _DisposalItem('SVG-002', 'Office Furniture', 'Furniture', 'Approved', '\$3,200', 'Medium', Colors.orange),
    _DisposalItem('SVG-003', 'Construction Materials', 'Raw Materials', 'In Progress', '\$8,750', 'Low', Colors.green),
    _DisposalItem('SVG-004', 'Vehicle Fleet (3 units)', 'Vehicles', 'Pending Auction', '\$45,000', 'High', Colors.red),
    _DisposalItem('SVG-005', 'IT Peripherals', 'Electronics', 'Completed', '\$1,800', 'Low', Colors.green),
    _DisposalItem('SVG-006', 'Safety Equipment', 'PPE', 'Approved', '\$2,100', 'Medium', Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const InitiationLikeSidebar(activeItemLabel: 'Salvage Disposal Team'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isNarrow),
                  const SizedBox(height: 24),
                  _buildTabBar(),
                  const SizedBox(height: 24),
                  _buildStatsRow(isNarrow),
                  const SizedBox(height: 24),
                  if (isNarrow) ...[
                    _buildTeamManagementPanel(),
                    const SizedBox(height: 24),
                    _buildDisposalQueuePanel(),
                    const SizedBox(height: 24),
                    _buildCompliancePanel(),
                    const SizedBox(height: 24),
                    _buildTimelinePanel(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildTeamManagementPanel()),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildCompliancePanel()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildDisposalQueuePanel()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildTimelinePanel()),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildInsightsRow(isNarrow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salvage & Disposal Team Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage salvage operations, asset disposal workflows, and team assignments for project decommissioning.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 16),
              _buildActionButtons(),
            ],
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildActionButton(Icons.person_add, 'Add Team Member', onTap: () {}),
        _buildActionButton(Icons.inventory_2, 'New Asset Entry', onTap: () {}),
        _buildActionButton(Icons.assessment, 'Generate Report', onTap: () {}),
        _buildPrimaryActionButton('Start Disposal Process', onTap: () {}),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatItem('Team Members', '5 active', Icons.people, Colors.blue),
      _StatItem('Assets Pending', '12 items', Icons.inventory, Colors.orange),
      _StatItem('Total Salvage Value', '\$73,350', Icons.attach_money, Colors.green),
      _StatItem('Disposal Progress', '68%', Icons.pie_chart, const Color(0xFF8B5CF6)),
      _StatItem('Compliance Score', '94/100', Icons.verified, Colors.teal),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat, flex: false)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatItem stat, {bool flex = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(stat.icon, size: 18, color: stat.color),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 14, color: Colors.green[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(stat.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: stat.color)),
          const SizedBox(height: 4),
          Text(stat.label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTeamManagementPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Manage disposal team members and assignments', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Filter'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Tasks', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: _teamMembers.map((member) => DataRow(
                cells: [
                  DataCell(Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        child: Text(member.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
                      ),
                      const SizedBox(width: 8),
                      Text(member.name, style: const TextStyle(fontSize: 13)),
                    ],
                  )),
                  DataCell(Text(member.role, style: const TextStyle(fontSize: 13))),
                  DataCell(Text(member.email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                  DataCell(_buildStatusBadge(member.status, member.statusColor)),
                  DataCell(Text('${member.tasks}', style: const TextStyle(fontSize: 13))),
                  DataCell(Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                      IconButton(icon: const Icon(Icons.visibility, size: 16), onPressed: () {}, color: const Color(0xFF64748B)),
                    ],
                  )),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalQueuePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disposal Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
                    SizedBox(height: 4),
                    Text('Track assets through the disposal workflow', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildActionButton(Icons.add, 'Add Item', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Asset ID', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Est. Value', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: _disposalItems.map((item) => DataRow(
                cells: [
                  DataCell(Text(item.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9)))),
                  DataCell(Text(item.description, style: const TextStyle(fontSize: 13))),
                  DataCell(_buildCategoryChip(item.category)),
                  DataCell(_buildStatusPill(item.status)),
                  DataCell(Text(item.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  DataCell(_buildPriorityBadge(item.priority, item.priorityColor)),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompliancePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compliance & Regulations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          const SizedBox(height: 4),
          Text('Environmental and safety compliance tracking', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          _buildComplianceItem('EPA Disposal Guidelines', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('OSHA Safety Standards', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('Hazmat Certification', 'Renewal Due', Icons.warning, Colors.orange),
          _buildComplianceItem('Asset Transfer Records', 'Compliant', Icons.check_circle, Colors.green),
          _buildComplianceItem('Environmental Impact Report', 'Pending', Icons.schedule, Colors.blue),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hazmat certification expires in 15 days. Schedule renewal.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String label, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Disposal Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F))),
          const SizedBox(height: 4),
          Text('Upcoming milestones and deadlines', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          _buildTimelineItem('Asset Audit Complete', 'Mar 15', true),
          _buildTimelineItem('Vendor Bidding Opens', 'Mar 20', true),
          _buildTimelineItem('Auction Date', 'Mar 28', false),
          _buildTimelineItem('Final Disposal Report', 'Apr 5', false),
          _buildTimelineItem('Project Closure', 'Apr 15', false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String date, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? Colors.green : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.circle,
              size: 14,
              color: completed ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: completed ? const Color(0xFF64748B) : const Color(0xFF1A1D1F))),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          if (!completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Upcoming', style: TextStyle(fontSize: 10, color: Color(0xFF0284C7))),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(bool isNarrow) {
    final insights = [
      _InsightCard('Cost Recovery Potential', '\$58,200', 'Based on current market valuations for salvageable assets.', Icons.trending_up, Colors.green),
      _InsightCard('Environmental Impact', '12.5 tons', 'CO2 emissions avoided through proper recycling.', Icons.eco, Colors.teal),
      _InsightCard('Average Disposal Time', '18 days', '23% faster than industry benchmark.', Icons.speed, Colors.blue),
    ];

    if (isNarrow) {
      return Column(
        children: insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInsightCard(insight),
        )).toList(),
      );
    }

    return Row(
      children: insights.map((insight) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildInsightCard(insight),
        ),
      )).toList(),
    );
  }

  Widget _buildInsightCard(_InsightCard insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, size: 18, color: insight.color),
              ),
              const Spacer(),
              Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(insight.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: insight.color)),
          const SizedBox(height: 8),
          Text(insight.description, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(category, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'Completed':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case 'In Progress':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Pending Auction':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'Approved':
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF4F46E5);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
    );
  }

  Widget _buildPriorityBadge(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final String email;
  final String status;
  final int tasks;
  final Color statusColor;

  const _TeamMember(this.name, this.role, this.email, this.status, this.tasks, this.statusColor);
}

class _DisposalItem {
  final String id;
  final String description;
  final String category;
  final String status;
  final String value;
  final String priority;
  final Color priorityColor;

  const _DisposalItem(this.id, this.description, this.category, this.status, this.value, this.priority, this.priorityColor);
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _InsightCard {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _InsightCard(this.title, this.value, this.description, this.icon, this.color);
}
