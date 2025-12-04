import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:ndu_project/services/api_config_secure.dart';
import 'package:ndu_project/firebase_options.dart';
// Use relative import to ensure the library is part of this compilation unit
import '../utils/diagram_model.dart';

// Dreamflow env bindings (must exist with these exact names)
// Do not rename: Dreamflow injects values via --dart-define at build time
const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

/// Central configuration for OpenAI access.
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
  /// calls to api.openai.com will be blocked by CORS. The UI will surface
  /// a clear error so the user can configure the proxy.
  static String get baseEndpoint {
    if (_trimmedEnvEndpoint.isNotEmpty) return _trimmedEnvEndpoint;
    // Fallback to project Cloud Function proxy if env not provided
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return 'https://us-central1-$projectId.cloudfunctions.net/openaiProxy';
  }

  /// Model used for light-weight autocomplete suggestions.
  static String get model => SecureAPIConfig.model;

  // Consider configured if using a proxy endpoint (no client API key needed)
  static bool get isConfigured => _isProxyEndpoint || apiKeyValue.isNotEmpty;

  /// Determine if we're using a proxy endpoint (Cloud Function, server, etc.)
  /// Proxies in this app expect requests to the BASE URL with NO extra path.
  static bool get _isProxyEndpoint {
    // Treat any non-openai.com endpoint as a proxy
    return !baseEndpoint.contains('openai.com');
  }

  /// Responses API endpoint. When using a proxy endpoint, do NOT append a path.
  static Uri responsesUri() {
    final base = baseEndpoint.endsWith('/')
        ? baseEndpoint.substring(0, baseEndpoint.length - 1)
        : baseEndpoint;
    if (_isProxyEndpoint) return Uri.parse(base);
    return Uri.parse('$base/responses');
  }

  /// Chat Completions endpoint. When using a proxy endpoint, do NOT append a path.
  static Uri chatUri() {
    final base = baseEndpoint.endsWith('/')
        ? baseEndpoint.substring(0, baseEndpoint.length - 1)
        : baseEndpoint;
    if (_isProxyEndpoint) return Uri.parse(base);
    return Uri.parse('$base/chat/completions');
  }

  /// Helpful diagnostic used by UI to provide actionable error messages
  static String? configurationWarning() {
    if (!kIsWeb) return null;
    if (_isProxyEndpoint) return null; // ok, using proxy
    // On web with direct OpenAI endpoint: likely to hit CORS
    return 'OpenAI proxy endpoint not configured. Using direct OpenAI endpoint may fail due to CORS. Set OPENAI_PROXY_ENDPOINT to your Cloud Function URL (do not append a path).';
  }
}

class OpenAiNotConfiguredException implements Exception {
  const OpenAiNotConfiguredException();

  @override
  String toString() =>
      'OpenAI API key is not configured. Please add a valid key to enable suggestions.';
}

/// Lightweight autocomplete service backed by OpenAI Responses API.
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
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final payload = {
      'model': OpenAiConfig.model,
      'temperature': _temperature,
      // Give the model more headroom for higher-quality continuations
      'max_output_tokens': 300,
      'input': [
        {
          'role': 'system',
          'content': [
            {
              'type': 'text',
              'text':
                  'You help business analysts finish their writing. Provide up to $maxSuggestions polished continuation suggestions that extend the user\'s draft. Do not repeat the existing text, do not number or bullet responses, and avoid placeholders.'
            }
          ]
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Field: $fieldName\nCurrent draft: """${_escape(currentText)}"""\nAdditional context: """${_escape(context)}"""\nReturn up to $maxSuggestions unique continuations, each on its own line.'
            }
          ]
        }
      ]
    };

    try {
      final warn = OpenAiConfig.configurationWarning();
      if (warn != null) {
        debugPrint('OpenAI configuration warning: ' + warn + ' (endpoint=' + OpenAiConfig.baseEndpoint + ')');
      }
      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      if (response.statusCode == 429) {
        throw Exception('OpenAI rate limit reached. Please try again shortly.');
      }
      if (response.statusCode == 401) {
        throw Exception('OpenAI rejected the API key. Please verify it.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'OpenAI request failed (${response.statusCode}): ${response.body}',
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
      throw Exception('OpenAI request timed out. Please retry in a moment.');
    } on FormatException catch (e) {
      throw Exception('Failed to parse OpenAI response: $e');
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
      if (buffer.isNotEmpty) return buffer.toString();
    }

    final choices = payload['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String) return content;
          if (content is List) {
            return content
                .map((e) => e is Map<String, dynamic> ? e['text'] ?? '' : e ?? '')
                .join();
          }
        }
        final text = first['text'];
        if (text is String) return text;
      } else if (first is String) {
        return first;
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

  static String _escape(String value) => value.replaceAll('"""', '"\"\"');
}

/// Diagram generation service. Returns a simple node/edge model suitable for lightweight rendering.
class OpenAiDiagramService {
  OpenAiDiagramService._internal();
  static final OpenAiDiagramService instance = OpenAiDiagramService._internal();

  Future<DiagramModel> generateDiagram({
    required String section,
    required String contextText,
    int maxTokens = 1200,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      // Fallback: single-node diagram using section name
      return DiagramModel(nodes: [DiagramNode(id: 'start', label: section)], edges: const []);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final prompt = _diagramPrompt(section: section, context: contextText);
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.4,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a delivery architect. Build a concise diagram model (nodes and edges) for the requested execution plan section. Always return ONLY a JSON object.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    });

    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('OpenAI diagram error ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return _parseDiagram(parsed);
    } catch (e) {
      // Fallback minimal diagram: section-centered
      return DiagramModel(
        nodes: const [
          DiagramNode(id: 'start', label: 'Start'),
          DiagramNode(id: 'section', label: 'Section'),
          DiagramNode(id: 'end', label: 'End'),
        ],
        edges: const [
          DiagramEdge(from: 'start', to: 'section', label: ''),
          DiagramEdge(from: 'section', to: 'end', label: ''),
        ],
      );
    }
  }

  String _diagramPrompt({required String section, required String context}) {
    final s = _sanitize(section);
    final c = _sanitize(context);
    return '''
Build a small, practical node-link diagram for the section "$s" of an Execution Plan, based on this context. The diagram should emphasize actionable planning flows (inputs -> activities -> outputs) and relevant systems/roles.

Return ONLY valid JSON with this exact structure:
{
  "nodes": [
    {"id": "start", "label": "...", "type": "start|process|decision|system|output|end"}
  ],
  "edges": [
    {"from": "start", "to": "next", "label": ""}
  ]
}

Guidelines:
- 5–12 nodes. Keep labels concise (<= 5 words) and non-generic.
- Use types to hint at shapes; we will render simply.
- Avoid placeholders. Only include nodes relevant to "$s".

Context:
"""
$c
"""
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
}

