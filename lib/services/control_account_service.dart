import 'package:ndu_project/models/control_account_model.dart';
import 'package:ndu_project/models/project_data_model.dart';

class ControlAccountService {
  /// Recalculate EVM metrics for all control accounts based on work package data.
  static List<ControlAccount> recalculateAll({
    required List<ControlAccount> accounts,
    required List<WorkPackage> workPackages,
    required List<ScheduleActivity> activities,
    required List<CostEstimateItem> costItems,
  }) {
    return accounts.map((account) {
      final filteredWps = workPackages
          .where((wp) => wp.controlAccountId == account.id)
          .toList();
      final filteredActivities = activities
          .where((a) => a.controlAccountId == account.id)
          .toList();
      final filteredCosts = costItems
          .where((c) => c.controlAccountId == account.id)
          .toList();

      return _recalculateOne(
        account: account,
        workPackages: filteredWps,
        activities: filteredActivities,
        costItems: filteredCosts,
      );
    }).toList();
  }

  /// Recalculate a single control account's EVM from its linked items.
  static ControlAccount _recalculateOne({
    required ControlAccount account,
    required List<WorkPackage> workPackages,
    required List<ScheduleActivity> activities,
    required List<CostEstimateItem> costItems,
  }) {
    final double bac =
        workPackages.fold<double>(0, (s, wp) => s + wp.budgetedCost);

    double ev = 0;
    for (final wp in workPackages) {
      if (wp.status == 'complete') {
        ev += wp.budgetedCost;
      } else if (wp.status == 'in_progress') {
        ev += wp.budgetedCost > 0
            ? (wp.actualCost / wp.budgetedCost).clamp(0, 1) * wp.budgetedCost
            : 0;
      }
    }

    final double ac =
        workPackages.fold<double>(0, (s, wp) => s + wp.actualCost);

    final double pvAtNow = _computePlannedValueToDate(
      account.plannedValueByPeriod,
    );

    final double cpi = ac > 0 ? ev / ac : 1.0;
    final double spi = pvAtNow > 0 ? ev / pvAtNow : 1.0;
    final double eac = cpi > 0 ? bac / cpi : bac;
    final double etc = eac - ac;
    final double vac = bac - eac;

    return account.copyWith(
      budgetAtCompletion: bac,
      earnedValue: ev,
      actualCost: ac,
      cpi: cpi,
      spi: spi,
      eac: eac,
      etc: etc,
      vac: vac,
      lastRecalculated: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Sum planned values for periods up to the current month.
  static double _computePlannedValueToDate(Map<String, double> pvByPeriod) {
    final now = DateTime.now();
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    double total = 0;
    for (final entry in pvByPeriod.entries) {
      if (entry.key.compareTo(currentKey) <= 0) {
        total += entry.value;
      }
    }
    return total;
  }

  /// Compute CPI (Cost Performance Index).
  static double computeCpi(double earnedValue, double actualCost) {
    return actualCost > 0 ? earnedValue / actualCost : 1.0;
  }

  /// Compute SPI (Schedule Performance Index).
  static double computeSpi(double earnedValue, double plannedValue) {
    return plannedValue > 0 ? earnedValue / plannedValue : 1.0;
  }

  /// Compute EAC (Estimate at Completion) using CPI-based formula.
  static double computeEac(double bac, double cpi) {
    return cpi > 0 ? bac / cpi : bac;
  }

  /// Compute ETC (Estimate to Complete).
  static double computeEtc(double eac, double actualCost) {
    return eac - actualCost;
  }

  /// Compute VAC (Variance at Completion).
  static double computeVac(double bac, double eac) {
    return bac - eac;
  }

  /// TCPI based on BAC (to-complete performance index).
  static double computeTcpii(double bac, double ev, double ac) {
    return (bac - ac) > 0 ? (bac - ev) / (bac - ac) : 1.0;
  }

  /// TCPI based on EAC (to-complete performance index using EAC).
  static double computeTcpis(double bac, double ev, double eac, double ac) {
    return (eac - ac) > 0 ? (bac - ev) / (eac - ac) : 1.0;
  }
}
