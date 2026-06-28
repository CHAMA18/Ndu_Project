/// WBS AI Screen — 3 AI actions (suggest, expand, validate) with global/regional/local context.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/wbs/models/wbs_models.dart';
import 'package:ndu_project/wbs/providers/wbs_provider.dart';
import 'package:ndu_project/services/ai/kaz_ai_service.dart';

class WBSAIScreen extends StatefulWidget {
  const WBSAIScreen({super.key});

  @override
  State<WBSAIScreen> createState() => _WBSAIScreenState();
}

class _WBSAIScreenState extends State<WBSAIScreen> {
  String? _activeAction;
  bool _loading = false;
  List<Map<String, dynamic>> _suggestions = [];
  String _disclaimer = '';
  bool _usedFallback = false;

  final _industryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _siteContextCtrl = TextEditingController();

  final _actions = [
    ('suggest', 'Suggest WBS split', Icons.auto_awesome,
        'Full Level 1 + Level 2 from global/regional/local projects',
        const Color(0xFFF8BD2A)),
    ('expand', 'Expand a node', Icons.search,
        'Level 2 children for a selected Level 1 node',
        const Color(0xFFBBC3FF)),
    ('validate', 'Validate WBS', Icons.shield,
        'Review against best practices', const Color(0xFFC084FC)),
  ];

  @override
  void dispose() {
    _industryCtrl.dispose();
    _regionCtrl.dispose();
    _siteContextCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAction(String action) async {
    final wbs = context.read<WBSProvider>().wbs!;
    final frameworkMeta = wbs.framework;

    setState(() {
      _activeAction = action;
      _loading = true;
      _suggestions = [];
    });

    // Build existing nodes for context
    final existingNodes = <Map<String, dynamic>>[
      {
        'code': wbs.level0.code,
        'name': wbs.level0.name,
        'level': 0,
      },
      ...wbs.level0.children.map((l1) => {
            'code': l1.code,
            'name': l1.name,
            'level': 1,
            'description': l1.description,
          }),
      ...wbs.level0.children.expand((l1) => l1.children.map((l2) => {
            'code': l2.code,
            'name': l2.name,
            'level': 2,
            'description': l2.description,
          })),
    ];

    try {
      final result = await KAZAIService.wbsAI(
        action: action,
        projectName: wbs.projectName,
        framework: wbs.framework.name,
        frameworkLabel: frameworkMeta.label,
        level1Label: frameworkMeta.level1Label,
        level2Label: frameworkMeta.level2Label,
        industry: _industryCtrl.text.trim().isEmpty
            ? null
            : _industryCtrl.text.trim(),
        region: _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        siteContext: _siteContextCtrl.text.trim().isEmpty
            ? null
            : _siteContextCtrl.text.trim(),
        existingNodes: existingNodes,
      );

      setState(() {
        _suggestions =
            (result['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _disclaimer = result['disclaimer'] ?? '';
        _usedFallback = result['usedFallback'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _disclaimer = '⚠️ AI service unavailable.';
        _loading = false;
      });
    }
  }

  void _applySuggestion(Map<String, dynamic> s) {
    final provider = context.read<WBSProvider>();
    final l1Id = provider.addLevel1Node(
      s['name'] as String? ?? '',
      s['description'] as String?,
    );
    provider.updateNode(
      l1Id,
      WBSNode(
        id: l1Id,
        level: WBSLevel.level1,
        code: '',
        name: s['name'] as String? ?? '',
        description: s['description'] as String?,
        aiGenerated: true,
        aiSource: s['aiSource'] != null
            ? AISource.values.byName(s['aiSource'] as String)
            : null,
        aiConfidence: s['aiConfidence'] != null
            ? AIConfidence.values.byName(s['aiConfidence'] as String)
            : null,
        aiReference: s['aiReference'] as String?,
        children: const [],
      ),
    );
    final children = s['children'] as List?;
    if (children != null) {
      for (final child in children) {
        final c = child as Map<String, dynamic>;
        final l2Id = provider.addLevel2Node(
          l1Id,
          c['name'] as String? ?? '',
          c['description'] as String?,
        );
        provider.updateNode(
          l2Id,
          WBSNode(
            id: l2Id,
            level: WBSLevel.level2,
            code: '',
            name: c['name'] as String? ?? '',
            description: c['description'] as String?,
            aiGenerated: true,
            aiSource: c['aiSource'] != null
                ? AISource.values.byName(c['aiSource'] as String)
                : null,
            aiConfidence: c['aiConfidence'] != null
                ? AIConfidence.values.byName(c['aiConfidence'] as String)
                : null,
            aiReference: c['aiReference'] as String?,
            children: const [],
          ),
        );
      }
    }
    setState(() {
      _suggestions.removeWhere((item) => item['name'] == s['name']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFFF8BD2A), size: 20),
                    const SizedBox(width: 8),
                    const Text('AI WBS Generator',
                        style: TextStyle(
                            color: Color(0xFFD4E4FA),
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF168FFC).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('KAZ AI',
                      style: TextStyle(
                          color: Color(0xFFBBC3FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8BD2A).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF8BD2A).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Color(0xFFF8BD2A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All AI-generated WBS nodes must be validated by a qualified SME before baseline.',
                      style: TextStyle(
                          color: Color(0xFFC7C6CC), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Context inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF122131).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF46464C).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color(0xFFF8BD2A), size: 14),
                      SizedBox(width: 6),
                      Text('PROJECT CONTEXT (IMPROVES AI SUGGESTIONS)',
                          style: TextStyle(
                              color: Color(0xFFF8BD2A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            'Industry', _industryCtrl,
                            'e.g. Manufacturing, Oil & Gas'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                            'Region', _regionCtrl,
                            'e.g. East Africa, Southeast Asia'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                      'Site-specific context', _siteContextCtrl,
                      'e.g. Greenfield site, existing grid connection...',
                      maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action grid
            Row(
              children: _actions.map((a) {
                final isActive = _activeAction == a.$1;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : () => _runAction(a.$1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? a.$5.withValues(alpha: 0.08)
                                : const Color(0xFF1C2B3C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? a.$5
                                  : const Color(0xFF46464C),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(a.$3, color: a.$5, size: 20),
                              const SizedBox(height: 8),
                              Text(a.$2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFFD4E4FA),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(a.$4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF909096),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Loading
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFFF8BD2A)),
                      SizedBox(height: 12),
                      Text('KAZ AI is analyzing similar projects...',
                          style: TextStyle(
                              color: Color(0xFFC7C6CC), fontSize: 13)),
                    ],
                  ),
                ),
              ),
            // Results
            if (!_loading && _suggestions.isNotEmpty) ...[
              if (_usedFallback)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2B3C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚠️ Used KAZ AI fallback response (live model unavailable).',
                    style: TextStyle(color: Color(0xFF909096), fontSize: 11),
                  ),
                ),
              ..._suggestions.map((s) => _buildSuggestionCard(s)),
              if (_disclaimer.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8BD2A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFFF8BD2A)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(_disclaimer,
                      style: const TextStyle(
                          color: Color(0xFFF8BD2A), fontSize: 12)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF909096),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF46464C)),
            filled: true,
            fillColor: const Color(0xFF0D1C2D),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF46464C))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF8BD2A))),
          ),
          style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    final children = (s['children'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final aiSource = s['aiSource'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF46464C).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level 1 node
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8BD2A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('L1',
                      style: TextStyle(
                          color: Color(0xFFF8BD2A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(s['name'] as String? ?? '',
                              style: const TextStyle(
                                  color: Color(0xFFD4E4FA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (aiSource != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF168FFC)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(aiSource.toUpperCase(),
                                style: const TextStyle(
                                    color: Color(0xFFBBC3FF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    if (s['description'] != null)
                      Text(s['description'] as String,
                          style: const TextStyle(
                              color: Color(0xFFC7C6CC), fontSize: 13)),
                    if (s['aiReference'] != null)
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 10, color: Color(0xFFF8BD2A)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(s['aiReference'] as String,
                                style: const TextStyle(
                                    color: Color(0xFF909096),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Level 2 children
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 44),
              padding: const EdgeInsets.only(left: 16),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF46464C), width: 1),
                ),
              ),
              child: Column(
                children: children.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2B3C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text('L2',
                                style: TextStyle(
                                    color: Color(0xFF909096),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c['name'] as String? ?? '',
                              style: const TextStyle(
                                  color: Color(0xFFD4E4FA),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          // Apply button
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _applySuggestion(s),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add to WBS'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF8BD2A),
                foregroundColor: const Color(0xFF402D00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
