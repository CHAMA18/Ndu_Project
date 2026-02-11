import 'package:ndu_project/models/project_activity.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Central orchestration utility that builds a unified, cross-phase
/// activity log from structured project data.
class ProjectIntelligenceService {
  static const List<String> _estimateSections = <String>[
    'cost_analysis',
    'cost_estimate',
    'project_charter',
  ];

  static const List<String> _scheduleSections = <String>[
    'schedule',
    'project_charter',
  ];

  static const List<String> _trainingSections = <String>[
    'team_training',
    'project_charter',
  ];

  static ProjectDataModel rebuildActivityLog(ProjectDataModel data) {
    final now = DateTime.now();
    final existingById = <String, ProjectActivity>{
      for (final activity in data.projectActivities) activity.id: activity,
    };
    final nextById = <String, ProjectActivity>{};

    void upsert(ProjectActivity draft) {
      final existing = existingById[draft.id];
      nextById[draft.id] = _mergeLifecycle(draft, existing);
    }

    for (final item in data.frontEndPlanning.opportunityItems) {
      final title = item.opportunity.trim();
      if (title.isEmpty) continue;

      final details = <String>[];
      if (item.potentialCostSavings.trim().isNotEmpty) {
        details
            .add('Potential cost savings: ${item.potentialCostSavings.trim()}');
      }
      if (item.potentialScheduleSavings.trim().isNotEmpty) {
        details.add(
            'Potential schedule savings: ${item.potentialScheduleSavings.trim()}');
      }
      final description = details.isEmpty
          ? 'Opportunity identified in Front End Planning.'
          : details.join(' | ');

      upsert(
        ProjectActivity(
          id: 'activity_opp_${item.id}',
          title: title,
          description: description,
          sourceSection: 'fep_opportunities',
          phase: _phaseForSection('fep_opportunities'),
          discipline: _fallback(item.discipline, 'Planning'),
          role: _fallback(item.stakeholder, 'Project Manager'),
          assignedTo: _nullable(item.assignedTo),
          applicableSections:
              _resolveApplicableSections(item.appliesTo, 'fep_opportunities'),
          dueDate: '',
          status: ProjectActivityStatus.pending,
          approvalStatus: ProjectApprovalStatus.draft,
          createdAt: existingById['activity_opp_${item.id}']?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    for (final item in data.frontEndPlanning.allowanceItems) {
      final title = item.name.trim().isNotEmpty
          ? item.name.trim()
          : 'Allowance ${item.number.toString()}';
      if (title.trim().isEmpty) continue;

      final details = <String>[
        if (item.type.trim().isNotEmpty) 'Type: ${item.type.trim()}',
        if (item.amount > 0) 'Value: ${item.amount.toStringAsFixed(2)}',
        if (item.notes.trim().isNotEmpty) item.notes.trim(),
      ];
      final description = details.isEmpty
          ? 'Allowance identified in Front End Planning.'
          : details.join(' | ');

      upsert(
        ProjectActivity(
          id: 'activity_allow_${item.id}',
          title: title,
          description: description,
          sourceSection: 'fep_allowance',
          phase: _phaseForSection('fep_allowance'),
          discipline: _fallback(item.type, 'Finance'),
          role: 'Cost Engineer',
          assignedTo: _nullable(item.assignedTo),
          applicableSections:
              _resolveApplicableSections(item.appliesTo, 'fep_allowance'),
          dueDate: '',
          status: ProjectActivityStatus.pending,
          approvalStatus: ProjectApprovalStatus.draft,
          createdAt:
              existingById['activity_allow_${item.id}']?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    for (var i = 0; i < data.frontEndPlanning.requirementItems.length; i++) {
      final item = data.frontEndPlanning.requirementItems[i];
      final title = item.description.trim();
      if (title.isEmpty) continue;

      upsert(
        ProjectActivity(
          id: 'activity_req_$i',
          title: title,
          description: _fallback(item.comments, 'Requirement identified.'),
          sourceSection: 'fep_requirements',
          phase: _phaseForSection('fep_requirements'),
          discipline: _fallback(item.requirementType, 'Engineering'),
          role: 'Requirements Owner',
          assignedTo: null,
          applicableSections: const <String>[
            'project_charter',
            'project_framework',
            'requirements_implementation',
          ],
          dueDate: '',
          status: ProjectActivityStatus.pending,
          approvalStatus: ProjectApprovalStatus.draft,
          createdAt: existingById['activity_req_$i']?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    for (var i = 0; i < data.frontEndPlanning.riskRegisterItems.length; i++) {
      final item = data.frontEndPlanning.riskRegisterItems[i];
      final title = item.riskName.trim();
      if (title.isEmpty) continue;

      final details = <String>[
        if (item.impactLevel.trim().isNotEmpty) 'Impact: ${item.impactLevel}',
        if (item.likelihood.trim().isNotEmpty) 'Likelihood: ${item.likelihood}',
        if (item.mitigationStrategy.trim().isNotEmpty)
          'Mitigation: ${item.mitigationStrategy}',
      ];

      upsert(
        ProjectActivity(
          id: 'activity_risk_$i',
          title: title,
          description: details.join(' | '),
          sourceSection: 'fep_risks',
          phase: _phaseForSection('fep_risks'),
          discipline: 'Risk Management',
          role: 'Risk Owner',
          assignedTo: null,
          applicableSections: const <String>[
            'project_charter',
            'risk_assessment',
            'schedule',
          ],
          dueDate: '',
          status: ProjectActivityStatus.pending,
          approvalStatus: ProjectApprovalStatus.draft,
          createdAt: existingById['activity_risk_$i']?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    _upsertDashboardItems(
      items: data.withinScopeItems,
      prefix: 'scope_in',
      sourceSection: 'fep_summary_within_scope',
      discipline: 'Planning',
      role: 'Project Manager',
      applicableSections: const <String>[
        'project_charter',
        'project_framework',
        'work_breakdown_structure',
      ],
      now: now,
      existingById: existingById,
      upsert: upsert,
    );

    _upsertDashboardItems(
      items: data.outOfScopeItems,
      prefix: 'scope_out',
      sourceSection: 'fep_summary_out_of_scope',
      discipline: 'Planning',
      role: 'Project Manager',
      applicableSections: const <String>[
        'project_charter',
        'scope_tracking_plan',
      ],
      now: now,
      existingById: existingById,
      upsert: upsert,
    );

    _upsertDashboardItems(
      items: data.assumptionItems,
      prefix: 'assumption',
      sourceSection: 'fep_summary_assumptions',
      discipline: 'Planning',
      role: 'Project Manager',
      applicableSections: const <String>[
        'project_charter',
        'risk_assessment',
        'project_plan',
      ],
      now: now,
      existingById: existingById,
      upsert: upsert,
    );

    _upsertDashboardItems(
      items: data.constraintItems,
      prefix: 'constraint',
      sourceSection: 'fep_summary_constraints',
      discipline: 'Planning',
      role: 'Project Manager',
      applicableSections: const <String>[
        'project_charter',
        'risk_assessment',
        'cost_estimate',
      ],
      now: now,
      existingById: existingById,
      upsert: upsert,
    );

    final activities = nextById.values.toList()
      ..sort((a, b) {
        final sourceOrder = a.sourceSection.compareTo(b.sourceSection);
        if (sourceOrder != 0) return sourceOrder;
        return a.title.compareTo(b.title);
      });

    return data.copyWith(projectActivities: activities);
  }

  static String buildContextScan(ProjectDataModel data,
      {String? sectionLabel}) {
    final buffer = StringBuffer();
    final activities = data.projectActivities;

    void writeField(String label, String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      buffer.writeln('$label: $text');
    }

    buffer.writeln('Project Context Scan');
    buffer.writeln('====================');
    writeField('Project Name', data.projectName);
    writeField('Solution Title', data.solutionTitle);
    writeField('Business Case', data.businessCase);
    writeField('Project Objective', data.projectObjective);
    writeField('Charter Assumptions', data.charterAssumptions);
    writeField('Charter Constraints', data.charterConstraints);

    if (data.withinScopeItems.isNotEmpty) {
      buffer.writeln('Within Scope:');
      for (final item in data.withinScopeItems) {
        final text = item.description.trim();
        if (text.isNotEmpty) buffer.writeln('- $text');
      }
    }

    if (data.frontEndPlanning.requirementItems.isNotEmpty) {
      buffer.writeln('Requirements:');
      for (final item in data.frontEndPlanning.requirementItems) {
        final text = item.description.trim();
        if (text.isNotEmpty) buffer.writeln('- $text');
      }
    }

    if (data.frontEndPlanning.riskRegisterItems.isNotEmpty) {
      buffer.writeln('Risks:');
      for (final item in data.frontEndPlanning.riskRegisterItems) {
        final text = item.riskName.trim();
        if (text.isNotEmpty) buffer.writeln('- $text');
      }
    }

    if (activities.isNotEmpty) {
      final pending =
          activities.where((a) => a.status == ProjectActivityStatus.pending);
      final implemented = activities
          .where((a) => a.status == ProjectActivityStatus.implemented);
      buffer.writeln(
          'Activity Summary: total=${activities.length}, pending=${pending.length}, implemented=${implemented.length}');
    }

    if ((sectionLabel ?? '').trim().isNotEmpty) {
      writeField('Target Section', sectionLabel!);
    }

    return buffer.toString().trim();
  }

  static void _upsertDashboardItems({
    required List<PlanningDashboardItem> items,
    required String prefix,
    required String sourceSection,
    required String discipline,
    required String role,
    required List<String> applicableSections,
    required DateTime now,
    required Map<String, ProjectActivity> existingById,
    required void Function(ProjectActivity draft) upsert,
  }) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final title = item.description.trim();
      if (title.isEmpty) continue;
      final id = 'activity_${prefix}_$i';

      upsert(
        ProjectActivity(
          id: id,
          title: title,
          description: title,
          sourceSection: sourceSection,
          phase: _phaseForSection(sourceSection),
          discipline: discipline,
          role: role,
          assignedTo: null,
          applicableSections: applicableSections,
          dueDate: '',
          status: ProjectActivityStatus.pending,
          approvalStatus: ProjectApprovalStatus.draft,
          createdAt: existingById[id]?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
  }

  static ProjectActivity _mergeLifecycle(
      ProjectActivity draft, ProjectActivity? existing) {
    if (existing == null) return draft;
    final preservedAssignedTo = draft.assignedTo ?? existing.assignedTo;
    final preservedDueDate =
        draft.dueDate.trim().isEmpty ? existing.dueDate : draft.dueDate;

    return draft.copyWith(
      assignedTo: preservedAssignedTo,
      dueDate: preservedDueDate,
      status: existing.status,
      approvalStatus: existing.approvalStatus,
      createdAt: existing.createdAt,
    );
  }

  static List<String> _resolveApplicableSections(
      List<String> tags, String sourceSection) {
    final sections = <String>{sourceSection, 'project_charter'};
    for (final tag in tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized == 'estimate') {
        sections.addAll(_estimateSections);
      } else if (normalized == 'schedule') {
        sections.addAll(_scheduleSections);
      } else if (normalized == 'training') {
        sections.addAll(_trainingSections);
      } else if (normalized == 'project wide' || normalized == 'projectwide') {
        sections.addAll(const <String>['project_plan', 'execution_plan']);
      }
    }
    final result = sections.toList()..sort();
    return result;
  }

  static String _phaseForSection(String sourceSection) {
    if (sourceSection.startsWith('fep_')) return 'Front End Planning';
    if (sourceSection.startsWith('design_')) return 'Design Phase';
    if (sourceSection.contains('execution')) return 'Execution Phase';
    if (sourceSection.contains('launch')) return 'Launch Phase';
    if (sourceSection.contains('project_')) return 'Planning Phase';
    return 'Initiation Phase';
  }

  static String _fallback(String? value, String fallback) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullable(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
