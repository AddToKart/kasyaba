-- Prevent duplicate recurring bill instances when workers overlap.
CREATE UNIQUE INDEX "bill_instances_templateId_dueDate_key"
ON "bill_instances"("templateId", "dueDate");

-- PostgreSQL treats NULLs as distinct in the composite Prisma constraint, so
-- protect the shared system categories with a partial unique index as well.
CREATE UNIQUE INDEX "expense_categories_system_name_key"
ON "expense_categories"("name")
WHERE "userId" IS NULL;

-- Alert generation can be triggered by both the worker and API reads. Keep
-- one alert per user/key before enforcing the invariant for future writes.
DELETE FROM "financial_alerts" older
USING "financial_alerts" newer
WHERE older."userId" = newer."userId"
  AND older."deduplicationKey" = newer."deduplicationKey"
  AND (
    older."createdAt" < newer."createdAt"
    OR (
      older."createdAt" = newer."createdAt"
      AND older."id" < newer."id"
    )
  );

CREATE UNIQUE INDEX "financial_alerts_userId_deduplicationKey_key"
ON "financial_alerts"("userId", "deduplicationKey");
