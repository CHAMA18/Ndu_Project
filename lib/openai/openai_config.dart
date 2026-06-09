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
const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

/// Central configuration for AI API access.
///
/// Supports both OpenAI and Anthropic (Claude) models:
/// - **Claude models**: Call the Anthropic API directly from the client for
///   minimum latency (no proxy overhead). Uses the `x-api-key` header with
///   the `anthropic-dangerous-direct-browser-access` header for CORS support.
/// - **OpenAI models**: Route through the Firebase Cloud Function proxy to
///   avoid CORS issues and keep the API key server-side.
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
  static String get baseEndpoint {
    if (_trimmedEnvEndpoint.isNotEmpty) return _trimmedEnvEndpoint;
    // Fallback to project Cloud Function proxy if env not provided
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return 'https://us-central1-$projectId.cloudfunctions.net/openaiProxy';
  }

  /// Model used for AI requests.
  static String get model => SecureAPIConfig.model;

  /// OpenAI Agent Builder workflow used by the Firebase proxy.
  static String get workflowId => SecureAPIConfig.workflowId;

  // Consider configured if using a proxy endpoint (no client API key needed)
  // OR if an API key is available. Claude models always need a key since
  // they call the API directly.
  static bool get isConfigured {
    if (SecureAPIConfig.isClaudeModel) {
      return apiKeyValue.isNotEmpty;
    }
    return _isProxyEndpoint || apiKeyValue.isNotEmpty;
  }

  /// Determine if we're using a proxy endpoint (Cloud Function, server, etc.)
  static bool get _isProxyEndpoint {
    return !baseEndpoint.contains('openai.com');
  }

  /// Responses API endpoint. For Claude models, returns the Anthropic
  /// Messages API endpoint directly. For OpenAI, uses the proxy.
  static Uri responsesUri() {
    if (SecureAPIConfig.isClaudeModel) {
      return Uri.parse(SecureAPIConfig.anthropicBaseUrl);
    }
    final base = baseEndpoint.endsWith('/')
        ? baseEndpoint.substring(0, baseEndpoint.length - 1)
        : baseEndpoint;
    if (_isProxyEndpoint) return Uri.parse(base);
    return Uri.parse('$base/responses');
  }

  /// Chat Completions endpoint. For Claude models, returns the Anthropic
  /// Messages API endpoint directly. For OpenAI, uses the proxy.
  static Uri chatUri() {
    if (SecureAPIConfig.isClaudeModel) {
      return Uri.parse(SecureAPIConfig.anthropicBaseUrl);
    }
    final base = baseEndpoint.endsWith('/')
        ? baseEndpoint.substring(0, baseEndpoint.length - 1)
        : baseEndpoint;
    if (_isProxyEndpoint) return Uri.parse(base);
    return Uri.parse('$base/chat/completions');
  }

  /// Returns the appropriate HTTP headers for the current model.
  /// Claude uses `x-api-key` + Anthropic-specific headers.
  /// OpenAI uses `Authorization: Bearer`.
  static Map<String, String> buildHeaders() {
    final base = <String, String>{'Content-Type': 'application/json'};
    if (SecureAPIConfig.isClaudeModel) {
      base['x-api-key'] = apiKeyValue;
      base['anthropic-version'] = '2023-06-01';
      base['anthropic-dangerous-direct-browser-access'] = 'true';
    } else {
      base['Authorization'] = 'Bearer $apiKeyValue';
    }
    return base;
  }

  /// Wraps a request body map, cleaning up parameters based on the
  /// target model's requirements.
  ///
  /// For Claude models:
  /// - Converts `max_completion_tokens` → `max_tokens` (Anthropic format)
  /// - Keeps `temperature` (Claude supports it natively)
  /// - Keeps `response_format` (adds JSON instruction to system prompt)
  ///
  /// For OpenAI reasoning models (o3, o4, o1):
  /// - Removes `temperature` (only default value of 1 supported)
  /// - Removes `max_tokens` and `max_output_tokens` (use `max_completion_tokens`)
  static Map<String, dynamic> wrapBody(Map<String, dynamic> body) {
    final result = Map<String, dynamic>.from(body);

    if (SecureAPIConfig.isClaudeModel) {
      // Claude uses `max_tokens` instead of `max_completion_tokens`
      final maxCompletion = result.remove('max_completion_tokens');
      if (maxCompletion != null && result['max_tokens'] == null) {
        result['max_tokens'] = maxCompletion;
      }
      result.remove('max_output_tokens');
      // Claude supports temperature natively — no need to strip it
      return result;
    }

    // Strip unsupported params for OpenAI reasoning models
    if (SecureAPIConfig.isReasoningModel) {
      result.remove('max_tokens');
      result.remove('max_output_tokens');
      result.remove('temperature');
    }

    return result;
  }

  /// Converts an OpenAI-format request body to Anthropic Messages API format.
  /// This is called before sending requests when using Claude models.
  ///
  /// OpenAI format: {"messages": [{"role": "system", "content": "..."}, ...]}
  /// Anthropic format: {"system": "...", "messages": [{"role": "user", "content": "..."}]}
  static String convertToAnthropicPayload(Map<String, dynamic> openaiBody) {
    final messages = openaiBody['messages'] as List? ?? [];
    final systemPrompt = StringBuffer();
    final anthropicMessages = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg is! Map<String, dynamic>) continue;
      final role = msg['role'] as String? ?? 'user';
      final content = msg['content'];

      if (role == 'system') {
        // Anthropic uses a top-level `system` field
        if (content is String) {
          systemPrompt.write(content);
        } else if (content is List) {
          for (final item in content) {
            if (item is Map<String, dynamic>) {
              final text = item['text'] ?? '';
              if (text is String && text.isNotEmpty) {
                systemPrompt.writeln(text);
              }
            }
          }
        }
      } else {
        // user / assistant messages
        String textContent = '';
        if (content is String) {
          textContent = content;
        } else if (content is List) {
          for (final item in content) {
            if (item is Map<String, dynamic>) {
              final type = item['type'] as String? ?? '';
              final text = item['text'] ?? '';
              if ((type == 'text' || type == 'input_text' || type == 'output_text') &&
                  text is String) {
                textContent += text;
              }
            }
          }
        }
        anthropicMessages.add({'role': role, 'content': textContent});
      }
    }

    // If response_format is json_object, append JSON instruction to system prompt
    final responseFormat = openaiBody['response_format'];
    if (responseFormat is Map && responseFormat['type'] == 'json_object') {
      systemPrompt.writeln(
        '\n\nIMPORTANT: You MUST return only valid JSON matching the requested schema. '
        'Do not include any text outside the JSON object.',
      );
    }

    final payload = <String, dynamic>{
      'model': openaiBody['model'] ?? SecureAPIConfig.model,
      'max_tokens': openaiBody['max_tokens'] ?? openaiBody['max_completion_tokens'] ?? 1024,
      'messages': anthropicMessages,
    };

    if (systemPrompt.isNotEmpty) {
      payload['system'] = systemPrompt.toString().trim();
    }

    if (openaiBody['temperature'] != null) {
      payload['temperature'] = openaiBody['temperature'];
    }

    return jsonEncode(payload);
  }

  /// Converts an Anthropic Messages API response back to OpenAI Chat Completions
  /// format so the existing client parsing logic continues to work unchanged.
  static Map<String, dynamic> convertFromAnthropicResponse(
      Map<String, dynamic> anthropicData) {
    final content = anthropicData['content'] as List? ?? [];
    final textContent = content
        .whereType<Map<String, dynamic>>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String? ?? '')
        .join('');

    return {
      'id': anthropicData['id'] ?? 'chatcmpl-claude-${DateTime.now().millisecondsSinceEpoch}',
      'object': 'chat.completion',
      'model': anthropicData['model'] ?? SecureAPIConfig.model,
      'choices': [
        {
          'index': 0,
          'message': {
            'role': 'assistant',
            'content': textContent,
          },
          'finish_reason': anthropicData['stop_reason'] == 'end_turn'
              ? 'stop'
              : (anthropicData['stop_reason'] ?? 'stop'),
        }
      ],
      'usage': {
        'prompt_tokens': (anthropicData['usage'] as Map?)?['input_tokens'] ?? 0,
        'completion_tokens': (anthropicData['usage'] as Map?)?['output_tokens'] ?? 0,
        'total_tokens':
            ((anthropicData['usage'] as Map?)?['input_tokens'] as int? ?? 0) +
                ((anthropicData['usage'] as Map?)?['output_tokens'] as int? ?? 0),
      }
    };
  }

  /// Sends an AI request using the appropriate format for the current model.
  /// For Claude models, this converts the request to Anthropic format and
  /// the response back to OpenAI format transparently.
  static Future<http.Response> sendRequest({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    Duration? timeout,
  }) async {
    if (SecureAPIConfig.isClaudeModel) {
      // Use Anthropic-specific headers and payload format
      final claudeHeaders = buildHeaders();
      final claudePayload = convertToAnthropicPayload(wrapBody(body));
      final claudeUri = chatUri(); // Always use Messages API endpoint

      final response = await http
          .post(claudeUri, headers: claudeHeaders, body: claudePayload)
          .timeout(timeout ?? const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Convert Anthropic response to OpenAI format for seamless parsing
        try {
          final anthropicData = jsonDecode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>;
          final openaiCompatData = convertFromAnthropicResponse(anthropicData);
          return http.Response(
            jsonEncode(openaiCompatData),
            response.statusCode,
            headers: response.headers,
            reasonPhrase: response.reasonPhrase,
          );
        } catch (e) {
          debugPrint('Failed to convert Anthropic response: $e');
          // Return original response if conversion fails
          return response;
        }
      }
      return response;
    } else {
      // OpenAI format — send as-is through the proxy
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(wrapBody(body)))
          .timeout(timeout ?? const Duration(seconds: 10));
      return response;
    }
  }

  /// Helpful diagnostic used by UI to provide actionable error messages
  static String? configurationWarning() {
    if (!kIsWeb) return null;
    if (SecureAPIConfig.isClaudeModel) {
      // Claude uses direct API access with CORS header — no proxy needed
      return null;
    }
    if (_isProxyEndpoint) return null; // ok, using proxy
    return 'AI proxy endpoint not configured. Using direct endpoint may fail due to CORS.';
  }
}

class OpenAiNotConfiguredException implements Exception {
  const OpenAiNotConfiguredException();

  @override
  String toString() =>
      'AI API key is not configured. Please add a valid key to enable suggestions.';
}

/// Lightweight autocomplete service backed by AI.
class OpenAiAutocompleteService {
  OpenAiAutocompleteService._internal({http.Client? client})
      : _client = client ?? http.Client();

  static final OpenAiAutocompleteService instance =
      OpenAiAutocompleteService._internal();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 8);
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

    final payload = {
      'model': OpenAiConfig.model,
      'temperature': _temperature,
      'max_tokens': 300,
      'messages': [
        {
          'role': 'system',
          'content':
              'You help business analysts finish their writing. Provide up to $maxSuggestions polished continuation suggestions that extend the user\'s draft. Do not repeat the existing text, do not number or bullet responses, and avoid placeholders.'
        },
        {
          'role': 'user',
          'content':
              'Field: $fieldName\nCurrent draft: """${_escape(currentText)}"""\nAdditional context: """${_escape(context)}"""\nReturn up to $maxSuggestions unique continuations, each on its own line.'
        }
      ],
    };

    try {
      final response = await OpenAiConfig.sendRequest(
        uri: OpenAiConfig.responsesUri(),
        headers: OpenAiConfig.buildHeaders(),
        body: payload,
        timeout: _timeout,
      );

      if (response.statusCode == 429) {
        throw Exception('AI rate limit reached. Please try again shortly.');
      }
      if (response.statusCode == 401) {
        throw Exception('AI rejected the API key. Please verify it.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'AI request failed (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final combined = _extractText(data).trim();
      final suggestions = combined
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .take(maxSuggestions)
          .toList();

      if (suggestions.isNotEmpty) return suggestions;

      return _fallbackSuggestions(currentText, maxSuggestions);
    } on TimeoutException {
      throw Exception('AI request timed out. Please retry in a moment.');
    } on FormatException catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  static String _extractText(Map<String, dynamic> payload) {
    final output = payload['output'];
    if (output is List) {
      final buffer = StringBuffer();
      for (final entry in output) {
        if (entry is Map<String, dynamic>) {
          final content = entry['content'];
          if (content is List) {
            for (final item in content) {
              if (item is Map<String, dynamic>) {
                final type = item['type'];
                final text = item['text'];
                if (text is String &&
                    (type == 'output_text' || type == 'text')) {
                  buffer.write(text);
                }
              } else if (item is String) {
                buffer.write(item);
              }
            }
          }
        } else if (entry is String) {
          buffer.write(entry);
        }
      }
      if (buffer.isNotEmpty) return buffer.toString().replaceAll('*', '');
    }

    final choices = payload['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String) return content.replaceAll('*', '');
          if (content is List) {
            return content
                .map((e) => e is Map<String, dynamic> ? (e['text'] ?? '') : (e ?? ''))
                .join()
                .replaceAll('*', '');
          }
        }
        final text = first['text'];
        if (text is String) return text.replaceAll('*', '');
      } else if (first is String) {
        return first.toString().replaceAll('*', '');
      }
    }

    return '';
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
      return DiagramModel(nodes: [DiagramNode(id: 'start', label: section)], edges: const []);
    }

    final prompt = _diagramPrompt(section: section, context: contextText, refinementHint: refinementHint);

    final payload = {
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''You are an expert strategic planning architect specializing in executive-level project visualization. Your diagrams are exceptional because they:
1. Show REASONING and LOGIC, not just process steps
2. Illustrate strategic thinking with decision criteria and branching paths
3. Highlight dependencies, risks, and validation checkpoints
4. Connect objectives to outcomes through clear cause-effect chains
5. Use specific, contextual labels derived from the actual project content

You create diagrams that executives and stakeholders can use to understand the "WHY" behind each step, not just the "WHAT". Every node and edge must serve a strategic purpose. Generic placeholders are never acceptable.

Always return ONLY a valid JSON object with nodes and edges arrays.'''
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };

    try {
      final response = await OpenAiConfig.sendRequest(
        uri: OpenAiConfig.chatUri(),
        headers: OpenAiConfig.buildHeaders(),
        body: payload,
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI diagram error ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return _parseDiagram(parsed);
    } catch (e) {
      debugPrint('AI diagram generation failed: $e');
      return _createFallbackDiagram(section);
    }
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
