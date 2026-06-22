import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/profile_onboarding_service.dart';

/// World-class profile onboarding modal.
///
/// Renders as a centered glassmorphic dialog with a dark blurred backdrop,
/// spring-based entrance animation, staggered content reveals, and
/// micro-interactions on every interactive element.
///
/// 7 steps, each skippable:
///   1. Welcome
///   2. Role
///   3. Experience level
///   4. Industry
///   5. Team size
///   6. Project preferences (use case + type + methodology)
///   7. Review & finish
///
/// Answers are saved to Firestore incrementally. After finishing or skipping,
/// the dialog closes and the user returns to the dashboard.
class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key, this.returnTo = AppRoutes.dashboard});

  final String returnTo;

  /// Show the onboarding as a modal dialog overlay. Preferred entry point —
  /// renders above the current screen with a blurred backdrop.
  static Future<void> show(BuildContext context,
      {String returnTo = AppRoutes.dashboard}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // we render our own backdrop
      builder: (ctx) => ProfileOnboardingScreen(returnTo: returnTo),
    );
  }

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Entrance animation (scale + fade on dialog open)
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  // Per-page staggered reveal
  late final AnimationController _revealController;
  late final Animation<double> _revealFade;
  late final Animation<Offset> _revealSlide;

  ProfileOnboardingAnswers _answers = const ProfileOnboardingAnswers();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _useCaseController = TextEditingController();
  bool _isSaving = false;

  static const int _pageCount = 7;

  // ── Brand palette (refined, sophisticated) ─────────────────────────────
  static const Color _bgDeep = Color(0xFF0B1120);       // near-black navy
  static const Color _bgSurface = Color(0xFF131B2E);    // card surface
  static const Color _bgElevated = Color(0xFF1A2440);   // elevated card
  static const Color _border = Color(0xFF243154);       // subtle border
  static const Color _borderHover = Color(0xFF3B4F7A);  // hover border
  static const Color _gold = Color(0xFFFCD34D);         // warm gold (not flat yellow)
  static const Color _goldDim = Color(0xFFB45309);      // deep amber
  static const Color _goldGlow = Color(0xFFFCD34D);     // for glows
  static const Color _textPrimary = Color(0xFFF8FAFC);   // near-white
  static const Color _textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color _textMuted = Color(0xFF64748B);     // slate-500

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entranceScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack, // spring-like overshoot
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _entranceController.forward();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _revealFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealController, curve: Curves.easeOut));
    _revealController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _industryController.dispose();
    _useCaseController.dispose();
    _entranceController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _triggerReveal() {
    _revealController.reset();
    _revealController.forward();
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (_currentPage < _pageCount - 1) {
      await _saveIncremental();
      if (!mounted) return;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      _triggerReveal();
    } else {
      await _finish();
    }
  }

  Future<void> _previous() async {
    if (_currentPage > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      _triggerReveal();
    }
  }

  Future<void> _skipStep() async {
    if (_currentPage < _pageCount - 1) {
      if (!mounted) return;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      _triggerReveal();
    } else {
      await _finish();
    }
  }

  Future<void> _skipAll() async {
    setState(() => _isSaving = true);
    try {
      await ProfileOnboardingService.markComplete(
        _answers.copyWith(skipped: true),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    _close();
  }

  Future<void> _saveIncremental() async {
    setState(() => _isSaving = true);
    try {
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
    _close();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/${widget.returnTo}');
    }
  }

  // ── Setters ─────────────────────────────────────────────────────────────

  void _setRole(UserRole r) =>
      setState(() => _answers = _answers.copyWith(role: r));
  void _setExperience(ExperienceLevel e) =>
      setState(() => _answers = _answers.copyWith(experience: e));
  void _setTeamSize(int s) =>
      setState(() => _answers = _answers.copyWith(teamSize: s));
  void _setProjectType(PrimaryProjectType t) =>
      setState(() => _answers = _answers.copyWith(projectType: t));
  void _setMethodology(PreferredMethodology m) =>
      setState(() => _answers = _answers.copyWith(methodology: m));

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final dialogWidth = (screenSize.width * 0.92).clamp(420.0, 600.0);
    final dialogHeight = (screenSize.height * 0.88).clamp(560.0, 760.0);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Stack(
          children: [
            // ── Blurred backdrop ──────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // swallow taps so backdrop doesn't close
                child: Container(
                  color: Colors.black.withOpacity(0.72 * _entranceOpacity.value),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 24 * _entranceOpacity.value,
                      sigmaY: 24 * _entranceOpacity.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // ── Centered dialog ───────────────────────────────────────────
            Center(
              child: Transform.scale(
                scale: _entranceScale.value,
                child: Opacity(
                  opacity: _entranceOpacity.value,
                  child: Container(
                    width: dialogWidth,
                    height: dialogHeight,
                    decoration: BoxDecoration(
                      color: _bgDeep,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _border, width: 1),
                      boxShadow: [
                        // Outer ambient glow
                        BoxShadow(
                          color: _gold.withOpacity(0.06),
                          blurRadius: 80,
                          spreadRadius: 0,
                          offset: const Offset(0, 0),
                        ),
                        // Deep drop shadow
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 60,
                          spreadRadius: 0,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
                        children: [
                          _buildTopBar(),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              onPageChanged: (p) =>
                                  setState(() => _currentPage = p),
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
                          _buildBottomNav(isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          // Close (skip all) — ghost icon button with hover
          _GhostIconButton(
            icon: Icons.close_rounded,
            onTap: _isSaving ? null : _skipAll,
            tooltip: 'Skip onboarding',
          ),
          const Spacer(),
          // Step counter — refined "01 / 07"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 1),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${(_currentPage + 1).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const TextSpan(
                    text: ' / ',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  TextSpan(
                    text: '$_pageCount'.padLeft(2, '0'),
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isMobile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: _bgDeep,
        border: Border(
          top: BorderSide(color: _border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated progress bar (replaces dots)
          _buildProgressBar(),
          const SizedBox(height: 20),
          Row(
            children: [
              // Back
              if (_currentPage > 0)
                _GhostButton(
                  label: 'Back',
                  icon: Icons.arrow_back_rounded,
                  onTap: _isSaving ? null : _previous,
                )
              else
                const SizedBox(width: 80),
              const Spacer(),
              // Skip this step (middle steps only)
              if (_currentPage > 0 && _currentPage < _pageCount - 1)
                _TextButton(
                  label: 'Skip',
                  onTap: _isSaving ? null : _skipStep,
                ),
              const SizedBox(width: 12),
              // Primary CTA
              _PrimaryButton(
                label: _currentPage == 0
                    ? 'Get started'
                    : (_currentPage == _pageCount - 1 ? 'Finish' : 'Continue'),
                icon: _currentPage == _pageCount - 1
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                isLoading: _isSaving,
                onTap: _isSaving ? null : _next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final segmentWidth = maxWidth / _pageCount;
        return SizedBox(
          height: 4,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: _bgSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Filled portion — animated
              AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                width: segmentWidth * (_currentPage + 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [_gold, Color(0xFFFBBF24)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reusable text styles ─────────────────────────────────────────────────

  Widget _eyebrow(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          fontFamily: 'Satoshi',
        ),
      );

  Widget _heading(String text) => Text(
        text,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
          fontFamily: 'Satoshi',
        ),
      );

  Widget _subheading(String text) => Text(
        text,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 14.5,
          height: 1.55,
          fontFamily: 'Satoshi',
        ),
      );

  Widget _bodyScroll(List<Widget> children) {
    return FadeTransition(
      opacity: _revealFade,
      child: SlideTransition(
        position: _revealSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  // ── Premium option card ──────────────────────────────────────────────────

  Widget _optionCard<T>({
    required T value,
    required T? selected,
    required String title,
    required String subtitle,
    required ValueChanged<T> onTap,
  }) {
    final isSelected = selected == value;
    return _PremiumOptionCard<T>(
      value: value,
      isSelected: isSelected,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  // ── Page 1: Welcome ──────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return _bodyScroll([
      const SizedBox(height: 20),
      // Animated rocket icon
      Center(
        child: _AnimatedRocketIcon(),
      ),
      const SizedBox(height: 28),
      // Heading
      const Center(
        child: Text(
          'Welcome to NDU',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Tagline — letter-spaced
      const Center(
        child: Text(
          'NAVIGATE  ·  DELIVER  ·  UPGRADE',
          style: TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      const SizedBox(height: 20),
      // Description
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'A few quick questions (about 2 minutes) will help us tailor your '
          'workspace — show the right templates, the right dashboards, and the '
          'right starting point for your first project.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14.5,
            height: 1.6,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      const SizedBox(height: 32),
      // "What happens next" glassmorphic card
      _buildJourneyPreview(),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildJourneyPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT HAPPENS NEXT',
            style: TextStyle(
              color: _gold,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 16),
          _journeyStep('1', 'Tell us about you',
              'Role, experience, industry, team size — 7 short steps.'),
          _journeyStep('2', 'Pick your project type',
              'Software, construction, hardware, services, or hybrid.'),
          _journeyStep('3', 'Create your first project',
              'Name it, choose a methodology, and we scaffold the WBS.'),
          _journeyStep('4', 'Open your dashboard',
              'Tailored to your role and project type.', isLast: true),
        ],
      ),
    );
  }

  Widget _journeyStep(String n, String title, String subtitle,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle with gradient
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                n,
                style: const TextStyle(
                  color: Color(0xFF0B1120),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Satoshi',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Role ─────────────────────────────────────────────────────────

  Widget _buildRolePage(ThemeData theme) {
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Step 1'),
            const SizedBox(height: 10),
            _heading('What best describes your role?'),
            const SizedBox(height: 8),
            _subheading(
                'This shapes what dashboards and templates we surface first.'),
          ],
        ),
      ),
      ...UserRole.values.map((r) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: _optionCard<UserRole>(
              value: r,
              selected: _answers.role,
              title: r.label,
              subtitle: r.description,
              onTap: _setRole,
            ),
          )),
      const SizedBox(height: 16),
    ]);
  }

  // ── Page 3: Experience ───────────────────────────────────────────────────

  Widget _buildExperiencePage(ThemeData theme) {
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Step 2'),
            const SizedBox(height: 10),
            _heading('How experienced are you?'),
            const SizedBox(height: 8),
            _subheading(
                'We adjust the level of guidance and the depth of default reporting.'),
          ],
        ),
      ),
      ...ExperienceLevel.values.map((e) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: _optionCard<ExperienceLevel>(
              value: e,
              selected: _answers.experience,
              title: e.label,
              subtitle: e.description,
              onTap: _setExperience,
            ),
          )),
      const SizedBox(height: 16),
    ]);
  }

  // ── Page 4: Industry ─────────────────────────────────────────────────────

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
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Step 3'),
            const SizedBox(height: 10),
            _heading('What industry do you work in?'),
            const SizedBox(height: 8),
            _subheading(
                'Type your own, or pick a common one. Used for benchmarking and template matching.'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _PremiumTextField(
          controller: _industryController,
          hint: 'e.g. Technology / SaaS',
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'SUGGESTIONS',
          style: TextStyle(
            color: _textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return _SuggestionChip(
              label: s,
              onTap: () {
                setState(() => _industryController.text = s);
                HapticFeedback.selectionClick();
              },
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 5: Team size ────────────────────────────────────────────────────

  Widget _buildTeamSizePage(ThemeData theme) {
    const bands = [
      (1, 'Just me', 'Solo founder, contractor, or individual contributor.'),
      (5, '2–5 people', 'Small team, startup, or focused delivery squad.'),
      (15, '6–15 people', 'Cross-functional team or small department.'),
      (50, '16–50 people', 'Multiple teams, mid-size program.'),
      (200, '51–200 people', 'Department or large program.'),
      (500, '200+ people', 'Enterprise / organisation-wide delivery.'),
    ];
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Step 4'),
            const SizedBox(height: 10),
            _heading('How big is your team or organisation?'),
            const SizedBox(height: 8),
            _subheading(
                'We right-size the collaboration, governance, and reporting defaults.'),
          ],
        ),
      ),
      ...bands.map((b) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: _optionCard<int>(
              value: b.$1,
              selected: _answers.teamSize,
              title: b.$2,
              subtitle: b.$3,
              onTap: _setTeamSize,
            ),
          )),
      const SizedBox(height: 16),
    ]);
  }

  // ── Page 6: Project preferences ──────────────────────────────────────────

  Widget _buildProjectPrefsPage(ThemeData theme) {
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Step 5'),
            const SizedBox(height: 10),
            _heading('What are you here to deliver?'),
            const SizedBox(height: 8),
            _subheading(
                'Three quick picks so we scaffold your first project correctly.'),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 6),
        child: Text(
          'Primary use case',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _PremiumTextField(
          controller: _useCaseController,
          hint:
              'e.g. Deliver a software platform on time and on budget; track procurement...',
          maxLines: 3,
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 6),
        child: Text(
          'Project type',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      ...PrimaryProjectType.values.map((t) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 3, 24, 3),
            child: _optionCard<PrimaryProjectType>(
              value: t,
              selected: _answers.projectType,
              title: t.label,
              subtitle: t.description,
              onTap: _setProjectType,
            ),
          )),
      const SizedBox(height: 12),
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 6),
        child: Text(
          'Preferred methodology',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      ...PreferredMethodology.values.map((m) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 3, 24, 3),
            child: _optionCard<PreferredMethodology>(
              value: m,
              selected: _answers.methodology,
              title: m.label,
              subtitle: m.description,
              onTap: _setMethodology,
            ),
          )),
      const SizedBox(height: 16),
    ]);
  }

  // ── Page 7: Review ───────────────────────────────────────────────────────

  Widget _buildReviewPage(ThemeData theme) {
    return _bodyScroll([
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow('Final step'),
            const SizedBox(height: 10),
            _heading('Review your answers'),
            const SizedBox(height: 8),
            _subheading(
                'You can change any of these later in Settings. Tap Finish to open your tailored dashboard.'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1),
          ),
          child: Column(
            children: [
              _reviewRow('Role', _answers.role?.label),
              _reviewDivider(),
              _reviewRow('Experience', _answers.experience?.label),
              _reviewDivider(),
              _reviewRow(
                  'Industry',
                  _industryController.text.trim().isNotEmpty
                      ? _industryController.text.trim()
                      : _answers.industry),
              _reviewDivider(),
              _reviewRow(
                  'Team size',
                  _answers.teamSize == null
                      ? null
                      : _teamSizeLabel(_answers.teamSize!)),
              _reviewDivider(),
              _reviewRow(
                  'Primary use case',
                  _useCaseController.text.trim().isNotEmpty
                      ? _useCaseController.text.trim()
                      : _answers.primaryUseCase),
              _reviewDivider(),
              _reviewRow('Project type', _answers.projectType?.label),
              _reviewDivider(),
              _reviewRow('Methodology', _answers.methodology?.label),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'After you finish, you\'ll land on your project dashboard. From there '
          'you can create your first project and we\'ll scaffold a WBS, cost '
          'framework, and reporting tailored to your answers.',
          style: TextStyle(
              color: _textMuted, fontSize: 12.5, height: 1.5, fontFamily: 'Satoshi'),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _reviewDivider() =>
      const Divider(height: 1, color: _border, indent: 16, endIndent: 16);

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
                    color: _textMuted, fontSize: 12.5, fontFamily: 'Satoshi')),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value == null || value.isEmpty
                  ? '— skipped —'
                  : (value.length > 80 ? '${value.substring(0, 80)}…' : value),
              style: TextStyle(
                color: value == null || value.isEmpty
                    ? _textMuted.withOpacity(0.4)
                    : _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                fontFamily: 'Satoshi',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _teamSizeLabel(int v) {
    if (v == 1) return 'Just me';
    if (v == 5) return '2–5 people';
    if (v == 15) return '6–15 people';
    if (v == 50) return '16–50 people';
    if (v == 200) return '51–200 people';
    return '200+ people';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Premium sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Animated rocket icon with a subtle floating + glow pulse.
class _AnimatedRocketIcon extends StatefulWidget {
  @override
  State<_AnimatedRocketIcon> createState() => _AnimatedRocketIconState();
}

class _AnimatedRocketIconState extends State<_AnimatedRocketIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final float = (Curves.easeInOut.transform(_ctrl.value) - 0.5) * 8.0;
        final glowOpacity = 0.15 + (Curves.easeInOut.transform(_ctrl.value) * 0.1);
        return Transform.translate(
          offset: Offset(0, float),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFCD34D),
                  Color(0xFFF59E0B),
                ],
                center: Alignment.center,
                radius: 0.8,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFCD34D).withOpacity(glowOpacity),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFF0B1120),
                size: 38,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium option card with hover state, selection glow, and tap scale.
class _PremiumOptionCard<T> extends StatefulWidget {
  const _PremiumOptionCard({
    required this.value,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final T value;
  final bool isSelected;
  final String title;
  final String subtitle;
  final ValueChanged<T> onTap;

  @override
  State<_PremiumOptionCard<T>> createState() => _PremiumOptionCardState<T>();
}

class _PremiumOptionCardState<T> extends State<_PremiumOptionCard<T>> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap(widget.value);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFFCD34D).withOpacity(0.06)
                : (_isHovered
                    ? const Color(0xFF1A2440)
                    : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFFCD34D)
                  : (_isHovered
                      ? const Color(0xFF3B4F7A)
                      : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFCD34D).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFF8FAFC),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.4,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? const Color(0xFFFCD34D)
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF475569),
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Color(0xFF0B1120))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium text field with focus glow.
class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 14,
          height: 1.4,
          fontFamily: 'Satoshi',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF475569), fontSize: 13, fontFamily: 'Satoshi'),
          filled: true,
          fillColor: const Color(0xFF131B2E),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF243154), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFCD34D), width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Suggestion chip with hover/tap state.
class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF1A2440)
                : const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF3B4F7A)
                  : const Color(0xFF243154),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Satoshi',
            ),
          ),
        ),
      ),
    );
  }
}

/// Ghost icon button (close, back) with hover state.
class _GhostIconButton extends StatefulWidget {
  const _GhostIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  State<_GhostIconButton> createState() => _GhostIconButtonState();
}

class _GhostIconButtonState extends State<_GhostIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF1A2440)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF3B4F7A)
                  : const Color(0xFF243154),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: enabled
                ? (_isHovered
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF94A3B8))
                : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

/// Ghost text button (Back) with icon + hover.
class _GhostButton extends StatefulWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF1A2440)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF3B4F7A)
                  : const Color(0xFF243154),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: enabled
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text-only skip button.
class _TextButton extends StatefulWidget {
  const _TextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: enabled
                ? (_isHovered
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF64748B))
                : const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
            decoration:
                _isHovered && enabled ? TextDecoration.underline : null,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

/// Primary CTA button — gold gradient with glow, hover lift, press scale, loading spinner.
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (enabled) widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.97 : 1.0)
            ..translate(0.0, _isHovered && enabled ? -1.0 : 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFFFCD34D)
                          .withOpacity(_isHovered ? 0.45 : 0.25),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0B1120),
                  ),
                )
              else ...[
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFF0B1120),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(widget.icon, size: 18, color: const Color(0xFF0B1120)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
