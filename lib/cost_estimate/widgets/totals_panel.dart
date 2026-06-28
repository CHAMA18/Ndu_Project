/// Totals Panel — sticky sidebar showing live-computed totals.
///
/// Implements the baseline formula from the guidance doc:
///   Direct + Indirect + SSHER/Quality + Risk + Contingency + Escalation + Taxes = Cost Baseline
///   Cost Baseline + Management Reserve = Total Authorized Budget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';

class TotalsPanel extends StatelessWidget {
  const TotalsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CostEstimateProvider>(
      builder: (context, provider, _) {
        final estimate = provider.estimate;
        if (estimate == null) return const SizedBox.shrink();
        final t = estimate.totals;
        final currency = estimate.currency;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF122131).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF46464C).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ESTIMATE TOTALS',
                    style: TextStyle(
                      color: Color(0xFFF8BD2A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (estimate.status == EstimateStatus.baselined ||
                      estimate.status == EstimateStatus.rebaselined)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock,
                            size: 12, color: Color(0xFF4ADE80)),
                        const SizedBox(width: 4),
                        Text(
                          'v${estimate.baseline?.version}',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _TotalRow(label: 'Direct costs', value: t.direct, currency: currency),
              _TotalRow(label: 'Indirect costs', value: t.indirect, currency: currency),
              _TotalRow(label: 'SSHER & Quality', value: t.sherQuality, currency: currency),
              _TotalRow(label: 'Risk allowances', value: t.riskAllowances, currency: currency),
              _TotalRow(label: 'Contingency', value: t.contingency, currency: currency),
              _TotalRow(label: 'Escalation', value: t.escalation, currency: currency),
              _TotalRow(label: 'Taxes & duties', value: t.taxes, currency: currency),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF46464C), height: 1),
              const SizedBox(height: 12),
              // Cost Baseline
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8BD2A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Color(0xFFF8BD2A), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Cost Baseline',
                      style: TextStyle(
                        color: Color(0xFFD4E4FA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(t.costBaseline, currency),
                      style: const TextStyle(
                        color: Color(0xFFF8BD2A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Management Reserve
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF273647).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Color(0xFFC7C6CC), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Mgmt Reserve',
                      style: TextStyle(
                        color: Color(0xFFC7C6CC),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(t.managementReserve, currency),
                      style: const TextStyle(
                        color: Color(0xFFC7C6CC),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Total Authorized Budget
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8BD2A).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF8BD2A).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'TOTAL AUTHORIZED',
                      style: TextStyle(
                        color: Color(0xFFD4E4FA),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(t.totalAuthorizedBudget, currency),
                      style: const TextStyle(
                        color: Color(0xFFD4E4FA),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 13),
          ),
          Text(
            formatCurrency(value, currency),
            style: const TextStyle(
              color: Color(0xFFD4E4FA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
