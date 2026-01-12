import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/front_end_planning_navigation.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

import 'package:ndu_project/screens/project_charter_sections.dart';
import 'package:ndu_project/screens/charter_governance_section.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';

class ProjectCharterScreen extends StatefulWidget {
  const ProjectCharterScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProjectCharterScreen(),
      ),
    );
  }

  @override
  State<ProjectCharterScreen> createState() => _ProjectCharterScreenState();
}

class _ProjectCharterScreenState extends State<ProjectCharterScreen> {
  ProjectDataModel? _projectData;
  bool _isGenerating = false;
  late final OpenAiServiceSecure _openAi;
  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.read(context);
      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });

        // Auto-generate charter content if needed
        if (_projectData != null) {
          await _ensureCharterContent();
        }
      }
    });
  }

  
  Future<void> _exportPdf() async {
      final projectData = ProjectDataHelper.getData(context);
      final fep = projectData.frontEndPlanning;
      await PdfExportHelper.exportScreenPdf(
        context: context,
        screenTitle: 'Project Charter',
        sections: [
          PdfSection.keyValue('Project Info', [
            {'Project Name': projectData.projectName ?? 'N/A'},
          ]),
          PdfSection.text('Notes', fep.requirementsNotes ?? 'No data recorded.'),
        ],
      );
  }
@override
  void dispose() {
    super.dispose();
  }

  Future<void> _regenerateAllCharter() async {
    if (_projectData == null) return;
    final provider = ProjectDataInherited.read(context);
    provider.updateField((data) {
      return data.copyWith(
        businessCase: '',
        projectGoals: [],
        charterAssumptions: '',
        charterConstraints: '',
      );
    });
    setState(() {
      _projectData = provider.projectData;
    });
    await _ensureCharterContent();
  }

  Future<void> _ensureCharterContent() async {
    if (_projectData == null || _isGenerating) return;

    final needsOverview = _projectData!.businessCase.trim().isEmpty &&
        _projectData!.solutionDescription.trim().isEmpty;
    final needsAssumptions = _projectData!.charterAssumptions.trim().isEmpty;
    final needsConstraints = _projectData!.charterConstraints.trim().isEmpty;

    if (!needsOverview && !needsAssumptions && !needsConstraints) {
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final projectContext = ProjectDataHelper.buildFepContext(_projectData!);

      if (projectContext.trim().isNotEmpty) {
        if (needsOverview) {
          try {
            final overview = await _openAi.generateFepSectionText(
              section: 'Project Overview',
              context: projectContext,
              maxTokens: 600,
            );

            if (mounted && overview.isNotEmpty && _projectData != null) {
              final provider = ProjectDataInherited.read(context);
              provider.updateField((data) {
                if (data.businessCase.trim().isEmpty) {
                  return data.copyWith(businessCase: overview);
                }
                return data;
              });

              setState(() {
                _projectData = provider.projectData;
              });
            }
          } catch (e) {
            debugPrint('Error generating charter overview: $e');
          }
        }

        if (needsAssumptions || needsConstraints) {
          if (!mounted) return;
          final provider = ProjectDataInherited.read(context);
          if (needsAssumptions) {
            try {
              final assumptions = await _openAi.generateFepSectionText(
                section: 'Assumptions',
                context: projectContext,
                maxTokens: 320,
              );
              if (mounted && assumptions.trim().isNotEmpty) {
                provider.updateField((data) =>
                    data.copyWith(charterAssumptions: assumptions.trim()));
              }
            } catch (e) {
              debugPrint('Error generating charter assumptions: $e');
            }
          }
          if (needsConstraints) {
            try {
              final constraints = await _openAi.generateFepSectionText(
                section: 'Constraints',
                context: projectContext,
                maxTokens: 320,
              );
              if (mounted && constraints.trim().isNotEmpty) {
                provider.updateField((data) =>
                    data.copyWith(charterConstraints: constraints.trim()));
              }
            } catch (e) {
              debugPrint('Error generating charter constraints: $e');
            }
          }
          if (mounted) {
            setState(() {
              _projectData = provider.projectData;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error ensuring charter content: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateSection(String sectionType) async {
    if (_projectData == null || _isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final contextText = ProjectDataHelper.buildFepContext(_projectData!);
      final provider = ProjectDataInherited.read(context);

      if (sectionType == 'definition') {
        final overview = await _openAi.generateFepSectionText(
          section: 'Project Overview and Business Case',
          context: contextText,
          maxTokens: 800,
        );
        if (mounted && overview.isNotEmpty) {
          provider.updateField((data) => data.copyWith(
                businessCase: overview,
              ));
        }
      } else if (sectionType == 'scope') {
        final scope = await _openAi.generateProjectScope(
          context: contextText,
        );
        if (mounted) {
          final inScope = List<String>.from(scope['in'] ?? []);
          final outScope = List<String>.from(scope['out'] ?? []);
          if (inScope.isNotEmpty || outScope.isNotEmpty) {
            provider.updateField((data) => data.copyWith(
                  withinScope: inScope,
                  outOfScope: outScope,
                ));
          }
        }
      } else if (sectionType == 'risks') {
        final result = await _openAi.generateDetailedRisks(
          context: contextText,
        );
        if (mounted) {
          final newRisks = List<RiskRegisterItem>.from(result['risks'] ?? []);
          final newConstraints = List<String>.from(result['constraints'] ?? []);

          provider.updateField((data) {
            final fep = data.frontEndPlanning;
            final updatedFep = fep.copyWith(riskRegisterItems: newRisks);
            return data.copyWith(
              frontEndPlanning: updatedFep,
              constraints: newConstraints,
            );
          });
        }
      } else if (sectionType == 'tech') {
        final result = await _openAi.generateTechnicalRequirements(
          context: contextText,
        );
        if (mounted) {
          final it = result['it'] as ITConsiderationsData?;
          final infra = result['infra'] as InfrastructureConsiderationsData?;
          if (it != null || infra != null) {
            provider.updateField((data) => data.copyWith(
                  itConsiderationsData: it ?? data.itConsiderationsData,
                  infrastructureConsiderationsData:
                      infra ?? data.infrastructureConsiderationsData,
                ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _projectData = provider.projectData;
        });
      }
    } catch (e) {
      debugPrint('Error generating $sectionType: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate $sectionType: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppBreakpoints.pagePadding(context);
    final isMobile = AppBreakpoints.isMobile(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Project Charter',
      appBarTitle: 'Project Charter',
      backgroundColor: Colors.white,
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating project charter...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: pagePadding,
                    right: pagePadding,
                    top: pagePadding + (isMobile ? 16 : 24),
                    bottom: 120, // Space for floating approval bar
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FrontEndPlanningHeader(title: 'Project Charter', onExportPdf: _exportPdf),
                          const SizedBox(height: 16),

                          // ─── 1. Hero Header ───
                          CharterHeroHeader(
                            data: _projectData,
                            onRegenerateAll: () async {
                              final confirmed =
                                  await showRegenerateAllConfirmation(context);
                              if (confirmed && mounted) {
                                await _regenerateAllCharter();
                              }
                            },
                            isLoading: _isGenerating,
                          ),
                          const SizedBox(height: 24),

                          // ─── 2. Dashboard Stats Grid ───
                          CharterDashboardStats(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 3. Meta Info Horizontal Scroll ───
                          CharterMetaInfoScroll(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 4. Project Definition Bento (2-col grid) ───
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 768;
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CharterProjectDefinition(
                                            data: _projectData,
                                            onGenerate: () =>
                                                _generateSection('definition'),
                                          ),
                                          const SizedBox(height: 12),
                                          CharterSuccessCriteria(
                                              data: _projectData),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Right column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CharterFinancialOverview(
                                              data: _projectData),
                                          const SizedBox(height: 12),
                                          CharterScope(
                                            data: _projectData,
                                            onGenerate: () =>
                                                _generateSection('scope'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              // Mobile: single column
                              return Column(
                                children: [
                                  CharterProjectDefinition(
                                    data: _projectData,
                                    onGenerate: () =>
                                        _generateSection('definition'),
                                  ),
                                  const SizedBox(height: 12),
                                  CharterFinancialOverview(data: _projectData),
                                  const SizedBox(height: 12),
                                  CharterSuccessCriteria(data: _projectData),
                                  const SizedBox(height: 12),
                                  CharterScope(
                                    data: _projectData,
                                    onGenerate: () =>
                                        _generateSection('scope'),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ─── 5. Key Risks Section ───
                          CharterRisks(
                            data: _projectData,
                            onGenerate: () => _generateSection('risks'),
                          ),
                          const SizedBox(height: 24),

                          // ─── 6. Technical & Procurement Bento ───
                          CharterTechnicalProcurementBento(
                            data: _projectData,
                            onGenerate: () => _generateSection('tech'),
                          ),
                          const SizedBox(height: 24),

                          // ─── 7. Tentative Schedule Timeline ───
                          CharterScheduleTimeline(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 8. Governance Section ───
                          CharterGovernanceSection(data: _projectData),
                          const SizedBox(height: 24),

                          // ─── 9. Assumptions (Collapsible) ───
                          CharterAssumptions(data: _projectData),
                          const SizedBox(height: 32),

                          // ─── 10. Launch Phase Navigation ───
                          LaunchPhaseNavigation(
                            backLabel: 'Back',
                            nextLabel: 'Next',
                            onBack: () => FrontEndPlanningNavigation.goToPrevious(
                              context,
                              'project_charter',
                            ),
                            onNext: () => ProjectFrameworkScreen.open(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Floating Approval Action Bar ───
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CharterFloatingApprovalBar(data: _projectData),
                ),
              ],
            ),
    );
  }
}
<<<<<<< HEAD
=======

class _CardRow extends StatelessWidget {
  const _CardRow({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final cards = _extractCardData(projectData);

    if (isMobile) {
      return Column(
        children: [
          for (final data in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _InfoCard(data: data),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 18),
              child: _InfoCard(data: cards[i]),
            ),
          ),
      ],
    );
  }

  static List<_CardData> _extractCardData(ProjectDataModel? data) {
    if (data == null) {
      return const [
        _CardData(title: 'Assumptions', bullets: ['Complete business case to populate']),
        _CardData(title: 'Constraints', bullets: ['Complete business case to populate']),
        _CardData(title: 'Risks', bullets: ['Complete business case to populate']),
      ];
    }

    // Extract assumptions (from cost analysis or notes)
    final assumptions = <String>[];
    if (data.costAnalysisData != null) {
      for (final solution in data.costAnalysisData!.solutionCosts) {
        for (final row in solution.costRows) {
          if (row.assumptions.isNotEmpty) {
            assumptions.add(row.assumptions);
          }
        }
      }
    }
    if (assumptions.isEmpty) {
      assumptions.add('No specific assumptions documented');
    }

    // Extract constraints (from infrastructure, IT, or general notes)
    final constraints = <String>[];
    if (data.infrastructureConsiderationsData != null) {
      for (final infra in data.infrastructureConsiderationsData!.solutionInfrastructureData) {
        if (infra.majorInfrastructure.isNotEmpty) {
          constraints.add('Infrastructure: ${infra.majorInfrastructure}');
        }
      }
    }
    if (data.itConsiderationsData != null) {
      for (final it in data.itConsiderationsData!.solutionITData) {
        if (it.coreTechnology.isNotEmpty) {
          constraints.add('Technology: ${it.coreTechnology}');
        }
      }
    }
    if (constraints.isEmpty) {
      constraints.add('No specific constraints documented');
    }

    // Extract risks
    final risks = <String>[];
    if (data.preferredSolutionAnalysis != null) {
      for (final analysis in data.preferredSolutionAnalysis!.solutionAnalyses) {
        risks.addAll(analysis.risks.where((r) => r.isNotEmpty));
      }
    }
    for (final risk in data.solutionRisks) {
      risks.addAll(risk.risks.where((r) => r.isNotEmpty));
    }
    if (risks.isEmpty) {
      risks.add('No specific risks identified');
    }

    return [
      _CardData(title: 'Assumptions', bullets: assumptions.take(5).toList()),
      _CardData(title: 'Constraints', bullets: constraints.take(5).toList()),
      _CardData(title: 'Risks', bullets: risks.take(5).toList()),
    ];
  }
}

class _CardData {
  const _CardData({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppSemanticColors.subtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          _BulletList(items: data.bullets),
        ],
      ),
    );
  }
}

class _MilestoneGrid extends StatelessWidget {
  const _MilestoneGrid({required this.projectData});

  final ProjectDataModel? projectData;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final milestones = _extractMilestones(projectData);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final milestone in milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _MilestoneTile(milestone: milestone),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < milestones.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == milestones.length - 1 ? 0 : 18),
              child: _MilestoneTile(milestone: milestones[i]),
            ),
          ),
      ],
    );
  }

  static List<_MilestoneData> _extractMilestones(ProjectDataModel? data) {
    if (data == null) {
      return const [
        _MilestoneData(title: 'Milestone 1', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 2', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 3', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 4', description: 'Define milestones in the planning phase'),
      ];
    }

    final milestones = <_MilestoneData>[];
    
    // Extract from key milestones
    for (final milestone in data.keyMilestones) {
      if (milestone.name.isNotEmpty) {
        final description = [
          if (milestone.discipline.isNotEmpty) 'Discipline: ${milestone.discipline}',
          if (milestone.dueDate.isNotEmpty) 'Due: ${milestone.dueDate}',
          if (milestone.comments.isNotEmpty) milestone.comments,
        ].join(' • ');
        
        milestones.add(_MilestoneData(
          title: milestone.name,
          description: description.isNotEmpty ? description : 'No description available',
        ));
      }
    }
    
    // Extract from planning goals milestones
    for (final goal in data.planningGoals) {
      for (final milestone in goal.milestones) {
        if (milestone.title.isNotEmpty) {
          final description = milestone.deadline.isNotEmpty 
            ? 'Due: ${milestone.deadline}' 
            : 'No deadline specified';
          
          milestones.add(_MilestoneData(
            title: milestone.title,
            description: description,
          ));
        }
      }
    }
    
    if (milestones.isEmpty) {
      return const [
        _MilestoneData(title: 'Milestone 1', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 2', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 3', description: 'Define milestones in the planning phase'),
        _MilestoneData(title: 'Milestone 4', description: 'Define milestones in the planning phase'),
      ];
    }
    
    return milestones.take(8).toList();
  }
}

class _MilestoneData {
  const _MilestoneData({required this.title, required this.description});

  final String title;
  final String description;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final _MilestoneData milestone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          milestone.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          milestone.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _ChartSlice {
  const _ChartSlice({required this.color, required this.value, required this.label});

  final Color color;
  final double value;
  final String label;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.slices,
    required this.innerColor,
    required this.palette,
  });

  final List<_ChartSlice> slices;
  final Color innerColor;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    if (total == 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final strokeWidth = radius * 0.48;
    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.value / total) * math.pi * 2;
      // If slice color is transparent (placeholder), rotate through a pleasant palette
      paint.color = slice.color == Colors.transparent
          ? palette[i % palette.length]
          : slice.color;
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}
>>>>>>> 1ee471ae (Merge codebases)
