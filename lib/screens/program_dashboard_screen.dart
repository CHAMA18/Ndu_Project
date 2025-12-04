import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/program_model.dart';
import '../routing/app_router.dart';
import '../services/navigation_context_service.dart';
import '../services/program_service.dart';
import '../services/project_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/kaz_ai_chat_bubble.dart';

class ProgramDashboardScreen extends StatelessWidget {
  const ProgramDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Record this dashboard so the logo knows where to return on tap
    NavigationContextService.instance.setLastClientDashboard(AppRoutes.programDashboard);
    final theme = Theme.of(context);
    const background = Color(0xFFF7F8FC);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          const _ProgramBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1180;
                final horizontalPadding = constraints.maxWidth < 600 ? 20.0 : 40.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgramHeader(theme: theme, isCompact: isCompact),
                      const SizedBox(height: 28),
                      if (user == null)
                        Container(
                          padding: const EdgeInsets.all(60),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 20),
                                Text(
                                  'Please sign in to view your programs',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        StreamBuilder<List<ProgramModel>>(
                          stream: ProgramService.streamPrograms(ownerId: user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(80),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(60),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Error loading programs',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        snapshot.error.toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final programs = snapshot.data ?? [];

                            if (programs.isEmpty) {
                              return _EmptyProgramsState(theme: theme);
                            }

                            return Column(
                              children: [
                                for (int i = 0; i < programs.length; i++) ...[
                                  _ProgramCard(program: programs[i], isCompact: isCompact),
                                  if (i < programs.length - 1) const SizedBox(height: 24),
                                ],
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader({required this.theme, required this.isCompact});

  final ThemeData theme;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: isCompact ? 16 : 20),
          child: Align(
            alignment: isCompact ? Alignment.center : Alignment.centerLeft,
            child: AppLogo(
              height: isCompact ? 72 : 104,
              semanticLabel: 'NDU Program Platform',
            ),
          ),
        ),
        if (!isCompact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                color: const Color(0xFF2C3E50),
                tooltip: 'Back',
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFFFE4B3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFCF6B).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Program workspace overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A5800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF2C3E50),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFFE4B3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF8A5800)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Program overview',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A5800),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 26),
        Text(
          'Program dashboard',
          style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101012),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Coordinate up to three related projects with shared outcomes. View all programs you have created from your projects.',
          style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                height: 1.55,
              ),
        ),
      ],
    );
  }
}

class _EmptyProgramsState extends StatelessWidget {
  const _EmptyProgramsState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.layers_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No programs yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Programs are created from the Project Dashboard by selecting exactly three projects and grouping them together.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.dashboard),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go to Project Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: const Color(0xFF101012),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                elevation: 8,
                shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.isCompact});

  final ProgramModel program;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final projectCount = program.projectIds.length;

    return _FrostedCard(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.layers, size: 28, color: Colors.purple.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            program.name,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF101012),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          icon: Icons.folder_copy_outlined,
                          label: '$projectCount of 3 projects',
                          background: const Color(0xFFE9F0FF),
                          foreground: const Color(0xFF1A4DB3),
                        ),
                        _StatusChip(
                          icon: Icons.check_circle_outline,
                          label: program.status,
                          background: const Color(0xFFEEF9F4),
                          foreground: const Color(0xFF167A4A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Program', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<ProjectRecord>>(
            stream: ProjectService.streamProjectsByIds(program.projectIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading project data. Please check your connection and try again.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final projects = snapshot.data ?? [];

              if (projects.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE4B3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF8A5800), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No projects found. The projects in this program may have been deleted or you may not have access to them.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8A5800),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6E7EE)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _TableLabel('Project')),
                          if (!isCompact) ...[
                            Expanded(flex: 2, child: _TableLabel('Stage')),
                            Expanded(flex: 2, child: _TableLabel('Owner')),
                          ],
                          SizedBox(width: 80, child: Center(child: _TableLabel('Actions'))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEAEAF2)),
                    for (int i = 0; i < projects.length; i++) ...[
                      _ProgramProjectRow(project: projects[i], isCompact: isCompact),
                      if (i < projects.length - 1)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEAEAF2)),
                    ],
                  ],
                ),
              );
            },
          ),
          if (projectCount < 3) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF8A5800), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This program has ${3 - projectCount} available ${(3 - projectCount) == 1 ? "slot" : "slots"}. Programs work best with exactly 3 related projects.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8A5800),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Delete Program?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${program.name}"?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'This will only delete the program grouping. Individual projects will remain intact.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ProgramService.deleteProgram(program.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting program: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _ProgramProjectRow extends StatelessWidget {
  const _ProgramProjectRow({required this.project, required this.isCompact});

  final ProjectRecord project;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = project.name.isNotEmpty ? project.name : 'Untitled Project';
    final statusLabel = project.status.isNotEmpty ? project.status : 'Initiation';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCompact) ...[
                  const SizedBox(height: 6),
                  _Pill(
                    label: statusLabel,
                    background: Colors.blue.shade50,
                    foreground: Colors.blue.shade700,
                  ),
                ],
              ],
            ),
          ),
          if (!isCompact) ...[
            Expanded(
              flex: 2,
              child: _Pill(
                label: statusLabel,
                background: Colors.blue.shade50,
                foreground: Colors.blue.shade700,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                project.ownerName.isNotEmpty ? project.ownerName : 'Unknown',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          SizedBox(
            width: 80,
            child: Center(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new),
                tooltip: 'View project',
                color: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableLabel extends StatelessWidget {
  const _TableLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF6A6C7A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _ProjectsInProgramCard extends StatelessWidget {
  const _ProjectsInProgramCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _FrostedCard(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects in this program',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review selection, prioritize work, and manage shared outcomes before rolling up to the portfolio.',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Up to 3 related projects'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F2FA),
                  foregroundColor: const Color(0xFF1A1B23),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6E7EE)),
            ),
            child: Column(
              children: const [
                _ProjectHeaderRow(),
                Divider(height: 1, thickness: 1, color: Color(0xFFEAEAF2)),
                _ProjectDataRow(
                  projectName: 'Terminal upgrade - Phase 1',
                  projectCode: 'PRJ-001 | Infrastructure',
                  stageLabel: 'Front-end planning',
                  stageColor: Color(0xFF0B7AE4),
                  priorityLabel: 'P1 - Primary driver',
                  priorityColor: Color(0xFFFFB02E),
                  owner: 'Alex Rivera',
                  statusLabel: 'Open',
                ),
                Divider(height: 1, thickness: 1, color: Color(0xFFEAEAF2)),
                _ProjectDataRow(
                  projectName: 'Control system upgrade',
                  projectCode: 'PRJ-002 | Operations',
                  stageLabel: 'Execution',
                  stageColor: Color(0xFF17A673),
                  priorityLabel: 'P2 - Dependent',
                  priorityColor: Color(0xFF5455FF),
                  owner: 'Morgan Lee',
                  statusLabel: 'Open',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'There is room for one more project in this program. Keep all three aligned under a single interface plan.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8A5800),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add another project'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9B6500),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramActionsCard extends StatelessWidget {
  const _ProgramActionsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _FrostedCard(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program-level actions',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which governance, risks, and costs apply to the entire program.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          Column(
            children: const [
              _ActionRow(
                title: 'Gate approvals',
                description: 'Use the same approval path for all projects in this program.',
                badgeLabel: 'Applies to all',
                isHighlighted: true,
              ),
              Divider(height: 1, color: Color(0xFFEAEAF2)),
              _ActionRow(
                title: 'Shared risk register',
                description: 'Surface program-level risks and mitigation once across all work.',
                badgeLabel: 'Applies to all',
              ),
              Divider(height: 1, color: Color(0xFFEAEAF2)),
              _ActionRow(
                title: 'Common change control',
                description: 'Route change requests through a single program board.',
                badgeLabel: 'Project specific',
                badgeColor: Color(0xFFECECF7),
                badgeForeground: Color(0xFF3D3FA5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF101012),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Apply selections'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterfaceManagementCard extends StatelessWidget {
  const _InterfaceManagementCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _FrostedCard(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interface management',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track dependencies and shared interfaces across all projects in this program.',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0C2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_outline, size: 18, color: Color(0xFF8A5800)),
                    SizedBox(width: 6),
                    Text(
                      'Interface Manager: Taylor Brooks',
                      style: TextStyle(
                        color: Color(0xFF8A5800),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: const [
              _InterfaceRow(
                title: 'Terminal access windows',
                appliesLabel: 'Applies to all projects',
                chips: ['Ops coordination', 'Customer impact'],
                riskLabel: 'Risk: Medium',
              ),
              Divider(height: 1, color: Color(0xFFEAEAF2)),
              _InterfaceRow(
                title: 'Control room cutover',
                appliesLabel: 'Applies to PRJ-001, PRJ-002',
                chips: ['Safety and SHE/R'],
                riskLabel: 'Risk: High',
                riskColor: Color(0xFFE53935),
              ),
              Divider(height: 1, color: Color(0xFFEAEAF2)),
              _InterfaceRow(
                title: 'Training and readiness',
                appliesLabel: 'Applies to PRJ-002',
                chips: ['People readiness'],
                riskLabel: 'Risk: Low',
                riskColor: Color(0xFF1EB980),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF101012),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Update interfaces for all'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolledUpEstimatesCard extends StatelessWidget {
  const _RolledUpEstimatesCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _FrostedCard(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rolled up estimates',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'See combined cost, schedule, and risk posture for the entire program.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 640;
              final metrics = const [
                _RollupMetric(
                  label: 'Total cost estimate',
                  value: r'$5.4M',
                  footnote: 'PRJ-001 + PRJ-002',
                ),
                _RollupMetric(
                  label: 'Schedule impact',
                  value: '18 months',
                  footnote: 'Critical path aligned',
                ),
                _RollupMetric(
                  label: 'Risk posture',
                  value: 'Medium',
                  footnote: '3 open high risks',
                ),
              ];

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101012),
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF101012), Color(0xFF1F1F23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                child: isStacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < metrics.length; i++) ...[
                            metrics[i],
                            if (i != metrics.length - 1)
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.12),
                                margin: const EdgeInsets.symmetric(vertical: 18),
                              ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: metrics[0]),
                          const _RollupDivider(),
                          Expanded(child: metrics[1]),
                          const _RollupDivider(),
                          Expanded(child: metrics[2]),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Once all three projects are confirmed, you can promote this view to a dedicated program dashboard and roll it up into a portfolio.',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE6E7EE)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Export program dashboard'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF101012),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    elevation: 8,
                    shadowColor: const Color(0xFFFFB300).withOpacity(0.4),
                  ),
                  child: const Text('Roll up to portfolio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectHeaderRow extends StatelessWidget {
  const _ProjectHeaderRow();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF6A6C7A),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Project', style: textStyle)),
          Expanded(flex: 2, child: Text('Stage', style: textStyle)),
          Expanded(flex: 2, child: Text('Priority', style: textStyle)),
          Expanded(flex: 2, child: Text('Owner', style: textStyle)),
          Expanded(flex: 2, child: Center(child: Text('Actions', style: textStyle))),
        ],
      ),
    );
  }
}

class _ProjectDataRow extends StatelessWidget {
  const _ProjectDataRow({
    required this.projectName,
    required this.projectCode,
    required this.stageLabel,
    required this.stageColor,
    required this.priorityLabel,
    required this.priorityColor,
    required this.owner,
    required this.statusLabel,
  });

  final String projectName;
  final String projectCode;
  final String stageLabel;
  final Color stageColor;
  final String priorityLabel;
  final Color priorityColor;
  final String owner;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1B23)),
                ),
                const SizedBox(height: 4),
                Text(
                  projectCode,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Pill(label: stageLabel, background: stageColor.withOpacity(0.14), foreground: stageColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Pill(label: priorityLabel, background: priorityColor.withOpacity(0.18), foreground: const Color(0xFF111111)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              owner,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1A1B23)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  statusLabel,
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1B23)),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'View project actions',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.description,
    required this.badgeLabel,
    this.badgeColor,
    this.badgeForeground,
    this.isHighlighted = false,
  });

  final String title;
  final String description;
  final String badgeLabel;
  final Color? badgeColor;
  final Color? badgeForeground;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: isHighlighted ? const Color(0xFFFFF7E8) : null,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1B23)),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _Pill(
            label: badgeLabel,
            background: badgeColor ?? const Color(0xFFFFF1DA),
            foreground: badgeForeground ?? const Color(0xFF8A5800),
          ),
        ],
      ),
    );
  }
}

class _InterfaceRow extends StatelessWidget {
  const _InterfaceRow({
    required this.title,
    required this.appliesLabel,
    required this.chips,
    required this.riskLabel,
    this.riskColor,
  });

  final String title;
  final String appliesLabel;
  final List<String> chips;
  final String riskLabel;
  final Color? riskColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1B23)),
                ),
                const SizedBox(height: 6),
                _Pill(
                  label: appliesLabel,
                  background: const Color(0xFFEFF3FF),
                  foreground: const Color(0xFF1A4DB3),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map(
                        (chip) => _Pill(
                          label: chip,
                          background: const Color(0xFFF4F5FB),
                          foreground: const Color(0xFF32334B),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Pill(
                label: riskLabel,
                background: (riskColor ?? const Color(0xFFFFE7D2)).withOpacity(0.28),
                foreground: riskColor ?? const Color(0xFF8A5800),
              ),
              const SizedBox(height: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
                tooltip: 'Interface actions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RollupMetric extends StatelessWidget {
  const _RollupMetric({
    required this.label,
    required this.value,
    required this.footnote,
  });

  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          footnote,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _RollupDivider extends StatelessWidget {
  const _RollupDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 82,
      margin: const EdgeInsets.symmetric(horizontal: 22),
      color: Colors.white.withOpacity(0.2),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: background.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
      ),
    );
  }
}

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFDFBFF)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 28, offset: const Offset(0, 18)),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _ProgramBackdrop extends StatelessWidget {
  const _ProgramBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFCF4), Color(0xFFF4F6FB)],
            ),
          ),
          child: Stack(
            children: const [
              Positioned(
                top: -140,
                right: -90,
                child: _BlurCircle(color: Color(0xFFFFE9C7), size: 360, blur: 180),
              ),
              Positioned(
                top: 240,
                left: -80,
                child: _BlurCircle(color: Color(0xFFE2EBFF), size: 280, blur: 150),
              ),
              Positioned(
                bottom: -120,
                right: -40,
                child: _BlurCircle(color: Color(0xFFDDF7E8), size: 220, blur: 130),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color, required this.size, required this.blur});

  final Color color;
  final double size;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.65),
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.55),
            blurRadius: blur,
            spreadRadius: -12,
          ),
        ],
      ),
    );
  }
}
