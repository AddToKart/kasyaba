-- AlterTable
ALTER TABLE "users" ADD COLUMN "salaryAmount" DECIMAL(14,2),
ADD COLUMN "paydayFrequency" TEXT DEFAULT 'semi-monthly',
ADD COLUMN "paydaySchedule" TEXT DEFAULT '15th & 30th';

