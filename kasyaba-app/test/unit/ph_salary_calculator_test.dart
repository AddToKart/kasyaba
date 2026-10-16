import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/utils/ph_salary_calculator.dart';

void main() {
  group('PhSalaryCalculator Statutory Deductions', () {
    test('handles zero and negative salaries safely', () {
      final res = PhSalaryCalculator.calculate(grossBasicSalary: 0);
      expect(res.grossBasicSalary, 0.0);
      expect(res.sssContribution, 0.0);
      expect(res.philHealthContribution, 0.0);
      expect(res.pagIbigContribution, 0.0);
      expect(res.withholdingTax, 0.0);
      expect(res.netMonthlyPay, 0.0);
      expect(res.semiMonthlyPayout, 0.0);
    });

    test('calculates minimum wage statutory deductions (exempt from tax)', () {
      // ₱15,000 monthly basic
      final res = PhSalaryCalculator.calculate(grossBasicSalary: 15000);
      expect(res.grossBasicSalary, 15000.0);
      // SSS: MSC for 15,000 is 15,000 -> 15,000 * 4.5% = 675.00
      expect(res.sssContribution, 675.0);
      // PhilHealth: 15,000 * 2.5% = 375.00
      expect(res.philHealthContribution, 375.0);
      // Pag-IBIG: capped at 200.00
      expect(res.pagIbigContribution, 200.0);
      expect(res.totalStatutoryDeductions, 1250.0);
      // Taxable: 15,000 - 1,250 = 13,750 <= 20,833.33 -> 0 tax
      expect(res.taxableIncome, 13750.0);
      expect(res.withholdingTax, 0.0);
      expect(res.netMonthlyPay, 13750.0);
      expect(res.semiMonthlyPayout, 6875.0);
    });

    test('calculates standard salary ₱30,000 with bracket 2 tax', () {
      final res = PhSalaryCalculator.calculate(grossBasicSalary: 30000);
      // SSS: 30,000 >= 29,750 -> MSC 30,000 -> 1,350.00
      expect(res.sssContribution, 1350.0);
      // PhilHealth: 30,000 * 2.5% = 750.00
      expect(res.philHealthContribution, 750.0);
      // Pag-IBIG: 200.00
      expect(res.pagIbigContribution, 200.0);
      expect(res.totalStatutoryDeductions, 2300.0);
      // Taxable: 30,000 - 2,300 = 27,700
      expect(res.taxableIncome, 27700.0);
      // Tax: (27,700 - 20,833.33) * 0.15 = 6,866.67 * 0.15 = 1,030.0005
      expect(res.withholdingTax, closeTo(1030.0, 0.05));
      // Net: 30,000 - 2,300 - 1,030 = 26,670
      expect(res.netMonthlyPay, closeTo(26670.0, 0.05));
      expect(res.semiMonthlyPayout, closeTo(13335.0, 0.05));
    });

    test('calculates professional salary ₱45,000 + ₱3,000 non-taxable allowances with bracket 3 tax', () {
      final res = PhSalaryCalculator.calculate(
        grossBasicSalary: 45000,
        nonTaxableAllowances: 3000,
      );
      expect(res.grossBasicSalary, 45000.0);
      expect(res.nonTaxableAllowances, 3000.0);
      expect(res.totalGrossEarnings, 48000.0);

      // SSS capped at 30,000 MSC -> 1,350.00
      expect(res.sssContribution, 1350.0);
      // PhilHealth: 45,000 * 2.5% = 1,125.00
      expect(res.philHealthContribution, 1125.0);
      // Pag-IBIG: 200.00
      expect(res.pagIbigContribution, 200.0);
      expect(res.totalStatutoryDeductions, 2675.0);

      // Taxable: 45,000 - 2,675 = 42,325
      expect(res.taxableIncome, 42325.0);
      // Bracket 3: 1,875 + (42,325 - 33,333.33) * 0.20 = 1,875 + 1,798.334 = 3,673.33
      expect(res.withholdingTax, closeTo(3673.33, 0.05));
      // Total Deductions: 2,675 + 3,673.33 = 6,348.33
      expect(res.totalDeductions, closeTo(6348.33, 0.05));
      // Net: 48,000 - 6,348.33 = 41,651.67
      expect(res.netMonthlyPay, closeTo(41651.67, 0.05));
      // Semi-monthly (15th and 30th payout): 41,651.67 / 2 = 20,825.84
      expect(res.semiMonthlyPayout, closeTo(20825.84, 0.05));
    });

    test('respects PhilHealth salary ceiling of ₱100,000', () {
      final res = PhSalaryCalculator.calculate(grossBasicSalary: 150000);
      // PhilHealth ceiling: 100,000 * 2.5% = 2,500.00
      expect(res.philHealthContribution, 2500.0);
      expect(res.sssContribution, 1350.0);
      expect(res.pagIbigContribution, 200.0);
    });
  });
}
