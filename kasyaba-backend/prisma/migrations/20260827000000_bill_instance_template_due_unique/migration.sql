-- Deduplicate system categories before adding unique index
WITH canonical AS (
  SELECT name, MIN(id) AS keep_id
  FROM "expense_categories"
  WHERE "userId" IS NULL
  GROUP BY name
),
to_replace AS (
  SELECT ec.id AS old_id, c.keep_id AS new_id
  FROM "expense_categories" ec
  JOIN canonical c ON ec.name = c.name
  WHERE ec."userId" IS NULL AND ec.id <> c.keep_id
)
UPDATE "expense_entries" ee
SET "categoryId" = tr.new_id
FROM to_replace tr
WHERE ee."categoryId" = tr.old_id;

WITH canonical AS (
  SELECT name, MIN(id) AS keep_id
  FROM "expense_categories"
  WHERE "userId" IS NULL
  GROUP BY name
),
to_replace AS (
  SELECT ec.id AS old_id, c.keep_id AS new_id
  FROM "expense_categories" ec
  JOIN canonical c ON ec.name = c.name
  WHERE ec."userId" IS NULL AND ec.id <> c.keep_id
)
UPDATE "budgets" b
SET "categoryId" = tr.new_id
FROM to_replace tr
WHERE b."categoryId" = tr.old_id;

WITH canonical AS (
  SELECT name, MIN(id) AS keep_id
  FROM "expense_categories"
  WHERE "userId" IS NULL
  GROUP BY name
),
to_replace AS (
  SELECT ec.id AS old_id, c.keep_id AS new_id
  FROM "expense_categories" ec
  JOIN canonical c ON ec.name = c.name
  WHERE ec."userId" IS NULL AND ec.id <> c.keep_id
)
UPDATE "bill_templates" bt
SET "categoryId" = tr.new_id
FROM to_replace tr
WHERE bt."categoryId" = tr.old_id;

WITH canonical AS (
  SELECT name, MIN(id) AS keep_id
  FROM "expense_categories"
  WHERE "userId" IS NULL
  GROUP BY name
)
DELETE FROM "expense_categories" ec
USING canonical c
WHERE ec."userId" IS NULL
  AND ec.name = c.name
  AND ec.id <> c.keep_id;

-- Deduplicate bill instances if any exist
DELETE FROM "bill_instances" older
USING "bill_instances" newer
WHERE older."templateId" IS NOT NULL
  AND older."templateId" = newer."templateId"
  AND older."dueDate" = newer."dueDate"
  AND (
    (older."status" <> 'paid' AND newer."status" = 'paid')
    OR (
      (older."status" = newer."status" OR newer."status" <> 'paid')
      AND (
        older."createdAt" < newer."createdAt"
        OR (older."createdAt" = newer."createdAt" AND older."id" < newer."id")
      )
    )
  );

-- Prevent duplicate recurring bill instances when workers overlap.
CREATE UNIQUE INDEX IF NOT EXISTS "bill_instances_templateId_dueDate_key"
ON "bill_instances"("templateId", "dueDate");

-- PostgreSQL treats NULLs as distinct in the composite Prisma constraint, so
-- protect the shared system categories with a partial unique index as well.
CREATE UNIQUE INDEX IF NOT EXISTS "expense_categories_system_name_key"
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

CREATE UNIQUE INDEX IF NOT EXISTS "financial_alerts_userId_deduplicationKey_key"
ON "financial_alerts"("userId", "deduplicationKey");
