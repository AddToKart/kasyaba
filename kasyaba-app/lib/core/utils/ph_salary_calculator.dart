import 'dart:math' as math;

/// Holds the complete, deterministic Philippine Gross-to-Net statutory breakdown.
class PhSalaryBreakdown {
  /// The base gross salary subject to statutory deductions.
  final double grossBasicSalary;

  /// De Minimis and non-taxable allowances exempt from statutory and withholding taxes.
  final double nonTaxableAllowances;

  /// Combined gross earnings (grossBasicSalary + nonTaxableAllowances).
  final double totalGrossEarnings;

  /// SSS Employee contribution (RA 11199 schedule).
  final double sssContribution;

  /// PhilHealth Employee contribution (5% split 50/50 = 2.5% employee share).
  final double philHealthContribution;

  /// Pag-IBIG (HDMF) Employee contribution (2% with standard ₱200 cap).
  final double pagIbigContribution;

  /// Total statutory contributions (SSS + PhilHealth + Pag-IBIG).
  final double totalStatutoryDeductions;

  /// Taxable income after deducting mandatory statutory contributions.
  final double taxableIncome;

  /// TRAIN Law (RA 10963) withholding tax.
  final double withholdingTax;

  /// Total monthly deductions (statutory + withholding tax).
  final double totalDeductions;

  /// Net take-home monthly pay (totalGrossEarnings - totalDeductions).
  final double netMonthlyPay;

  /// Semi-monthly take-home payout hitting the wallet on 15th & 30th (netMonthlyPay / 2).
  final double semiMonthlyPayout;

  /// Description of the applied TRAIN Law tax bracket.
  final String taxBracketLabel;

  const PhSalaryBreakdown({
    required this.grossBasicSalary,
    required this.nonTaxableAllowances,
    required this.totalGrossEarnings,
    required this.sssContribution,
    required this.philHealthContribution,
    required this.pagIbigContribution,
    required this.totalStatutoryDeductions,
    required this.taxableIncome,
    required this.withholdingTax,
    required this.totalDeductions,
    required this.netMonthlyPay,
    required this.semiMonthlyPayout,
    required this.taxBracketLabel,
  });
}

/// Deterministic Philippine Statutory & TRAIN Law Net Salary Calculator.
class PhSalaryCalculator {
  /// Maximum monthly salary credit for SSS under the current schedule (₱30,000 MSC).
  static const double maxSssMsc = 30000.0;

  /// Minimum monthly salary credit for SSS under the current schedule (₱4,000 MSC).
  static const double minSssMsc = 4000.0;

  /// SSS employee contribution rate (4.5%).
  static const double sssEmployeeRate = 0.045;

  /// PhilHealth employee premium share rate (5.0% split 50/50 = 2.5%).
  static const double philHealthEmployeeRate = 0.025;

  /// PhilHealth salary floor (₱10,000.00).
  static const double philHealthFloor = 10000.0;

  /// PhilHealth salary ceiling (₱100,000.00).
  static const double philHealthCeiling = 100000.0;

  /// Pag-IBIG standard employee contribution cap (₱200.00).
  static const double pagIbigCap = 200.0;

  /// Computes the exact employee share for SSS (Social Security System).
  /// Under the RA 11199 schedule (MSC floor ₱4,000, ceiling ₱30,000, 4.5% employee rate).
  static double computeSss(double grossBasic) {
    if (grossBasic <= 0) return 0.0;
    if (grossBasic < 4250.0) return minSssMsc * sssEmployeeRate; // ₱180.00
    if (grossBasic >= 29750.0) return maxSssMsc * sssEmployeeRate; // ₱1,350.00

    // MSC increments in ₱500 steps from ₱4,000 to ₱30,000
    final steps = ((grossBasic - 4250.0) / 500.0).floor() + 1;
    final msc = minSssMsc + (steps * 500.0);
    final clampedMsc = math.min(maxSssMsc, math.max(minSssMsc, msc));
    return clampedMsc * sssEmployeeRate;
  }

  /// Computes the exact employee share for PhilHealth.
  /// 5.0% premium rate split 50/50 = 2.5% employee share.
  /// Floor ₱10,000 (₱250 min employee share), Ceiling ₱100,000 (₱2,500 max employee share).
  static double computePhilHealth(double grossBasic) {
    if (grossBasic <= 0) return 0.0;
    final clamped = math.min(philHealthCeiling, math.max(philHealthFloor, grossBasic));
    return clamped * philHealthEmployeeRate;
  }

  /// Computes the exact employee share for Pag-IBIG (HDMF).
  /// 1% if basic <= ₱1,500; 2% if basic > ₱1,500, capped at ₱200 standard cap.
  static double computePagIbig(double grossBasic) {
    if (grossBasic <= 0) return 0.0;
    if (grossBasic <= 1500.0) {
      return grossBasic * 0.01;
    }
    return math.min(pagIbigCap, grossBasic * 0.02);
  }

  /// Computes the monthly withholding tax under the TRAIN Law (Republic Act No. 10963).
  /// Returns a record of `(tax, bracketLabel)`.
  static (double tax, String bracketLabel) computeWithholdingTax(double taxableIncome) {
    if (taxableIncome <= 20833.33) {
      return (0.0, '0% (Exempt, ≤ ₱20,833.33)');
    } else if (taxableIncome <= 33333.33) {
      final excess = taxableIncome - 20833.33;
      final tax = excess * 0.15;
      return (tax, '15% of excess over ₱20,833.33');
    } else if (taxableIncome <= 66666.67) {
      final excess = taxableIncome - 33333.33;
      final tax = 1875.00 + (excess * 0.20);
      return (tax, '₱1,875 + 20% of excess over ₱33,333.33');
    } else if (taxableIncome <= 166666.67) {
      final excess = taxableIncome - 66666.67;
      final tax = 8541.67 + (excess * 0.25);
      return (tax, '₱8,541.67 + 25% of excess over ₱66,666.67');
    } else if (taxableIncome <= 666666.67) {
      final excess = taxableIncome - 166666.67;
      final tax = 33541.67 + (excess * 0.30);
      return (tax, '₱33,541.67 + 30% of excess over ₱166,666.67');
    } else {
      final excess = taxableIncome - 666666.67;
      final tax = 183541.67 + (excess * 0.35);
      return (tax, '₱183,541.67 + 35% of excess over ₱666,666.67');
    }
  }

  /// Computes the complete deterministic Philippine Gross-to-Net breakdown.
  static PhSalaryBreakdown calculate({
    required double grossBasicSalary,
    double nonTaxableAllowances = 0.0,
  }) {
    final validBasic = math.max(0.0, grossBasicSalary);
    final validAllowances = math.max(0.0, nonTaxableAllowances);
    final totalGross = validBasic + validAllowances;

    final sss = computeSss(validBasic);
    final philHealth = computePhilHealth(validBasic);
    final pagIbig = computePagIbig(validBasic);
    final totalStatutory = sss + philHealth + pagIbig;

    final taxable = math.max(0.0, validBasic - totalStatutory);
    final (tax, bracketLabel) = computeWithholdingTax(taxable);

    final totalDeductions = totalStatutory + tax;
    final netMonthly = math.max(0.0, totalGross - totalDeductions);
    final semiMonthly = netMonthly / 2.0;

    return PhSalaryBreakdown(
      grossBasicSalary: validBasic,
      nonTaxableAllowances: validAllowances,
      totalGrossEarnings: totalGross,
      sssContribution: sss,
      philHealthContribution: philHealth,
      pagIbigContribution: pagIbig,
      totalStatutoryDeductions: totalStatutory,
      taxableIncome: taxable,
      withholdingTax: tax,
      totalDeductions: totalDeductions,
      netMonthlyPay: netMonthly,
      semiMonthlyPayout: semiMonthly,
      taxBracketLabel: bracketLabel,
    );
  }
}
