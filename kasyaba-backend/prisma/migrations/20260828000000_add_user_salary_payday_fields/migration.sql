-- AlterTable
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "salaryAmount" DECIMAL(14,2),
ADD COLUMN IF NOT EXISTS "paydayFrequency" TEXT DEFAULT 'semi-monthly',
ADD COLUMN IF NOT EXISTS "paydaySchedule" TEXT DEFAULT '15th & 30th';
