/// NDU Portfolio — PMO Executive Dashboard (Ultra-Modern Edition)
///
/// World-class design with deep glassmorphism, gold gradient accents,
/// animated entrance, gradient charts, and premium micro-interactions.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';

class PortfolioDashboardScreen extends StatefulWidget {
  final String? portfolioId;

  const PortfolioDashboardScreen({super.key, this.portfolioId});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PortfolioDashboardScreen()),
    );
  }

  @override
  State<PortfolioDashboardScreen> createState() => _PortfolioDashboardScreenState();
}

class _PortfolioDashboardScreenState extends State<PortfolioDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _bg = Color(0xFF051424);
  static const _surface = Color(0xFF0D1C2D);
  static const _surfaceHigh = Color(0xFF1C2B3C);
  static const _surfaceHighest = Color(0xFF273647);
  static const _onSurface = Color(0xFFD4E4FA);
  static const _muted = Color(0xFF909096);
  static const _outline = Color(0xFF46464C);
  static const _gold = Color(0xFFF8BD2A);
  static const _goldBright = Color(0xFFFCD34D);
  static const _goldDeep = Color(0xFFF59E0B);
  static const _blue = Color(0xFF818CF8);
  static const _blueDeep = Color(0xFF6366F1);
  static const _emerald = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _crimson = Color(0xFFEF4444);
  static const _crimsonBright = Color(0xFFF87171);

  LinearGradient get _goldGrad => const LinearGradient(
    colors: [Color(0xFFFCD34D), Color(0xFFF8BD2A), Color(0xFFF59E0B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  Widget _glassCard({required Widget child, Color? glow, double blur = 0}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: glow != null ? [BoxShadow(color: glow.withValues(alpha: 0.08), blurRadius: blur)] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _outline.withValues(alpha: 0.3), width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -1.2), radius: 1.8, colors: [Color(0xFF0D1C2D), Color(0xFF051424)]),
        ),
        child: Stack(children: [
          Positioned(top: -100, right: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_blue.withValues(alpha: 0.06), Colors.transparent])))),
          Positioned(bottom: -150, left: -80, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_gold.withValues(alpha: 0.05), Colors.transparent])))),
          CustomScrollView(slivers: [
            SliverAppBar(
              pinned: true, toolbarHeight: 68,
              backgroundColor: _bg.withValues(alpha: 0.7), surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRect(child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(color: _bg.withValues(alpha: 0.7), border: Border(bottom: BorderSide(color: _outline.withValues(alpha: 0.4)))),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: _goldGrad, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]), child: const Icon(Icons.dashboard, color: Color(0xFF402D00), size: 20)),
                        const SizedBox(width: 12),
                        Text('Executive Dashboard', style: TextStyle(color: _onSurface, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontFamily: appFontFamily)),
                        const SizedBox(width: 32),
                        _nav('Global View', true), const SizedBox(width: 24), _nav('B.U. Filter', false), const SizedBox(width: 24), _nav('Strategic Goals', false),
                      ]),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: _surfaceHigh.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(24), border: Border.all(color: _outline.withValues(alpha: 0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search, color: _muted, size: 16), const SizedBox(width: 8), SizedBox(width: 140, child: TextField(style: TextStyle(color: _onSurface, fontSize: 13, fontFamily: appFontFamily), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Search portfolio...', hintStyle: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 13)))])),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 28, color: _outline.withValues(alpha: 0.4)),
                        const SizedBox(width: 12),
                        IconButton(icon: Icon(Icons.notifications_outlined, color: _muted, size: 18), onPressed: () {}),
                        IconButton(icon: Icon(Icons.history, color: _muted, size: 18), onPressed: () {}),
                        const SizedBox(width: 8),
                        Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [_gold, _goldDeep]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]), child: Material(color: Colors.transparent, child: InkWell(onTap: () {}, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.file_download_outlined, color: const Color(0xFF402D00), size: 14), const SizedBox(width: 6), Text('Export', style: TextStyle(color: const Color(0xFF402D00), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: appFontFamily))]))))),
                      ]),
                    ]),
                  )),
                ),
              )),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
              sliver: SliverFadeTransition(
                opacity: _fadeAnimation,
                sliver: SliverList(delegate: SliverChildListDelegate([
                  _buildKpis(context), const SizedBox(height: 28), _buildBento(context),
                ])),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _nav(String label, bool active) => Text(label, style: TextStyle(color: active ? _gold : _muted, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, letterSpacing: 0.3, fontFamily: appFontFamily));

  Widget _buildKpis(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 1000;
    final count = isDesktop ? 6 : MediaQuery.sizeOf(context).width > 600 ? 3 : 2;
    final sp = 16.0;
    final w = (MediaQuery.sizeOf(context).width - 64 - sp * (count - 1)) / count;
    final kpis = [
      ('Total Projects', '156', Icons.inventory_2_rounded, _blue, '+12% vs LY', _emerald, Icons.trending_up_rounded, null, null),
      ('On Track', '32%', Icons.check_circle_rounded, _emerald, '50 Projects', _muted, null, _emerald, null),
      ('At Risk', '41%', Icons.warning_amber_rounded, _amber, '64 Projects', _muted, null, _amber, null),
      ('Off Track', '27%', Icons.error_outline_rounded, _crimson, '42 Projects', _muted, null, _crimson, null),
      ('Total Budget', '\$1.2B', Icons.account_balance_wallet_rounded, _blue, 'FY24/25 Allocation', _muted, null, null, null),
      ('Budget Spent', '\$780M', Icons.payments_rounded, _gold, '65% utilized', _muted, null, null, 0.65),
    ];
    return Wrap(spacing: sp, runSpacing: sp, children: kpis.map((k) => SizedBox(width: w, child: _kpi(k))).toList());
  }

  Widget _kpi(dynamic k) {
    return _glassCard(glow: k.$4 as Color?, blur: 20, child: Stack(children: [
      if (k.$4 != null) Positioned(top: 0, left: 0, right: 0, child: Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [(k.$4 as Color), (k.$4 as Color).withValues(alpha: 0)])))),
      if (k.$8 != null) Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, decoration: BoxDecoration(color: k.$8 as Color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))))),
      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k.$1 as String, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, fontFamily: appFontFamily)),
          Container(width: 32, height: 32, decoration: BoxDecoration(color: (k.$4 as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(k.$3 as IconData, color: k.$4 as Color, size: 16)),
        ]),
        const SizedBox(height: 14),
        ShaderMask(shaderCallback: (b) => ((k.$4 == _gold) ? _goldGrad : LinearGradient(colors: [_onSurface, _onSurface])).createShader(b), child: Text(k.$2 as String, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1, fontFamily: appFontFamily))),
        const SizedBox(height: 6),
        if (k.$9 != null) ...[ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: k.$9 as double, backgroundColor: _surfaceHighest, valueColor: AlwaysStoppedAnimation(_gold), minHeight: 4)), const SizedBox(height: 4)],
        Row(children: [
          if (k.$7 != null) Icon(k.$7 as IconData, color: k.$6 as Color, size: 12),
          if (k.$7 != null) const SizedBox(width: 3),
          Text(k.$5 as String, style: TextStyle(color: k.$6 as Color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: appFontFamily)),
        ]),
      ])),
    ]));
  }

  Widget _buildBento(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w > 1000;
    return Column(children: [
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 8, child: _portfolioTable()), const SizedBox(width: 20), Expanded(flex: 4, child: _buChart())])
      else ...[_portfolioTable(), const SizedBox(height: 20), _buChart()],
      const SizedBox(height: 20),
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: _budgetTrend()), const SizedBox(width: 20), Expanded(flex: 4, child: _risksDonut()), const SizedBox(width: 20), const Expanded(flex: 4, child: SizedBox())])
      else ...[_budgetTrend(), const SizedBox(height: 20), _risksDonut()],
      const SizedBox(height: 20),
      if (isDesktop) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: _upcoming()), const SizedBox(width: 20), Expanded(flex: 6, child: _overdue())])
      else ...[_upcoming(), const SizedBox(height: 20), _overdue()],
    ]);
  }

  Widget _portfolioTable() {
    final ps = [
      ('Project Alpha', 'On Track', _emerald, [_emerald, _emerald, _emerald], '12', '5', '30 Jun 2024', null),
      ('Project Beta', 'At Risk', _amber, [_amber, _emerald, _emerald], '28', '9', '15 Aug 2024', null),
      ('Project Gamma', 'On Track', _emerald, [_emerald, _amber, _emerald], '15', '7', '10 Jul 2024', null),
      ('Project Delta', 'Off Track', _crimson, [_crimson, _crimson, _amber], '42', '18', 'Delayed', _crimson),
      ('Project Epsilon', 'On Track', _emerald, [_emerald, _emerald, _emerald], '4', '2', '31 May 2024', null),
    ];
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Portfolio Health Overview', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, fontFamily: appFontFamily)),
        Row(children: [_pillBtn('View All'), const SizedBox(width: 8), _pillBtn('Filter')]),
      ])),
      Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
      ...List.generate(ps.length, (i) {
        final p = ps[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: i.isOdd ? _surface.withValues(alpha: 0.3) : Colors.transparent, border: i < ps.length - 1 ? Border(bottom: BorderSide(color: _outline.withValues(alpha: 0.1))) : null),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [Container(width: 4, height: 28, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(p.$1, style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: appFontFamily))])),
            Expanded(flex: 2, child: Row(children: [_dot(p.$3), const SizedBox(width: 8), Text(p.$2, style: TextStyle(color: _muted, fontSize: 13, fontFamily: appFontFamily))])),
            Expanded(flex: 2, child: Row(children: p.$4.map<Widget>((c) => Padding(padding: const EdgeInsets.only(right: 6), child: _dot(c, size: 7))).toList())),
            Expanded(child: Center(child: _badge(p.$5, high: int.parse(p.$5) > 30))),
            Expanded(child: Center(child: _badge(p.$6))),
            Expanded(flex: 2, child: Text(p.$7, style: TextStyle(color: p.$8 ?? _muted, fontSize: 13, fontWeight: p.$8 != null ? FontWeight.w700 : FontWeight.w400, fontFamily: appFontFamily))),
          ]),
        );
      }),
    ]));
  }

  Widget _dot(Color c, {double size = 8}) => Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]));
  Widget _badge(String count, {bool high = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: high ? _crimson.withValues(alpha: 0.12) : _surfaceHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: high ? _crimson.withValues(alpha: 0.3) : _outline.withValues(alpha: 0.3))), child: Text(count, style: TextStyle(color: high ? _crimsonBright : _onSurface, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: appFontFamily)));
  Widget _pillBtn(String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: _surfaceHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: _outline.withValues(alpha: 0.3))), child: Text(label, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)));

  Widget _buChart() {
    final us = [('IT Infrastructure', 28, 0.80, _blue), ('HR Transformation', 24, 0.70, _gold), ('Customer Experience', 24, 0.70, const Color(0xFF9CA3AF)), ('Strategic Sales', 18, 0.55, _surfaceHighest)];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PROJECTS BY BUSINESS UNIT', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      ...us.map((u) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(u.$1, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: appFontFamily)), Text('${u.$2}', style: TextStyle(color: u.$4 == _surfaceHighest ? _muted : u.$4, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: appFontFamily))]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Stack(children: [Container(height: 22, decoration: BoxDecoration(color: _surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8))), FractionallySizedBox(widthFactor: u.$3, child: Container(height: 22, decoration: BoxDecoration(gradient: LinearGradient(colors: [u.$4, u.$4.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(8), boxShadow: u.$4 != _surfaceHighest ? [BoxShadow(color: u.$4.withValues(alpha: 0.3), blurRadius: 8)] : null)))])),
      ]))),
    ])));
  }

  Widget _budgetTrend() {
    final ms = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final hs = [0.40, 0.45, 0.55, 0.65, 0.85, 0.50];
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BUDGET UTILIZATION TREND', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 24),
      SizedBox(height: 160, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(6, (i) {
        final hl = i == 4;
        return Container(width: 24, decoration: BoxDecoration(gradient: hl ? LinearGradient(colors: [_blue, _blueDeep], begin: Alignment.bottomCenter, end: Alignment.topCenter) : LinearGradient(colors: [_blue.withValues(alpha: 0.15), _blue.withValues(alpha: 0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), boxShadow: hl ? [BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 12)] : null), height: 160 * hs[i]);
      }))),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ms.map((m) => Text(m, style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: appFontFamily))).toList()),
    ])));
  }

  Widget _risksDonut() {
    return _glassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RISKS BY CATEGORY', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontFamily: appFontFamily)),
      const SizedBox(height: 20),
      Row(children: [
        SizedBox(width: 110, height: 110, child: CustomPaint(painter: _DonutPainter(segments: [(_crimson, 0.25), (_amber, 0.30), (_emerald, 0.45)], trackColor: _surfaceHighest.withValues(alpha: 0.4)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('248', style: TextStyle(color: _onSurface, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: appFontFamily)), Text('TOTAL', style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.w600, fontFamily: appFontFamily))])))),
        const SizedBox(width: 24),
        Expanded(child: Column(children: [_rLeg('Strategic', '25%', _crimson), const SizedBox(height: 10), _rLeg('Technical', '30%', _amber), const SizedBox(height: 10), _rLeg('Resource', '45%', _emerald)])),
      ]),
    ])));
  }

  Widget _rLeg(String l, String p, Color c) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4)])), const SizedBox(width: 8), Text(l, style: TextStyle(color: _onSurface, fontSize: 11, fontFamily: appFontFamily))]), Text(p, style: TextStyle(color: _onSurface, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: appFontFamily))]);

  Widget _upcoming() {
    final ms = [('Requirement Sign-off', 'Project Beta', '22 May 2024', null), ('Database Migration', 'Project Gamma', '28 May 2024', null), ('Security Audit Completion', 'Project Alpha', '01 Jun 2024', _emerald)];
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('UPCOMING MILESTONES (30 DAYS)', style: TextStyle(color: _onSurface, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: appFontFamily)), Container(width: 28, height: 28, decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.event, color: _gold, size: 14))])),
      Divider(height: 1, color: _outline.withValues(alpha: 0.15)),
      ...ms.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(m.$1, style: TextStyle(color: _gold.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily))), Text(m.$2, style: TextStyle(color: _muted, fontSize: 12, fontFamily: appFontFamily)), const SizedBox(width: 12), Text(m.$3, style: TextStyle(color: m.$4 ?? _muted, fontSize: 12, fontWeight: m.$4 != null ? FontWeight.w700 : FontWeight.w400, fontFamily: appFontFamily))]))),
    ]));
  }

  Widget _overdue() {
    final os = [('UAT Start Phase', 'Project Delta', '12 Days', true), ('Vendor Final Payment', 'Project Zeta', '5 Days', false), ('Training Modules Delivery', 'Project Eta', '3 Days', false)];
    return _glassCard(glow: _crimson, blur: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), decoration: BoxDecoration(color: _crimson.withValues(alpha: 0.06), border: Border(bottom: BorderSide(color: _crimson.withValues(alpha: 0.15)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('OVERDUE MILESTONES', style: TextStyle(color: _crimsonBright, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: appFontFamily)), Container(width: 28, height: 28, decoration: BoxDecoration(color: _crimson.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.dangerous, color: _crimsonBright, size: 14))])),
      ...os.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(m.$1, style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: appFontFamily))), Text(m.$2, style: TextStyle(color: _muted, fontSize: 12, fontFamily: appFontFamily)), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(gradient: m.$4 ? LinearGradient(colors: [_crimson, _crimsonBright]) : null, color: m.$4 ? null : _crimson.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), boxShadow: m.$4 ? [BoxShadow(color: _crimson.withValues(alpha: 0.3), blurRadius: 8)] : null), child: Text(m.$3, style: TextStyle(color: m.$4 ? Colors.white : _crimsonBright, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: appFontFamily)))]))),
    ]));
  }
}

class _DonutPainter extends CustomPainter {
  final List<(Color, double)> segments;
  final Color trackColor;
  _DonutPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sw = 10.0;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - sw / 2, paint..color = trackColor);
    double start = -90 * 3.14159 / 180;
    const gap = 0.04;
    for (final (color, frac) in segments) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - sw / 2), start, frac * 2 * 3.14159 - gap, false, paint..color = color);
      start += frac * 2 * 3.14159;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
