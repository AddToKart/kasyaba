import { Router } from "express";
import { registerRoutes as registerAuthRoutes } from "../modules/auth/routes";
import { registerRoutes as registerAccountRoutes } from "../modules/accounts/routes";
import { registerRoutes as registerIncomeRoutes } from "../modules/income/routes";
import { registerRoutes as registerExpenseRoutes } from "../modules/expenses/routes";
import { registerRoutes as registerCategoryRoutes } from "../modules/categories/routes";
import { registerRoutes as registerBudgetRoutes } from "../modules/budgets/routes";
import { registerRoutes as registerGoalRoutes } from "../modules/goals/routes";
import { registerRoutes as registerBillRoutes } from "../modules/bills/routes";
import { registerRoutes as registerAlertRoutes } from "../modules/alerts/routes";
import { registerRoutes as registerDashboardRoutes } from "../modules/dashboard/routes";
import { registerRoutes as registerTransactionRoutes } from "../modules/transactions/routes";
import { registerRoutes as registerPlanningRoutes } from "../modules/planning/routes";
import { registerRoutes as registerLegalRoutes } from "../modules/legal/routes";
import { prisma } from "../config/database";
import { Request, Response } from "express";

const router = Router();

// Health check (no auth)
router.get("/health/live", (_req: Request, res: Response) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

router.get("/health/ready", async (_req: Request, res: Response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: "error", message: "Database not ready" });
  }
});

// Public legal pages (Google Play privacy policy + account deletion URL)
registerLegalRoutes(router);

// Register all module routes
registerAuthRoutes(router);
registerAccountRoutes(router);
registerIncomeRoutes(router);
registerExpenseRoutes(router);
registerCategoryRoutes(router);
registerBudgetRoutes(router);
registerGoalRoutes(router);
registerBillRoutes(router);
registerAlertRoutes(router);
registerDashboardRoutes(router);
registerTransactionRoutes(router);
registerPlanningRoutes(router);

export default router;
