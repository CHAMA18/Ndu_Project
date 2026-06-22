import 'dart:ui';
import 'dart:math' as _math;
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
  bool _isCelebrating = false;

  // Celebration animation (plays when user taps Finish)
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;
  late final Animation<double> _celebrationOpacity;
  late final Animation<double> _confettiOpacity;

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

    // Celebration animation: scale-up + fade-out of the dialog, plus a
    // confetti burst overlay. Total 1400ms — long enough to feel celebratory,
    // short enough to not annoy.
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Check icon pops in with a spring (0–40%)
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    // Dialog fades out (60–100%)
    _celebrationOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    // Confetti burst (0–70%, then fades)
    _confettiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _industryController.dispose();
    _useCaseController.dispose();
    _entranceController.dispose();
    _revealController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _triggerReveal() {
    _revealController.reset();
    _revealController.forward();
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (_currentPage < _pageCount - 1) {
      // Save incrementally but NEVER block navigation on a save failure.
      await _saveIncremental().catchError((e) {
        debugPrint('[Onboarding] incremental save failed (non-blocking): $e');
      });
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
    } catch (e) {
      // Swallow save errors — never block the user's navigation.
      debugPrint('[Onboarding] save error (non-blocking): $e');
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
    } catch (e) {
      debugPrint('[Onboarding] finish save error (non-blocking): $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    // ── Play the celebration animation ──────────────────────────────────
    // Triggers a full-screen confetti burst + scales the check icon with a
    // spring, then fades the dialog out. After 1400ms, closes the dialog
    // and navigates to the dashboard.
    setState(() => _isCelebrating = true);
    _celebrationController.forward();

    // Wait for the celebration to finish, then close.
    await Future.delayed(const Duration(milliseconds: 1400));
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
      animation: Listenable.merge([_entranceController, _celebrationController]),
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
            // ── Centered dialog (fades out during celebration) ────────────
            Center(
              child: Transform.scale(
                scale: _entranceScale.value,
                child: Opacity(
                  opacity: _entranceOpacity.value *
                      (_isCelebrating ? _celebrationOpacity.value : 1.0),
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
            // ── Celebration overlay (confetti + giant check) ───────────────
            if (_isCelebrating)
              Positioned.fill(
                child: IgnorePointer(
                  child: _CelebrationOverlay(
                    controller: _celebrationController,
                    scale: _celebrationScale,
                    confettiOpacity: _confettiOpacity,
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
                    style: const TextStyle(decoration: TextDecoration.none,
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const TextSpan(
                    text: ' / ',
                    style: TextStyle(decoration: TextDecoration.none,
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$_pageCount'.padLeft(2, '0'),
                    style: const TextStyle(decoration: TextDecoration.none,
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
        style: const TextStyle(decoration: TextDecoration.none,
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      );

  Widget _heading(String text) => Text(
        text,
        style: const TextStyle(decoration: TextDecoration.none,
          color: _textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
        ),
      );

  Widget _subheading(String text) => Text(
        text,
        style: const TextStyle(decoration: TextDecoration.none,
          color: _textSecondary,
          fontSize: 14.5,
          height: 1.55,
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

  /// Reusable page header: eyebrow + heading + subheading, consistently
  /// padded across all question pages.
  Widget _pageHeader(String step, String heading, String subheading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(step),
          const SizedBox(height: 10),
          _heading(heading),
          const SizedBox(height: 8),
          _subheading(subheading),
        ],
      ),
    );
  }

  /// Reusable section label for sub-sections within a page.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Text(
        text,
        style: const TextStyle(decoration: TextDecoration.none,
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
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
          style: TextStyle(decoration: TextDecoration.none,
            color: _textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Tagline — letter-spaced
      const Center(
        child: Text(
          'NAVIGATE  ·  DELIVER  ·  UPGRADE',
          style: TextStyle(decoration: TextDecoration.none,
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
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
          style: TextStyle(decoration: TextDecoration.none,
            color: _textSecondary,
            fontSize: 14.5,
            height: 1.6,
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
            style: TextStyle(decoration: TextDecoration.none,
              color: _gold,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
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
                style: const TextStyle(decoration: TextDecoration.none,
                  color: Color(0xFF0B1120),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
                  style: const TextStyle(decoration: TextDecoration.none,
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(decoration: TextDecoration.none,
                    color: _textMuted,
                    fontSize: 12.5,
                    height: 1.4,
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
    final roles = [
      (UserRole.projectManager, 'Project Manager', 'PM, delivery lead, program owner', Icons.assignment_ind_outlined, const Color(0xFF3B82F6)),
      (UserRole.engineer, 'Engineer', 'Software, civil, mechanical, electrical', Icons.engineering_outlined, const Color(0xFF10B981)),
      (UserRole.designer, 'Designer / UX', 'Product, UI/UX, service designer', Icons.palette_outlined, const Color(0xFF8B5CF6)),
      (UserRole.executive, 'Executive / Sponsor', 'Director, VP, C-level, sponsor', Icons.business_center_outlined, const Color(0xFFEF4444)),
      (UserRole.consultant, 'Consultant / Advisor', 'External advisor, SME', Icons.support_agent_outlined, const Color(0xFFF59E0B)),
      (UserRole.analyst, 'Analyst', 'Business, data, systems analyst', Icons.analytics_outlined, const Color(0xFF0EA5E9)),
      (UserRole.other, 'Other', 'Anything else', Icons.more_horiz_rounded, const Color(0xFF64748B)),
    ];
    return _bodyScroll([
      _pageHeader('Step 1', 'What best describes your role?',
          'This shapes what dashboards and templates we surface first.'),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 480;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: roles.map((r) {
              return _RoleCard(
                role: r.$1,
                label: r.$2,
                subtitle: r.$3,
                icon: r.$4,
                accent: r.$5,
                isSelected: _answers.role == r.$1,
                onTap: _setRole,
                width: isWide ? (constraints.maxWidth - 30) / 2 : double.infinity,
              );
            }).toList(),
          );
        }),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 3: Experience ───────────────────────────────────────────────────

  Widget _buildExperiencePage(ThemeData theme) {
    final levels = [
      (ExperienceLevel.beginner, 'Beginner', 'New to project delivery or this kind of work', 1, const Color(0xFF10B981)),
      (ExperienceLevel.intermediate, 'Intermediate', 'Some experience, comfortable with basics', 2, const Color(0xFF3B82F6)),
      (ExperienceLevel.expert, 'Expert', 'Years of hands-on delivery experience', 3, const Color(0xFF8B5CF6)),
      (ExperienceLevel.executive, 'Executive overview', 'Need high-level dashboards, not detail', 4, const Color(0xFFF59E0B)),
    ];
    return _bodyScroll([
      _pageHeader('Step 2', 'How experienced are you?',
          'We adjust the level of guidance and the depth of default reporting.'),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: levels.map((l) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExperienceCard(
                level: l.$1,
                label: l.$2,
                subtitle: l.$3,
                bars: l.$4,
                accent: l.$5,
                isSelected: _answers.experience == l.$1,
                onTap: _setExperience,
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 4: Industry ─────────────────────────────────────────────────────

  Widget _buildIndustryPage(ThemeData theme) {
    final suggestions = [
      ('Technology / SaaS', Icons.code_rounded, const Color(0xFF3B82F6)),
      ('Financial services', Icons.account_balance_rounded, const Color(0xFF10B981)),
      ('Healthcare', Icons.medical_services_outlined, const Color(0xFFEF4444)),
      ('Construction & engineering', Icons.construction_outlined, const Color(0xFFF59E0B)),
      ('Government / public sector', Icons.account_balance_outlined, const Color(0xFF8B5CF6)),
      ('Manufacturing', Icons.factory_outlined, const Color(0xFF0EA5E9)),
      ('Energy & utilities', Icons.bolt_outlined, const Color(0xFFFCD34D)),
      ('Telecommunications', Icons.wifi_outlined, const Color(0xFF06B6D4)),
      ('Education', Icons.school_outlined, const Color(0xFFEC4899)),
      ('Non-profit', Icons.volunteer_activism_outlined, const Color(0xFF14B8A6)),
      ('Other', Icons.category_outlined, const Color(0xFF64748B)),
    ];
    return _bodyScroll([
      _pageHeader('Step 3', 'What industry do you work in?',
          'Type your own, or pick a common one. Used for benchmarking and template matching.'),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _PremiumTextField(
          controller: _industryController,
          hint: 'e.g. Technology / SaaS',
          prefixIcon: Icons.search_outlined,
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'SUGGESTIONS',
          style: TextStyle(decoration: TextDecoration.none,
            color: _textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 480;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return _IndustryChip(
                label: s.$1,
                icon: s.$2,
                accent: s.$3,
                isSelected: _industryController.text == s.$1,
                onTap: () {
                  setState(() => _industryController.text = s.$1);
                  HapticFeedback.selectionClick();
                },
                width: isWide ? (constraints.maxWidth - 24) / 3 : double.infinity,
              );
            }).toList(),
          );
        }),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 5: Team size ────────────────────────────────────────────────────

  Widget _buildTeamSizePage(ThemeData theme) {
    final bands = [
      (1, 'Just me', 'Solo founder, contractor, or individual contributor.', 1, const Color(0xFF64748B)),
      (5, '2–5 people', 'Small team, startup, or focused delivery squad.', 3, const Color(0xFF10B981)),
      (15, '6–15 people', 'Cross-functional team or small department.', 7, const Color(0xFF3B82F6)),
      (50, '16–50 people', 'Multiple teams, mid-size program.', 12, const Color(0xFF8B5CF6)),
      (200, '51–200 people', 'Department or large program.', 18, const Color(0xFFF59E0B)),
      (500, '200+ people', 'Enterprise / organisation-wide delivery.', 24, const Color(0xFFEF4444)),
    ];
    return _bodyScroll([
      _pageHeader('Step 4', 'How big is your team or organisation?',
          'We right-size the collaboration, governance, and reporting defaults.'),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: bands.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TeamSizeCard(
                value: b.$1,
                label: b.$2,
                subtitle: b.$3,
                avatarCount: b.$4,
                accent: b.$5,
                isSelected: _answers.teamSize == b.$1,
                onTap: _setTeamSize,
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 6: Project preferences ──────────────────────────────────────────

  Widget _buildProjectPrefsPage(ThemeData theme) {
    final projectTypes = [
      (PrimaryProjectType.software, 'Software / IT', Icons.code_rounded, const Color(0xFF3B82F6)),
      (PrimaryProjectType.construction, 'Construction', Icons.construction_rounded, const Color(0xFFF59E0B)),
      (PrimaryProjectType.hardware, 'Hardware / Product', Icons.memory_rounded, const Color(0xFF8B5CF6)),
      (PrimaryProjectType.services, 'Services / Ops', Icons.settings_suggest_outlined, const Color(0xFF10B981)),
      (PrimaryProjectType.hybrid, 'Hybrid / Cross-domain', Icons.hub_outlined, const Color(0xFF0EA5E9)),
    ];
    final methodologies = [
      (PreferredMethodology.agile, 'Agile', Icons.speed_rounded, const Color(0xFF10B981)),
      (PreferredMethodology.waterfall, 'Waterfall', Icons.waterfall_chart_outlined, const Color(0xFF3B82F6)),
      (PreferredMethodology.hybrid, 'Hybrid', Icons.merge_outlined, const Color(0xFF8B5CF6)),
      (PreferredMethodology.notSure, 'Not sure yet', Icons.help_outline_rounded, const Color(0xFF64748B)),
    ];
    return _bodyScroll([
      _pageHeader('Step 5', 'What are you here to deliver?',
          'Three quick picks so we scaffold your first project correctly.'),
      const SizedBox(height: 16),
      // Use case
      _sectionLabel('Primary use case'),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _PremiumTextField(
          controller: _useCaseController,
          hint: 'e.g. Deliver a software platform on time and on budget; track procurement...',
          maxLines: 3,
        ),
      ),
      const SizedBox(height: 20),
      // Project type
      _sectionLabel('Project type'),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 480;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: projectTypes.map((t) {
              return _IconOptionCard<PrimaryProjectType>(
                value: t.$1,
                label: t.$2,
                icon: t.$3,
                accent: t.$4,
                isSelected: _answers.projectType == t.$1,
                onTap: _setProjectType,
                width: isWide ? (constraints.maxWidth - 16) / 2 : double.infinity,
              );
            }).toList(),
          );
        }),
      ),
      const SizedBox(height: 20),
      // Methodology
      _sectionLabel('Preferred methodology'),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 480;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methodologies.map((m) {
              return _IconOptionCard<PreferredMethodology>(
                value: m.$1,
                label: m.$2,
                icon: m.$3,
                accent: m.$4,
                isSelected: _answers.methodology == m.$1,
                onTap: _setMethodology,
                width: isWide ? (constraints.maxWidth - 16) / 2 : double.infinity,
              );
            }).toList(),
          );
        }),
      ),
      const SizedBox(height: 24),
    ]);
  }

  // ── Page 7: Review ───────────────────────────────────────────────────────

  Widget _buildReviewPage(ThemeData theme) {
    final industryText = _industryController.text.trim().isNotEmpty
        ? _industryController.text.trim()
        : _answers.industry;
    final useCaseText = _useCaseController.text.trim().isNotEmpty
        ? _useCaseController.text.trim()
        : _answers.primaryUseCase;
    final completionCount = [
      _answers.role,
      _answers.experience,
      industryText,
      _answers.teamSize,
      useCaseText,
      _answers.projectType,
      _answers.methodology,
    ].where((v) => v != null && v.toString().isNotEmpty).length;

    return _bodyScroll([
      const SizedBox(height: 12),
      // Celebration icon
      Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 40),
        ),
      ),
      const SizedBox(height: 20),
      const Center(
        child: Text(
          'You\'re all set',
          style: TextStyle(decoration: TextDecoration.none,
            color: _textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          '$completionCount of 7 answers captured',
          style: const TextStyle(decoration: TextDecoration.none,
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Review your answers below. You can change any of these later in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(decoration: TextDecoration.none,
              color: _textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      // Summary card with grouped rows
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _reviewRow('Role', _answers.role?.label, Icons.assignment_ind_outlined),
              _reviewDivider(),
              _reviewRow('Experience', _answers.experience?.label, Icons.trending_up_outlined),
              _reviewDivider(),
              _reviewRow('Industry', industryText, Icons.business_outlined),
              _reviewDivider(),
              _reviewRow('Team size',
                  _answers.teamSize == null ? null : _teamSizeLabel(_answers.teamSize!),
                  Icons.group_outlined),
              _reviewDivider(),
              _reviewRow('Primary use case', useCaseText, Icons.lightbulb_outline_rounded),
              _reviewDivider(),
              _reviewRow('Project type', _answers.projectType?.label, Icons.folder_outlined),
              _reviewDivider(),
              _reviewRow('Methodology', _answers.methodology?.label, Icons.route_outlined),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'After you finish, you\'ll land on your project dashboard. From there '
          'you can create your first project and we\'ll scaffold a WBS, cost '
          'framework, and reporting tailored to your answers.',
          style: TextStyle(decoration: TextDecoration.none,
              color: _textMuted, fontSize: 12.5, height: 1.5),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _reviewDivider() =>
      const Divider(height: 1, color: _border, indent: 16, endIndent: 16);

  Widget _reviewRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2440),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(label,
                  style: const TextStyle(decoration: TextDecoration.none,
                      color: _textMuted, fontSize: 12.5)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value == null || value.isEmpty
                  ? '— skipped —'
                  : (value.length > 80 ? '${value.substring(0, 80)}…' : value),
              style: TextStyle(decoration: TextDecoration.none,
                color: value == null || value.isEmpty
                    ? _textMuted.withOpacity(0.4)
                    : _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
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
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.value),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
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
                      style: TextStyle(decoration: TextDecoration.none,
                        color: widget.isSelected
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFF8FAFC),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(decoration: TextDecoration.none,
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.4,
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
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(decoration: TextDecoration.none,
          color: Color(0xFFF8FAFC),
          fontSize: 14,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(decoration: TextDecoration.none,
              color: Color(0xFF475569), fontSize: 13, ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B))
              : null,
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
            style: const TextStyle(decoration: TextDecoration.none,
              color: Color(0xFF94A3B8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
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
                style: TextStyle(decoration: TextDecoration.none,
                  color: enabled
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
          style: TextStyle(decoration: TextDecoration.none,
            color: enabled
                ? (_isHovered
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF64748B))
                : const Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (enabled) widget.onTap?.call();
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
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
                  style: const TextStyle(decoration: TextDecoration.none,
                    color: Color(0xFF0B1120),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(widget.icon,
                    size: 18, color: const Color(0xFF0B1120)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Premium page-specific widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Role card with colored icon tile — used on Step 2.
/// Two-column grid on wide screens, single column on narrow.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isSelected;
  final ValueChanged<UserRole> onTap;
  final double width;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent.withOpacity(0.08)
                : (_isHovered ? const Color(0xFF1A2440) : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (_isHovered ? const Color(0xFF3B4F7A) : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(widget.isSelected ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: widget.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(decoration: TextDecoration.none,
                          color: widget.isSelected ? widget.accent : const Color(0xFFF8FAFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: const TextStyle(decoration: TextDecoration.none,
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, size: 18, color: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Experience level card with signal-bar visualization — used on Step 3.
class _ExperienceCard extends StatefulWidget {
  const _ExperienceCard({
    required this.level,
    required this.label,
    required this.subtitle,
    required this.bars,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final ExperienceLevel level;
  final String label;
  final String subtitle;
  final int bars;
  final Color accent;
  final bool isSelected;
  final ValueChanged<ExperienceLevel> onTap;

  @override
  State<_ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<_ExperienceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent.withOpacity(0.08)
                : (_isHovered ? const Color(0xFF1A2440) : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (_isHovered ? const Color(0xFF3B4F7A) : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Signal bars visualization
              SizedBox(
                width: 48,
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final filled = i < widget.bars;
                    final height = 8.0 + (i * 7.0);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: filled
                            ? widget.accent
                            : const Color(0xFF243154),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(decoration: TextDecoration.none,
                          color: widget.isSelected ? widget.accent : const Color(0xFFF8FAFC),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: const TextStyle(decoration: TextDecoration.none,
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, size: 20, color: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Industry chip with icon — used on Step 4 suggestions.
class _IndustryChip extends StatefulWidget {
  const _IndustryChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  @override
  State<_IndustryChip> createState() => _IndustryChipState();
}

class _IndustryChipState extends State<_IndustryChip> {
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
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent.withOpacity(0.12)
                : (_isHovered ? const Color(0xFF1A2440) : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (_isHovered ? const Color(0xFF3B4F7A) : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 20,
                  color: widget.isSelected ? widget.accent : const Color(0xFF94A3B8)),
              const SizedBox(height: 6),
              Text(widget.label,
                  style: TextStyle(decoration: TextDecoration.none,
                    color: widget.isSelected ? widget.accent : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Team size card with avatar cluster visualization — used on Step 5.
class _TeamSizeCard extends StatefulWidget {
  const _TeamSizeCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.avatarCount,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final int value;
  final String label;
  final String subtitle;
  final int avatarCount;
  final Color accent;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  State<_TeamSizeCard> createState() => _TeamSizeCardState();
}

class _TeamSizeCardState extends State<_TeamSizeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent.withOpacity(0.08)
                : (_isHovered ? const Color(0xFF1A2440) : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (_isHovered ? const Color(0xFF3B4F7A) : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Avatar cluster
              SizedBox(
                width: 72,
                height: 36,
                child: Stack(
                  children: List.generate(
                    widget.avatarCount.clamp(1, 5),
                    (i) {
                      return Positioned(
                        left: i * 12.0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.accent.withOpacity(0.2 - (i * 0.03)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF131B2E),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            i == 4 && widget.avatarCount > 5
                                ? Icons.more_horiz
                                : Icons.person,
                            size: 14,
                            color: widget.accent.withOpacity(0.8 - (i * 0.1)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(decoration: TextDecoration.none,
                          color: widget.isSelected ? widget.accent : const Color(0xFFF8FAFC),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: const TextStyle(decoration: TextDecoration.none,
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, size: 20, color: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon option card — used for project type + methodology on Step 6.
/// Compact card with centered icon + label, grid layout.
class _IconOptionCard<T> extends StatefulWidget {
  const _IconOptionCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  final T value;
  final String label;
  final IconData icon;
  final Color accent;
  final bool isSelected;
  final ValueChanged<T> onTap;
  final double width;

  @override
  State<_IconOptionCard<T>> createState() => _IconOptionCardState<T>();
}

class _IconOptionCardState<T> extends State<_IconOptionCard<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent.withOpacity(0.08)
                : (_isHovered ? const Color(0xFF1A2440) : const Color(0xFF131B2E)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : (_isHovered ? const Color(0xFF3B4F7A) : const Color(0xFF243154)),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(widget.isSelected ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.label,
                    style: TextStyle(decoration: TextDecoration.none,
                      color: widget.isSelected ? widget.accent : const Color(0xFFF8FAFC),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (widget.isSelected)
                Icon(Icons.check_circle, size: 16, color: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// Celebration overlay — plays when user taps Finish
// ═══════════════════════════════════════════════════════════════════════════

/// Confetti color palette — shared between the overlay and the painter.
const List<Color> _confettiColors = [
  Color(0xFFFCD34D), // gold
  Color(0xFFF59E0B), // amber
  Color(0xFF10B981), // green
  Color(0xFF3B82F6), // blue
  Color(0xFF8B5CF6), // purple
  Color(0xFFEF4444), // red
  Color(0xFF0EA5E9), // sky
  Color(0xFFEC4899), // pink
];

/// Full-screen celebration overlay with a confetti burst and a giant
/// animated check icon. Rendered on top of the dialog when the user
/// taps "Finish", before the dialog closes and navigates to the dashboard.
///
/// The confetti is 40 particles with random colors, sizes, trajectories,
/// and rotations — animated outward from the center using the parent
/// [AnimationController]. The check icon pops in with a spring
/// ([Curves.easeOutBack]) and then the whole overlay fades out.
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay({
    required this.controller,
    required this.scale,
    required this.confettiOpacity,
  });

  final AnimationController controller;
  final Animation<double> scale;
  final Animation<double> confettiOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            // ── Confetti layer ───────────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  progress: controller.value,
                  opacity: confettiOpacity.value,
                ),
              ),
            ),
            // ── Giant check icon (spring pop-in) ─────────────────────────
            Center(
              child: Transform.scale(
                scale: scale.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 48,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            // ── "You're all set!" text below the check ───────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 90),
                  Transform.scale(
                    scale: scale.value,
                    child: const Text(
                      'You\'re all set!',
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter that renders 40 confetti particles bursting outward
/// from the center of the screen. Each particle has a random angle,
/// distance, color, size, and rotation — deterministic via a fixed seed
/// so the burst looks the same every time (no jarring randomness between
/// frames).
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 0.6;

    // Use a fixed seed so the confetti pattern is stable across frames.
    final random = _SeededRandom(42);

    for (int i = 0; i < 40; i++) {
      final angle = random.nextDouble() * 2 * 3.14159265;
      final distance = maxRadius * progress * (0.5 + random.nextDouble() * 0.5);
      final dx = center.dx + distance * (angle - 3.14159265 / 2).cos();
      final dy = center.dy + distance * angle.sin() * 0.7; // squashed vertical
      final particleSize = 4.0 + random.nextDouble() * 6.0;
      final color = _confettiColors[i % _confettiColors.length];
      final rotation = progress * 6.28 * (random.nextDouble() - 0.5) * 2;

      // Fade out in the last 30% of the animation
      final particleOpacity = opacity *
          (1.0 - (progress * 0.7).clamp(0.0, 1.0));

      final paint = Paint()
        ..color = color.withOpacity(particleOpacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      // Alternate between circles and rectangles for visual variety
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, particleSize / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize,
            height: particleSize * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

/// Simple deterministic PRNG so confetti particles don't jitter between
/// frames. Same seed → same sequence, every time.
class _SeededRandom {
  _SeededRandom(this.seed);
  final int seed;
  int _state = 0;

  double nextDouble() {
    _state = (_state + 1) * 1103515245 + 12345 + seed;
    return ((_state.abs()) % 100000) / 100000.0;
  }
}

/// Extension to add cos/sin to num for cleaner confetti math.
extension _NumTrig on num {
  double cos() => _math.cos(toDouble());
  double sin() => _math.sin(toDouble());
}
