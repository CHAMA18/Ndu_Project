/// Review Screen — email composer, calendar link, double-acceptance gate.
///
/// Verbatim warning: "Upon finalization, a baseline would be set for the Scope,
/// Cost and Schedule. Scope changes would trigger Management of Change (for
/// waterfall projects)."

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CostEstimateProvider>(
      builder: (context, provider, _) {
        final estimate = provider.estimate!;
        final isBaselined = estimate.status == EstimateStatus.baselined ||
            estimate.status == EstimateStatus.rebaselined;
        final review = estimate.review ??
            ReviewApproval(
              requiredApprovers: [],
              acceptanceStep1: (confirmed: false, by: null, at: null),
              acceptanceStep2: (confirmed: false, by: null, at: null),
            );
        final isApprover = provider.currentRole == RBACRole.approver ||
            provider.currentRole == RBACRole.admin;
        final canReview = isApprover &&
            (estimate.status == EstimateStatus.draft ||
                estimate.status == EstimateStatus.inReview);

        return Scaffold(
          backgroundColor: const Color(0xFF051424),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fact_check, color: Color(0xFFF8BD2A), size: 20),
                    SizedBox(width: 8),
                    Text('Review & Acceptance',
                        style: TextStyle(
                            color: Color(0xFFD4E4FA),
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                // Baselined state
                if (isBaselined)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF4ADE80)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF4ADE80), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Baseline locked — v${estimate.baseline?.version}',
                                style: const TextStyle(
                                    color: Color(0xFF4ADE80),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Re-baselines remaining: ${estimate.baseline?.rebaselineRemaining}',
                                style: const TextStyle(
                                    color: Color(0xFFC7C6CC), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Schedule prompt
                if (canReview && review.meetingScheduled == null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BD2A).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF8BD2A)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Color(0xFFF8BD2A), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Schedule cost estimate review',
                            style: TextStyle(
                                color: Color(0xFFF8BD2A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showEmailComposer(context, provider, estimate),
                          icon: const Icon(Icons.mail, size: 14),
                          label: const Text('Email & schedule'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF8BD2A),
                            foregroundColor: const Color(0xFF402D00),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                // Acceptance progress
                if (review.acceptanceStep1.confirmed ||
                    review.acceptanceStep2.confirmed) ...[
                  _buildAcceptanceStep(
                    1,
                    'Alignment confirmed',
                    'Everyone who needs to approve is aligned on scope, schedule, and cost.',
                    review.acceptanceStep1.confirmed,
                  ),
                  const SizedBox(height: 8),
                  _buildAcceptanceStep(
                    2,
                    'Baseline acknowledged',
                    'Upon finalization, a baseline would be set for the Scope, Cost and Schedule.',
                    review.acceptanceStep2.confirmed,
                  ),
                  const SizedBox(height: 24),
                ],
                // Begin acceptance button
                if (canReview &&
                    review.meetingScheduled != null &&
                    !review.acceptanceStep1.confirmed)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => _showAcceptanceGate(context, provider, estimate),
                      icon: const Icon(Icons.shield, size: 16),
                      label: const Text('Begin acceptance'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF8BD2A),
                        foregroundColor: const Color(0xFF402D00),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcceptanceStep(
      int num, String title, String desc, bool done) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF4ADE80).withValues(alpha: 0.08)
            : const Color(0xFF1C2B3C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done
              ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
              : const Color(0xFF46464C),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? const Color(0xFF4ADE80) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF46464C),
              ),
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Color(0xFF0D1C2D))
                : Center(
                    child: Text('$num',
                        style: const TextStyle(
                            color: Color(0xFF909096), fontSize: 11)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFFD4E4FA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(
                        color: Color(0xFF909096), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailComposer(
      BuildContext context, CostEstimateProvider provider, CostEstimate estimate) {
    final recipients = [
      ...estimate.stakeholders.map((s) => s.email),
      ...estimate.access.map((a) => a.userEmail),
    ].toSet().toList();
    final subjectCtrl =
        TextEditingController(text: 'Cost Estimate Review Required — ${estimate.projectName}');
    final bodyCtrl = TextEditingController(text: '''Hello,

A cost estimate for ${estimate.projectName} is ready for review.

Estimate details:
  - Class: ${estimate.className.label}
  - Delivery model: ${estimate.deliveryModel.label}
  - Cost baseline: ${formatCurrency(estimate.totals.costBaseline, estimate.currency)}
  - Total authorized budget: ${formatCurrency(estimate.totals.totalAuthorizedBudget, estimate.currency)}

Please review the estimate and confirm your alignment on scope, schedule, and cost.

Upon finalization, a baseline will be set for the Scope, Cost and Schedule. Scope changes will trigger Management of Change (for waterfall projects).

Schedule the cost estimate review meeting to discuss.

Thank you,''');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1C2D),
        title: const Row(
          children: [
            Icon(Icons.mail, color: Color(0xFFF8BD2A), size: 18),
            SizedBox(width: 8),
            Text('Schedule cost estimate review',
                style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('To: ${recipients.join(", ")}',
                    style: const TextStyle(
                        color: Color(0xFF909096), fontSize: 11)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject',
                    labelStyle: TextStyle(color: Color(0xFF909096))),
                style: const TextStyle(color: Color(0xFFD4E4FA)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: Color(0xFF909096))),
                style: const TextStyle(
                    color: Color(0xFFD4E4FA), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF909096))),
          ),
          FilledButton(
            onPressed: () {
              provider.updateReview(ReviewApproval(
                requiredApprovers: [],
                meetingScheduled: ReviewMeeting(
                  date: DateTime.now().add(const Duration(days: 7)),
                  title: 'Cost Estimate Review — ${estimate.projectName}',
                  calendarLink: '',
                  attendees: recipients,
                ),
                emailDraft: EmailDraft(
                  to: recipients,
                  subject: subjectCtrl.text,
                  body: bodyCtrl.text,
                  sentAt: DateTime.now(),
                ),
                acceptanceStep1: (confirmed: false, by: null, at: null),
                acceptanceStep2: (confirmed: false, by: null, at: null),
              ));
              provider.submitForReview();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF8BD2A),
                foregroundColor: const Color(0xFF402D00)),
            child: const Text('Send & submit for review'),
          ),
        ],
      ),
    );
  }

  void _showAcceptanceGate(
      BuildContext context, CostEstimateProvider provider, CostEstimate estimate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AcceptanceGateDialog(
        provider: provider,
        estimate: estimate,
      ),
    );
  }
}

class _AcceptanceGateDialog extends StatefulWidget {
  final CostEstimateProvider provider;
  final CostEstimate estimate;

  const _AcceptanceGateDialog({
    required this.provider,
    required this.estimate,
  });

  @override
  State<_AcceptanceGateDialog> createState() => _AcceptanceGateDialogState();
}

class _AcceptanceGateDialogState extends State<_AcceptanceGateDialog> {
  bool _step1Confirmed = false;
  bool _step2Confirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1C2D),
      title: const Row(
        children: [
          Icon(Icons.shield, color: Color(0xFFF8BD2A), size: 18),
          SizedBox(width: 8),
          Text('Double Acceptance Gate',
              style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Two confirmations are required to lock the baseline.',
              style: TextStyle(color: Color(0xFFC7C6CC), fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Step 1
            _buildStep(
              1,
              'Alignment Confirmation',
              'Confirm that everyone that needs to approve the estimate is aligned on the scope, schedule and cost.',
              _step1Confirmed,
              _step2Confirmed,
              () => setState(() => _step1Confirmed = true),
            ),
            const SizedBox(height: 12),
            // Step 2
            _buildStep(
              2,
              'Baseline Acknowledgment',
              'Upon finalization, a baseline would be set for the Scope, Cost and Schedule. Scope changes would trigger Management of Change (for waterfall projects).',
              _step2Confirmed,
              _step1Confirmed,
              () {
                setState(() => _step2Confirmed = true);
                widget.provider.setAcceptanceStep1(true);
                widget.provider.setAcceptanceStep2(true);
                widget.provider.lockBaseline();
                Navigator.of(context).pop();
              },
              isWarning: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close',
              style: TextStyle(color: Color(0xFF909096))),
        ),
      ],
    );
  }

  Widget _buildStep(
    int num,
    String title,
    String desc,
    bool confirmed,
    bool canConfirm,
    VoidCallback onConfirm, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: confirmed
            ? const Color(0xFF4ADE80).withValues(alpha: 0.08)
            : isWarning
                ? const Color(0xFFF8BD2A).withValues(alpha: 0.05)
                : const Color(0xFF1C2B3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confirmed
              ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
              : isWarning
                  ? const Color(0xFFF8BD2A).withValues(alpha: 0.4)
                  : const Color(0xFF46464C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: confirmed
                      ? const Color(0xFF4ADE80)
                      : isWarning
                          ? const Color(0xFFF8BD2A)
                          : const Color(0xFF273647),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: confirmed
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF0D1C2D))
                      : Text('$num',
                          style: TextStyle(
                            color: isWarning
                                ? const Color(0xFF402D00)
                                : const Color(0xFF909096),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFFD4E4FA),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 13)),
          if (isWarning) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1C2D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFF8BD2A).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Color(0xFFF8BD2A), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cost baseline: ${formatCurrency(widget.estimate.totals.costBaseline, widget.estimate.currency)} · Change process: ${widget.estimate.deliveryModel.changeProcess}',
                      style: const TextStyle(
                          color: Color(0xFFC7C6CC), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!confirmed)
            FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isWarning ? const Color(0xFFF8BD2A) : const Color(0xFFF8BD2A),
                foregroundColor: const Color(0xFF402D00),
                minimumSize: const Size.fromHeight(36),
              ),
              child: Text(num == 1
                  ? 'Confirm alignment'
                  : 'Approve & lock baseline'),
            )
          else
            const Row(
              children: [
                Icon(Icons.check_circle,
                    color: Color(0xFF4ADE80), size: 14),
                SizedBox(width: 4),
                Text('Confirmed',
                    style:
                        TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}
