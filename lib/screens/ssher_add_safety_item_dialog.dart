import 'package:ndu_project/widgets/expanding_text_field.dart';
import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
class SsherItemInput {
 final String department;
 final String teamMember;
 final String concern;
 final String riskLevel; // 'Low' | 'Medium' | 'High'
 final String mitigation;
 
 // Traceability fields
 final List<String> costItemIds;
 final List<String> scheduleActivityIds;
 final List<String> techScopeComponentIds;
 final String relatedWbsId;
 final String notes;

 SsherItemInput({
   required this.department, 
   required this.teamMember, 
   required this.concern, 
   required this.riskLevel, 
   required this.mitigation,
   this.costItemIds = const [],
   this.scheduleActivityIds = const [],
   this.techScopeComponentIds = const [],
   this.relatedWbsId = '',
   this.notes = '',
 });
}

class AddSsherItemDialog extends StatefulWidget {
 final Color accentColor;
 final IconData icon;
 final String heading;
 final String blurb;
 final String concernLabel;
 final String mitigationLabel;
 final String departmentLabel;
 final String teamMemberLabel;
 final String riskLevelLabel;
 final String saveButtonLabel;
 final List<String> departmentOptions;

 final SsherItemInput? initialData;

 const AddSsherItemDialog({
 super.key,
 required this.accentColor,
 required this.icon,
 required this.heading,
 required this.blurb,
 required this.concernLabel,
 this.mitigationLabel = 'Mitigation Strategy',
 this.departmentLabel = 'Department',
 this.teamMemberLabel = 'Team Member',
 this.riskLevelLabel = 'Risk Level',
 this.saveButtonLabel = 'Save Item',
 this.departmentOptions = const [
 'Operations',
 'Manufacturing',
 'Logistics',
 'HR',
 'Maintenance',
 'IT Security',
 'Compliance',
 'Facilities',
 'Sustainability',
 'Energy',
 'Data Governance',
 ],
 this.initialData,
 });

 @override
 State<AddSsherItemDialog> createState() => _AddSsherItemDialogState();
}

class _AddSsherItemDialogState extends State<AddSsherItemDialog> {
 final _formKey = GlobalKey<FormState>();
 late TextEditingController _memberCtrl;
 late TextEditingController _concernCtrl;
 late TextEditingController _mitigationCtrl;
 late TextEditingController _costLinksCtrl;
 late TextEditingController _scheduleLinksCtrl;
 late TextEditingController _techScopeLinksCtrl;
 late TextEditingController _wbsIdCtrl;
 late TextEditingController _traceNotesCtrl;
 late String _department;
 late String _riskLevel;
 bool _showTraceability = false;

 @override
 void initState() {
 super.initState();
 _memberCtrl = TextEditingController(text: widget.initialData?.teamMember ?? '');
 _concernCtrl = TextEditingController(text: widget.initialData?.concern ?? '');
 _mitigationCtrl = TextEditingController(text: widget.initialData?.mitigation ?? '');
 _costLinksCtrl = TextEditingController(text: widget.initialData?.costItemIds.join(', ') ?? '');
 _scheduleLinksCtrl = TextEditingController(text: widget.initialData?.scheduleActivityIds.join(', ') ?? '');
 _techScopeLinksCtrl = TextEditingController(text: widget.initialData?.techScopeComponentIds.join(', ') ?? '');
 _wbsIdCtrl = TextEditingController(text: widget.initialData?.relatedWbsId ?? '');
 _traceNotesCtrl = TextEditingController(text: widget.initialData?.notes ?? '');
 _department = widget.initialData?.department ?? 'Operations';
 _riskLevel = widget.initialData?.riskLevel ?? 'High';
 
 // Show traceability if initial data has any traceability info
 _showTraceability = (widget.initialData?.costItemIds.isNotEmpty ?? false) ||
                      (widget.initialData?.scheduleActivityIds.isNotEmpty ?? false) ||
                      (widget.initialData?.techScopeComponentIds.isNotEmpty ?? false) ||
                      (widget.initialData?.relatedWbsId?.isNotEmpty ?? false) ||
                      (widget.initialData?.notes?.isNotEmpty ?? false);

 if (!widget.departmentOptions.contains(_department)) {
 _department = widget.departmentOptions.first;
 }
 }

 @override
 void dispose() {
 _memberCtrl.dispose();
 _concernCtrl.dispose();
 _mitigationCtrl.dispose();
 _costLinksCtrl.dispose();
 _scheduleLinksCtrl.dispose();
 _techScopeLinksCtrl.dispose();
 _wbsIdCtrl.dispose();
 _traceNotesCtrl.dispose();
 super.dispose();
 }

 InputDecoration _inputDecoration(String label, ThemeData theme, ColorScheme colorScheme) {
 final borderRadius = BorderRadius.circular(12);
 final outlineColor = colorScheme.outline.withOpacity(theme.brightness == Brightness.light ? 0.2 : 0.4);
 final labelStyle = theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant);

 return InputDecoration(
 labelText: label,
 labelStyle: labelStyle,
 filled: true,
 fillColor: Color.alphaBlend(colorScheme.primary.withOpacity(0.04), colorScheme.surfaceContainerHighest.withOpacity(theme.brightness == Brightness.light ? 0.65 : 0.35)),
 border: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
 enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: outlineColor)),
 focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: BorderSide(color: widget.accentColor, width: 1.5)),
 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 );
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final colorScheme = theme.colorScheme;

 final dialog = Dialog(
 insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
 backgroundColor: colorScheme.surface,
 surfaceTintColor: colorScheme.surfaceTint,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 child: ConstrainedBox(
 constraints: const BoxConstraints(maxWidth: 720),
 child: Padding(
 padding: const EdgeInsets.all(20),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(children: [
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.12), shape: BoxShape.circle),
 child: Icon(widget.icon, color: widget.accentColor, size: 22),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 widget.heading,
 style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
 ),
 ),
 IconButton(
 icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
 tooltip: 'Close',
 onPressed: () => Navigator.pop(context),
 ),
 ]),
 const SizedBox(height: 16),
 Text(
 widget.blurb,
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
 ),
 const SizedBox(height: 16),

 // Grid-like form
 LayoutBuilder(builder: (context, constraints) {
 final isNarrow = constraints.maxWidth < 600;
 return Column(children: [
 isNarrow
 ? Column(children: _row1(theme, colorScheme))
 : Row(children: _row1(theme, colorScheme)),
 const SizedBox(height: 12),
 ExpandingTextFormField(
 controller: _concernCtrl,
 minLines: 3,
 decoration: _inputDecoration(widget.concernLabel, theme, colorScheme),
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
 validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
 ),
 const SizedBox(height: 12),
 ExpandingTextFormField(
 controller: _mitigationCtrl,
 minLines: 3,
 decoration: _inputDecoration(widget.mitigationLabel, theme, colorScheme),
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
 validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
 ),
 ]);
 }),

 // Traceability Section (expandable)
 const SizedBox(height: 16),
 Container(
 decoration: BoxDecoration(
 color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
 ),
 child: Column(children: [
 ListTile(
 leading: Icon(Icons.link, color: widget.accentColor, size: 20),
 title: Text('Traceability Links', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
 subtitle: Text('Link to cost, schedule, and technical scope items', style: theme.textTheme.bodySmall),
 trailing: IconButton(
 icon: Icon(_showTraceability ? Icons.expand_less : Icons.expand_more),
 onPressed: () => setState(() => _showTraceability = !_showTraceability),
 ),
 if (_showTraceability) ...[
 const Divider(height: 1),
 Padding(
 padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
 children: [
 VoiceTextFormField(
 controller: _costLinksCtrl,
 decoration: _inputDecoration('Cost Item IDs / WBS Elements', theme, colorScheme).copyWith(
 helperText: 'Comma-separated cost line item references',
 hintText: 'e.g., COST-001, WBS-1.2.3',
 ),
 ),
 const SizedBox(height: 10),
 VoiceTextFormField(
 controller: _scheduleLinksCtrl,
 decoration: _inputDecoration('Schedule Activity IDs', theme, colorScheme).copyWith(
 helperText: 'Comma-separated activity or milestone references',
 hintText: 'e.g., MILE-001, ACT-100',
 ),
 ),
 const SizedBox(height: 10),
 VoiceTextFormField(
 controller: _techScopeLinksCtrl,
 decoration: _inputDecoration('Tech Scope Components', theme, colorScheme).copyWith(
 helperText: 'Comma-separated technology scope references',
 hintText: 'e.g., TECH-SYS-01, COMP-DATABASE',
 ),
 ),
 const SizedBox(height: 10),
 VoiceTextFormField(
 controller: _wbsIdCtrl,
 decoration: _inputDecoration('Primary WBS Reference', theme, colorScheme).copyWith(
 hintText: 'Main work breakdown structure element',
 ),
 ),
 const SizedBox(height: 10),
 VoiceTextFormField(
 controller: _traceNotesCtrl,
 maxLines: 2,
 decoration: _inputDecoration('Traceability Notes', theme, colorScheme).copyWith(
 hintText: 'Additional context about cross-references...',
 ),
 ),
 ],
 ),
 ],
 ]),
 ),

 const SizedBox(height: 20),
 Row(children: [
 OutlinedButton(
 onPressed: () => Navigator.pop(context),
 style: OutlinedButton.styleFrom(
 foregroundColor: colorScheme.onSurfaceVariant,
 side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 child: const Text('Cancel'),
 ),
 const SizedBox(width: 12),
 ElevatedButton.icon(
 onPressed: _save,
 icon: const Icon(Icons.check, size: 18),
 label: Text(widget.saveButtonLabel),
 style: ElevatedButton.styleFrom(
 backgroundColor: widget.accentColor,
 foregroundColor: Colors.white,
 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 elevation: 1,
 ),
 ),
 ]),
 ],
 ),
 ),
 ),
 ),
 );

 return dialog;
 }

 List<Widget> _row1(ThemeData theme, ColorScheme colorScheme) {
 return [
 Expanded(
 child: DropdownButtonFormField<String>(
 initialValue: _department,
 items: [
 for (final option in widget.departmentOptions)
 DropdownMenuItem(value: option, child: Text(option)),
 ],
 onChanged: (v) => setState(() => _department = v ?? _department),
 decoration: _inputDecoration(widget.departmentLabel, theme, colorScheme),
 dropdownColor: colorScheme.surface,
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: VoiceTextFormField(
 controller: _memberCtrl,
 decoration: _inputDecoration(widget.teamMemberLabel, theme, colorScheme),
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
 validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: DropdownButtonFormField<String>(
 initialValue: _riskLevel,
 items: const [
 DropdownMenuItem(value: 'Low', child: Text('Low')),
 DropdownMenuItem(value: 'Medium', child: Text('Medium')),
 DropdownMenuItem(value: 'High', child: Text('High')),
 ],
 onChanged: (v) => setState(() => _riskLevel = v ?? _riskLevel),
 decoration: _inputDecoration(widget.riskLevelLabel, theme, colorScheme),
 dropdownColor: colorScheme.surface,
 style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
 ),
 ),
 ];
 }

 void _save() {
 if (!_formKey.currentState!.validate()) return;
 
 // Parse comma-separated IDs
 final parseIds = (String text) => text
     .split(',')
     .map((s) => s.trim())
     .where((s) => s.isNotEmpty)
     .toList();

 Navigator.pop(
 context,
 SsherItemInput(
 department: _department,
 teamMember: _memberCtrl.text.trim(),
 concern: _concernCtrl.text.trim(),
 riskLevel: _riskLevel,
 mitigation: _mitigationCtrl.text.trim(),
 costItemIds: parseIds(_costLinksCtrl.text),
 scheduleActivityIds: parseIds(_scheduleLinksCtrl.text),
 techScopeComponentIds: parseIds(_techScopeLinksCtrl.text),
 relatedWbsId: _wbsIdCtrl.text.trim(),
 notes: _traceNotesCtrl.text.trim(),
 ),
 );
 }
}
