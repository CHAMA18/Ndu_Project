import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Front End Planning – Procurement screen
/// Recreates the provided procurement workspace mock with strategies and vendor table.
class FrontEndPlanningProcurementScreen extends StatefulWidget {
  const FrontEndPlanningProcurementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningProcurementScreen()),
    );
  }

  @override
  State<FrontEndPlanningProcurementScreen> createState() => _FrontEndPlanningProcurementScreenState();
}

class _FrontEndPlanningProcurementScreenState extends State<FrontEndPlanningProcurementScreen> {
  final TextEditingController _notes = TextEditingController();

  bool _approvedOnly = false;
  bool _preferredOnly = false;
  bool _listView = true;
  String _categoryFilter = 'All Categories';
  final Set<int> _expandedStrategies = {0};

  _ProcurementTab _selectedTab = _ProcurementTab.itemsList;
  int _selectedTrackableIndex = 0;
  late final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  // Start empty: no default seeded data for procurement items
  final List<_ProcurementItem> _items = const [];

  // Start empty: no default seeded trackable items
  final List<_TrackableItem> _trackableItems = const [];

  // Start empty: no default seeded strategies
  final List<_ProcurementStrategy> _strategies = const [];

  // Start empty: no default seeded vendors
  final List<_VendorRow> _vendors = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _notes.text = data.frontEndPlanning.procurement;
      if (_notes.text.trim().isEmpty) {
        _generateAiSuggestion();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _generateAiSuggestion() async {
    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Procurement');
      final ai = OpenAiServiceSecure();
      // Increase token budget for richer guidance specific to Procurement
      final suggestion = await ai.generateFepSectionText(
        section: 'Procurement',
        context: ctx,
        maxTokens: 1400,
        temperature: 0.5,
      );
      if (!mounted) return;
      if (_notes.text.trim().isEmpty && suggestion.trim().isNotEmpty) {
        setState(() {
          _notes.text = suggestion.trim();
        });
      }
    } catch (e) {
      debugPrint('AI procurement suggestion failed: $e');
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<String> get _categoryOptions {
    final categories = _vendors.map((vendor) => vendor.category).toSet().toList()..sort();
    return ['All Categories', ...categories];
  }

  List<_VendorRow> get _filteredVendors {
    return _vendors.where((vendor) {
      if (_approvedOnly && !vendor.approved) return false;
      if (_preferredOnly && !vendor.preferred) return false;
      if (_categoryFilter != 'All Categories' && vendor.category != _categoryFilter) return false;
      return true;
    }).toList();
  }

  void _handleNotesChanged(String value) {
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          procurement: value,
        ),
      ),
    );
  }

  Future<bool> _persistProcurementNotes({bool showConfirmation = false}) async {
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'fep_procurement',
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          procurement: _notes.text.trim(),
        ),
      ),
      showSnackbar: false,
    );

    if (mounted && showConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Procurement notes saved' : 'Unable to save procurement notes'),
          backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }

    return success;
  }

  void _toggleStrategy(int index) {
    setState(() {
      if (_expandedStrategies.contains(index)) {
        _expandedStrategies.remove(index);
      } else {
        _expandedStrategies.add(index);
      }
    });
  }

  void _handleItemListTap() {
    setState(() => _selectedTab = _ProcurementTab.itemsList);
  }

  void _handleTabSelected(_ProcurementTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  void _handleTrackableSelected(int index) {
    if (_selectedTrackableIndex == index) return;
    setState(() => _selectedTrackableIndex = index);
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case _ProcurementTab.procurementDashboard:
        return _buildDashboardSection();
      case _ProcurementTab.itemsList:
        return _ItemsListView(
          key: const ValueKey('procurement_items_list'),
          items: _items,
          trackableItems: _trackableItems,
          selectedIndex: _selectedTrackableIndex,
          onSelectTrackable: _handleTrackableSelected,
          currencyFormat: _currencyFormat,
        );
      case _ProcurementTab.vendorManagement:
        return _buildDashboardSection(key: const ValueKey('procurement_vendor_management'));
      case _ProcurementTab.rfqWorkflow:
      case _ProcurementTab.purchaseOrders:
      case _ProcurementTab.itemTracking:
      case _ProcurementTab.reports:
        return _ComingSoonCard(
          key: ValueKey('procurement_${_selectedTab.name}_coming_soon'),
          title: _selectedTab.title,
        );
    }
  }

  Widget _buildDashboardSection({Key? key}) {
    return Column(
      key: key ?? const ValueKey('procurement_dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlanHeader(onItemListTap: _handleItemListTap),
        const SizedBox(height: 16),
        _AiSuggestionCard(
          onAccept: _handleAcceptSuggestion,
          onEdit: _handleEditSuggestion,
          onReject: _handleRejectSuggestion,
        ),
        const SizedBox(height: 32),
        _StrategiesSection(
          strategies: _strategies,
          expandedStrategies: _expandedStrategies,
          onToggle: _toggleStrategy,
        ),
        const SizedBox(height: 32),
        _VendorsSection(
          vendors: _filteredVendors,
          allVendorsCount: _vendors.length,
          approvedOnly: _approvedOnly,
          preferredOnly: _preferredOnly,
          listView: _listView,
          categoryFilter: _categoryFilter,
          categoryOptions: _categoryOptions,
          onApprovedChanged: (value) => setState(() => _approvedOnly = value),
          onPreferredChanged: (value) => setState(() => _preferredOnly = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onViewModeChanged: (value) => setState(() => _listView = value),
        ),
      ],
    );
  }

  Future<void> _handleAcceptSuggestion() async {
    final success = await _persistProcurementNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'AI suggestion accepted and saved.' : 'Unable to save procurement notes.'),
        backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  void _handleEditSuggestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit suggestion to customize the procurement plan.')),
    );
  }

  void _handleRejectSuggestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion dismissed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Procurement'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F6FA),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ProcurementTopBar(
                                  onBack: () => Navigator.of(context).maybePop(),
                                  onForward: () {},
                                ),
                                const SizedBox(height: 24),
                                _NotesCard(
                                  controller: _notes,
                                  onChanged: _handleNotesChanged,
                                ),
                                const SizedBox(height: 32),
                                _ProcurementTabBar(
                                  selectedTab: _selectedTab,
                                  onSelected: _handleTabSelected,
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildTabContent(),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
}

class _ProcurementTopBar extends StatelessWidget {
  const _ProcurementTopBar({required this.onBack, required this.onForward});

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(icon: Icons.arrow_forward_ios_rounded, onTap: onForward),
          const SizedBox(width: 20),
          const Text(
            'Procurement',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          const _UserBadge(),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
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

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFD1D5DB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          SizedBox(width: 10),
          Text(
            'John Doe',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          SizedBox(width: 6),
          Text(
            'Product Manager',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 8,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Input your notes here...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _ProcurementTabBar extends StatelessWidget {
  const _ProcurementTabBar({required this.selectedTab, required this.onSelected});

  final _ProcurementTab selectedTab;
  final ValueChanged<_ProcurementTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = _ProcurementTab.values;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 960;
          if (isCompact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in tabs)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 160,
                        child: _TabButton(
                          label: tab.label,
                          selected: tab == selectedTab,
                          onTap: () => onSelected(tab),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final double tabWidth = (constraints.maxWidth - (tabs.length - 1) * 8) / tabs.length;
          return Row(
            children: [
              for (final tab in tabs) ...[
                SizedBox(
                  width: tabWidth,
                  child: _TabButton(
                    label: tab.label,
                    selected: tab == selectedTab,
                    onTap: () => onSelected(tab),
                  ),
                ),
                if (tab != tabs.last) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? const Color(0xFF2563EB) : Colors.transparent, width: 1.2),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x0C1D4ED8),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.onItemListTap});

  final VoidCallback onItemListTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Row(
            children: [
              Text(
                'SmartCare Expansion Project Procurement Plan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              SizedBox(width: 8),
              Icon(Icons.lock_outline, size: 18, color: Color(0xFF6B7280)),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onItemListTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Item List'),
        ),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard({required this.onAccept, required this.onEdit, required this.onReject});

  final VoidCallback onAccept;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCF0E6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_circle_rounded, color: Color(0xFF0EA5E9)),
              SizedBox(width: 12),
              Text(
                'AI Suggestion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your project scope, I recommend creating procurement strategies for IT Equipment, Office Renovation, and Furniture to organize purchasing activities effectively.',
            style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onReject, child: const Text('Reject')),
              const SizedBox(width: 12),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsListView extends StatelessWidget {
  const _ItemsListView({
    super.key,
    required this.items,
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.currencyFormat,
  });

  final List<_ProcurementItem> items;
  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final totalItems = items.length;
    final criticalItems = items.where((item) => item.priority == _ProcurementPriority.critical).length;
    final pendingApprovals = items
        .where((item) => item.status == _ProcurementItemStatus.vendorSelection && item.priority == _ProcurementPriority.critical)
        .length;
    final totalBudget = items.fold<int>(0, (value, item) => value + item.budget);
    final selectedTrackable = (selectedIndex >= 0 && selectedIndex < trackableItems.length) ? trackableItems[selectedIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryMetricsRow(
          totalItems: totalItems,
          criticalItems: criticalItems,
          pendingApprovals: pendingApprovals,
          totalBudgetLabel: currencyFormat.format(totalBudget),
        ),
        const SizedBox(height: 24),
        _ItemsToolbar(),
        const SizedBox(height: 20),
        _ItemsTable(items: items, currencyFormat: currencyFormat),
        const SizedBox(height: 28),
        _TrackableAndTimeline(
          trackableItems: trackableItems,
          selectedIndex: selectedIndex,
          onSelectTrackable: onSelectTrackable,
          selectedItem: selectedTrackable,
        ),
      ],
    );
  }
}

class _SummaryMetricsRow extends StatelessWidget {
  const _SummaryMetricsRow({
    required this.totalItems,
    required this.criticalItems,
    required this.pendingApprovals,
    required this.totalBudgetLabel,
  });

  final int totalItems;
  final int criticalItems;
  final int pendingApprovals;
  final String totalBudgetLabel;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final cards = [
      _SummaryCard(
        icon: Icons.inventory_2_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$totalItems',
        label: 'Total Items',
      ),
      _SummaryCard(
        icon: Icons.warning_amber_rounded,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$criticalItems',
        label: 'Critical Items',
        valueColor: const Color(0xFFDC2626),
      ),
      _SummaryCard(
        icon: Icons.access_time,
        iconBackground: const Color(0xFFF5F3FF),
        value: '$pendingApprovals',
        label: 'Pending Approvals',
        valueColor: const Color(0xFF1F2937),
      ),
      _SummaryCard(
        icon: Icons.attach_money,
        iconBackground: const Color(0xFFECFEFF),
        value: totalBudgetLabel,
        label: 'Total Budget',
        valueColor: const Color(0xFF047857),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
          const SizedBox(height: 12),
          cards[3],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final Color iconBackground;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _DropdownField(label: 'All Categories')),
              SizedBox(width: 12),
              Expanded(child: _DropdownField(label: 'All Statuses')),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _AddItemButton(),
          ),
        ],
      );
    }

    return Row(
      children: const [
        SizedBox(width: 320, child: _SearchField()),
        SizedBox(width: 16),
        SizedBox(width: 190, child: _DropdownField(label: 'All Categories')),
        SizedBox(width: 16),
        SizedBox(width: 190, child: _DropdownField(label: 'All Statuses')),
        Spacer(),
        _AddItemButton(),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
          hintText: 'Search items...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final options = label == 'All Categories'
        ? const ['All Categories', 'Materials', 'Equipment', 'Services']
        : const ['All Statuses', 'Planning', 'RFQ Review', 'Vendor Selection', 'Ordered', 'Delivered'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                ),
              )
              .toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  const _AddItemButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items, required this.currencyFormat});

  final List<_ProcurementItem> items;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: _ItemsTableHeader(),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          for (var i = 0; i < items.length; i++) ...[
            _ItemRow(item: items[i], currencyFormat: currencyFormat),
            if (i != items.length - 1) const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }
}

class _ItemsTableHeader extends StatelessWidget {
  const _ItemsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _HeaderCell(label: 'Item', flex: 4),
        _HeaderCell(label: 'Category', flex: 2),
        _HeaderCell(label: 'Status', flex: 2),
        _HeaderCell(label: 'Priority', flex: 2),
        _HeaderCell(label: 'Budget', flex: 2),
        _HeaderCell(label: 'Est. Delivery', flex: 2),
        _HeaderCell(label: 'Progress', flex: 2),
        _HeaderCell(label: 'Actions', flex: 2, alignEnd: true),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.flex, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currencyFormat});

  final _ProcurementItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(item.estimatedDelivery);
    final dateLabel = DateFormat('M/d/yyyy').format(date);
    final progressLabel = '${(item.progress * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(item.category, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgePill(
                label: item.status.label,
                background: item.status.backgroundColor,
                border: item.status.borderColor,
                foreground: item.status.textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgePill(
                label: item.priority.label,
                background: item.priority.backgroundColor,
                border: item.priority.borderColor,
                foreground: item.priority.textColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(item.budget),
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progressLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.progress.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(item.progressColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _ActionIcon(icon: Icons.remove_red_eye_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.edit_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.link_outlined),
                SizedBox(width: 8),
                _ActionIcon(icon: Icons.more_horiz_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF475569)),
      ),
    );
  }
}

class _TrackableAndTimeline extends StatelessWidget {
  const _TrackableAndTimeline({
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.selectedItem,
  });

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final _TrackableItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackableItemsCard(
            trackableItems: trackableItems,
            selectedIndex: selectedIndex,
            onSelectTrackable: onSelectTrackable,
          ),
          const SizedBox(height: 20),
          _TrackingTimelineCard(item: selectedItem),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _TrackableItemsCard(
            trackableItems: trackableItems,
            selectedIndex: selectedIndex,
            onSelectTrackable: onSelectTrackable,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _TrackingTimelineCard(item: selectedItem),
        ),
      ],
    );
  }
}

class _TrackableItemsCard extends StatelessWidget {
  const _TrackableItemsCard({required this.trackableItems, required this.selectedIndex, required this.onSelectTrackable});

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;

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
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(
              'Trackable Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          for (var i = 0; i < trackableItems.length; i++)
            _TrackableRow(
              item: trackableItems[i],
              selected: i == selectedIndex,
              onTap: () => onSelectTrackable(i),
              showDivider: i != trackableItems.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TrackableRow extends StatelessWidget {
  const _TrackableRow({required this.item, required this.selected, required this.onTap, required this.showDivider});

  final _TrackableItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final lastUpdateLabel = item.lastUpdate != null ? DateFormat('M/d/yyyy').format(DateTime.parse(item.lastUpdate!)) : 'Never';

    return Material(
      color: selected ? const Color(0xFFF8FAFC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.orderStatus.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BadgePill(
                        label: item.currentStatus.label,
                        background: item.currentStatus.backgroundColor,
                        border: item.currentStatus.borderColor,
                        foreground: item.currentStatus.textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(lastUpdateLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                  ),
                  const _UpdateButton(),
                ],
              ),
              if (showDivider) const SizedBox(height: 18),
              if (showDivider) const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF1F2937),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TrackingTimelineCard extends StatelessWidget {
  const _TrackingTimelineCard({required this.item});

  final _TrackableItem? item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: item == null
          ? const Center(
              child: Text(
                'Select an item to view tracking timeline.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),
                Text(
                  item!.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click on an item to view its tracking timeline',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _BadgePill(
                  label: item!.currentStatus.label,
                  background: item!.currentStatus.backgroundColor,
                  border: item!.currentStatus.borderColor,
                  foreground: item!.currentStatus.textColor,
                ),
                const SizedBox(height: 16),
                for (final event in item!.events) ...[
                  _TimelineEntry(event: event),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.event});

  final _TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M/d/yyyy').format(DateTime.parse(event.date));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 6),
              Text(
                event.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Text(
                event.subtext,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrategiesSection extends StatelessWidget {
  const _StrategiesSection({required this.strategies, required this.expandedStrategies, required this.onToggle});

  final List<_ProcurementStrategy> strategies;
  final Set<int> expandedStrategies;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Procurement Strategies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            Text(
              '${strategies.length} ${strategies.length == 1 ? 'strategy' : 'strategies'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            for (var i = 0; i < strategies.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == strategies.length - 1 ? 0 : 12),
                child: _StrategyCard(
                  strategy: strategies[i],
                  expanded: expandedStrategies.contains(i),
                  onTap: () => onToggle(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({required this.strategy, required this.expanded, required this.onTap});

  final _ProcurementStrategy strategy;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: const Color(0x19000000),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strategy.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strategy.itemCount} items',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: strategy.status),
                  const SizedBox(width: 16),
                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: const Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          if (expanded)
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                strategy.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _StrategyStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == _StrategyStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8FFF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isActive ? const Color(0xFF34D399) : const Color(0xFFD1D5DB)),
      ),
      child: Text(
        isActive ? 'active' : 'draft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _VendorsSection extends StatelessWidget {
  const _VendorsSection({
    required this.vendors,
    required this.allVendorsCount,
    required this.approvedOnly,
    required this.preferredOnly,
    required this.listView,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.onApprovedChanged,
    required this.onPreferredChanged,
    required this.onCategoryChanged,
    required this.onViewModeChanged,
  });

  final List<_VendorRow> vendors;
  final int allVendorsCount;
  final bool approvedOnly;
  final bool preferredOnly;
  final bool listView;
  final String categoryFilter;
  final List<String> categoryOptions;
  final ValueChanged<bool> onApprovedChanged;
  final ValueChanged<bool> onPreferredChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vendors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            Text(
              '${vendors.length} of $allVendorsCount vendors',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined, size: 18),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            FilterChip(
              label: const Text('Approved Only'),
              selected: approvedOnly,
              onSelected: onApprovedChanged,
              selectedColor: const Color(0xFFEFF6FF),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: approvedOnly ? const Color(0xFF2563EB) : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            FilterChip(
              label: const Text('Preferred Only'),
              selected: preferredOnly,
              onSelected: onPreferredChanged,
              selectedColor: const Color(0xFFF1F5F9),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: preferredOnly ? const Color(0xFF2563EB) : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categoryFilter,
                  items: categoryOptions
                      .map((option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCategoryChanged(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              isSelected: [listView, !listView],
              onPressed: (index) => onViewModeChanged(index == 0),
              children: const [
                Icon(Icons.view_list_rounded, size: 20),
                Icon(Icons.grid_view_rounded, size: 20),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View Company Approved Vendor List'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (vendors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'No vendors match the selected filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          )
        else if (listView)
          _VendorDataTable(vendors: vendors)
        else
          _VendorGrid(vendors: vendors),
      ],
    );
  }
}

class _VendorDataTable extends StatelessWidget {
  const _VendorDataTable({required this.vendors});

  final List<_VendorRow> vendors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 24,
                headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                dataTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                columns: const [
                  DataColumn(label: SizedBox(width: 24)),
                  DataColumn(label: Text('Vendor Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Approved')),
                  DataColumn(label: Text('Preferred')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: vendors
                    .map(
                      (vendor) => DataRow(
                        cells: [
                          DataCell(Checkbox(value: false, onChanged: (_) {})),
                          DataCell(_VendorNameCell(vendor: vendor)),
                          DataCell(Text(vendor.category)),
                          DataCell(_RatingStars(rating: vendor.rating)),
                          DataCell(_YesNoBadge(value: vendor.approved)),
                          DataCell(_YesNoBadge(value: vendor.preferred, showStar: true)),
                          DataCell(IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {})),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorGrid extends StatelessWidget {
  const _VendorGrid({required this.vendors});

  final List<_VendorRow> vendors;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3.2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: vendors.length,
      itemBuilder: (_, index) {
        final vendor = vendors[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VendorNameCell(vendor: vendor),
              const SizedBox(height: 8),
              Text(vendor.category, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              _RatingStars(rating: vendor.rating),
              const Spacer(),
              Row(
                children: [
                  _YesNoBadge(value: vendor.approved),
                  const SizedBox(width: 8),
                  _YesNoBadge(value: vendor.preferred, showStar: true),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {}),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VendorNameCell extends StatelessWidget {
  const _VendorNameCell({required this.vendor});

  final _VendorRow vendor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE2E8F0),
          child: Text(
            vendor.initials,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              const Text(
                'View Company Approved Vendor List',
                style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFACC15),
          size: 18,
        ),
      ),
    );
  }
}

class _YesNoBadge extends StatelessWidget {
  const _YesNoBadge({required this.value, this.showStar = false});

  final bool value;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    final Color background = value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC);
    final Color foreground = value ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: value ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value ? 'Yes' : 'No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground)),
          if (showStar) ...[
            const SizedBox(width: 6),
            Icon(value ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: foreground),
          ],
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            'This section is under construction. Check back soon for the interactive experience.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

enum _ProcurementTab { procurementDashboard, itemsList, vendorManagement, rfqWorkflow, purchaseOrders, itemTracking, reports }

extension _ProcurementTabExtension on _ProcurementTab {
  String get label {
    switch (this) {
      case _ProcurementTab.procurementDashboard:
        return 'Procurement Dashboard';
      case _ProcurementTab.itemsList:
        return 'Items List';
      case _ProcurementTab.vendorManagement:
        return 'Vendor Management';
      case _ProcurementTab.rfqWorkflow:
        return 'RFQ Workflow';
      case _ProcurementTab.purchaseOrders:
        return 'Purchase Orders';
      case _ProcurementTab.itemTracking:
        return 'Item Tracking';
      case _ProcurementTab.reports:
        return 'Reports';
    }
  }

  String get title {
    switch (this) {
      case _ProcurementTab.procurementDashboard:
        return 'Procurement Dashboard';
      case _ProcurementTab.itemsList:
        return 'Items List';
      case _ProcurementTab.vendorManagement:
        return 'Vendor Management';
      case _ProcurementTab.rfqWorkflow:
        return 'RFQ Workflow';
      case _ProcurementTab.purchaseOrders:
        return 'Purchase Orders';
      case _ProcurementTab.itemTracking:
        return 'Item Tracking';
      case _ProcurementTab.reports:
        return 'Reports';
    }
  }
}

class _ProcurementItem {
  const _ProcurementItem({
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.budget,
    required this.estimatedDelivery,
    required this.progress,
  });

  final String name;
  final String description;
  final String category;
  final _ProcurementItemStatus status;
  final _ProcurementPriority priority;
  final int budget;
  final String estimatedDelivery;
  final double progress;

  Color get progressColor {
    if (progress >= 1.0) return const Color(0xFF10B981);
    if (progress >= 0.5) return const Color(0xFF2563EB);
    if (progress == 0) return const Color(0xFFD1D5DB);
    return const Color(0xFF38BDF8);
  }
}

enum _ProcurementItemStatus { planning, rfqReview, vendorSelection, ordered, delivered }

extension _ProcurementItemStatusExtension on _ProcurementItemStatus {
  String get label {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return 'planning';
      case _ProcurementItemStatus.rfqReview:
        return 'rfq review';
      case _ProcurementItemStatus.vendorSelection:
        return 'vendor selection';
      case _ProcurementItemStatus.ordered:
        return 'ordered';
      case _ProcurementItemStatus.delivered:
        return 'delivered';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return const Color(0xFFEFF6FF);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFFFF7ED);
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFFEFF6FF);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFFF1F5F9);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
        return const Color(0xFF2563EB);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFEA580C);
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFF2563EB);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFF1F2937);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _ProcurementItemStatus.planning:
      case _ProcurementItemStatus.vendorSelection:
        return const Color(0xFFBFDBFE);
      case _ProcurementItemStatus.rfqReview:
        return const Color(0xFFFECF8F);
      case _ProcurementItemStatus.ordered:
        return const Color(0xFFE2E8F0);
      case _ProcurementItemStatus.delivered:
        return const Color(0xFFBBF7D0);
    }
  }
}

enum _ProcurementPriority { critical, high, medium, low }

extension _ProcurementPriorityExtension on _ProcurementPriority {
  String get label {
    switch (this) {
      case _ProcurementPriority.critical:
        return 'critical';
      case _ProcurementPriority.high:
        return 'high';
      case _ProcurementPriority.medium:
        return 'medium';
      case _ProcurementPriority.low:
        return 'low';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFFFF1F2);
      case _ProcurementPriority.high:
        return const Color(0xFFEFF6FF);
      case _ProcurementPriority.medium:
        return const Color(0xFFF8FAFC);
      case _ProcurementPriority.low:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get textColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFDC2626);
      case _ProcurementPriority.high:
        return const Color(0xFF1D4ED8);
      case _ProcurementPriority.medium:
        return const Color(0xFF475569);
      case _ProcurementPriority.low:
        return const Color(0xFF4B5563);
    }
  }

  Color get borderColor {
    switch (this) {
      case _ProcurementPriority.critical:
        return const Color(0xFFFECACA);
      case _ProcurementPriority.high:
        return const Color(0xFFBFDBFE);
      case _ProcurementPriority.medium:
        return const Color(0xFFE2E8F0);
      case _ProcurementPriority.low:
        return const Color(0xFFE2E8F0);
    }
  }
}

class _TrackableItem {
  const _TrackableItem({
    required this.name,
    required this.description,
    required this.orderStatus,
    required this.currentStatus,
    required this.lastUpdate,
    required this.events,
  });

  final String name;
  final String description;
  final String orderStatus;
  final _TrackableStatus currentStatus;
  final String? lastUpdate;
  final List<_TimelineEvent> events;
}

enum _TrackableStatus { inTransit, notTracked, delivered }

extension _TrackableStatusExtension on _TrackableStatus {
  String get label {
    switch (this) {
      case _TrackableStatus.inTransit:
        return 'in transit';
      case _TrackableStatus.notTracked:
        return 'Not Tracked';
      case _TrackableStatus.delivered:
        return 'delivered';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFFEFF6FF);
      case _TrackableStatus.notTracked:
        return const Color(0xFFF1F5F9);
      case _TrackableStatus.delivered:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFF2563EB);
      case _TrackableStatus.notTracked:
        return const Color(0xFF475569);
      case _TrackableStatus.delivered:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _TrackableStatus.inTransit:
        return const Color(0xFFBFDBFE);
      case _TrackableStatus.notTracked:
        return const Color(0xFFE2E8F0);
      case _TrackableStatus.delivered:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.title,
    required this.description,
    required this.subtext,
    required this.date,
  });

  final String title;
  final String description;
  final String subtext;
  final String date;
}

class _ProcurementStrategy {
  const _ProcurementStrategy({
    required this.title,
    required this.status,
    required this.itemCount,
    required this.description,
  });

  final String title;
  final _StrategyStatus status;
  final int itemCount;
  final String description;
}

enum _StrategyStatus { active, draft }

class _VendorRow {
  const _VendorRow({
    required this.initials,
    required this.name,
    required this.category,
    required this.rating,
    required this.approved,
    required this.preferred,
  });

  final String initials;
  final String name;
  final String category;
  final int rating;
  final bool approved;
  final bool preferred;
}