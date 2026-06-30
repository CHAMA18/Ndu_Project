library;

/// Add Line Dialog — create or edit a cost line.
///
/// Fields: category, sub-category, description, WBS ref, quantity, unit, rate,
/// total, in-schedule toggle, basis source (with KAZ AI disclaimer), confidence.
///
/// Light-mode (white) theme — matches the rest of the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/cost_estimate/models/cost_estimate_models.dart';
import 'package:ndu_project/cost_estimate/providers/cost_estimate_provider.dart';
import 'package:ndu_project/cost_estimate/providers/compute_utils.dart';

class AddLineDialog extends StatefulWidget {
  final CostCategory defaultCategory;
  final CostLine? editingLine;

  const AddLineDialog({
    super.key,
    required this.defaultCategory,
    this.editingLine,
  });

  @override
  State<AddLineDialog> createState() => _AddLineDialogState();
}

class _AddLineDialogState extends State<AddLineDialog> {
  late CostCategory _category;
  late String _subCategory;
  late String _description;
  late String _wbsRef;
  late bool _useQtyRate;
  late String _quantity;
  late String _unit;
  late String _rate;
  late String _total;
  late bool _inSchedule;
  late CostSourceType _basisSource;
  late String _basisReference;
  late Confidence _confidence;

  @override
  void initState() {
    super.initState();
    final l = widget.editingLine;
    _category = l?.category ?? widget.defaultCategory;
    _subCategory = l?.subCategory ?? '';
    _description = l?.description ?? '';
    _wbsRef = l?.wbsRef ?? '';
    _useQtyRate = l?.quantity != null && l?.rate != null;
    _quantity = l?.quantity?.toString() ?? '';
    _unit = l?.unit ?? 'hours';
    _rate = l?.rate?.toString() ?? '';
    _total = l?.total.toString() ?? '';
    _inSchedule = l?.inSchedule ?? true;
    _basisSource = l?.basisSource ?? CostSourceType.historical;
    _basisReference = l?.basisReference ?? '';
    _confidence = l?.confidence ?? Confidence.med;
  }

  double get _computedTotal {
    if (_useQtyRate) {
      final q = double.tryParse(_quantity) ?? 0;
      final r = double.tryParse(_rate) ?? 0;
      return q * r;
    }
    return double.tryParse(_total) ?? 0;
  }

  bool get _canSave => _description.trim().isNotEmpty && _computedTotal > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.editingLine != null ? 'Edit cost line' : 'Add cost line',
        style: const TextStyle(color: Color(0xFF1A1D1F)),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category
              _buildDropdown<CostCategory>(
                label: 'Category',
                value: _category,
                items: CostCategory.values,
                onChanged: (v) => setState(() => _category = v),
                getLabel: (c) => c.label,
              ),
              const SizedBox(height: 12),
              // Sub-category + WBS ref
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Sub-category',
                      value: _subCategory,
                      onChanged: (v) => _subCategory = v,
                      hint: 'e.g. Senior Developer',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'WBS reference',
                      value: _wbsRef,
                      onChanged: (v) => _wbsRef = v,
                      hint: 'e.g. 1.2.3',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              _buildTextField(
                label: 'Description',
                value: _description,
                onChanged: (v) => _description = v,
                hint: 'e.g. Backend API development — 8 weeks',
              ),
              const SizedBox(height: 12),
              // Qty × Rate vs Lump sum toggle
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Quantity × Rate'),
                    selected: _useQtyRate,
                    onSelected: (s) => setState(() => _useQtyRate = s),
                    selectedColor: LightModeColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _useQtyRate
                          ? LightModeColors.accent
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _useQtyRate
                          ? LightModeColors.accent
                          : const Color(0xFFE4E7EC),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Lump sum'),
                    selected: !_useQtyRate,
                    onSelected: (s) => setState(() => _useQtyRate = !s),
                    selectedColor: LightModeColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: !_useQtyRate
                          ? LightModeColors.accent
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: !_useQtyRate
                          ? LightModeColors.accent
                          : const Color(0xFFE4E7EC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_useQtyRate)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Quantity',
                        value: _quantity,
                        onChanged: (v) => _quantity = v,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Unit',
                        value: _unit,
                        onChanged: (v) => _unit = v,
                        hint: 'hours',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Rate',
                        value: _rate,
                        onChanged: (v) => _rate = v,
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                )
              else
                _buildTextField(
                  label: 'Total amount',
                  value: _total,
                  onChanged: (v) => _total = v,
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 12),
              // Computed total preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LightModeColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'COMPUTED TOTAL',
                      style: TextStyle(
                        color: LightModeColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      formatCurrency(_computedTotal, 'USD'),
                      style: const TextStyle(
                        color: Color(0xFF1A1D1F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // In-schedule toggle
              CheckboxListTile(
                value: _inSchedule,
                onChanged: (v) => setState(() => _inSchedule = v ?? true),
                title: const Text(
                  'Reflected in project schedule',
                  style: TextStyle(color: Color(0xFF1A1D1F), fontSize: 13),
                ),
                subtitle: const Text(
                  'Uncheck for SSHER, Quality, or PMO costs not in the schedule.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                ),
                activeColor: LightModeColors.accent,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 12),
              // Basis source
              _buildDropdown<CostSourceType>(
                label: 'Basis source',
                value: _basisSource,
                items: CostSourceType.values,
                onChanged: (v) => setState(() => _basisSource = v),
                getLabel: (s) => s.label,
              ),
              if (_basisSource.disclaimer != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LightModeColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: LightModeColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 14, color: LightModeColors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _basisSource.disclaimer!,
                          style: const TextStyle(
                              color: Color(0xFFD97706), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Basis reference + confidence
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Basis reference',
                      value: _basisReference,
                      onChanged: (v) => _basisReference = v,
                      hint: _basisSource == CostSourceType.kazAI
                          ? 'KAZ AI'
                          : 'e.g. Quote #1234',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<Confidence>(
                      label: 'Confidence',
                      value: _confidence,
                      items: Confidence.values,
                      onChanged: (v) => setState(() => _confidence = v),
                      getLabel: (c) => c.name.toUpperCase(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
        FilledButton(
          onPressed: _canSave ? _handleSave : null,
          style: FilledButton.styleFrom(
            backgroundColor: LightModeColors.accent,
            foregroundColor: LightModeColors.lightOnPrimary,
          ),
          child: Text(widget.editingLine != null ? 'Save changes' : 'Add line'),
        ),
      ],
    );
  }

  void _handleSave() {
    final provider = context.read<CostEstimateProvider>();
    final line = CostLine(
      id: widget.editingLine?.id ?? newId('line'),
      category: _category,
      subCategory: _subCategory.trim(),
      description: _description.trim(),
      wbsRef: _wbsRef.trim().isEmpty ? null : _wbsRef.trim(),
      quantity: _useQtyRate ? (double.tryParse(_quantity) ?? 0) : null,
      unit: _useQtyRate ? _unit : null,
      rate: _useQtyRate ? (double.tryParse(_rate) ?? 0) : null,
      total: _computedTotal,
      inSchedule: _inSchedule,
      basisSource: _basisSource,
      basisReference:
          _basisReference.trim().isEmpty ? null : _basisReference.trim(),
      aiGenerated: _basisSource == CostSourceType.kazAI,
      confidence: _confidence,
    );
    if (widget.editingLine != null) {
      provider.updateLine(widget.editingLine!.id, line);
    } else {
      provider.addLine(line);
    }
    Navigator.of(context).pop();
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: LightModeColors.accent, width: 1.6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF1A1D1F), fontSize: 14),
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    required String Function(T) getLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(getLabel(i),
                        style: const TextStyle(
                            color: Color(0xFF1A1D1F), fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: LightModeColors.accent, width: 1.6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
          ),
          dropdownColor: Colors.white,
        ),
      ],
    );
  }
}
