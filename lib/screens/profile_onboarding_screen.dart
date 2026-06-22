import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/profile_onboarding_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// First-time-user profile onboarding flow.
///
/// 7 steps, each skippable:
///   1. Welcome
///   2. Role
///   3. Experience level
///   4. Industry
///   5. Team size
///   6. Primary use case + project type + methodology (combined)
///   7. Review & finish
///
/// Answers are saved to Firestore incrementally (merge) so the user can
/// close the app mid-flow and resume. After finishing (or skipping), the
/// user is routed to the dashboard.
///
/// Visual style matches the existing app: dark navy background (#0f172a),
/// brand gold accents (#FFD700), rounded cards, Satoshi font.
class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key, this.returnTo = AppRoutes.dashboard});

  ///Route name to navigate to after the flow finishes. Defaults to the
  /// main project dashboard.
  final String returnTo;

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Incremental answers (saved to Firestore on each step advance).
  ProfileOnboardingAnswers _answers = const ProfileOnboardingAnswers();

  // Free-text controllers for industry + use case steps.
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _useCaseController = TextEditingController();

  bool _isSaving = false;

  static const int _pageCount = 7;

  @override
  void dispose() {
    _pageController.dispose();
    _industryController.dispose();
    _useCaseController.dispose();
    super.dispose();
  }

  // ---- Navigation -----------------------------------------------------------

  Future<void> _next() async {
    if (_currentPage < _pageCount - 1) {
      await _saveIncremental();
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _previous() async {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skipStep() async {
    // Advance without recording an answer for this step.
    if (_currentPage < _pageCount - 1) {
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _skipAll() async {
    // Mark the entire flow as skipped and exit.
    setState(() => _isSaving = true);
    try {
      await ProfileOnboardingService.markComplete(
        _answers.copyWith(skipped: true),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    context.go('/${widget.returnTo}');
  }

  Future<void> _saveIncremental() async {
    setState(() => _isSaving = true);
    try {
      // Pull current text-controller values into the answers object.
      _answers = _answers.copyWith(
        industry: _industryController.text.trim().isEmpty
            ? _answers.industry
            : _industryController.text.trim(),
        primaryUseCase: _useCaseController.text.trim().isEmpty
            ? _answers.primaryUseCase
            : _useCaseController.text.trim(),
      );
      await ProfileOnboardingService.save(_answers);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    try {
      _answers = _answers.copyWith(
        industry: _industryController.text.trim().isEmpty
            ? _answers.industry
            : _industryController.text.trim(),
        primaryUseCase: _useCaseController.text.trim().isEmpty
            ? _answers.primaryUseCase
            : _useCaseController.text.trim(),
        skipped: false,
      );
      await ProfileOnboardingService.markComplete(_answers);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    context.go('/${widget.returnTo}');
  }

  // ---- Helpers --------------------------------------------------------------

  void _setRole(UserRole role) =>
      setState(() => _answers = _answers.copyWith(role: role));

  void _setExperience(ExperienceLevel e) =>
      setState(() => _answers = _answers.copyWith(experience: e));

  void _setTeamSize(int size) =>
      setState(() => _answers = _answers.copyWith(teamSize: size));

  void _setProjectType(PrimaryProjectType t) =>
      setState(() => _answers = _answers.copyWith(projectType: t));

  void _setMethodology(PreferredMethodology m) =>
      setState(() => _answers = _answers.copyWith(methodology: m));

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: close (skip all) + progress
            _buildTopBar(),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildWelcomePage(),
                  _buildRolePage(theme),
                  _buildExperiencePage(theme),
                  _buildIndustryPage(theme),
                  _buildTeamSizePage(theme),
                  _buildProjectPrefsPage(theme),
                  _buildReviewPage(theme),
                ],
              ),
            ),
            // Bottom navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ---- Top bar --------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Skip-all (close)
          TextButton(
            onPressed: _isSaving ? null : _skipAll,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Skip all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const Spacer(),
          // Page counter
          Text(
            'Step ${_currentPage + 1} of $_pageCount',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Bottom nav -----------------------------------------------------------

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _pageCount,
            effect: WormEffect(
              dotColor: const Color(0xFF334155),
              activeDotColor: const Color(0xFFFFD700),
              dotHeight: 8,
              dotWidth: 8,
              spacing: 10,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Back
              if (_currentPage > 0)
                TextButton(
                  onPressed: _isSaving ? null : _previous,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Back'),
                )
              else
                const SizedBox(width: 16),
              const Spacer(),
              // Skip this step (only on middle steps, not welcome/finish)
              if (_currentPage > 0 && _currentPage < _pageCount - 1)
                TextButton(
                  onPressed: _isSaving ? null : _skipStep,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Skip this step',
                      style: TextStyle(fontSize: 13)),
                ),
              const SizedBox(width: 8),
              // Next / Finish
              ElevatedButton(
                onPressed: _isSaving ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF0F172A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF0F172A)),
                      )
                    : Text(
                        _currentPage == 0
                            ? 'Get started'
                            : (_currentPage == _pageCount - 1
                                ? 'Finish'
                                : 'Continue'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Reusable card --------------------------------------------------------

  Widget _sectionHeader(String eyebrow, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              )),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              )),
          const SizedBox(height: 10),
          Text(subtitle,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.5,
              )),
        ],
      ),
    );
  }

  Widget _optionCard<T>({
    required T value,
    required T? selected,
    required String title,
    required String subtitle,
    required ValueChanged<T> onTap,
  }) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withOpacity(0.08)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF475569),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollBody(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ---- Page 1: Welcome ------------------------------------------------------

  Widget _buildWelcomePage() {
    return _scrollBody([
      const SizedBox(height: 40),
      Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.rocket_launch,
              color: Color(0xFFFFD700), size: 44),
        ),
      ),
      const SizedBox(height: 32),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Welcome to NDU',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Navigate. Deliver. Upgrade.\n\nA few quick questions (about 2 minutes) '
          'will help us tailor your workspace — show the right templates, the right '
          'dashboards, and the right starting point for your first project.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ),
      const SizedBox(height: 40),
      _journeyPreview(),
      const SizedBox(height: 24),
    ]);
  }

  Widget _journeyPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What happens next',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 14),
            _journeyStep('1', 'Tell us about you',
                'Role, experience, industry, team size — 7 short steps.'),
            _journeyStep('2', 'Pick your project type',
                'Software, construction, hardware, services, or hybrid.'),
            _journeyStep('3', 'Create your first project',
                'Name it, choose a methodology, and we scaffold the WBS.'),
            _journeyStep('4', 'Open your dashboard',
                'Tailored to your role and project type.'),
          ],
        ),
      ),
    );
  }

  Widget _journeyStep(String n, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Page 2: Role ---------------------------------------------------------

  Widget _buildRolePage(ThemeData theme) {
    return _scrollBody([
      _sectionHeader('Step 1', 'What best describes your role?',
          'This shapes what dashboards and templates we surface first.'),
      ...UserRole.values.map(
        (r) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: _optionCard<UserRole>(
            value: r,
            selected: _answers.role,
            title: r.label,
            subtitle: r.description,
            onTap: _setRole,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ---- Page 3: Experience ---------------------------------------------------

  Widget _buildExperiencePage(ThemeData theme) {
    return _scrollBody([
      _sectionHeader('Step 2', 'How experienced are you?',
          'We adjust the level of guidance and the depth of default reporting.'),
      ...ExperienceLevel.values.map(
        (e) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: _optionCard<ExperienceLevel>(
            value: e,
            selected: _answers.experience,
            title: e.label,
            subtitle: e.description,
            onTap: _setExperience,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ---- Page 4: Industry -----------------------------------------------------

  Widget _buildIndustryPage(ThemeData theme) {
    const suggestions = [
      'Technology / SaaS',
      'Financial services',
      'Healthcare',
      'Construction & engineering',
      'Government / public sector',
      'Manufacturing',
      'Energy & utilities',
      'Telecommunications',
      'Education',
      'Non-profit',
      'Other',
    ];
    return _scrollBody([
      _sectionHeader('Step 3', 'What industry do you work in?',
          'Type your own, or pick a common one. Used for benchmarking and template matching.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _industryController,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Technology / SaaS',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text('Suggestions',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            )),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return ActionChip(
              label: Text(s,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              backgroundColor: const Color(0xFF1E293B),
              side: const BorderSide(color: Color(0xFF334155)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onPressed: () => _industryController.text = s,
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  // ---- Page 5: Team size ----------------------------------------------------

  Widget _buildTeamSizePage(ThemeData theme) {
    const bands = [
      (1, 'Just me', 'Solo founder, contractor, or individual contributor.'),
      (5, '2–5 people', 'Small team, startup, or focused delivery squad.'),
      (15, '6–15 people', 'Cross-functional team or small department.'),
      (50, '16–50 people', 'Multiple teams, mid-size program.'),
      (200, '51–200 people', 'Department or large program.'),
      (500, '200+ people', 'Enterprise / organisation-wide delivery.'),
    ];
    return _scrollBody([
      _sectionHeader('Step 4', 'How big is your team or organisation?',
          'We right-size the collaboration, governance, and reporting defaults.'),
      ...bands.map(
        (b) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: _optionCard<int>(
            value: b.$1,
            selected: _answers.teamSize,
            title: b.$2,
            subtitle: b.$3,
            onTap: _setTeamSize,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ---- Page 6: Project preferences (combined) -------------------------------

  Widget _buildProjectPrefsPage(ThemeData theme) {
    return _scrollBody([
      _sectionHeader('Step 5', 'What are you here to deliver?',
          'Three quick picks so we scaffold your first project correctly.'),
      // Use case free-text
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
        child: Text('Primary use case',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _useCaseController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          decoration: InputDecoration(
            hintText:
                'e.g. Deliver a software platform on time and on budget; track procurement; manage a construction program...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
      const SizedBox(height: 24),
      // Project type
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
        child: Text('Project type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
      ),
      ...PrimaryProjectType.values.map(
        (t) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: _optionCard<PrimaryProjectType>(
            value: t,
            selected: _answers.projectType,
            title: t.label,
            subtitle: t.description,
            onTap: _setProjectType,
          ),
        ),
      ),
      const SizedBox(height: 20),
      // Methodology
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
        child: Text('Preferred methodology',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
      ),
      ...PreferredMethodology.values.map(
        (m) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: _optionCard<PreferredMethodology>(
            value: m,
            selected: _answers.methodology,
            title: m.label,
            subtitle: m.description,
            onTap: _setMethodology,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ---- Page 7: Review -------------------------------------------------------

  Widget _buildReviewPage(ThemeData theme) {
    return _scrollBody([
      _sectionHeader('Final step', 'Review your answers',
          'You can change any of these later in Settings. Tap Finish to open your tailored dashboard.'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              _reviewRow('Role', _answers.role?.label),
              _reviewRow('Experience', _answers.experience?.label),
              _reviewRow('Industry',
                  _industryController.text.trim().isNotEmpty
                      ? _industryController.text.trim()
                      : _answers.industry),
              _reviewRow(
                  'Team size',
                  _answers.teamSize == null
                      ? null
                      : _teamSizeLabel(_answers.teamSize!)),
              _reviewRow(
                  'Primary use case',
                  _useCaseController.text.trim().isNotEmpty
                      ? _useCaseController.text.trim()
                      : _answers.primaryUseCase),
              _reviewRow('Project type', _answers.projectType?.label),
              _reviewRow('Methodology', _answers.methodology?.label),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'After you finish, you\'ll land on your project dashboard. '
          'From there you can create your first project and we\'ll scaffold '
          'a WBS, cost framework, and reporting tailored to your answers.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }

  String _teamSizeLabel(int v) {
    if (v == 1) return 'Just me';
    if (v == 5) return '2–5 people';
    if (v == 15) return '6–15 people';
    if (v == 50) return '16–50 people';
    if (v == 200) return '51–200 people';
    return '200+ people';
  }

  Widget _reviewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                )),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value == null || value.isEmpty
                  ? '— skipped —'
                  : (value.length > 80 ? '${value.substring(0, 80)}…' : value),
              style: TextStyle(
                color: value == null || value.isEmpty
                    ? Colors.white24
                    : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
