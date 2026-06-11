import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/pricing_config_model.dart';
import 'package:ndu_project/screens/basic_plan_dashboard_screen.dart';
import 'package:ndu_project/screens/management_level_screen.dart';
import 'package:ndu_project/services/pricing_config_service.dart';
import 'package:ndu_project/services/subscription_service.dart';
import 'package:ndu_project/widgets/payment_dialog.dart';

const Color _pageBackground = Color(0xFFF5F6F8);
const Color _primaryText = Color(0xFF0F0F0F);
const Color _secondaryText = Color(0xFF5A5C60);
const Color _themeColor = Color(0xFFF4B400); // Unified golden theme
const Color _themeSurface = Color(0xFFFFF7E6); // Soft warm backdrop

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  String? _selectedTierKey;
  // ignore: unused_field
  bool _isCheckingSubscription = false;
  bool _isAnnual = false;

  /// Map a tier key from PricingConfig to SubscriptionTier for payment processing.
  /// basic_project maps to project tier for subscription purposes.
  SubscriptionTier _convertToSubscriptionTier(String tierKey) {
    switch (tierKey) {
      case 'basic_project':
        return SubscriptionTier.project;
      case 'project':
        return SubscriptionTier.project;
      case 'program':
        return SubscriptionTier.program;
      case 'portfolio':
        return SubscriptionTier.portfolio;
      default:
        return SubscriptionTier.project;
    }
  }

  Future<void> _handlePlanSelection(BuildContext context, TierConfig tier) async {
    setState(() => _isCheckingSubscription = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final isBasicPlan = tier.key == 'basic_project';
      final subscriptionTier = _convertToSubscriptionTier(tier.key);
      final hasSubscription = await SubscriptionService.hasActiveSubscription(tier: subscriptionTier);
      
      if (!context.mounted) return;
      
      if (hasSubscription) {
        _navigateToManagementLevel(navigator, isBasicPlan: isBasicPlan);
      } else {
        final priceInfo = _priceForTier(tier);
        final paymentResult = await PaymentDialog.show(
          context: context,
          tier: subscriptionTier,
          isAnnual: _isAnnual,
          displayTierName: tier.label,
          displayPrice: priceInfo.price,
          pricingTierKey: tier.key,
          displayPeriod: _isAnnual ? 'Billed annually' : 'Billed monthly',
          onPaymentComplete: () {
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Subscription activated successfully!'),
                backgroundColor: Color(0xFF22C55E),
              ),
            );
          },
        );
        
        if (!context.mounted) return;
        if (paymentResult) {
          _navigateToManagementLevel(navigator, isBasicPlan: isBasicPlan);
        }
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error checking subscription: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCheckingSubscription = false);
    }
  }
  
  void _navigateToManagementLevel(NavigatorState navigator, {bool isBasicPlan = false}) {
    final screen = isBasicPlan
        ? const BasicPlanDashboardScreen()
        : const ManagementLevelScreen();
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  _PlanPrice _priceForTier(TierConfig tier) {
    final String? note = tier.key == 'basic_project' ? 'First month free' : null;
    if (_isAnnual) {
      final double annualPrice = tier.annualPriceDollars;
      final double annualOriginal = tier.monthlyPriceDollars * 12;
      return _PlanPrice(
        price: _currencyFormatter.format(annualPrice),
        originalPrice: annualOriginal != annualPrice ? _currencyFormatter.format(annualOriginal) : null,
        period: 'per year',
        note: note,
      );
    }
    return _PlanPrice(
      price: _currencyFormatter.format(tier.monthlyPriceDollars),
      period: 'per month',
      note: note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 800 && size.width < 1200;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : (isTablet ? 32 : 16),
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(context),
              const SizedBox(height: 32),
              _buildSectionHeader(isDesktop || isTablet),
              const SizedBox(height: 24),
              // Plans grid — loaded dynamically from PricingConfigService
              _buildDynamicPlansGrid(isDesktop, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the plans grid using dynamic pricing from PricingConfigService
  Widget _buildDynamicPlansGrid(bool isDesktop, bool isTablet) {
    return StreamBuilder<PricingConfig>(
      stream: PricingConfigService.watchConfig(),
      initialData: PricingConfigService.current,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: _themeColor),
            ),
          );
        }

        final config = snapshot.data ?? PricingConfig.defaults;
        final tiers = config.sortedTiers;

        if (tiers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.price_check_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No plans available yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        final plans = tiers.map((tier) => _DynamicPricingPlan(
          tier: tier,
          price: _priceForTier(tier),
          isSelected: _selectedTierKey == tier.key,
          onSelect: () {
            setState(() => _selectedTierKey = tier.key);
            _handlePlanSelection(context, tier);
          },
        )).toList();

        if (isDesktop) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: plans.map((plan) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _DynamicPlanColumn(plan: plan),
                ),
              )).toList(),
            ),
          );
        } else if (isTablet) {
          return Column(
            children: _buildTabletGrid(plans),
          );
        } else {
          return Column(
            children: plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _DynamicPlanColumn(plan: plan),
            )).toList(),
          );
        }
      },
    );
  }

  /// Build a 2x2 tablet grid from the list of plans
  List<Widget> _buildTabletGrid(List<_DynamicPricingPlan> plans) {
    final rows = <Widget>[];
    for (var i = 0; i < plans.length; i += 2) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + 2 && j < plans.length; j++) {
        rowChildren.add(Expanded(child: Padding(
          padding: const EdgeInsets.all(8),
          child: _DynamicPlanColumn(plan: plans[j]),
        )));
      }
      // If odd number and last row, add spacer
      if (rowChildren.length == 1) {
        rowChildren.add(const Expanded(child: SizedBox()));
      }
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rowChildren,
        ),
      ));
      if (i + 2 < plans.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    return rows;
  }

  Widget _buildSectionHeader(bool showInlineToggle) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: _primaryText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          width: 220,
          decoration: BoxDecoration(
            color: _themeColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );

    if (showInlineToggle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          title,
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BillingToggle(
                isAnnual: _isAnnual,
                onChanged: (value) => setState(() => _isAnnual = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'Annual will save 1 month\'s payment',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 12),
        _BillingToggle(
          isAnnual: _isAnnual,
          onChanged: (value) => setState(() => _isAnnual = value),
        ),
        const SizedBox(height: 8),
        const Text(
          'Annual will save 1 month\'s payment',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        _BackButton(onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.maybePop();
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
            );
          }
        }),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Select a plan that fits your needs',
            style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
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
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, color: _secondaryText, size: 20),
        ),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.isAnnual, required this.onChanged});

  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BillingToggleButton(
            label: 'Monthly',
            isActive: !isAnnual,
            onTap: () => onChanged(false),
          ),
          _BillingToggleButton(
            label: 'Annual',
            isActive: isAnnual,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _BillingToggleButton extends StatelessWidget {
  const _BillingToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? _themeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _secondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic plan data — built from TierConfig + computed price
class _DynamicPricingPlan {
  final TierConfig tier;
  final _PlanPrice price;
  final bool isSelected;
  final VoidCallback onSelect;

  const _DynamicPricingPlan({
    required this.tier,
    required this.price,
    required this.isSelected,
    required this.onSelect,
  });
}

class _DynamicPlanColumn extends StatelessWidget {
  const _DynamicPlanColumn({required this.plan});

  final _DynamicPricingPlan plan;

  @override
  Widget build(BuildContext context) {
    final Color accent = _themeColor;
    final tier = plan.tier;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            _themeSurface,
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: plan.isSelected ? accent : Colors.black12,
          width: plan.isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
          if (plan.isSelected)
            BoxShadow(
              color: accent.withOpacity(0.14),
              blurRadius: 26,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Text(
                  tier.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const Spacer(),
              if (plan.isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: _themeColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: _themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Subtitle: from config, with fallback
          Text(
            tier.subtitle.isNotEmpty
                ? tier.subtitle
                : 'Includes ${tier.includedSeats} seat${tier.includedSeats > 1 ? 's' : ''}${tier.maxSeats > tier.includedSeats ? ', up to ${tier.maxSeats} total' : ''}',
            style: const TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (plan.price.originalPrice != null) ...[
                Text(
                  plan.price.originalPrice!,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.line_through,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                plan.price.price,
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  plan.price.period,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // Show per-seat pricing if tier supports additional seats
          if (tier.maxSeats > tier.includedSeats) ...[
            const SizedBox(height: 4),
            Text(
              '+ \$${tier.perSeatMonthlyDollars.toStringAsFixed(0)}/mo per extra seat',
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (plan.price.note != null) ...[
            const SizedBox(height: 6),
            Text(
              plan.price.note!,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: tier.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [accent, accent.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: _primaryText,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: plan.onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isSelected ? accent : Colors.white,
                foregroundColor: plan.isSelected ? Colors.white : accent,
                elevation: plan.isSelected ? 8 : 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent, width: 1.4),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                shadowColor: accent.withOpacity(plan.isSelected ? 0.3 : 0.15),
              ),
              child: Text(plan.isSelected ? 'Selected' : 'Select Plan'),
            ),
          ),
        ],
      ),
    );
  }

}

class _PlanPrice {
  const _PlanPrice({required this.price, required this.period, this.note, this.originalPrice});

  final String price;
  final String period;
  final String? note;
  final String? originalPrice;
}
