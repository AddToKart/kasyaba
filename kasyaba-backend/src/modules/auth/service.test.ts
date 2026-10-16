import { deleteAccount, exportUserData, restoreUserData } from "./service";
import { prisma } from "../../config/database";

const DUMMY_HASH =
  "$argon2id$v=19$m=65536,t=3,p=4$GKmewFZOWrSFYExcVutlVg$hk8T97esnJfp9LNr4FFLdbAsDKMYCEIdNwYwowSSAEs";

vi.mock("../../config/database", () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      delete: vi.fn(),
    },
    expenseCategory: {
      deleteMany: vi.fn(),
    },
    $transaction: vi.fn(async (cb) => {
      const tx = {
        financialAlert: { deleteMany: vi.fn() },
        financialSnapshot: { deleteMany: vi.fn() },
        savingsContribution: { deleteMany: vi.fn() },
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
      };
      return cb(tx);
    }),
  },
}));

describe("Auth Service - Account Management", () => {
  beforeEach(() => {
    vi.clearAllMocks();
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
  });
});
