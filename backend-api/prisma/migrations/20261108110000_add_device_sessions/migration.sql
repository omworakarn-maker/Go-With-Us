CREATE TABLE "device_sessions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "device_key" TEXT NOT NULL,
    "device_name" TEXT NOT NULL,
    "user_agent" TEXT NOT NULL DEFAULT '',
    "version" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    CONSTRAINT "device_sessions_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "device_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "device_sessions_user_id_device_key_key" ON "device_sessions"("user_id", "device_key");
CREATE INDEX "device_sessions_user_id_revoked_at_expires_at_idx" ON "device_sessions"("user_id", "revoked_at", "expires_at");
