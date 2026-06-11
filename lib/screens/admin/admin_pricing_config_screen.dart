import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndu_project/models/pricing_config_model.dart';
import 'package:ndu_project/services/pricing_config_service.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class AdminPricingConfigScreen extends StatefulWidget {
  const AdminPricingConfigScreen({super.key});

  @override
  State<AdminPricingConfigScreen> createState() =>
      _AdminPricingConfigScreenState();
}

class _AdminPricingConfigScreenState extends State<AdminPricingConfigScreen> {
  PricingConfig? _config;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final config = await PricingConfigService.loadConfig();
      if (mounted) {
        setState(() {
          _config = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance
        .setLastAdminDashboard(AppRoutes.adminHome);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.attach_money,
                  color: Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Pricing Configuration',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: UnifiedProfileMenu(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTierDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Add Tier',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadConfig,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlobalSettings(),
                          const SizedBox(height: 28),
                          _buildTiersHeader(),
                          const SizedBox(height: 16),
                          ...(_config?.sortedTiers ?? [])
                              .map((tier) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _TierCard(
                                      tier: tier,
                                      onEdit: () =>
                                          _showEditTierDialog(context, tier),
                                      onToggleActive: () =>
                                          _toggleTierActive(tier),
                                      onDelete: () => _confirmDeleteTier(tier),
                                    ),
                                  ))
                              ,
                          if ((_config?.tiers.length ?? 0) == 0)
                            _buildEmptyState(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load pricing config',
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConfig,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.price_check_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No pricing tiers configured',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Add your first tier or seed defaults to get started.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddTierDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Tier'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _seedDefaults,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Seed Defaults'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettings() {
    final config = _config ?? PricingConfig.defaults;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text('Global Settings',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SettingField(
                  label: 'Free Trial Duration (days)',
                  value: config.trialDurationDays.toString(),
                  icon: Icons.timer_outlined,
                  onSave: (value) async {
                    final days = int.tryParse(value);
                    if (days != null && days > 0) {
                      await PricingConfigService.updateTrialDuration(days);
                      _loadConfig();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SettingField(
                  label: 'Default Currency',
                  value: config.defaultCurrency,
                  icon: Icons.currency_exchange,
                  onSave: (value) async {
                    if (value.isNotEmpty) {
                      await PricingConfigService.updateCurrency(
                          value.toUpperCase());
                      _loadConfig();
                    }
                  },
                ),
              ),
            ],
          ),
          if (config.updatedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Last updated: ${_formatDate(config.updatedAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiersHeader() {
    return Row(
      children: [
        const Text('Pricing Tiers',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _seedDefaults,
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reset to Defaults'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange[700],
            side: BorderSide(color: Colors.orange[300]!),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTierActive(TierConfig tier) async {
    final updated = tier.copyWith(isActive: !tier.isActive);
    await PricingConfigService.saveTierConfig(updated);
    _loadConfig();
  }

  Future<void> _confirmDeleteTier(TierConfig tier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${tier.label}"?'),
        content: Text(
            'This will permanently remove the "${tier.label}" tier from the pricing configuration. '
            'Existing subscribers on this tier will not be affected, but new sign-ups will not see it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PricingConfigService.removeTier(tier.key);
      _loadConfig();
    }
  }

  Future<void> _seedDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
            'This will overwrite all tier prices and settings with the default values. '
            'Custom tiers will be preserved unless you choose a full reset.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PricingConfigService.saveConfig(PricingConfig.defaults);
      _loadConfig();
    }
  }

  void _showAddTierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _TierFormDialog(
        existingTierKeys: _config?.tiers.keys.toList() ?? [],
        onSave: (tier) async {
          await PricingConfigService.addTier(tier);
          _loadConfig();
        },
      ),
    );
  }

  void _showEditTierDialog(BuildContext context, TierConfig tier) {
    showDialog(
      context: context,
      builder: (context) => _TierFormDialog(
        existingTier: tier,
        existingTierKeys: _config?.tiers.keys.toList() ?? [],
        onSave: (updated) async {
          await PricingConfigService.saveTierConfig(updated);
          _loadConfig();
        },
      ),
    );
  }
}

// =============================================================================
// TIER CARD WIDGET
// =============================================================================

class _TierCard extends StatelessWidget {
  final TierConfig tier;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TierCard({
    required this.tier,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tier.isActive ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tier.isActive ? Colors.grey[200]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: tier.isActive
                  ? const Color(0xFF6366F1).withOpacity(0.05)
                  : Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: tier.isActive
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tier.key.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(tier.label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tier.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tier.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tier.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tier.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pricing details
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                // Monthly & Annual prices
                Row(
                  children: [
                    Expanded(
                      child: _PriceTile(
                        label: 'Monthly',
                        value: '\$${tier.monthlyPriceDollars.toStringAsFixed(0)}',
                        subtext: 'per month',
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(
                      child: _PriceTile(
                        label: 'Annual',
                        value:
                            '\$${tier.annualPriceDollars.toStringAsFixed(0)}',
                        subtext: 'per year',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Seat pricing
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.people_outline,
                        label: 'Included seats',
                        value: '${tier.includedSeats}',
                      ),
                    ),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.person_add,
                        label: 'Extra seat/mo',
                        value:
                            '\$${tier.perSeatMonthlyDollars.toStringAsFixed(0)}',
                      ),
                    ),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.person_add,
                        label: 'Extra seat/yr',
                        value:
                            '\$${tier.perSeatAnnualDollars.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.group,
                        label: 'Max seats',
                        value: '${tier.maxSeats}',
                      ),
                    ),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.sort,
                        label: 'Display order',
                        value: '${tier.sortOrder}',
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                // Features
                if (tier.features.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tier.features
                        .map((f) => Chip(
                              label: Text(f, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],

                // Action buttons
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onToggleActive,
                      icon: Icon(
                        tier.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      label: Text(tier.isActive ? 'Deactivate' : 'Activate'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            tier.isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SMALL HELPER WIDGETS
// =============================================================================

class _PriceTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;

  const _PriceTile({
    required this.label,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
        Text(subtext, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SettingField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Future<void> Function(String) onSave;

  const _SettingField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onSave,
  });

  @override
  State<_SettingField> createState() => _SettingFieldState();
}

class _SettingFieldState extends State<_SettingField> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SettingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text == widget.value) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.label} updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: _save,
                    ),
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TIER FORM DIALOG (Add / Edit)
// =============================================================================

class _TierFormDialog extends StatefulWidget {
  final TierConfig? existingTier;
  final List<String> existingTierKeys;
  final Future<void> Function(TierConfig) onSave;

  const _TierFormDialog({
    this.existingTier,
    required this.existingTierKeys,
    required this.onSave,
  });

  @override
  State<_TierFormDialog> createState() => _TierFormDialogState();
}

class _TierFormDialogState extends State<_TierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyController;
  late TextEditingController _labelController;
  late TextEditingController _monthlyPriceController;
  late TextEditingController _annualPriceController;
  late TextEditingController _includedSeatsController;
  late TextEditingController _perSeatMonthlyController;
  late TextEditingController _perSeatAnnualController;
  late TextEditingController _maxSeatsController;
  late TextEditingController _sortOrderController;
  late TextEditingController _featuresController;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditing => widget.existingTier != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTier;
    _keyController = TextEditingController(text: t?.key ?? '');
    _labelController = TextEditingController(text: t?.label ?? '');
    _monthlyPriceController = TextEditingController(
        text: t != null ? (t.monthlyPriceDollars).toStringAsFixed(0) : '');
    _annualPriceController = TextEditingController(
        text: t != null ? (t.annualPriceDollars).toStringAsFixed(0) : '');
    _includedSeatsController =
        TextEditingController(text: (t?.includedSeats ?? 1).toString());
    _perSeatMonthlyController = TextEditingController(
        text: t != null ? (t.perSeatMonthlyDollars).toStringAsFixed(0) : '15');
    _perSeatAnnualController = TextEditingController(
        text: t != null ? (t.perSeatAnnualDollars).toStringAsFixed(0) : '165');
    _maxSeatsController =
        TextEditingController(text: (t?.maxSeats ?? 50).toString());
    _sortOrderController =
        TextEditingController(text: (t?.sortOrder ?? 0).toString());
    _featuresController =
        TextEditingController(text: t?.features.join(', ') ?? '');
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    _monthlyPriceController.dispose();
    _annualPriceController.dispose();
    _includedSeatsController.dispose();
    _perSeatMonthlyController.dispose();
    _perSeatAnnualController.dispose();
    _maxSeatsController.dispose();
    _sortOrderController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _autoFillAnnual() {
    final monthly = int.tryParse(_monthlyPriceController.text);
    if (monthly != null) {
      _annualPriceController.text = (monthly * 10).toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final tier = TierConfig(
        key: _keyController.text.trim().toLowerCase(),
        label: _labelController.text.trim(),
        monthlyPriceCents: (int.parse(_monthlyPriceController.text) * 100),
        annualPriceCents: (int.parse(_annualPriceController.text) * 100),
        includedSeats: int.parse(_includedSeatsController.text),
        perSeatMonthlyCents: (int.parse(_perSeatMonthlyController.text) * 100),
        perSeatAnnualCents: (int.parse(_perSeatAnnualController.text) * 100),
        maxSeats: int.parse(_maxSeatsController.text),
        isActive: _isActive,
        features: _featuresController.text
            .split(',')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList(),
        sortOrder: int.parse(_sortOrderController.text),
      );
      await widget.onSave(tier);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_isEditing ? Icons.edit : Icons.add_circle,
                        color: const Color(0xFF6366F1), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Edit Tier' : 'Add New Tier',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tier Key
                TextFormField(
                  controller: _keyController,
                  enabled: !_isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Tier Key *',
                    hintText: 'e.g. project, program, portfolio',
                    border: OutlineInputBorder(),
                    helperText: 'Unique identifier, cannot be changed after creation',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!_isEditing &&
                        widget.existingTierKeys.contains(v.trim().toLowerCase())) {
                      return 'This tier key already exists';
                    }
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim().toLowerCase())) {
                      return 'Lowercase letters, numbers, underscores only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Label
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Display Label *',
                    hintText: 'e.g. Project Plan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Monthly & Annual prices
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlyPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Price (USD) *',
                          hintText: '79',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        onChanged: (_) => _autoFillAnnual(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _annualPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Annual Price (USD) *',
                          hintText: '790',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Seat pricing section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, size: 18, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          const Text('Seat Pricing',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _includedSeatsController,
                              decoration: const InputDecoration(
                                labelText: 'Included Seats *',
                                hintText: '3',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxSeatsController,
                              decoration: const InputDecoration(
                                labelText: 'Max Seats *',
                                hintText: '10',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _perSeatMonthlyController,
                              decoration: const InputDecoration(
                                labelText: 'Extra Seat / Month (USD) *',
                                hintText: '15',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _perSeatAnnualController,
                              decoration: const InputDecoration(
                                labelText: 'Extra Seat / Year (USD) *',
                                hintText: '165',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sort order
                TextFormField(
                  controller: _sortOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Display Order *',
                    hintText: '1',
                    border: OutlineInputBorder(),
                    helperText: 'Lower numbers appear first',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Features
                TextFormField(
                  controller: _featuresController,
                  decoration: const InputDecoration(
                    labelText: 'Features (comma-separated)',
                    hintText: 'Full project delivery, Risk matrix, Cost analysis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Active toggle
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  subtitle: Text(_isActive
                      ? 'This tier is visible to customers'
                      : 'This tier is hidden from customers'),
                  activeColor: const Color(0xFF6366F1),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Create Tier',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
