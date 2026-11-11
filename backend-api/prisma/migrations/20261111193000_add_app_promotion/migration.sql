CREATE TABLE "app_promotion" (
    "id" TEXT PRIMARY KEY,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "image" TEXT NOT NULL,
    "frequency" TEXT NOT NULL DEFAULT 'daily',
    "targetType" TEXT NOT NULL DEFAULT 'none',
    "target" TEXT NOT NULL DEFAULT '',
    "title" TEXT NOT NULL DEFAULT '',
    "revision" TEXT NOT NULL
);
