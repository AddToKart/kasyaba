import { deleteAccount, exportUserData, restoreUserData } from "./service";
import { generateBillInstances } from "../bills/service";
import { prisma } from "../../config/database";

const DUMMY_HASH =
  "$argon2id$v=19$m=65536,t=3,p=4$GKmewFZOWrSFYExcVutlVg$hk8T97esnJfp9LNr4FFLdbAsDKMYCEIdNwYwowSSAEs";

const { txMocks } = vi.hoisted(() => ({
  txMocks: {
    financialAlert: { deleteMany: vi.fn() },
    financialSnapshot: { deleteMany: vi.fn() },
    savingsContribution: { deleteMany: vi.fn(), upsert: vi.fn() },
    savingsGoal: { deleteMany: vi.fn(), upsert: vi.fn() },
    billInstance: { deleteMany: vi.fn() },
    billTemplate: { deleteMany: vi.fn(), upsert: vi.fn() },
    budget: { deleteMany: vi.fn(), upsert: vi.fn() },
    accountTransfer: { deleteMany: vi.fn(), upsert: vi.fn() },
    incomeEntry: { deleteMany: vi.fn(), upsert: vi.fn() },
    expenseEntry: { deleteMany: vi.fn(), upsert: vi.fn() },
    financialAccount: { deleteMany: vi.fn(), upsert: vi.fn() },
    expenseCategory: { deleteMany: vi.fn(), upsert: vi.fn() },
    authSession: { deleteMany: vi.fn() },
    user: { delete: vi.fn(), update: vi.fn() },
  },
}));

vi.mock("../bills/service", () => ({
  generateBillInstances: vi.fn(),
}));

vi.mock("../../config/database", () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      delete: vi.fn(),
    },
    expenseCategory: {
      deleteMany: vi.fn(),
    },
    $transaction: vi.fn(async (cb) => cb(txMocks)),
  },
}));

describe("Auth Service - Account Management", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(generateBillInstances).mockResolvedValue(0);
  });

  describe("deleteAccount", () => {
    it("throws NotFoundError if user does not exist", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce(null);
      await expect(deleteAccount("non-existent-id")).rejects.toThrow(
        "User not found",
      );
    });

    it("cascades deletion across user records within a transaction", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);
      await expect(deleteAccount("user-123")).resolves.toBeUndefined();
      expect(prisma.$transaction).toHaveBeenCalledOnce();
    });

    it("requires password confirmation when the account has a password", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
        passwordHash: DUMMY_HASH,
      } as never);
      await expect(deleteAccount("user-123")).rejects.toThrow(
        "Password confirmation is required",
      );
    });

    it("rejects an incorrect confirmation password", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
        passwordHash: DUMMY_HASH,
      } as never);
      await expect(deleteAccount("user-123", "wrong-password")).rejects.toThrow(
        "Incorrect password",
      );
    });

    it("deletes when the correct password is supplied", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
        passwordHash: DUMMY_HASH,
      } as never);
      await expect(
        deleteAccount("user-123", "kasyaba-timing-equalization-dummy"),
      ).resolves.toBeUndefined();
    });
  });

  describe("exportUserData", () => {
    it("throws NotFoundError if user does not exist", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce(null);
      await expect(exportUserData("non-existent-id")).rejects.toThrow(
        "User not found",
      );
    });

    it("exports all financial records without passwordHash", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
        email: "test@kasyaba.app",
        displayName: "Test User",
        financialAccounts: [],
        incomeEntries: [],
        expenseEntries: [],
        budgets: [],
        savingsGoals: [],
        billTemplates: [],
        billInstances: [],
        financialSnapshots: [],
        financialAlerts: [],
      } as never);

      const result = await exportUserData("user-123");
      expect(result.exportedAt).toBeDefined();
      expect(result.user.email).toBe("test@kasyaba.app");
      expect(result.user).not.toHaveProperty("passwordHash");
    });
  });

  describe("restoreUserData", () => {
    it("restores user records and returns counts", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      const result = await restoreUserData("user-123", {
        user: {
          salaryAmount: "50000",
          financialAccounts: [{ id: "acc-1", name: "BDO" }],
          expenseEntries: [
            { id: "exp-1", amount: 500, accountId: "acc-1", categoryId: "cat-1" },
          ],
        },
      });

      expect(result.restoredAt).toBeDefined();
      expect(result.counts.accounts).toBe(1);
      expect(result.counts.expenses).toBe(1);
    });

    it("restores a global budget whose categoryId is null", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      const result = await restoreUserData("user-123", {
        user: {
          budgets: [
            {
              id: "budget-1",
              categoryId: null,
              amount: 5000,
              startsOn: "2026-03-01T00:00:00.000Z",
            },
          ],
        },
      });

      expect(result.counts.budgets).toBe(1);
      expect(txMocks.budget.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "budget-1" },
          update: expect.objectContaining({
            categoryId: null,
            amount: 5000,
          }),
          create: expect.objectContaining({
            id: "budget-1",
            userId: "user-123",
            categoryId: null,
            amount: 5000,
          }),
        }),
      );
    });

    it("restores contributions nested under their restored goal", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      const result = await restoreUserData("user-123", {
        user: {
          savingsGoals: [
            {
              id: "goal-1",
              name: "Emergency Fund",
              targetAmount: 100000,
              contributions: [
                {
                  id: "contrib-1",
                  goalId: "goal-1",
                  amount: 2500,
                  contributedAt: "2026-03-05T00:00:00.000Z",
                  notes: "Payday deposit",
                },
              ],
            },
          ],
        },
      });

      expect(result.counts.goals).toBe(1);
      expect(result.counts.contributions).toBe(1);
      expect(txMocks.savingsContribution.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: "contrib-1" },
          update: expect.objectContaining({
            userId: "user-123",
            goalId: "goal-1",
            amount: 2500,
            notes: "Payday deposit",
          }),
          create: expect.objectContaining({
            id: "contrib-1",
            userId: "user-123",
            goalId: "goal-1",
            amount: 2500,
            notes: "Payday deposit",
          }),
        }),
      );

      const upsert = txMocks.savingsContribution.upsert.mock.calls[0][0];
      expect(upsert.update.contributedAt.toISOString()).toBe(
        "2026-03-05T00:00:00.000Z",
      );
      expect(upsert.create.createdAt.toISOString()).toBe(
        "2026-03-05T00:00:00.000Z",
      );
    });

    it("skips contributions whose goal was not restored for this user", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      const result = await restoreUserData("user-123", {
        user: {
          savingsGoals: [],
          savingsContributions: [
            {
              id: "contrib-orphan",
              goalId: "goal-from-another-user",
              amount: 100,
            },
          ],
        },
      });

      expect(result.counts.contributions).toBe(0);
      expect(txMocks.savingsContribution.upsert).not.toHaveBeenCalled();
    });

    it("derives a monthly bill anchor from startsOn when dayOfMonth is null", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      const result = await restoreUserData("user-123", {
        user: {
          billTemplates: [
            {
              id: "bill-monthly",
              name: "Electricity",
              defaultAmount: 1500,
              recurrence: "monthly",
              dayOfMonth: null,
              startsOn: "2026-03-17T08:30:00.000Z",
              isActive: true,
            },
          ],
        },
      });

      expect(result.counts.bills).toBe(1);
      const upsert = txMocks.billTemplate.upsert.mock.calls[0][0];
      expect(upsert.update.dayOfMonth).toBe(17);
      expect(upsert.create.dayOfMonth).toBe(17);
    });

    it("restores a weekly bill's explicit dayOfWeek and round-trips its schedule fields", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      await restoreUserData("user-123", {
        user: {
          billTemplates: [
            {
              id: "bill-weekly",
              name: "Gym",
              defaultAmount: 500,
              recurrence: "weekly",
              dayOfWeek: 5,
              startsOn: "2026-11-18T00:00:00.000Z",
              endsOn: "2027-06-30T00:00:00.000Z",
              reminderLeadDays: 3,
              isActive: true,
            },
          ],
        },
      });

      const upsert = txMocks.billTemplate.upsert.mock.calls[0][0];
      expect(upsert.update.dayOfWeek).toBe(5);
      expect(upsert.create.dayOfWeek).toBe(5);
      expect(upsert.create.endsOn.toISOString()).toBe(
        "2027-06-30T00:00:00.000Z",
      );
      expect(upsert.create.reminderLeadDays).toBe(3);
    });

    it("derives a weekly bill dayOfWeek from startsOn when it is missing", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      await restoreUserData("user-123", {
        user: {
          billTemplates: [
            {
              id: "bill-weekly-derived",
              name: "Gym",
              defaultAmount: 500,
              recurrence: "weekly",
              dayOfWeek: null,
              startsOn: "2026-11-18T00:00:00.000Z",
            },
          ],
        },
      });

      const upsert = txMocks.billTemplate.upsert.mock.calls[0][0];
      expect(upsert.update.dayOfWeek).toBe(3);
      expect(upsert.create.dayOfWeek).toBe(3);
    });

    it("generates bill instances after a successful restore", async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValueOnce({
        id: "user-123",
      } as never);

      await restoreUserData("user-123", {
        user: {
          billTemplates: [
            {
              id: "bill-1",
              name: "Water",
              defaultAmount: 800,
              recurrence: "monthly",
              startsOn: "2026-03-10T00:00:00.000Z",
            },
          ],
        },
      });

      expect(generateBillInstances).toHaveBeenCalledOnce();
      expect(generateBillInstances).toHaveBeenCalledWith("user-123");
    });
  });
});
