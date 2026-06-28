/// Cost Estimate Screen — main entry point for the Cost Estimate module.
///
/// A comprehensive screen that includes:
///   - Setup wizard (if no estimate exists)
///   - Builder with 4 sub-tabs (Direct, Indirect, SSHER/Quality, Additional)
///   - Totals sidebar
///   - Basis of Estimate (BOE)
///   - AI Assistant
///   - Stakeholders & Access
///   - Accounting Integration
///   - Review & Acceptance (double-acceptance gate with verbatim warning)
///   - Baseline & Variance
///
/// This is the Dart/Flutter equivalent of the Next.js Cost Estimate module.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';
import 'package:ndu_project/cost_estimate/screens/setup_wizard_screen.dart';
import 'package:ndu_project/cost_estimate/screens/builder_screen.dart';
import 'package:ndu_project/cost_estimate/screens/boe_screen.dart';
import 'package:ndu_project/cost_estimate/screens/ai_assistant_screen.dart';
import 'package:ndu_project/cost_estimate/screens/stakeholders_screen.dart';
import 'package:ndu_project/cost_estimate/screens/accounting_screen.dart';
import 'package:ndu_project/cost_estimate/screens/review_screen.dart';
import 'package:ndu_project/cost_estimate/screens/baseline_screen.dart';
import 'package:ndu_project/cost_estimate/screens/variance_screen.dart';

class CostEstimateModuleScreen extends StatefulWidget {
  const CostEstimateModuleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CostEstimateModuleScreen()),
    );
  }

  @override
  State<CostEstimateModuleScreen> createState() =>
      _CostEstimateModuleScreenState();
}

class _CostEstimateModuleScreenState extends State<CostEstimateModuleScreen> {
  _CESubModule _active = _CESubModule.builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<CostEstimateProvider>(
      builder: (context, provider, _) {
        final estimate = provider.estimate;

        // Show setup wizard if no estimate exists
        if (estimate == null || !provider.setupComplete) {
          return const SetupWizardScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: Row(
            children: [
              // Left rail
              _buildLeftRail(context, provider, estimate),
              // Main content
              Expanded(
                child: _buildMainContent(context, provider, estimate),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftRail(
      BuildContext context, CostEstimateProvider provider, CostEstimate estimate) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1C2D),
        border: Border(
          right: BorderSide(color: Color(0xFF46464C), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Project header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROJECT',
                  style: TextStyle(
                    color: Color(0xFF909096),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimate.projectName,
                  style: const TextStyle(
                    color: Color(0xFFD4E4FA),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _StatusBadge(status: estimate.status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF273647),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        estimate.className.label,
                        style: const TextStyle(
                          color: Color(0xFFC7C6CC),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${estimate.deliveryModel.label} · ${estimate.currency}',
                  style: const TextStyle(
                    color: Color(0xFF909096),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF46464C), height: 1),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _CESubModule.values.map((m) {
                final isActive = _active == m;
                return _NavTile(
                  icon: m.icon,
                  label: m.label,
                  isActive: isActive,
                  onTap: () => setState(() => _active = m),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, CostEstimateProvider provider, CostEstimate estimate) {
    switch (_active) {
      case _CESubModule.builder:
        return const BuilderScreen();
      case _CESubModule.boe:
        return const BOEScreen();
      case _CESubModule.ai:
        return const AIAssistantScreen();
      case _CESubModule.stakeholders:
        return const StakeholdersScreen();
      case _CESubModule.accounting:
        return const AccountingScreen();
      case _CESubModule.review:
        return const ReviewScreen();
      case _CESubModule.baseline:
        return const BaselineScreen();
      case _CESubModule.variance:
        return const VarianceScreen();
    }
  }
}

enum _CESubModule {
  builder,
  boe,
  ai,
  stakeholders,
  accounting,
  review,
  baseline,
  variance;

  String get label => switch (this) {
        _CESubModule.builder => 'Builder',
        _CESubModule.boe => 'Basis of Estimate',
        _CESubModule.ai => 'AI Assistant',
        _CESubModule.stakeholders => 'Stakeholders & Access',
        _CESubModule.accounting => 'Accounting',
        _CESubModule.review => 'Review & Acceptance',
        _CESubModule.baseline => 'Baseline',
        _CESubModule.variance => 'Variance & Re-baseline',
      };

  IconData get icon => switch (this) {
        _CESubModule.builder => Icons.list_alt,
        _CESubModule.boe => Icons.description,
        _CESubModule.ai => Icons.auto_awesome,
        _CESubModule.stakeholders => Icons.group,
        _CESubModule.accounting => Icons.link,
        _CESubModule.review => Icons.fact_check,
        _CESubModule.baseline => Icons.lock,
        _CESubModule.variance => Icons.trending_down,
      };
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF8BD2A).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? const Color(0xFFF8BD2A)
                    : const Color(0xFFC7C6CC),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFF8BD2A)
                        : const Color(0xFFC7C6CC),
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
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

class _StatusBadge extends StatelessWidget {
  final EstimateStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, _) = switch (status) {
      EstimateStatus.draft =>
        (const Color(0xFFC7C6CC), const Color(0xFF273647)),
      EstimateStatus.inReview =>
        (const Color(0xFFBBC3FF), const Color(0xFF273647)),
      EstimateStatus.approved =>
        (const Color(0xFFF8BD2A), const Color(0xFF273647)),
      EstimateStatus.baselined =>
        (const Color(0xFF4ADE80), const Color(0xFF273647)),
      EstimateStatus.variance =>
        (const Color(0xFFFB923C), const Color(0xFF273647)),
      EstimateStatus.rebaselined =>
        (const Color(0xFFC084FC), const Color(0xFF273647)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
