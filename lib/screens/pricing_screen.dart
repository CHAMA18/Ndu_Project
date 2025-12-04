import 'package:flutter/material.dart';
import 'package:ndu_project/screens/management_level_screen.dart';
import 'package:ndu_project/services/subscription_service.dart';
import 'package:ndu_project/widgets/payment_dialog.dart';

const Color _pageBackground = Color(0xFFF5F6F8);
const Color _primaryText = Color(0xFF0F0F0F);
const Color _secondaryText = Color(0xFF5A5C60);
const Color _accent = Color(0xFFFFC940);

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _annualBilling = true;
  _PlanTier _selectedTier = _PlanTier.program;
  bool _isCheckingSubscription = false;

  /// Handle plan selection - check subscription and show payment if needed
  Future<void> _handlePlanSelection(BuildContext context, _PricingPlan plan) async {
    setState(() => _isCheckingSubscription = true);
    
    try {
      // Convert _PlanTier to SubscriptionTier
      final subscriptionTier = _convertToSubscriptionTier(plan.tier);
      
      // Check if user already has an active subscription for this tier
      final hasSubscription = await SubscriptionService.hasActiveSubscription(tier: subscriptionTier);
      
      if (!mounted) return;
      
      if (hasSubscription) {
        // User has active subscription, proceed to next screen
        _navigateToManagementLevel(context);
      } else {
        // Show payment dialog
        final paymentResult = await PaymentDialog.show(
          context: context,
          tier: subscriptionTier,
          isAnnual: _annualBilling,
          onPaymentComplete: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription activated successfully!'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            }
          },
        );
        
        if (paymentResult && mounted) {
          _navigateToManagementLevel(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingSubscription = false);
      }
    }
  }
  
  SubscriptionTier _convertToSubscriptionTier(_PlanTier tier) {
    switch (tier) {
      case _PlanTier.project:
        return SubscriptionTier.project;
      case _PlanTier.program:
        return SubscriptionTier.program;
      case _PlanTier.portfolio:
        return SubscriptionTier.portfolio;
    }
  }
  
  void _navigateToManagementLevel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
    );
  }

  static const List<_PricingPlan> _plans = [
    _PricingPlan(
      tier: _PlanTier.project,
      label: 'Project Plan',
      subtitle: 'Launch single projects with AI-guided planning, disciplined governance, and execution clarity.',
      monthlyPrice: r'$79',
      annualPrice: r'$790',
      focusTags: [
        'Launch-ready teams',
        'Single project focus',
      ],
      valueProps: [
        'Structured playbooks covering requirements, design, procurement, and health risk.',
        'KAZ AI summaries, approvals, and decision logs anchored into every workspace.',
        'Risk, safety, health, environment (SSHER) dashboards with mitigation scoring.',
        'Interactive work breakdown structure with dependencies, milestones, and exports.',
        'Team onboarding, training, and change management workflows to keep velocity.',
      ],
      ctaLabel: 'Start with Project',
    ),
    _PricingPlan(
      tier: _PlanTier.program,
      label: 'Program Plan',
      subtitle: 'Coordinate multiple projects, align stakeholders, and measure benefits in real time.',
      monthlyPrice: r'$189',
      annualPrice: r'$1,890',
      focusTags: [
        'Up to 12 projects',
        'Program playbooks',
      ],
      valueProps: [
        'Program command centers with benefit tracking, investment prioritization, and dependency views.',
        'Consolidated risk, change request, and readiness indicators rolled up across every project.',
        'KAZ AI scenario planning surfaces next best actions, approvals, and emerging gaps.',
        'Procurement, contracts, and vendor governance streamlined at the program layer.',
        'Stakeholder rituals, approval gates, and executive briefings templated for velocity.',
      ],
      ctaLabel: 'Start with Program',
      badge: 'Most popular',
      isHighlighted: true,
    ),
    _PricingPlan(
      tier: _PlanTier.portfolio,
      label: 'Porfolio Plan',
      subtitle: 'Optimize enterprise investments with predictive governance and executive intelligence.',
      monthlyPrice: r'$449',
      annualPrice: r'$4,490',
      focusTags: [
        'Executive scale',
        'Predictive governance',
      ],
      valueProps: [
        'Strategic portfolio guardrails aligning investments, capacity, and transformation readiness.',
        'Predictive KAZ AI governance with compliance, funding, and risk escalation guardrails.',
        'Enterprise integrations, SSO, and API access for analytics platforms.',
        'Advanced financial intelligence with scenario modeling and capital allocation tracking.',
        'Dedicated success architect, white-glove onboarding, and ongoing change enablement.',
      ],
      ctaLabel: 'Start with Portfolio',
      badge: 'Executive scale',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isDesktop = size.width >= 1180;
    final bool isTablet = size.width >= 820 && size.width < 1180;

    final EdgeInsets horizontalPadding = EdgeInsets.symmetric(
      horizontal: isDesktop
          ? 120
          : isTablet
              ? 72
              : 24,
    );

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Padding(
            padding: horizontalPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context),
                const SizedBox(height: 36),
                _buildHeroSection(),
                const SizedBox(height: 28),
                // Removed tier filter chips per request
                const SizedBox(height: 0),
                _buildBillingToggle(),
                const SizedBox(height: 40),
                _PlanGrid(
                  plans: _plans,
                  selectedTier: _selectedTier,
                  annualBilling: _annualBilling,
                  onSelect: (tier) => setState(() => _selectedTier = tier),
                  onCtaTap: (plan) => _handlePlanSelection(context, plan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        _BackButton(onPressed: () async {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.maybePop();
          } else {
            // Fallback: go to management level overview if no back stack
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
            );
          }
        }),
        const SizedBox(width: 12),
        _breadcrumb(),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _secondaryText,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Compare management tiers'),
        ),
      ],
    );
  }

  Widget _breadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Project, Program and Portfolio delivery redefined',
            style: TextStyle(
              color: _secondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Pricing designed around how you deliver',
          style: TextStyle(
            fontSize: 48,
            height: 1.05,
            letterSpacing: -1,
            fontWeight: FontWeight.w800,
            color: _primaryText,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Select the tier that aligns with your operating cadence. Every plan activates KAZ AI copilots and our world-class workspaces across initiation, planning, and execution.',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 18,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanFilters() {
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: _PlanTier.values
          .map(
            (tier) => ChoiceChip(
              label: Text(_labelForTier(tier)),
              selected: _selectedTier == tier,
              onSelected: (_) => setState(() => _selectedTier = tier),
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: _selectedTier == tier ? Colors.white : _secondaryText,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBillingToggle() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        const Text(
          'Billing cadence',
          style: TextStyle(
            color: _secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        _billingChip(
          label: 'Monthly',
          selected: !_annualBilling,
          onSelected: () => setState(() => _annualBilling = false),
        ),
        _billingChip(
          label: 'Annual',
          selected: _annualBilling,
          onSelected: () => setState(() => _annualBilling = true),
          highlight: true,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Save 2 months',
            style: TextStyle(
              color: Color(0xFF8C6800),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _billingChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    bool highlight = false,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: highlight ? _accent : Colors.black,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _secondaryText,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    );
  }

  static String _labelForTier(_PlanTier tier) {
    switch (tier) {
      case _PlanTier.project:
        return 'Project';
      case _PlanTier.program:
        return 'Program';
      case _PlanTier.portfolio:
        return 'Portfolio';
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.arrow_back, color: _secondaryText, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.plans,
    required this.selectedTier,
    required this.annualBilling,
    required this.onSelect,
    required this.onCtaTap,
  });

  final List<_PricingPlan> plans;
  final _PlanTier selectedTier;
  final bool annualBilling;
  final ValueChanged<_PlanTier> onSelect;
  final ValueChanged<_PricingPlan> onCtaTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 22;
        int columns = 1;
        if (constraints.maxWidth >= 1260) {
          columns = 3;
        } else if (constraints.maxWidth >= 840) {
          columns = 2;
        }

        final double cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        // Ensure equal heights across visible cards on larger layouts.
        // Choose a balanced height that fits all planned content.
        final double? cardHeight = columns >= 2
            ? (columns == 3
                ? 760 // desktop 3-up
                : 820) // tablet 2-up
            : null; // mobile stacks naturally; no fixed height needed

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: cardWidth,
                  child: _PlanCard(
                    plan: plan,
                    isSelected: selectedTier == plan.tier,
                    annualBilling: annualBilling,
                    onTap: () {
                      onSelect(plan.tier);
                      onCtaTap(plan);
                    },
                    onSelect: () => onSelect(plan.tier),
                    fixedHeight: cardHeight,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.annualBilling,
    required this.onTap,
    required this.onSelect,
    this.fixedHeight,
  });

  final _PricingPlan plan;
  final bool isSelected;
  final bool annualBilling;
  final VoidCallback onTap;
  final VoidCallback onSelect;
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final bool highlight = isSelected;
    final Color borderColor = highlight ? _accent : Colors.black.withOpacity(0.08);
    final Color fillColor = highlight ? const Color(0xFFFFF5D8) : Colors.white;
    final Color priceColor = highlight ? const Color(0xFF1A1400) : Colors.black;
    final String price = annualBilling ? plan.annualPrice : plan.monthlyPrice;
    final String cadence = annualBilling ? 'per year' : 'per month';
    final String note = annualBilling ? 'Save two months when billed annually.' : 'Billed monthly. Cancel anytime.';

    return GestureDetector(
      onTap: onSelect,
      child: SizedBox(
        height: fixedHeight,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: highlight ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(highlight ? 0.07 : 0.04),
                blurRadius: highlight ? 32 : 18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _accent),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(
                      color: Color(0xFF8C6800),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              if (plan.badge != null) const SizedBox(height: 16),
              // Plan title (Project / Program / Portfolio)
              Text(
                plan.label,
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.subtitle,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: plan.focusTags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              RichText(
                text: TextSpan(
                  text: price,
                  style: TextStyle(
                    color: priceColor,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                  children: [
                    TextSpan(
                      text: ' $cadence',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note,
                style: const TextStyle(color: _secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 26),
              const Divider(color: Color(0xFFE8E8EA), thickness: 1),
              const SizedBox(height: 12),
              // Scrollable features zone to ensure equal-height cards never overflow
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _NoGlowBehavior(),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: plan.valueProps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = plan.valueProps[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle, color: _accent, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: _secondaryText,
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highlight ? Colors.black : Colors.black.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    elevation: 0,
                  ),
                  child: Text(
                    plan.ctaLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingPlan {
  const _PricingPlan({
    required this.tier,
    required this.label,
    required this.subtitle,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.focusTags,
    required this.valueProps,
    required this.ctaLabel,
    this.badge,
    this.isHighlighted = false,
  });

  final _PlanTier tier;
  final String label;
  final String subtitle;
  final String monthlyPrice;
  final String annualPrice;
  final List<String> focusTags;
  final List<String> valueProps;
  final String ctaLabel;
  final String? badge;
  final bool isHighlighted;
}

enum _PlanTier { project, program, portfolio }

// Removes overscroll glow inside scrollable areas within cards
class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}