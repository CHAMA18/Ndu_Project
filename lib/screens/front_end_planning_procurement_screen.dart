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

  final List<_ProcurementItem> _items = const [
    _ProcurementItem(
      name: 'Network core switches',
      description: 'Upgrade backbone switches for the new wing.',
      category: 'IT Equipment',
      status: _ProcurementItemStatus.rfqReview,
      priority: _ProcurementPriority.high,
      budget: 85000,
      estimatedDelivery: '2024-08-15',
      progress: 0.35,
    ),
    _ProcurementItem(
      name: 'Office renovation package',
      description: 'Buildout for the shared collaboration floor.',
      category: 'Construction Services',
      status: _ProcurementItemStatus.vendorSelection,
      priority: _ProcurementPriority.critical,
      budget: 240000,
      estimatedDelivery: '2024-09-30',
      progress: 0.55,
    ),
    _ProcurementItem(
      name: 'Ergonomic workstations',
      description: 'Sit-stand desks and task chairs for 120 seats.',
      category: 'Furniture',
      status: _ProcurementItemStatus.ordered,
      priority: _ProcurementPriority.medium,
      budget: 68000,
      estimatedDelivery: '2024-07-10',
      progress: 0.8,
    ),
    _ProcurementItem(
      name: 'Wireless access points',
      description: 'Coverage expansion for floor 3 and floor 4.',
      category: 'IT Equipment',
      status: _ProcurementItemStatus.planning,
      priority: _ProcurementPriority.high,
      budget: 42000,
      estimatedDelivery: '2024-10-01',
      progress: 0.1,
    ),
    _ProcurementItem(
      name: 'Security camera upgrade',
      description: 'Replace legacy devices with smart analytics units.',
      category: 'Security',
      status: _ProcurementItemStatus.delivered,
      priority: _ProcurementPriority.medium,
      budget: 52000,
      estimatedDelivery: '2024-06-12',
      progress: 1.0,
    ),
  ];

  final List<_TrackableItem> _trackableItems = const [
    _TrackableItem(
      name: 'Server rack shipment',
      description: '42U racks for data center row A.',
      orderStatus: 'PO-1042',
      currentStatus: _TrackableStatus.inTransit,
      lastUpdate: '2024-06-18',
      events: [
        _TimelineEvent(
          title: 'Departed factory',
          description: 'Loaded onto carrier trailer at origin site.',
          subtext: 'Carrier: UPS Freight',
          date: '2024-06-12',
        ),
        _TimelineEvent(
          title: 'Arrived at regional hub',
          description: 'Cross-dock completed and cleared for linehaul.',
          subtext: 'Tracking: UPA-2291',
          date: '2024-06-15',
        ),
        _TimelineEvent(
          title: 'Customs cleared',
          description: 'Documentation verified and released.',
          subtext: 'Broker: BlueStar Logistics',
          date: '2024-06-17',
        ),
      ],
    ),
    _TrackableItem(
      name: 'Modular workstations',
      description: 'Set of 80 desks and power rails.',
      orderStatus: 'PO-1044',
      currentStatus: _TrackableStatus.delivered,
      lastUpdate: '2024-06-08',
      events: [
        _TimelineEvent(
          title: 'Delivered to site',
          description: 'Received at loading dock and inspected.',
          subtext: 'Signed by: Facilities team',
          date: '2024-06-08',
        ),
        _TimelineEvent(
          title: 'In transit',
          description: 'Final mile delivery in progress.',
          subtext: 'Carrier: Coastal Freight',
          date: '2024-06-06',
        ),
        _TimelineEvent(
          title: 'Dispatched',
          description: 'Shipment released from vendor warehouse.',
          subtext: 'Vendor: GreenLeaf Office',
          date: '2024-06-04',
        ),
      ],
    ),
    _TrackableItem(
      name: 'HVAC air handlers',
      description: 'Units for expansion zone climate control.',
      orderStatus: 'PO-1038',
      currentStatus: _TrackableStatus.notTracked,
      lastUpdate: null,
      events: [
        _TimelineEvent(
          title: 'Not tracked',
          description: 'Carrier tracking unavailable.',
          subtext: 'Awaiting vendor update.',
          date: '2024-06-20',
        ),
      ],
    ),
  ];

  final List<_ProcurementStrategy> _strategies = const [
    _ProcurementStrategy(
      title: 'IT equipment procurement',
      status: _StrategyStatus.active,
      itemCount: 12,
      description: 'Bundle network, compute, and AV purchases to secure volume discounts and align delivery dates.',
    ),
    _ProcurementStrategy(
      title: 'Facilities renovation services',
      status: _StrategyStatus.active,
      itemCount: 6,
      description: 'Leverage local contractors for phased buildout with strict safety and SLA requirements.',
    ),
    _ProcurementStrategy(
      title: 'Workplace furniture and fixtures',
      status: _StrategyStatus.draft,
      itemCount: 9,
      description: 'Standardize ergonomic configurations to streamline ordering and reduce variability.',
    ),
  ];

  final List<_VendorRow> _vendors = const [
    _VendorRow(
      initials: 'AT',
      name: 'Atlas Tech Supply',
      category: 'IT Equipment',
      rating: 5,
      approved: true,
      preferred: true,
    ),
    _VendorRow(
      initials: 'BL',
      name: 'BrightLine Interiors',
      category: 'Construction Services',
      rating: 4,
      approved: true,
      preferred: false,
    ),
    _VendorRow(
      initials: 'CW',
      name: 'Cloudway Systems',
      category: 'IT Equipment',
      rating: 4,
      approved: true,
      preferred: true,
    ),
    _VendorRow(
      initials: 'SO',
      name: 'SupplyOne Logistics',
      category: 'Logistics',
      rating: 3,
      approved: false,
      preferred: false,
    ),
    _VendorRow(
      initials: 'GO',
      name: 'GreenLeaf Office',
      category: 'Furniture',
      rating: 5,
      approved: true,
      preferred: true,
    ),
    _VendorRow(
      initials: 'SN',
      name: 'SecureNet Solutions',
      category: 'Security',
      rating: 4,
      approved: true,
      preferred: false,
    ),
  ];

  final List<_VendorHealthMetric> _vendorHealthMetrics = const [
    _VendorHealthMetric(category: 'IT Equipment', score: 0.86, change: '+4% QoQ'),
    _VendorHealthMetric(category: 'Construction Services', score: 0.72, change: '-2% QoQ'),
    _VendorHealthMetric(category: 'Furniture', score: 0.91, change: '+6% QoQ'),
    _VendorHealthMetric(category: 'Security', score: 0.78, change: '+1% QoQ'),
  ];

  final List<_VendorOnboardingTask> _vendorOnboardingTasks = const [
    _VendorOnboardingTask(
      title: 'Insurance verification - SupplyOne',
      owner: 'J. Patel',
      dueDate: '2024-06-24',
      status: _VendorTaskStatus.inReview,
    ),
    _VendorOnboardingTask(
      title: 'Security assessment - SecureNet',
      owner: 'L. Chen',
      dueDate: '2024-06-28',
      status: _VendorTaskStatus.pending,
    ),
    _VendorOnboardingTask(
      title: 'Payment terms signed - BrightLine',
      owner: 'M. Owens',
      dueDate: '2024-06-18',
      status: _VendorTaskStatus.complete,
    ),
  ];

  final List<_VendorRiskItem> _vendorRiskItems = const [
    _VendorRiskItem(
      vendor: 'SupplyOne Logistics',
      risk: 'Late delivery trend on three orders',
      severity: _RiskSeverity.high,
      lastIncident: '2024-06-10',
    ),
    _VendorRiskItem(
      vendor: 'BrightLine Interiors',
      risk: 'Pending safety documentation update',
      severity: _RiskSeverity.medium,
      lastIncident: '2024-06-12',
    ),
    _VendorRiskItem(
      vendor: 'SecureNet Solutions',
      risk: 'Minor SLA deviation on last install',
      severity: _RiskSeverity.low,
      lastIncident: '2024-06-05',
    ),
  ];

  final List<_RfqItem> _rfqs = const [
    _RfqItem(
      title: 'Network infrastructure upgrade',
      category: 'IT Equipment',
      owner: 'J. Patel',
      dueDate: '2024-07-05',
      invited: 6,
      responses: 3,
      budget: 160000,
      status: _RfqStatus.inMarket,
      priority: _ProcurementPriority.high,
    ),
    _RfqItem(
      title: 'Office renovation phase 2',
      category: 'Construction Services',
      owner: 'M. Owens',
      dueDate: '2024-07-18',
      invited: 4,
      responses: 2,
      budget: 320000,
      status: _RfqStatus.evaluation,
      priority: _ProcurementPriority.critical,
    ),
    _RfqItem(
      title: 'AV collaboration kits',
      category: 'Equipment',
      owner: 'L. Chen',
      dueDate: '2024-06-28',
      invited: 5,
      responses: 5,
      budget: 98000,
      status: _RfqStatus.review,
      priority: _ProcurementPriority.medium,
    ),
    _RfqItem(
      title: 'Security and access control',
      category: 'Security',
      owner: 'R. Singh',
      dueDate: '2024-07-22',
      invited: 3,
      responses: 1,
      budget: 110000,
      status: _RfqStatus.draft,
      priority: _ProcurementPriority.high,
    ),
  ];

  final List<_RfqCriterion> _rfqCriteria = const [
    _RfqCriterion(label: 'Price competitiveness', weight: 0.4),
    _RfqCriterion(label: 'Lead time reliability', weight: 0.25),
    _RfqCriterion(label: 'Quality compliance', weight: 0.2),
    _RfqCriterion(label: 'Sustainability alignment', weight: 0.15),
  ];

  final List<_PurchaseOrder> _purchaseOrders = const [
    _PurchaseOrder(
      id: 'PO-1042',
      vendor: 'Atlas Tech Supply',
      category: 'IT Equipment',
      owner: 'J. Patel',
      orderedDate: '2024-06-10',
      expectedDate: '2024-07-02',
      amount: 98500,
      progress: 0.6,
      status: _PurchaseOrderStatus.inTransit,
    ),
    _PurchaseOrder(
      id: 'PO-1043',
      vendor: 'BrightLine Interiors',
      category: 'Construction Services',
      owner: 'M. Owens',
      orderedDate: '2024-06-15',
      expectedDate: '2024-08-05',
      amount: 185000,
      progress: 0.2,
      status: _PurchaseOrderStatus.awaitingApproval,
    ),
    _PurchaseOrder(
      id: 'PO-1044',
      vendor: 'GreenLeaf Office',
      category: 'Furniture',
      owner: 'L. Chen',
      orderedDate: '2024-06-02',
      expectedDate: '2024-06-30',
      amount: 72000,
      progress: 0.75,
      status: _PurchaseOrderStatus.issued,
    ),
    _PurchaseOrder(
      id: 'PO-1045',
      vendor: 'SupplyOne Logistics',
      category: 'Logistics',
      owner: 'R. Singh',
      orderedDate: '2024-05-28',
      expectedDate: '2024-06-12',
      amount: 24000,
      progress: 1.0,
      status: _PurchaseOrderStatus.received,
    ),
    _PurchaseOrder(
      id: 'PO-1046',
      vendor: 'SecureNet Solutions',
      category: 'Security',
      owner: 'S. Parker',
      orderedDate: '2024-06-08',
      expectedDate: '2024-07-20',
      amount: 56000,
      progress: 0.35,
      status: _PurchaseOrderStatus.issued,
    ),
  ];

  final List<_TrackingAlert> _trackingAlerts = const [
    _TrackingAlert(
      title: 'Carrier delay risk',
      description: 'SupplyOne shipment has not moved in 48 hours.',
      severity: _AlertSeverity.high,
      date: '2024-06-19',
    ),
    _TrackingAlert(
      title: 'Customs review requested',
      description: 'Atlas Tech shipment awaiting secondary inspection.',
      severity: _AlertSeverity.medium,
      date: '2024-06-18',
    ),
    _TrackingAlert(
      title: 'Delivery window confirmed',
      description: 'GreenLeaf furniture arrival scheduled for June 30.',
      severity: _AlertSeverity.low,
      date: '2024-06-16',
    ),
  ];

  final List<_CarrierPerformance> _carrierPerformance = const [
    _CarrierPerformance(carrier: 'UPS Freight', onTimeRate: 92, avgDays: 4),
    _CarrierPerformance(carrier: 'Coastal Freight', onTimeRate: 88, avgDays: 5),
    _CarrierPerformance(carrier: 'BlueStar Logistics', onTimeRate: 95, avgDays: 3),
  ];

  final List<_ReportKpi> _reportKpis = const [
    _ReportKpi(label: 'Total Spend YTD', value: '\$1.08M', delta: '+6.4% vs last year', positive: false),
    _ReportKpi(label: 'Savings Identified', value: '\$214K', delta: '+18.2% vs last quarter', positive: true),
    _ReportKpi(label: 'Contract Compliance', value: '78%', delta: '+3.1% vs last quarter', positive: true),
    _ReportKpi(label: 'Avg Lead Time', value: '28 days', delta: '-2.4 days', positive: true),
  ];

  final List<_SpendBreakdown> _spendBreakdown = const [
    _SpendBreakdown(label: 'IT Equipment', amount: 420000, percent: 0.4, color: Color(0xFF2563EB)),
    _SpendBreakdown(label: 'Construction Services', amount: 310000, percent: 0.3, color: Color(0xFF14B8A6)),
    _SpendBreakdown(label: 'Furniture', amount: 160000, percent: 0.15, color: Color(0xFFF97316)),
    _SpendBreakdown(label: 'Security', amount: 120000, percent: 0.1, color: Color(0xFF8B5CF6)),
    _SpendBreakdown(label: 'Logistics', amount: 50000, percent: 0.05, color: Color(0xFF10B981)),
  ];

  final List<_LeadTimeMetric> _leadTimeMetrics = const [
    _LeadTimeMetric(label: 'IT Equipment', onTimeRate: 0.82),
    _LeadTimeMetric(label: 'Construction Services', onTimeRate: 0.74),
    _LeadTimeMetric(label: 'Furniture', onTimeRate: 0.9),
    _LeadTimeMetric(label: 'Security', onTimeRate: 0.79),
  ];

  final List<_SavingsOpportunity> _savingsOpportunities = const [
    _SavingsOpportunity(title: 'Bundle network hardware', value: '\$48K', owner: 'J. Patel'),
    _SavingsOpportunity(title: 'Standardize workstation kits', value: '\$36K', owner: 'L. Chen'),
    _SavingsOpportunity(title: 'Negotiate logistics tiers', value: '\$22K', owner: 'R. Singh'),
  ];

  final List<_ComplianceMetric> _complianceMetrics = const [
    _ComplianceMetric(label: 'Preferred vendor usage', value: 0.64),
    _ComplianceMetric(label: 'PO matched invoices', value: 0.92),
    _ComplianceMetric(label: 'SLA adherence', value: 0.86),
    _ComplianceMetric(label: 'Contracted spend', value: 0.78),
  ];

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
        return _VendorManagementView(
          key: const ValueKey('procurement_vendor_management'),
          vendors: _filteredVendors,
          allVendors: _vendors,
          approvedOnly: _approvedOnly,
          preferredOnly: _preferredOnly,
          listView: _listView,
          categoryFilter: _categoryFilter,
          categoryOptions: _categoryOptions,
          healthMetrics: _vendorHealthMetrics,
          onboardingTasks: _vendorOnboardingTasks,
          riskItems: _vendorRiskItems,
          onApprovedChanged: (value) => setState(() => _approvedOnly = value),
          onPreferredChanged: (value) => setState(() => _preferredOnly = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onViewModeChanged: (value) => setState(() => _listView = value),
        );
      case _ProcurementTab.rfqWorkflow:
        return _RfqWorkflowView(
          key: const ValueKey('procurement_rfq_workflow'),
          rfqs: _rfqs,
          criteria: _rfqCriteria,
          currencyFormat: _currencyFormat,
        );
      case _ProcurementTab.purchaseOrders:
        return _PurchaseOrdersView(
          key: const ValueKey('procurement_purchase_orders'),
          orders: _purchaseOrders,
          currencyFormat: _currencyFormat,
        );
      case _ProcurementTab.itemTracking:
        return _ItemTrackingView(
          key: const ValueKey('procurement_item_tracking'),
          trackableItems: _trackableItems,
          selectedIndex: _selectedTrackableIndex,
          onSelectTrackable: _handleTrackableSelected,
          selectedItem: (_selectedTrackableIndex >= 0 && _selectedTrackableIndex < _trackableItems.length)
              ? _trackableItems[_selectedTrackableIndex]
              : null,
          alerts: _trackingAlerts,
          carriers: _carrierPerformance,
        );
      case _ProcurementTab.reports:
        return _ReportsView(
          key: const ValueKey('procurement_reports'),
          kpis: _reportKpis,
          spendBreakdown: _spendBreakdown,
          leadTimeMetrics: _leadTimeMetrics,
          savingsOpportunities: _savingsOpportunities,
          complianceMetrics: _complianceMetrics,
          currencyFormat: _currencyFormat,
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

class _VendorManagementView extends StatelessWidget {
  const _VendorManagementView({
    super.key,
    required this.vendors,
    required this.allVendors,
    required this.approvedOnly,
    required this.preferredOnly,
    required this.listView,
    required this.categoryFilter,
    required this.categoryOptions,
    required this.healthMetrics,
    required this.onboardingTasks,
    required this.riskItems,
    required this.onApprovedChanged,
    required this.onPreferredChanged,
    required this.onCategoryChanged,
    required this.onViewModeChanged,
  });

  final List<_VendorRow> vendors;
  final List<_VendorRow> allVendors;
  final bool approvedOnly;
  final bool preferredOnly;
  final bool listView;
  final String categoryFilter;
  final List<String> categoryOptions;
  final List<_VendorHealthMetric> healthMetrics;
  final List<_VendorOnboardingTask> onboardingTasks;
  final List<_VendorRiskItem> riskItems;
  final ValueChanged<bool> onApprovedChanged;
  final ValueChanged<bool> onPreferredChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final totalVendors = allVendors.length;
    final preferredCount = allVendors.where((vendor) => vendor.preferred).length;
    final avgRating = totalVendors == 0 ? 0 : allVendors.fold<int>(0, (sum, vendor) => sum + vendor.rating) / totalVendors;
    final preferredRate = totalVendors == 0 ? 0 : (preferredCount / totalVendors * 100).round();

    final metricCards = [
      _SummaryCard(
        icon: Icons.inventory_2_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$totalVendors',
        label: 'Active Vendors',
      ),
      _SummaryCard(
        icon: Icons.star_outline,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$preferredRate%',
        label: 'Preferred Coverage',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.thumb_up_alt_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: avgRating.toStringAsFixed(1),
        label: 'Avg Rating',
      ),
      _SummaryCard(
        icon: Icons.shield_outlined,
        iconBackground: const Color(0xFFFFF1F2),
        value: '${riskItems.length}',
        label: 'Compliance Actions',
        valueColor: const Color(0xFFDC2626),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Vendor Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Invite Vendor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Vendor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metricCards[0],
              const SizedBox(height: 12),
              metricCards[1],
              const SizedBox(height: 12),
              metricCards[2],
              const SizedBox(height: 12),
              metricCards[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metricCards.length; i++) ...[
                Expanded(child: metricCards[i]),
                if (i != metricCards.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _VendorHealthCard(metrics: healthMetrics),
              const SizedBox(height: 16),
              _VendorOnboardingCard(tasks: onboardingTasks),
              const SizedBox(height: 16),
              _VendorRiskCard(riskItems: riskItems),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _VendorHealthCard(metrics: healthMetrics)),
              const SizedBox(width: 16),
              Expanded(child: _VendorOnboardingCard(tasks: onboardingTasks)),
              const SizedBox(width: 16),
              Expanded(child: _VendorRiskCard(riskItems: riskItems)),
            ],
          ),
        const SizedBox(height: 24),
        _VendorsSection(
          vendors: vendors,
          allVendorsCount: allVendors.length,
          approvedOnly: approvedOnly,
          preferredOnly: preferredOnly,
          listView: listView,
          categoryFilter: categoryFilter,
          categoryOptions: categoryOptions,
          onApprovedChanged: onApprovedChanged,
          onPreferredChanged: onPreferredChanged,
          onCategoryChanged: onCategoryChanged,
          onViewModeChanged: onViewModeChanged,
        ),
      ],
    );
  }
}

class _VendorHealthCard extends StatelessWidget {
  const _VendorHealthCard({required this.metrics});

  final List<_VendorHealthMetric> metrics;

  Color _scoreColor(double score) {
    if (score >= 0.85) return const Color(0xFF10B981);
    if (score >= 0.7) return const Color(0xFF2563EB);
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Vendor health by category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].category,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].score * 100).round()}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].score,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(metrics[i].score)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metrics[i].change,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorOnboardingCard extends StatelessWidget {
  const _VendorOnboardingCard({required this.tasks});

  final List<_VendorOnboardingTask> tasks;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Onboarding pipeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tasks.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasks[i].title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${tasks[i].owner} · Due ${DateFormat('M/d').format(DateTime.parse(tasks[i].dueDate))}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _VendorTaskStatusPill(status: tasks[i].status),
              ],
            ),
            if (i != tasks.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorRiskCard extends StatelessWidget {
  const _VendorRiskCard({required this.riskItems});

  final List<_VendorRiskItem> riskItems;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Risk watchlist',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < riskItems.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riskItems[i].vendor,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riskItems[i].risk,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last incident: ${DateFormat('M/d').format(DateTime.parse(riskItems[i].lastIncident))}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _RiskSeverityPill(severity: riskItems[i].severity),
              ],
            ),
            if (i != riskItems.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _VendorTaskStatusPill extends StatelessWidget {
  const _VendorTaskStatusPill({required this.status});

  final _VendorTaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _RiskSeverityPill extends StatelessWidget {
  const _RiskSeverityPill({required this.severity});

  final _RiskSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: severity.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: severity.borderColor),
      ),
      child: Text(
        severity.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: severity.textColor),
      ),
    );
  }
}

class _RfqWorkflowView extends StatelessWidget {
  const _RfqWorkflowView({
    super.key,
    required this.rfqs,
    required this.criteria,
    required this.currencyFormat,
  });

  final List<_RfqItem> rfqs;
  final List<_RfqCriterion> criteria;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final stages = const [
      _RfqStage(title: 'Draft', subtitle: 'Scope and requirements', status: _WorkflowStageStatus.complete),
      _RfqStage(title: 'Review', subtitle: 'Stakeholder alignment', status: _WorkflowStageStatus.complete),
      _RfqStage(title: 'In Market', subtitle: 'Vendor outreach', status: _WorkflowStageStatus.active),
      _RfqStage(title: 'Evaluation', subtitle: 'Score responses', status: _WorkflowStageStatus.upcoming),
      _RfqStage(title: 'Award', subtitle: 'Finalize supplier', status: _WorkflowStageStatus.upcoming),
    ];

    final totalInvited = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.invited);
    final totalResponses = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.responses);
    final responseRate = totalInvited == 0 ? 0 : (totalResponses / totalInvited * 100).round();
    final inEvaluation = rfqs.where((rfq) => rfq.status == _RfqStatus.evaluation).length;
    final pipelineValue = rfqs.fold<int>(0, (sum, rfq) => sum + rfq.budget);

    final metrics = [
      _SummaryCard(
        icon: Icons.assignment_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '${rfqs.length}',
        label: 'Open RFQs',
      ),
      _SummaryCard(
        icon: Icons.checklist_rounded,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$inEvaluation',
        label: 'In Evaluation',
      ),
      _SummaryCard(
        icon: Icons.groups_outlined,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$responseRate%',
        label: 'Response Rate',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.account_balance_wallet_outlined,
        iconBackground: const Color(0xFFECFEFF),
        value: currencyFormat.format(pipelineValue),
        label: 'Pipeline Value',
        valueColor: const Color(0xFF047857),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'RFQ Workflow',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Templates'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create RFQ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final stage in stages) _RfqStageCard(stage: stage)],
        ),
        const SizedBox(height: 20),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _RfqListCard(rfqs: rfqs, currencyFormat: currencyFormat),
              const SizedBox(height: 16),
              _RfqSidebarCard(rfqs: rfqs, criteria: criteria),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RfqListCard(rfqs: rfqs, currencyFormat: currencyFormat)),
              const SizedBox(width: 24),
              SizedBox(width: 320, child: _RfqSidebarCard(rfqs: rfqs, criteria: criteria)),
            ],
          ),
      ],
    );
  }
}

class _RfqStageCard extends StatelessWidget {
  const _RfqStageCard({required this.stage});

  final _RfqStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: stage.status.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stage.status.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(stage.status.icon, size: 20, color: stage.status.iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RfqListCard extends StatelessWidget {
  const _RfqListCard({required this.rfqs, required this.currencyFormat});

  final List<_RfqItem> rfqs;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: const [
              Text(
                'Active RFQs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              SizedBox(width: 8),
              Text(
                'Prioritized by due date',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rfqs.length; i++) ...[
            _RfqItemCard(rfq: rfqs[i], currencyFormat: currencyFormat),
            if (i != rfqs.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RfqItemCard extends StatelessWidget {
  const _RfqItemCard({required this.rfq, required this.currencyFormat});

  final _RfqItem rfq;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double responseRate = rfq.invited == 0 ? 0.0 : rfq.responses / rfq.invited;
    final dueLabel = DateFormat('MMM d').format(DateTime.parse(rfq.dueDate));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
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
                    Text(
                      rfq.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rfq.category} · Owner ${rfq.owner}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RfqStatusPill(status: rfq.status),
              const SizedBox(width: 6),
              _BadgePill(
                label: rfq.priority.label,
                background: rfq.priority.backgroundColor,
                border: rfq.priority.borderColor,
                foreground: rfq.priority.textColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: [
                _RfqMeta(label: 'Due', value: dueLabel),
                const SizedBox(height: 8),
                _RfqMeta(label: 'Responses', value: '${rfq.responses}/${rfq.invited}'),
                const SizedBox(height: 8),
                _RfqMeta(label: 'Budget', value: currencyFormat.format(rfq.budget)),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _RfqMeta(label: 'Due', value: dueLabel)),
                Expanded(child: _RfqMeta(label: 'Responses', value: '${rfq.responses}/${rfq.invited}')),
                Expanded(child: _RfqMeta(label: 'Budget', value: currencyFormat.format(rfq.budget))),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vendor response progress',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              Text(
                '${(responseRate * 100).round()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: responseRate,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RfqMeta extends StatelessWidget {
  const _RfqMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _RfqStatusPill extends StatelessWidget {
  const _RfqStatusPill({required this.status});

  final _RfqStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _RfqSidebarCard extends StatelessWidget {
  const _RfqSidebarCard({required this.rfqs, required this.criteria});

  final List<_RfqItem> rfqs;
  final List<_RfqCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    final upcoming = [...rfqs]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final topUpcoming = upcoming.take(3).toList();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evaluation criteria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < criteria.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        criteria[i].label,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                    ),
                    Text(
                      '${(criteria[i].weight * 100).round()}%',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: criteria[i].weight,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                if (i != criteria.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming deadlines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < topUpcoming.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topUpcoming[i].title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(DateTime.parse(topUpcoming[i].dueDate)),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (i != topUpcoming.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseOrdersView extends StatelessWidget {
  const _PurchaseOrdersView({
    super.key,
    required this.orders,
    required this.currencyFormat,
  });

  final List<_PurchaseOrder> orders;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final awaitingApproval = orders.where((order) => order.status == _PurchaseOrderStatus.awaitingApproval).length;
    final inTransit = orders.where((order) => order.status == _PurchaseOrderStatus.inTransit).length;
    final openOrders = orders.where((order) => order.status != _PurchaseOrderStatus.received).length;
    final totalSpend = orders.fold<int>(0, (sum, order) => sum + order.amount);

    final metrics = [
      _SummaryCard(
        icon: Icons.receipt_long_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$openOrders',
        label: 'Open Orders',
      ),
      _SummaryCard(
        icon: Icons.approval_outlined,
        iconBackground: const Color(0xFFFFF7ED),
        value: '$awaitingApproval',
        label: 'Awaiting Approval',
        valueColor: const Color(0xFFF97316),
      ),
      _SummaryCard(
        icon: Icons.local_shipping_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$inTransit',
        label: 'In Transit',
      ),
      _SummaryCard(
        icon: Icons.attach_money,
        iconBackground: const Color(0xFFECFEFF),
        value: currencyFormat.format(totalSpend),
        label: 'Total Spend',
        valueColor: const Color(0xFF047857),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Purchase Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Export'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create PO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              for (var i = 0; i < orders.length; i++) ...[
                _PurchaseOrderCard(order: orders[i], currencyFormat: currencyFormat),
                if (i != orders.length - 1) const SizedBox(height: 12),
              ],
            ],
          )
        else
          _PurchaseOrderTable(orders: orders, currencyFormat: currencyFormat),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _ApprovalQueueCard(orders: orders),
              const SizedBox(height: 16),
              _InvoiceMatchCard(orders: orders),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _ApprovalQueueCard(orders: orders)),
              const SizedBox(width: 16),
              Expanded(child: _InvoiceMatchCard(orders: orders)),
            ],
          ),
      ],
    );
  }
}

class _PurchaseOrderTable extends StatelessWidget {
  const _PurchaseOrderTable({required this.orders, required this.currencyFormat});

  final List<_PurchaseOrder> orders;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: _PurchaseOrderHeaderRow(),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  for (var i = 0; i < orders.length; i++) ...[
                    _PurchaseOrderRow(order: orders[i], currencyFormat: currencyFormat),
                    if (i != orders.length - 1) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseOrderHeaderRow extends StatelessWidget {
  const _PurchaseOrderHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _HeaderCell(label: 'PO', flex: 2),
        _HeaderCell(label: 'Vendor', flex: 3),
        _HeaderCell(label: 'Category', flex: 2),
        _HeaderCell(label: 'Status', flex: 2),
        _HeaderCell(label: 'Amount', flex: 2),
        _HeaderCell(label: 'Expected', flex: 2),
        _HeaderCell(label: 'Progress', flex: 2),
        _HeaderCell(label: 'Actions', flex: 2, alignEnd: true),
      ],
    );
  }
}

class _PurchaseOrderRow extends StatelessWidget {
  const _PurchaseOrderRow({required this.order, required this.currencyFormat});

  final _PurchaseOrder order;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final expectedLabel = DateFormat('M/d/yyyy').format(DateTime.parse(order.expectedDate));
    final progressLabel = '${(order.progress * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(order.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.vendor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text('Owner ${order.owner}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(order.category, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _PurchaseOrderStatusPill(status: order.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(currencyFormat.format(order.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          ),
          Expanded(flex: 2, child: Text(expectedLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
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
                    value: order.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
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
                _ActionIcon(icon: Icons.visibility_outlined),
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

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({required this.order, required this.currencyFormat});

  final _PurchaseOrder order;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final expectedLabel = DateFormat('M/d/yyyy').format(DateTime.parse(order.expectedDate));
    final progressLabel = '${(order.progress * 100).round()}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              ),
              _PurchaseOrderStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.vendor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(order.category, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RfqMeta(label: 'Expected', value: expectedLabel)),
              Expanded(child: _RfqMeta(label: 'Amount', value: currencyFormat.format(order.amount))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RfqMeta(label: 'Progress', value: progressLabel)),
              Expanded(child: _RfqMeta(label: 'Owner', value: order.owner)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: order.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D4ED8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderStatusPill extends StatelessWidget {
  const _PurchaseOrderStatusPill({required this.status});

  final _PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.borderColor),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.textColor),
      ),
    );
  }
}

class _ApprovalQueueCard extends StatelessWidget {
  const _ApprovalQueueCard({required this.orders});

  final List<_PurchaseOrder> orders;

  @override
  Widget build(BuildContext context) {
    final approvals = orders.where((order) => order.status == _PurchaseOrderStatus.awaitingApproval).toList();

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
          const Text(
            'Approval queue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          if (approvals.isEmpty)
            const Text('No approvals pending.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            for (var i = 0; i < approvals.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${approvals[i].id} · ${approvals[i].vendor}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(DateTime.parse(approvals[i].orderedDate)),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              if (i != approvals.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _InvoiceMatchCard extends StatelessWidget {
  const _InvoiceMatchCard({required this.orders});

  final List<_PurchaseOrder> orders;

  @override
  Widget build(BuildContext context) {
    final completed = orders.where((order) => order.status == _PurchaseOrderStatus.received).toList();
    final inProgress = orders.where((order) => order.status == _PurchaseOrderStatus.inTransit).toList();

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
          const Text(
            'Invoice matching',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Text(
            'Completed matches: ${completed.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Text(
            'In progress: ${inProgress.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open match workspace'),
          ),
        ],
      ),
    );
  }
}

class _ItemTrackingView extends StatelessWidget {
  const _ItemTrackingView({
    super.key,
    required this.trackableItems,
    required this.selectedIndex,
    required this.onSelectTrackable,
    required this.selectedItem,
    required this.alerts,
    required this.carriers,
  });

  final List<_TrackableItem> trackableItems;
  final int selectedIndex;
  final ValueChanged<int> onSelectTrackable;
  final _TrackableItem? selectedItem;
  final List<_TrackingAlert> alerts;
  final List<_CarrierPerformance> carriers;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final inTransit = trackableItems.where((item) => item.currentStatus == _TrackableStatus.inTransit).length;
    final delivered = trackableItems.where((item) => item.currentStatus == _TrackableStatus.delivered).length;
    final highAlerts = alerts.where((alert) => alert.severity == _AlertSeverity.high).length;
    final onTimeRate = carriers.isEmpty
        ? 0
        : (carriers.fold<int>(0, (sum, carrier) => sum + carrier.onTimeRate) / carriers.length).round();

    final metrics = [
      _SummaryCard(
        icon: Icons.local_shipping_outlined,
        iconBackground: const Color(0xFFEFF6FF),
        value: '$inTransit',
        label: 'In Transit',
      ),
      _SummaryCard(
        icon: Icons.check_circle_outline,
        iconBackground: const Color(0xFFE8FFF4),
        value: '$delivered',
        label: 'Delivered',
        valueColor: const Color(0xFF047857),
      ),
      _SummaryCard(
        icon: Icons.warning_amber_rounded,
        iconBackground: const Color(0xFFFFF1F2),
        value: '$highAlerts',
        label: 'High Priority Alerts',
        valueColor: const Color(0xFFDC2626),
      ),
      _SummaryCard(
        icon: Icons.track_changes_outlined,
        iconBackground: const Color(0xFFF1F5F9),
        value: '$onTimeRate%',
        label: 'On-time Rate',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Item Tracking',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              metrics[0],
              const SizedBox(height: 12),
              metrics[1],
              const SizedBox(height: 12),
              metrics[2],
              const SizedBox(height: 12),
              metrics[3],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i != metrics.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _TrackableItemsCard(
                trackableItems: trackableItems,
                selectedIndex: selectedIndex,
                onSelectTrackable: onSelectTrackable,
              ),
              const SizedBox(height: 16),
              _TrackingTimelineCard(item: selectedItem),
              const SizedBox(height: 16),
              _TrackingAlertsCard(alerts: alerts),
              const SizedBox(height: 16),
              _CarrierPerformanceCard(carriers: carriers),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _TrackableItemsCard(
                      trackableItems: trackableItems,
                      selectedIndex: selectedIndex,
                      onSelectTrackable: onSelectTrackable,
                    ),
                    const SizedBox(height: 16),
                    _TrackingAlertsCard(alerts: alerts),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _TrackingTimelineCard(item: selectedItem),
                    const SizedBox(height: 16),
                    _CarrierPerformanceCard(carriers: carriers),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TrackingAlertsCard extends StatelessWidget {
  const _TrackingAlertsCard({required this.alerts});

  final List<_TrackingAlert> alerts;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Logistics alerts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < alerts.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerts[i].title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alerts[i].description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('M/d').format(DateTime.parse(alerts[i].date)),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AlertSeverityPill(severity: alerts[i].severity),
              ],
            ),
            if (i != alerts.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AlertSeverityPill extends StatelessWidget {
  const _AlertSeverityPill({required this.severity});

  final _AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: severity.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: severity.borderColor),
      ),
      child: Text(
        severity.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: severity.textColor),
      ),
    );
  }
}

class _CarrierPerformanceCard extends StatelessWidget {
  const _CarrierPerformanceCard({required this.carriers});

  final List<_CarrierPerformance> carriers;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Carrier performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < carriers.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    carriers[i].carrier,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${carriers[i].onTimeRate}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Text(
                  '${carriers[i].avgDays}d avg',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: carriers[i].onTimeRate / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            if (i != carriers.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView({
    super.key,
    required this.kpis,
    required this.spendBreakdown,
    required this.leadTimeMetrics,
    required this.savingsOpportunities,
    required this.complianceMetrics,
    required this.currencyFormat,
  });

  final List<_ReportKpi> kpis;
  final List<_SpendBreakdown> spendBreakdown;
  final List<_LeadTimeMetric> leadTimeMetrics;
  final List<_SavingsOpportunity> savingsOpportunities;
  final List<_ComplianceMetric> complianceMetrics;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Procurement Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                _ReportKpiCard(kpi: kpis[i]),
                if (i != kpis.length - 1) const SizedBox(height: 12),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[
                Expanded(child: _ReportKpiCard(kpi: kpis[i])),
                if (i != kpis.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _SpendBreakdownCard(breakdown: spendBreakdown, currencyFormat: currencyFormat),
              const SizedBox(height: 16),
              _LeadTimePerformanceCard(metrics: leadTimeMetrics),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _SpendBreakdownCard(breakdown: spendBreakdown, currencyFormat: currencyFormat)),
              const SizedBox(width: 16),
              Expanded(child: _LeadTimePerformanceCard(metrics: leadTimeMetrics)),
            ],
          ),
        const SizedBox(height: 24),
        if (isMobile)
          Column(
            children: [
              _SavingsOpportunitiesCard(items: savingsOpportunities),
              const SizedBox(height: 16),
              _ComplianceSnapshotCard(metrics: complianceMetrics),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _SavingsOpportunitiesCard(items: savingsOpportunities)),
              const SizedBox(width: 16),
              Expanded(child: _ComplianceSnapshotCard(metrics: complianceMetrics)),
            ],
          ),
      ],
    );
  }
}

class _ReportKpiCard extends StatelessWidget {
  const _ReportKpiCard({required this.kpi});

  final _ReportKpi kpi;

  @override
  Widget build(BuildContext context) {
    final Color deltaColor = kpi.positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData deltaIcon = kpi.positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kpi.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(kpi.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(deltaIcon, size: 16, color: deltaColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kpi.delta,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: deltaColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendBreakdownCard extends StatelessWidget {
  const _SpendBreakdownCard({required this.breakdown, required this.currencyFormat});

  final List<_SpendBreakdown> breakdown;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Spend by category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < breakdown.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    breakdown[i].label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  currencyFormat.format(breakdown[i].amount),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: constraints.maxWidth * breakdown[i].percent,
                      decoration: BoxDecoration(
                        color: breakdown[i].color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (i != breakdown.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LeadTimePerformanceCard extends StatelessWidget {
  const _LeadTimePerformanceCard({required this.metrics});

  final List<_LeadTimeMetric> metrics;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Lead time performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].onTimeRate * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].onTimeRate,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SavingsOpportunitiesCard extends StatelessWidget {
  const _SavingsOpportunitiesCard({required this.items});

  final List<_SavingsOpportunity> items;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Savings opportunities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner ${items[i].owner}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Text(
                  items[i].value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ComplianceSnapshotCard extends StatelessWidget {
  const _ComplianceSnapshotCard({required this.metrics});

  final List<_ComplianceMetric> metrics;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Compliance snapshot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < metrics.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics[i].label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
                Text(
                  '${(metrics[i].value * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: metrics[i].value,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            if (i != metrics.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.title});

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

class _VendorHealthMetric {
  const _VendorHealthMetric({required this.category, required this.score, required this.change});

  final String category;
  final double score;
  final String change;
}

class _VendorOnboardingTask {
  const _VendorOnboardingTask({
    required this.title,
    required this.owner,
    required this.dueDate,
    required this.status,
  });

  final String title;
  final String owner;
  final String dueDate;
  final _VendorTaskStatus status;
}

enum _VendorTaskStatus { pending, inReview, complete }

extension _VendorTaskStatusExtension on _VendorTaskStatus {
  String get label {
    switch (this) {
      case _VendorTaskStatus.pending:
        return 'pending';
      case _VendorTaskStatus.inReview:
        return 'in review';
      case _VendorTaskStatus.complete:
        return 'complete';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFFF1F5F9);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFFFF7ED);
      case _VendorTaskStatus.complete:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFF64748B);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFF97316);
      case _VendorTaskStatus.complete:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _VendorTaskStatus.pending:
        return const Color(0xFFE2E8F0);
      case _VendorTaskStatus.inReview:
        return const Color(0xFFFED7AA);
      case _VendorTaskStatus.complete:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _VendorRiskItem {
  const _VendorRiskItem({
    required this.vendor,
    required this.risk,
    required this.severity,
    required this.lastIncident,
  });

  final String vendor;
  final String risk;
  final _RiskSeverity severity;
  final String lastIncident;
}

enum _RiskSeverity { low, medium, high }

extension _RiskSeverityExtension on _RiskSeverity {
  String get label {
    switch (this) {
      case _RiskSeverity.low:
        return 'low';
      case _RiskSeverity.medium:
        return 'medium';
      case _RiskSeverity.high:
        return 'high';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFFF1F5F9);
      case _RiskSeverity.medium:
        return const Color(0xFFFFF7ED);
      case _RiskSeverity.high:
        return const Color(0xFFFFF1F2);
    }
  }

  Color get textColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFF64748B);
      case _RiskSeverity.medium:
        return const Color(0xFFF97316);
      case _RiskSeverity.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get borderColor {
    switch (this) {
      case _RiskSeverity.low:
        return const Color(0xFFE2E8F0);
      case _RiskSeverity.medium:
        return const Color(0xFFFED7AA);
      case _RiskSeverity.high:
        return const Color(0xFFFECACA);
    }
  }
}

class _RfqItem {
  const _RfqItem({
    required this.title,
    required this.category,
    required this.owner,
    required this.dueDate,
    required this.invited,
    required this.responses,
    required this.budget,
    required this.status,
    required this.priority,
  });

  final String title;
  final String category;
  final String owner;
  final String dueDate;
  final int invited;
  final int responses;
  final int budget;
  final _RfqStatus status;
  final _ProcurementPriority priority;
}

enum _RfqStatus { draft, review, inMarket, evaluation, awarded }

extension _RfqStatusExtension on _RfqStatus {
  String get label {
    switch (this) {
      case _RfqStatus.draft:
        return 'draft';
      case _RfqStatus.review:
        return 'review';
      case _RfqStatus.inMarket:
        return 'in market';
      case _RfqStatus.evaluation:
        return 'evaluation';
      case _RfqStatus.awarded:
        return 'awarded';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFFF1F5F9);
      case _RfqStatus.review:
        return const Color(0xFFFFF7ED);
      case _RfqStatus.inMarket:
        return const Color(0xFFEFF6FF);
      case _RfqStatus.evaluation:
        return const Color(0xFFF5F3FF);
      case _RfqStatus.awarded:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFF64748B);
      case _RfqStatus.review:
        return const Color(0xFFF97316);
      case _RfqStatus.inMarket:
        return const Color(0xFF2563EB);
      case _RfqStatus.evaluation:
        return const Color(0xFF6D28D9);
      case _RfqStatus.awarded:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _RfqStatus.draft:
        return const Color(0xFFE2E8F0);
      case _RfqStatus.review:
        return const Color(0xFFFED7AA);
      case _RfqStatus.inMarket:
        return const Color(0xFFBFDBFE);
      case _RfqStatus.evaluation:
        return const Color(0xFFE9D5FF);
      case _RfqStatus.awarded:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _RfqStage {
  const _RfqStage({required this.title, required this.subtitle, required this.status});

  final String title;
  final String subtitle;
  final _WorkflowStageStatus status;
}

enum _WorkflowStageStatus { complete, active, upcoming }

extension _WorkflowStageStatusExtension on _WorkflowStageStatus {
  Color get backgroundColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFFE8FFF4);
      case _WorkflowStageStatus.active:
        return const Color(0xFFEFF6FF);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFFF8FAFC);
    }
  }

  Color get borderColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFFBBF7D0);
      case _WorkflowStageStatus.active:
        return const Color(0xFFBFDBFE);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get iconColor {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return const Color(0xFF047857);
      case _WorkflowStageStatus.active:
        return const Color(0xFF2563EB);
      case _WorkflowStageStatus.upcoming:
        return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (this) {
      case _WorkflowStageStatus.complete:
        return Icons.check_circle_rounded;
      case _WorkflowStageStatus.active:
        return Icons.radio_button_checked_rounded;
      case _WorkflowStageStatus.upcoming:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}

class _RfqCriterion {
  const _RfqCriterion({required this.label, required this.weight});

  final String label;
  final double weight;
}

class _PurchaseOrder {
  const _PurchaseOrder({
    required this.id,
    required this.vendor,
    required this.category,
    required this.owner,
    required this.orderedDate,
    required this.expectedDate,
    required this.amount,
    required this.progress,
    required this.status,
  });

  final String id;
  final String vendor;
  final String category;
  final String owner;
  final String orderedDate;
  final String expectedDate;
  final int amount;
  final double progress;
  final _PurchaseOrderStatus status;
}

enum _PurchaseOrderStatus { awaitingApproval, issued, inTransit, received }

extension _PurchaseOrderStatusExtension on _PurchaseOrderStatus {
  String get label {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return 'awaiting approval';
      case _PurchaseOrderStatus.issued:
        return 'issued';
      case _PurchaseOrderStatus.inTransit:
        return 'in transit';
      case _PurchaseOrderStatus.received:
        return 'received';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFFFF7ED);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFFEFF6FF);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFFF5F3FF);
      case _PurchaseOrderStatus.received:
        return const Color(0xFFE8FFF4);
    }
  }

  Color get textColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFF97316);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFF2563EB);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFF6D28D9);
      case _PurchaseOrderStatus.received:
        return const Color(0xFF047857);
    }
  }

  Color get borderColor {
    switch (this) {
      case _PurchaseOrderStatus.awaitingApproval:
        return const Color(0xFFFED7AA);
      case _PurchaseOrderStatus.issued:
        return const Color(0xFFBFDBFE);
      case _PurchaseOrderStatus.inTransit:
        return const Color(0xFFE9D5FF);
      case _PurchaseOrderStatus.received:
        return const Color(0xFFBBF7D0);
    }
  }
}

class _TrackingAlert {
  const _TrackingAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.date,
  });

  final String title;
  final String description;
  final _AlertSeverity severity;
  final String date;
}

enum _AlertSeverity { low, medium, high }

extension _AlertSeverityExtension on _AlertSeverity {
  String get label {
    switch (this) {
      case _AlertSeverity.low:
        return 'low';
      case _AlertSeverity.medium:
        return 'medium';
      case _AlertSeverity.high:
        return 'high';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFFF1F5F9);
      case _AlertSeverity.medium:
        return const Color(0xFFFFF7ED);
      case _AlertSeverity.high:
        return const Color(0xFFFFF1F2);
    }
  }

  Color get textColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFF64748B);
      case _AlertSeverity.medium:
        return const Color(0xFFF97316);
      case _AlertSeverity.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get borderColor {
    switch (this) {
      case _AlertSeverity.low:
        return const Color(0xFFE2E8F0);
      case _AlertSeverity.medium:
        return const Color(0xFFFED7AA);
      case _AlertSeverity.high:
        return const Color(0xFFFECACA);
    }
  }
}

class _CarrierPerformance {
  const _CarrierPerformance({required this.carrier, required this.onTimeRate, required this.avgDays});

  final String carrier;
  final int onTimeRate;
  final int avgDays;
}

class _ReportKpi {
  const _ReportKpi({required this.label, required this.value, required this.delta, required this.positive});

  final String label;
  final String value;
  final String delta;
  final bool positive;
}

class _SpendBreakdown {
  const _SpendBreakdown({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String label;
  final int amount;
  final double percent;
  final Color color;
}

class _LeadTimeMetric {
  const _LeadTimeMetric({required this.label, required this.onTimeRate});

  final String label;
  final double onTimeRate;
}

class _SavingsOpportunity {
  const _SavingsOpportunity({required this.title, required this.value, required this.owner});

  final String title;
  final String value;
  final String owner;
}

class _ComplianceMetric {
  const _ComplianceMetric({required this.label, required this.value});

  final String label;
  final double value;
}
