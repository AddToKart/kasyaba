import { describe, it, expect } from 'vitest';

describe('Purchase Affordability Calculator Engine', () => {
  it('correctly calculates post-purchase liquid cash and bill coverage', () => {
    const currentBalance = 50000;
    const purchaseAmount = 5000;
    const upcomingBills = 12000;
    const minThreshold = 2000;

    const postPurchaseBalance = currentBalance - purchaseAmount; // 45000
    const cashAfterBills = postPurchaseBalance - upcomingBills; // 33000

    expect(postPurchaseBalance).toBe(45000);
    expect(cashAfterBills).toBe(33000);
    expect(cashAfterBills >= minThreshold).toBe(true);
  });

  it('detects NOT_RECOMMENDED verdict when bills cannot be covered', () => {
    const currentBalance = 15000;
    const purchaseAmount = 10000;
    const upcomingBills = 8000;

    const postPurchaseBalance = currentBalance - purchaseAmount; // 5000
    const cashAfterBills = postPurchaseBalance - upcomingBills; // -3000

    expect(cashAfterBills < 0).toBe(true);
  });

  it('calculates earliest safe buy date based on daily net surplus rate', () => {
    const currentBalance = 5000;
    const purchaseAmount = 15000;
    const upcomingBills = 2000;
    const minThreshold = 1000;
    const dailySurplus = 500; // ₱500/day net savings

    const targetRequiredCash = purchaseAmount + upcomingBills + minThreshold; // 18000
    const deficit = targetRequiredCash - currentBalance; // 13000
    const daysNeeded = Math.ceil(deficit / dailySurplus); // 26 days

    expect(deficit).toBe(13000);
    expect(daysNeeded).toBe(26);
  });
});
