CREATE TYPE "TransactionStatus" AS ENUM ('planned', 'posted', 'cancelled');

ALTER TABLE "income_entries"
ADD COLUMN "status" "TransactionStatus" NOT NULL DEFAULT 'posted';

ALTER TABLE "expense_entries"
ADD COLUMN "status" "TransactionStatus" NOT NULL DEFAULT 'posted';

-- Preserve the meaning of existing future-dated entries after introducing
-- explicit lifecycle states.
UPDATE "income_entries"
SET "status" = 'planned'
WHERE "receivedAt" > CURRENT_TIMESTAMP;

UPDATE "expense_entries"
SET "status" = 'planned'
WHERE "spentAt" > CURRENT_TIMESTAMP;

CREATE TABLE "account_transfers" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "fromAccountId" TEXT NOT NULL,
  "toAccountId" TEXT NOT NULL,
  "amount" DECIMAL(14,2) NOT NULL,
  "transferredAt" TIMESTAMP(3) NOT NULL,
  "status" "TransactionStatus" NOT NULL DEFAULT 'posted',
  "notes" TEXT,
  "clientMutationId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "account_transfers_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "account_transfers_clientMutationId_key"
ON "account_transfers"("clientMutationId");
CREATE INDEX "account_transfers_userId_transferredAt_idx"
ON "account_transfers"("userId", "transferredAt");
CREATE INDEX "account_transfers_fromAccountId_transferredAt_idx"
ON "account_transfers"("fromAccountId", "transferredAt");
CREATE INDEX "account_transfers_toAccountId_transferredAt_idx"
ON "account_transfers"("toAccountId", "transferredAt");

ALTER TABLE "account_transfers"
ADD CONSTRAINT "account_transfers_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "account_transfers"
ADD CONSTRAINT "account_transfers_fromAccountId_fkey"
FOREIGN KEY ("fromAccountId") REFERENCES "financial_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "account_transfers"
ADD CONSTRAINT "account_transfers_toAccountId_fkey"
FOREIGN KEY ("toAccountId") REFERENCES "financial_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "account_transfers"
ADD CONSTRAINT "account_transfers_different_accounts_check"
CHECK ("fromAccountId" <> "toAccountId");
ALTER TABLE "account_transfers"
ADD CONSTRAINT "account_transfers_positive_amount_check"
CHECK ("amount" > 0);
