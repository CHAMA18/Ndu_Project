import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/procurement/procurement_models.dart';
import 'package:ndu_project/widgets/expandable_text.dart';

class ProcurementTables extends StatelessWidget {
  final List<ProcurementItemModel> items;

  const ProcurementTables({super.key, required this.items});

  bool _isContractor(ProcurementItemModel item) {
    const contractorCategories = [
      'Services',
      'Construction Services',
      'Security',
      'Logistics',
      'Consulting',
      'Labor'
    ];
    return contractorCategories.contains(item.category);
  }

  @override
  Widget build(BuildContext context) {
    final contractors = items.where((i) => _isContractor(i)).toList();
    final vendors = items.where((i) => !_isContractor(i)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contractors',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        _buildTable(
          context,
          items: contractors,
          isContractor: true,
        ),
        const SizedBox(height: 32),
        const Text(
          'Vendors / Procurement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        _buildTable(
          context,
          items: vendors,
          isContractor: false,
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, {required List<ProcurementItemModel> items, required bool isContractor}) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'No ${isContractor ? "contractors" : "vendors"} added yet.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 12,
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              border: TableBorder.all(color: Colors.grey[300]!, width: 0.5, borderRadius: BorderRadius.circular(8)),
              columns: isContractor 
                  ? const [
                      DataColumn(label: Text('Contract Item', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Potential Contractor(s)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estimated Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    ]
                  : const [
                      DataColumn(label: Text('Equipment/Item', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Procurement Stage', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Potential Vendor(s)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estimated Price', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
              rows: items.map((item) {
                return DataRow(
                  cells: isContractor
                      ? [
                          DataCell(_TextCell(item.name)),
                          DataCell(_ExpandableCell(item.description)),
                          DataCell(_TextCell(item.notes.isNotEmpty ? item.notes : 'TBD')), // Mapping notes to potential contractors
                          DataCell(_PriceCell(item.budget)),
                          DataCell(_StatusCell(item.status.name)),
                        ]
                      : [
                          DataCell(_TextCell(item.name)),
                          DataCell(_StatusCell(item.status.name)), // Mapping status to Stage
                          DataCell(_TextCell(item.notes.isNotEmpty ? item.notes : 'TBD')),
                          DataCell(_PriceCell(item.budget)),
                          DataCell(_StatusCell(item.status.name)), // Status duplicated as requested, or maybe priority?
                        ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  const _TextCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ExpandableCell extends StatelessWidget {
  final String text;
  const _ExpandableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      child: ExpandableText(
        text: text, 
        maxLines: 2, 
        style: const TextStyle(fontSize: 14),
        expandButtonColor: Colors.blue,
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final double amount;
  const _PriceCell(this.amount);

  @override
  Widget build(BuildContext context) {
    return Text(
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final String status;
  const _StatusCell(this.status);

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'planning') color = Colors.blue;
    if (status == 'ordered') color = Colors.orange;
    if (status == 'delivered') color = Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
