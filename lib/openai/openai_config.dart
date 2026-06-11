import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:ndu_project/services/api_config_secure.dart';
import 'package:ndu_project/firebase_options.dart';
// Use relative import to ensure the library is part of this compilation unit
import 'package:ndu_project/utils/diagram_model.dart';

// Dreamflow env bindings (must exist with these exact names)
// Do not rename: Dreamflow injects values via --dart-define at build time
const String apiKey = String.fromEnvironment('CLAUDE_PROXY_API_KEY');
const String endpoint = String.fromEnvironment('CLAUDE_PROXY_ENDPOINT');

/// Central configuration for Anthropic Claude access.
class OpenAiConfig {
  static String get _trimmedEnvEndpoint => endpoint.trim().isEmpty
      ? ''
      : endpoint.trim().replaceAll(RegExp(r'/+$'), '');

  /// API key preference: environment overrides user-provided runtime key.
  static String get apiKeyValue {
    if (apiKey.trim().isNotEmpty) return apiKey.trim();
    return SecureAPIConfig.apiKey ?? '';
  }

  /// Base endpoint preference: environment overrides default REST endpoint.
  /// IMPORTANT: If running on web and no proxy endpoint is provided, direct
  /// calls to api.anthropic.com will be blocked by CORS. The UI will surface
  /// a clear error so the user can configure the proxy.
  static String get baseEndpoint {
    if (_trimmedEnvEndpoint.isNotEmpty) return _trimmedEnvEndpoint;
    // Fallback to project Cloud Function proxy if env not provided
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return 'https://us-central1-$projectId.cloudfunctions.net/claudeProxy';
  }

  /// Model used for Claude API requests.
  static String get model => SecureAPIConfig.model;

  /// Anthropic API version.
  static String get anthropicVersion => SecureAPIConfig.anthropicVersion;

  // Consider configured if using a proxy endpoint (no client API key needed)
  static bool get isConfigured => _isProxyEndpoint || apiKeyValue.isNotEmpty;

  /// Determine if we're using a proxy endpoint (Cloud Function, server, etc.)
  /// Proxies in this app expect requests to the BASE URL with NO extra path.
  static bool get _isProxyEndpoint {
    // Treat any non-anthropic.com endpoint as a proxy
    return !baseEndpoint.contains('anthropic.com');
  }

  /// Claude Messages API endpoint. When using a proxy endpoint, do NOT append a path.
  static Uri messagesUri() {
    final base = baseEndpoint.endsWith('/')
        ? baseEndpoint.substring(0, baseEndpoint.length - 1)
        : baseEndpoint;
    if (_isProxyEndpoint) return Uri.parse(base);
    return Uri.parse('$base/v1/messages');
  }

  /// Alias for backward compatibility with code referencing chatUri().
  static Uri chatUri() => messagesUri();

  /// Alias for backward compatibility with code referencing responsesUri().
  static Uri responsesUri() => messagesUri();

  /// Wraps a request body map for the Anthropic Claude Messages API.
  /// Transforms OpenAI-style request bodies into Anthropic Claude format:
  /// - Extracts the system message from messages array into top-level `system` param
  /// - Replaces `max_completion_tokens` with `max_tokens`
  /// - Removes `response_format` (not supported by Claude; JSON is prompted)
  /// - Removes `temperature` restrictions for reasoning models (not applicable to Claude)
  static Map<String, dynamic> wrapBody(Map<String, dynamic> body) {
    final result = Map<String, dynamic>.from(body);

    // Extract system message from messages and move to top-level 'system' param
    // Anthropic Claude requires system as a top-level parameter, not in messages
    if (result.containsKey('messages') && result['messages'] is List) {
      final messages = List<Map<String, dynamic>>.from(
        (result['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)),
      );

      // Find and extract system messages
      final systemMessages = <String>[];
      messages.removeWhere((msg) {
        if (msg['role'] == 'system') {
          final content = msg['content'];
          if (content is String) {
            systemMessages.add(content);
          } else if (content is List) {
            // OpenAI Responses API format: content is list of input_text objects
            for (final item in content) {
              if (item is Map) {
                final text = item['text'] ?? item['content'] ?? '';
                if (text is String && text.isNotEmpty) {
                  systemMessages.add(text);
                }
              }
            }
          }
          return true;
        }
        return false;
      });

      if (systemMessages.isNotEmpty && !result.containsKey('system')) {
        result['system'] = systemMessages.join('\n\n');
      }

      // Transform user/assistant messages content format
      // OpenAI Responses API uses content as list of input_text/output_text
      // Anthropic Claude uses content as plain string or list of content blocks
      final transformedMessages = <Map<String, dynamic>>[];
      for (final msg in messages) {
        final role = msg['role'] as String?;
        final content = msg['content'];

        if (content is List) {
          // OpenAI Responses API format: extract text from content blocks
          final textParts = <String>[];
          for (final item in content) {
            if (item is Map) {
              final type = item['type'];
              final text = item['text'] ?? item['content'] ?? '';
              if (text is String && text.isNotEmpty) {
                textParts.add(text);
              }
            } else if (item is String) {
              textParts.add(item);
            }
          }
          transformedMessages.add({
            'role': role ?? 'user',
            'content': textParts.join('\n'),
          });
        } else {
          transformedMessages.add(msg);
        }
      }

      result['messages'] = transformedMessages;
    }

    // Handle OpenAI Responses API 'input' format
    // The OpenAI Responses API uses 'input' instead of 'messages'
    if (result.containsKey('input') && !result.containsKey('messages')) {
      final input = result['input'];
      if (input is List) {
        final messages = <Map<String, dynamic>>[];
        final systemParts = <String>[];

        for (final item in input) {
          if (item is Map<String, dynamic>) {
            final role = item['role'] as String?;
            final content = item['content'];

            if (role == 'system') {
              if (content is String) {
                systemParts.add(content);
              } else if (content is List) {
                for (final block in content) {
                  if (block is Map) {
                    final text = block['text'] ?? '';
                    if (text is String && text.isNotEmpty) {
                      systemParts.add(text);
                    }
                  }
                }
              }
            } else {
              if (content is String) {
                messages.add({'role': role ?? 'user', 'content': content});
              } else if (content is List) {
                final textParts = <String>[];
                for (final block in content) {
                  if (block is Map) {
                    final text = block['text'] ?? block['content'] ?? '';
                    if (text is String && text.isNotEmpty) {
                      textParts.add(text);
                    }
                  }
                }
                messages.add({'role': role ?? 'user', 'content': textParts.join('\n')});
              }
            }
          }
        }

        if (systemParts.isNotEmpty) {
          result['system'] = systemParts.join('\n\n');
        }
        result['messages'] = messages;
        result.remove('input');
      }
    }

    // Replace max_completion_tokens with max_tokens (Claude uses max_tokens)
    if (result.containsKey('max_completion_tokens')) {
      result['max_tokens'] = result.remove('max_completion_tokens');
    }
    if (result.containsKey('max_output_tokens')) {
      result['max_tokens'] = result.remove('max_output_tokens');
    }

    // Ensure max_tokens exists (required by Claude API)
    if (!result.containsKey('max_tokens')) {
      result['max_tokens'] = 1200;
    }

    // Remove response_format (not supported by Claude; JSON is prompted)
    result.remove('response_format');

    // Remove OpenAI-specific fields not applicable to Claude
    result.remove('workflow_id');
    result.remove('workflowId');

    // Ensure model is set
    if (!result.containsKey('model') || (result['model'] as String).isEmpty) {
      result['model'] = model;
    }

    return result;
  }

  /// Returns headers for Anthropic Claude API requests.
  static Map<String, String> headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': apiKeyValue,
      'anthropic-version': anthropicVersion,
    };
    return headers;
  }

  /// Extracts text content from an Anthropic Claude API response.
  /// Claude returns content as: { "content": [ { "type": "text", "text": "..." } ] }
  static String extractContent(Map<String, dynamic> data) {
    // Try Anthropic Claude format first
    final content = data['content'];
    if (content is List && content.isNotEmpty) {
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map<String, dynamic>) {
          if (block['type'] == 'text' && block['text'] is String) {
            buffer.write(block['text']);
          }
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }

    // Fallback: try OpenAI format for backward compatibility
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final messageContent = message['content'];
          if (messageContent is String) return messageContent;
          if (messageContent is List) {
            return messageContent
                .map((e) => e is Map<String, dynamic> ? (e['text'] ?? '') : (e ?? ''))
                .join();
          }
        }
        final text = first['text'];
        if (text is String) return text;
      }
    }

    // Try output format (OpenAI Responses API)
    final output = data['output'];
    if (output is List) {
      final buffer = StringBuffer();
      for (final entry in output) {
        if (entry is Map<String, dynamic>) {
          final entryContent = entry['content'];
          if (entryContent is List) {
            for (final item in entryContent) {
              if (item is Map<String, dynamic>) {
                final type = item['type'];
                final text = item['text'];
                if (text is String && (type == 'output_text' || type == 'text')) {
                  buffer.write(text);
                }
              }
            }
          }
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }

    return '';
  }

  /// Helpful diagnostic used by UI to provide actionable error messages
  static String? configurationWarning() {
    if (!kIsWeb) return null;
    if (_isProxyEndpoint) return null; // ok, using proxy
    // On web with direct Anthropic endpoint: likely to hit CORS
    return 'Claude proxy endpoint not configured. Using direct Anthropic endpoint may fail due to CORS. Set CLAUDE_PROXY_ENDPOINT to your Cloud Function URL (do not append a path).';
  }
}

class OpenAiNotConfiguredException implements Exception {
  const OpenAiNotConfiguredException();

  @override
  String toString() =>
      'Claude API key is not configured. Please add a valid key to enable suggestions.';
}

/// Lightweight autocomplete service backed by Anthropic Claude Messages API.
class OpenAiAutocompleteService {
  OpenAiAutocompleteService._internal({http.Client? client})
      : _client = client ?? http.Client();

  static final OpenAiAutocompleteService instance =
      OpenAiAutocompleteService._internal();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 12);
  static const double _temperature = 0.35;

  Future<List<String>> fetchSuggestions({
    required String fieldName,
    required String currentText,
    String context = '',
    int maxSuggestions = 3,
  }) async {
    if (currentText.trim().isEmpty) return const [];
    if (!OpenAiConfig.isConfigured) {
      throw const OpenAiNotConfiguredException();
    }

    final uri = OpenAiConfig.responsesUri();
    final headers = OpenAiConfig.headers();

    final payload = {
      'model': OpenAiConfig.model,
      'temperature': _temperature,
      'max_tokens': 300,
      'system': 'You help business analysts finish their writing. Provide up to $maxSuggestions polished continuation suggestions that extend the user\'s draft. Do not repeat the existing text, do not number or bullet responses, and avoid placeholders. Return each suggestion on its own line.',
      'messages': [
        {
          'role': 'user',
          'content': 'Field: $fieldName\nCurrent draft: """${_escape(currentText)}"""\nAdditional context: """${_escape(context)}"""\nReturn up to $maxSuggestions unique continuations, each on its own line.'
        }
      ],
    };

    try {
      final warn = OpenAiConfig.configurationWarning();
      if (warn != null) {
        debugPrint('Claude configuration warning: $warn (endpoint=${OpenAiConfig.baseEndpoint})');
      }
      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(OpenAiConfig.wrapBody(payload)))
          .timeout(_timeout);

      if (response.statusCode == 429) {
        throw Exception('Claude rate limit reached. Please try again shortly.');
      }
      if (response.statusCode == 401) {
        throw Exception('Claude rejected the API key. Please verify it.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Claude request failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final combined = OpenAiConfig.extractContent(data).trim();
      final suggestions = combined
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .take(maxSuggestions)
          .toList();

      if (suggestions.isNotEmpty) return suggestions;

      return _fallbackSuggestions(currentText, maxSuggestions);
    } on TimeoutException {
      throw Exception('Claude request timed out. Please retry in a moment.');
    } on FormatException catch (e) {
      throw Exception('Failed to parse Claude response: $e');
    }
  }

  static List<String> _fallbackSuggestions(String currentText, int count) {
    final trimmed = currentText.trim();
    if (trimmed.isEmpty) return const [];

    final lastSentenceBreak = trimmed.lastIndexOf(RegExp(r'[.!?]\s'));
    final seed = lastSentenceBreak == -1
        ? trimmed
        : trimmed.substring(lastSentenceBreak + 1).trim();

    final base = seed.isEmpty ? 'The initiative' : seed;

    final patterns = <String>[
      '$base will deliver measurable value by aligning stakeholders and clarifying success metrics.',
      '$base includes a phased rollout with checkpoints to reduce delivery risk and accelerate adoption.',
      '$base secures executive sponsorship, ensuring funding, governance, and rapid decision-making support.',
    ];

    return patterns.take(count).toList();
  }

  static String _escape(String value) => value.replaceAll('"""', '"""');
}

/// Diagram generation service. Returns a simple node/edge model suitable for lightweight rendering.
class OpenAiDiagramService {
  OpenAiDiagramService._internal();
  static final OpenAiDiagramService instance = OpenAiDiagramService._internal();

  Future<DiagramModel> generateDiagram({
    required String section,
    required String contextText,
    int maxTokens = 1200,
    String? refinementHint,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      // Fallback: single-node diagram using section name
      return DiagramModel(nodes: [DiagramNode(id: 'start', label: section)], edges: const []);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = OpenAiConfig.headers();

    final prompt = _diagramPrompt(section: section, context: contextText, refinementHint: refinementHint);
    final body = jsonEncode(OpenAiConfig.wrapBody({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': maxTokens,
      'system': '''You are an expert strategic planning architect specializing in executive-level project visualization. Your diagrams are exceptional because they:
1. Show REASONING and LOGIC, not just process steps
2. Illustrate strategic thinking with decision criteria and branching paths
3. Highlight dependencies, risks, and validation checkpoints
4. Connect objectives to outcomes through clear cause-effect chains
5. Use specific, contextual labels derived from the actual project content

You create diagrams that executives and stakeholders can use to understand the "WHY" behind each step, not just the "WHAT". Every node and edge must serve a strategic purpose. Generic placeholders are never acceptable.

Always return ONLY a valid JSON object with nodes and edges arrays.''',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    }));

    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Claude diagram error ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = OpenAiConfig.extractContent(data);
      // Extract JSON from the response (may be wrapped in markdown code block)
      final jsonStr = _extractJson(content);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _parseDiagram(parsed);
    } catch (e) {
      debugPrint('Claude diagram generation failed: $e');
      // Fallback contextual diagram based on section
      return _createFallbackDiagram(section);
    }
  }

  /// Extracts JSON from a string that may contain markdown code fences.
  static String _extractJson(String text) {
    // Try to find JSON within markdown code blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim() ?? text.trim();
    }
    // Try to find raw JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }
    return text.trim();
  }

  String _diagramPrompt({required String section, required String context, String? refinementHint}) {
    final s = _sanitize(section);
    final c = _sanitize(context);
    final hintLine = refinementHint != null ? '\nUser Refinement: ${_refinementHintText(refinementHint)}\n' : '';
    return '''
You are generating a REASONING DIAGRAM for the "$s" section. This must be an exceptional, thought-provoking visual that demonstrates strategic thinking—NOT a generic flowchart.

DIAGRAM REQUIREMENTS:
1. Show REASONING CHAINS: Each node should represent a logical step in strategic thinking (e.g., "Assess Current State" → "Identify Gaps" → "Evaluate Options" → "Select Approach")
2. Include DECISION POINTS with clear criteria (e.g., "Risk Threshold?" with branches showing "High" or "Acceptable")
3. Show DEPENDENCIES and PREREQUISITES: What must happen before each phase can begin
4. Include KEY CONSIDERATIONS at critical junctures (e.g., "Budget Constraints", "Timeline Pressures", "Stakeholder Alignment")
5. Represent CAUSE-EFFECT relationships: Show how one decision impacts subsequent phases
6. Include VALIDATION checkpoints: Points where progress is verified before proceeding

For "$s" specifically, the diagram should illustrate:
- Strategic objectives driving the execution plan
- Critical success factors and how they're addressed
- Risk mitigation decision points
- Resource allocation reasoning
- Phase dependencies and sequencing rationale
- Go/No-Go decision criteria

Return ONLY valid JSON with this exact structure:
{
  "nodes": [
    {"id": "unique_id", "label": "Descriptive Label (max 5 words)", "type": "start|objective|analysis|decision|action|validation|milestone|risk|output|end"}
  ],
  "edges": [
    {"from": "source_id", "to": "target_id", "label": "relationship or condition"}
  ]
}

Guidelines:
- 8–15 nodes for comprehensive reasoning flow
- Labels must be SPECIFIC to the content, never generic (e.g., "Validate Resource Capacity" not "Check Resources")
- Edge labels should describe WHY the connection exists (e.g., "if approved", "enables", "requires", "triggers")
- Include at least 2 decision nodes with branching paths
- Include at least 1 validation/checkpoint node
- Show parallel tracks where activities can occur simultaneously
- End with measurable outcomes, not just "End"

User Context for "$s":
"""
$c
"""
$hintLine
Generate a diagram that demonstrates STRATEGIC REASONING for executing this plan, not just process steps.
''';
  }

  DiagramModel _parseDiagram(Map<String, dynamic> map) {
    final rawNodes = (map['nodes'] as List? ?? []).whereType<Map>().toList();
    final rawEdges = (map['edges'] as List? ?? []).whereType<Map>().toList();
    final nodes = <DiagramNode>[];
    for (var i = 0; i < rawNodes.length; i++) {
      final m = rawNodes[i] as Map<String, dynamic>;
      final idRaw = (m['id'] ?? '').toString().trim();
      final id = idRaw.isEmpty ? 'n${i + 1}' : idRaw;
      nodes.add(DiagramNode(
        id: id,
        label: (m['label'] ?? '').toString().trim(),
        type: (m['type'] ?? 'process').toString().trim(),
      ));
    }
    final edges = rawEdges
        .map((m) => DiagramEdge(
              from: (m['from'] ?? '').toString().trim(),
              to: (m['to'] ?? '').toString().trim(),
              label: (m['label'] ?? '').toString().trim(),
            ))
        .where((e) => e.from.isNotEmpty && e.to.isNotEmpty)
        .toList();
    if (nodes.isEmpty) {
      return const DiagramModel(nodes: [DiagramNode(id: 'start', label: 'Start')], edges: []);
    }
    return DiagramModel(nodes: nodes, edges: edges);
  }

  String _sanitize(String v) => v.replaceAll('"', '\\"');

  String _refinementHintText(String hint) {
    switch (hint) {
      case 'more_decisions':
        return 'Add more decision nodes with branching criteria, and show alternative paths.';
      case 'simplify':
        return 'Simplify the diagram. Reduce to 5-7 key nodes, merge related steps, focus on the main flow.';
      case 'focus_risks':
        return 'Emphasize risk nodes, risk mitigations, and decision points where risks are evaluated.';
      case 'timelines':
        return 'Add milestone nodes and sequence indicators to show temporal progression and phase durations.';
      default:
        return hint;
    }
  }

  /// Creates a contextual fallback diagram when API fails
  DiagramModel _createFallbackDiagram(String section) {
    final sectionLower = section.toLowerCase();

    // Executive Plan Outline specific fallback
    if (sectionLower.contains('executive') || sectionLower.contains('outline')) {
      return const DiagramModel(
        nodes: [
          DiagramNode(id: 'objectives', label: 'Define Strategic Objectives', type: 'objective'),
          DiagramNode(id: 'assess', label: 'Assess Current State', type: 'analysis'),
          DiagramNode(id: 'gaps', label: 'Identify Capability Gaps', type: 'analysis'),
          DiagramNode(id: 'decision', label: 'Feasibility Check', type: 'decision'),
          DiagramNode(id: 'approach', label: 'Select Execution Approach', type: 'action'),
          DiagramNode(id: 'resources', label: 'Allocate Resources', type: 'action'),
          DiagramNode(id: 'validate', label: 'Stakeholder Validation', type: 'validation'),
          DiagramNode(id: 'plan', label: 'Finalize Execution Plan', type: 'milestone'),
          DiagramNode(id: 'outcomes', label: 'Defined Success Metrics', type: 'output'),
        ],
        edges: [
          DiagramEdge(from: 'objectives', to: 'assess', label: 'drives'),
          DiagramEdge(from: 'assess', to: 'gaps', label: 'reveals'),
          DiagramEdge(from: 'gaps', to: 'decision', label: 'informs'),
          DiagramEdge(from: 'decision', to: 'approach', label: 'if viable'),
          DiagramEdge(from: 'approach', to: 'resources', label: 'requires'),
          DiagramEdge(from: 'resources', to: 'validate', label: 'enables'),
          DiagramEdge(from: 'validate', to: 'plan', label: 'if approved'),
          DiagramEdge(from: 'plan', to: 'outcomes', label: 'produces'),
        ],
      );
    }

    // Strategy related sections
    if (sectionLower.contains('strategy')) {
      return const DiagramModel(
        nodes: [
          DiagramNode(id: 'vision', label: 'Strategic Vision', type: 'objective'),
          DiagramNode(id: 'analyze', label: 'Market Analysis', type: 'analysis'),
          DiagramNode(id: 'options', label: 'Evaluate Options', type: 'decision'),
          DiagramNode(id: 'select', label: 'Strategy Selection', type: 'action'),
          DiagramNode(id: 'implement', label: 'Implementation Roadmap', type: 'milestone'),
        ],
        edges: [
          DiagramEdge(from: 'vision', to: 'analyze', label: 'guides'),
          DiagramEdge(from: 'analyze', to: 'options', label: 'enables'),
          DiagramEdge(from: 'options', to: 'select', label: 'informs'),
          DiagramEdge(from: 'select', to: 'implement', label: 'produces'),
        ],
      );
    }

    // Default reasoning-based fallback
    return DiagramModel(
      nodes: [
        DiagramNode(id: 'start', label: 'Define $section Goals', type: 'objective'),
        const DiagramNode(id: 'analyze', label: 'Analyze Requirements', type: 'analysis'),
        const DiagramNode(id: 'evaluate', label: 'Evaluate Approaches', type: 'decision'),
        const DiagramNode(id: 'plan', label: 'Develop Action Plan', type: 'action'),
        const DiagramNode(id: 'validate', label: 'Validation Checkpoint', type: 'validation'),
        DiagramNode(id: 'outcome', label: '$section Complete', type: 'output'),
      ],
      edges: const [
        DiagramEdge(from: 'start', to: 'analyze', label: 'requires'),
        DiagramEdge(from: 'analyze', to: 'evaluate', label: 'enables'),
        DiagramEdge(from: 'evaluate', to: 'plan', label: 'informs'),
        DiagramEdge(from: 'plan', to: 'validate', label: 'requires'),
        DiagramEdge(from: 'validate', to: 'outcome', label: 'confirms'),
      ],
    );
  }
}
