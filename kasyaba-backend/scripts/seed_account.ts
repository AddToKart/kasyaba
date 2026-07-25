import { PrismaClient } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function seedAccountData() {
  console.log('🌱 Starting account data seeding...');

  // 1. Ensure categories exist
  let categories = await prisma.expenseCategory.findMany();
  if (categories.length === 0) {
    const defaultCats = [
      { name: 'Food & Dining', iconKey: 'restaurant' },
      { name: 'Groceries', iconKey: 'shopping_cart' },
      { name: 'Utilities', iconKey: 'bolt' },
      { name: 'Housing', iconKey: 'home' },
      { name: 'Transportation', iconKey: 'directions_car' },
      { name: 'Entertainment', iconKey: 'movie' },
      { name: 'Shopping', iconKey: 'shopping_bag' },
      { name: 'Health & Medical', iconKey: 'medical_services' },
      { name: 'Subscriptions', iconKey: 'subscriptions' },
      { name: 'Other', iconKey: 'receipt' },
    ];
    for (const cat of defaultCats) {
      await prisma.expenseCategory.create({ data: cat });
    }
    categories = await prisma.expenseCategory.findMany();
    console.log(`✅ Created ${categories.length} default categories.`);
  }

  // 2. Upsert Demo User and Reset Passwords for testing
  const passwordHash = await argon2.hash('Password123!');

  await prisma.user.upsert({
    where: { email: 'demo@kasyaba.com' },
    update: { passwordHash },
    create: {
      email: 'demo@kasyaba.com',
      displayName: 'Kurtborbe15',
      passwordHash,
      currencyCode: 'PHP',
      timezone: 'Asia/Manila',
    },
  });

  // Update passwordHash for all users so Password123! works for every account
  await prisma.user.updateMany({
    data: { passwordHash },
  });

  const users = await prisma.user.findMany();
  console.log('\n📋 Available Accounts in Database:');
  for (const u of users) {
    console.log(`  • Email: ${u.email} | Name: ${u.displayName || 'No Name'} | Password: Password123!`);
  }

  const catMap = new Map(categories.map((c) => [c.name, c.id]));
  const defaultCatId = categories[0].id;

  for (const user of users) {
    console.log(`\n📦 Seeding data for user: ${user.displayName || user.email} (${user.id})`);

    // 3. Ensure Financial Account
    let account = await prisma.financialAccount.findFirst({
      where: { userId: user.id },
    });
    if (!account) {
      account = await prisma.financialAccount.create({
        data: {
          userId: user.id,
          name: 'Main Bank Account',
          type: 'bank',
          openingBalance: 15000,
          currencyCode: 'PHP',
        },
      });
      console.log(`  💳 Created main financial account.`);
    }

    // 4. Create Income Entries (Current month)
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();

    const salaryDate = new Date(currentYear, currentMonth, 1, 10, 0, 0);
    const freelanceDate = new Date(currentYear, currentMonth, 15, 14, 30, 0);

    // Delete existing entries to prevent duplication for clean seed
    await prisma.incomeEntry.deleteMany({ where: { userId: user.id } });
    await prisma.expenseEntry.deleteMany({ where: { userId: user.id } });
    await prisma.financialSnapshot.deleteMany({ where: { userId: user.id } });
    await prisma.budget.deleteMany({ where: { userId: user.id } });
    await prisma.billInstance.deleteMany({ where: { userId: user.id } });
    await prisma.savingsGoal.deleteMany({ where: { userId: user.id } });

    await prisma.incomeEntry.createMany({
      data: [
        {
          userId: user.id,
          accountId: account.id,
          amount: 45000,
          source: 'Monthly Salary',
          receivedAt: salaryDate,
          notes: 'Main payroll deposit',
        },
        {
          userId: user.id,
          accountId: account.id,
          amount: 12500,
          source: 'Freelance Design',
          receivedAt: freelanceDate,
          notes: 'Client UI design project',
        },
      ],
    });
    console.log(`  💵 Added 2 income entries (Total: ₱57,500.00).`);

    // 5. Create Expense Entries over past 30 days
    const expensesToSeed = [
      { daysAgo: 28, amount: 3200, desc: 'Supermarket Groceries', catName: 'Groceries' },
      { daysAgo: 26, amount: 3400, desc: 'Meralco Electric Bill', catName: 'Utilities' },
      { daysAgo: 25, amount: 650, desc: 'Manila Water Bill', catName: 'Utilities' },
      { daysAgo: 24, amount: 1699, desc: 'PLDT Fiber Internet', catName: 'Utilities' },
      { daysAgo: 22, amount: 850, desc: 'Dinner with friends', catName: 'Food & Dining' },
      { daysAgo: 20, amount: 2500, desc: 'Weekly Grocery Stockup', catName: 'Groceries' },
      { daysAgo: 18, amount: 1200, desc: 'Gasoline refill', catName: 'Transportation' },
      { daysAgo: 16, amount: 450, desc: 'Starbucks Coffee & Snacks', catName: 'Food & Dining' },
      { daysAgo: 14, amount: 4500, desc: 'New Sneakers', catName: 'Shopping' },
      { daysAgo: 12, amount: 1800, desc: 'Pharmacy & Vitamins', catName: 'Health & Medical' },
      { daysAgo: 10, amount: 2800, desc: 'Fresh Market Produce', catName: 'Groceries' },
      { daysAgo: 8, amount: 549, desc: 'Netflix & Spotify Premium', catName: 'Subscriptions' },
      { daysAgo: 6, amount: 1400, desc: 'Weekend Buffet Lunch', catName: 'Food & Dining' },
      { daysAgo: 4, amount: 750, desc: 'GrabCar Commute', catName: 'Transportation' },
      { daysAgo: 2, amount: 2100, desc: 'Department Store Items', catName: 'Shopping' },
      { daysAgo: 1, amount: 480, desc: 'Ramen Dinner', catName: 'Food & Dining' },
    ];

    for (const item of expensesToSeed) {
      const spentAt = new Date(now.getTime() - item.daysAgo * 24 * 60 * 60 * 1000);
      const catId = catMap.get(item.catName) || defaultCatId;
      await prisma.expenseEntry.create({
        data: {
          userId: user.id,
          accountId: account.id,
          categoryId: catId,
          amount: item.amount,
          description: item.desc,
          spentAt,
        },
      });
    }
    console.log(`  🛍️ Added ${expensesToSeed.length} detailed expense entries.`);

    // 6. Create 30 Daily Financial Snapshots (Rolling 30 Days)
    let currentBal = 18500;
    const totalIncome = 57500;
    let accumulatedExpenses = 5000;

    for (let i = 29; i >= 0; i--) {
      const snapshotDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      
      // Simulate balance movement:
      // Day 29 to 25: steady spending
      // Day 24 (salary day): +45,000 boost
      // Day 10 (freelance day): +12,500 boost
      if (i === 24) {
        currentBal += 45000;
      } else if (i === 10) {
        currentBal += 12500;
      } else {
        // daily expense deduction between 300 and 1500
        const dailySpend = 300 + ((i * 137) % 1100);
        currentBal = Math.max(5000, currentBal - dailySpend);
        accumulatedExpenses += dailySpend;
      }

      const projectedEnd = Math.round(currentBal + (totalIncome - accumulatedExpenses) * 0.4);

      await prisma.financialSnapshot.create({
        data: {
          userId: user.id,
          snapshotDate,
          actualBalance: Math.round(currentBal * 100) / 100,
          incomeMonthToDate: totalIncome,
          expensesMonthToDate: Math.round(accumulatedExpenses * 100) / 100,
          savingsMonthToDate: 5000,
          projectedMonthEndIncome: totalIncome,
          projectedMonthEndExpenses: Math.round((accumulatedExpenses * 1.2) * 100) / 100,
          predictedMonthEndBalance: Math.round(projectedEnd * 100) / 100,
          healthScore: Math.min(95, Math.max(65, 75 + (i % 15))),
          healthGrade: 'Good',
        },
      });
    }
    console.log(`  📈 Generated 30 daily financial snapshots for 30-day balance trend chart.`);

    // 7. Add Active Budget
    const foodCatId = catMap.get('Food & Dining') || defaultCatId;
    await prisma.budget.create({
      data: {
        userId: user.id,
        categoryId: foodCatId,
        amount: 25000,
        startsOn: new Date(currentYear, currentMonth, 1),
        isActive: true,
      },
    });
    console.log(`  🎯 Created monthly budget of ₱25,000.00.`);

    // 8. Add Upcoming Bills
    const in5Days = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
    const in12Days = new Date(now.getTime() + 12 * 24 * 60 * 60 * 1000);

    await prisma.billInstance.createMany({
      data: [
        {
          userId: user.id,
          name: 'Credit Card Minimum',
          amount: 3500,
          dueDate: in5Days,
          status: 'upcoming',
        },
        {
          userId: user.id,
          name: 'Condo Association Dues',
          amount: 2800,
          dueDate: in12Days,
          status: 'upcoming',
        },
      ],
    });
    console.log(`  📅 Added 2 upcoming bills.`);

    // 9. Add Active Savings Goal
    const goal = await prisma.savingsGoal.create({
      data: {
        userId: user.id,
        name: 'Emergency Fund',
        targetAmount: 100000,
        targetDate: new Date(currentYear + 1, 0, 1),
        status: 'active',
      },
    });

    await prisma.savingsContribution.create({
      data: {
        goalId: goal.id,
        userId: user.id,
        accountId: account.id,
        amount: 35000,
        contributedAt: new Date(),
        notes: 'Initial savings deposit',
      },
    });
    console.log(`  💰 Created "Emergency Fund" savings goal with ₱35,000 saved.`);
  }

  console.log('\n✨ Database seeding completed successfully!');
}

seedAccountData()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
