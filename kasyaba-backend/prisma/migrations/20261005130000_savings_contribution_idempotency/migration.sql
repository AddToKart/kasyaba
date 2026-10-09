-- Idempotency key for offline-queued goal contributions, matching the
-- clientMutationId pattern used by income, expenses, and transfers.
ALTER TABLE "savings_contributions" ADD COLUMN "clientMutationId" TEXT;

CREATE UNIQUE INDEX "savings_contributions_clientMutationId_key"
  ON "savings_contributions"("clientMutationId");
