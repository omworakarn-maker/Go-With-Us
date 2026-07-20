/*
  Warnings:

  - You are about to drop the column `recipient_id` on the `messages` table. All the data in the column will be lost.
  - The `budget` column on the `trips` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- DropForeignKey
ALTER TABLE "messages" DROP CONSTRAINT "messages_recipient_id_fkey";

-- DropIndex
DROP INDEX "messages_created_at_idx";

-- DropIndex
DROP INDEX "messages_recipient_id_idx";

-- AlterTable
ALTER TABLE "messages" DROP COLUMN "recipient_id",
ADD COLUMN     "is_read" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "receiver_id" TEXT;

-- AlterTable
ALTER TABLE "trips" ADD COLUMN     "embedding" JSONB,
ADD COLUMN     "gallery" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "groupAnalysis" TEXT,
ADD COLUMN     "itinerary" JSONB,
ADD COLUMN     "summary" TEXT,
DROP COLUMN "budget",
ADD COLUMN     "budget" INTEGER NOT NULL DEFAULT 1000;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "embedding" JSONB;

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'alert',
    "target_id" TEXT,
    "user_id" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "notifications_user_id_idx" ON "notifications"("user_id");

-- CreateIndex
CREATE INDEX "notifications_target_id_idx" ON "notifications"("target_id");

-- CreateIndex
CREATE INDEX "notifications_created_at_idx" ON "notifications"("created_at");

-- CreateIndex
CREATE INDEX "messages_receiver_id_idx" ON "messages"("receiver_id");

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
