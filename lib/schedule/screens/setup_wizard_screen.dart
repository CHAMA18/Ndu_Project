/// Setup Wizard Screen — creates a new schedule.
/// 2-step: project name + delivery model (Agile/Waterfall/Hybrid).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/schedule/providers/schedule_provider.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});
  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;
  String _projectName = '';
  String? _deliveryModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.calendar_today, color: Color(0xFFF8BD2A), size: 28),
                SizedBox(width: 8),
                Text('NDU ', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 24, fontWeight: FontWeight.bold)),
                Text('PROJECT', style: TextStyle(color: Color(0xFFF8BD2A), fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              const Text('Schedule Setup', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF909096), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3)),
              const SizedBox(height: 32),
              Expanded(child: _step == 0 ? _buildProjectNameStep() : _buildDeliveryModelStep()),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: const Text('Back', style: TextStyle(color: Color(0xFFC7C6CC)))) else const SizedBox(width: 80),
                FilledButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF8BD2A), foregroundColor: const Color(0xFF402D00), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: Text(_step == 1 ? 'Create schedule' : 'Continue'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() => _step == 0 ? _projectName.trim().isNotEmpty : _deliveryModel != null;

  void _handleNext() {
    if (_step < 1) {
      setState(() => _step++);
    } else {
      context.read<ScheduleProvider>().setup(projectName: _projectName.trim(), deliveryModel: _deliveryModel!);
    }
  }

  Widget _buildProjectNameStep() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Name your project', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        onChanged: (v) => setState(() => _projectName = v),
        decoration: InputDecoration(labelText: 'Project name (Level 0)', hintText: 'e.g. NDU Manufacturing Facility', filled: true, fillColor: const Color(0xFF0D1C2D), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF46464C))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF8BD2A)))),
        style: const TextStyle(color: Color(0xFFD4E4FA)),
        autofocus: true,
      ),
    ]);
  }

  Widget _buildDeliveryModelStep() {
    final models = [
      ('AGILE', 'Agile', Icons.speed, 'Epic → Feature → Story → Task. Sprint-based with rolling-wave planning.', 'Levels 0–5'),
      ('WATERFALL', 'Waterfall', Icons.water_drop, 'WBS → EWP → Procurement → CWP → Activity → Task. CPM-based with up to 8 levels.', 'Levels 0–8'),
      ('HYBRID', 'Hybrid', Icons.merge, 'Waterfall phases with Agile sprints within execution.', 'Levels 0–8'),
    ];
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Pick delivery model', style: TextStyle(color: Color(0xFFD4E4FA), fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      ...models.map((m) {
        final selected = _deliveryModel == m.$1;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _deliveryModel = m.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: selected ? const Color(0xFFF8BD2A).withValues(alpha: 0.08) : const Color(0xFF1C2B3C), borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? const Color(0xFFF8BD2A) : const Color(0xFF46464C))),
              child: Row(children: [
                Icon(m.$3, color: selected ? const Color(0xFFF8BD2A) : const Color(0xFFC7C6CC), size: 24),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(m.$2, style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: const Color(0xFF273647), borderRadius: BorderRadius.circular(8)), child: Text(m.$5, style: const TextStyle(color: Color(0xFFC7C6CC), fontSize: 10)))]),
                  Text(m.$4, style: const TextStyle(color: Color(0xFF909096), fontSize: 12)),
                ])),
                if (selected) const Icon(Icons.check_circle, color: Color(0xFFF8BD2A), size: 20),
              ]),
            ),
          ),
        );
      }),
    ]);
  }
}
