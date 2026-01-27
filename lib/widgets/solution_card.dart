import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Card widget for displaying a potential solution with summary information
class SolutionCard extends StatelessWidget {
  const SolutionCard({
    super.key,
    required this.solution,
    required this.onViewDetails,
    this.onDelete,
    this.riskCount = 0,
    this.itConsiderationsCount = 0,
    this.infrastructureStatus = 'Not specified',
    this.costBenefitSummary = 'Not calculated',
    this.stakeholderCount = 0,
    this.scopeBrief = '',
  });

  final PotentialSolution solution;
  final VoidCallback onViewDetails;
  final VoidCallback? onDelete;
  final int riskCount;
  final int itConsiderationsCount;
  final String infrastructureStatus;
  final String costBenefitSummary;
  final int stakeholderCount;
  final String scopeBrief;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solution #${solution.number}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete solution',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (solution.title.isNotEmpty)
              Text(
                solution.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            _buildSummaryRow(Icons.description, 'Scope', scopeBrief.isNotEmpty ? scopeBrief : 'Not specified'),
            _buildSummaryRow(Icons.warning, 'Risks', '$riskCount identified'),
            _buildSummaryRow(Icons.computer, 'IT', '$itConsiderationsCount items'),
            _buildSummaryRow(Icons.construction, 'Infrastructure', infrastructureStatus),
            _buildSummaryRow(Icons.attach_money, 'Cost Benefit', costBenefitSummary),
            _buildSummaryRow(Icons.people, 'Stakeholders', '$stakeholderCount identified'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
