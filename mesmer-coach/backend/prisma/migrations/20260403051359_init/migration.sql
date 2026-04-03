-- CreateEnum
CREATE TYPE "Role" AS ENUM ('Admin', 'ProgramManager', 'RegionalCoordinator', 'M_E', 'Coach', 'Trainer', 'Enumerator', 'Enterprise');

-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "region" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Enterprise" (
    "id" SERIAL NOT NULL,
    "enterpriseName" TEXT NOT NULL,
    "ownerName" TEXT NOT NULL,
    "gender" TEXT NOT NULL,
    "age" INTEGER,
    "sector" TEXT NOT NULL,
    "businessActivity" TEXT,
    "location" TEXT NOT NULL,
    "contactNumber" TEXT NOT NULL,
    "dateCoachingStarted" TIMESTAMP(3),
    "baselineEmployees" INTEGER,
    "baselineMonthlyRevenue" DOUBLE PRECISION,
    "existingRecordKeeping" TEXT NOT NULL,
    "keyChallenges" TEXT,
    "consentStatus" TEXT NOT NULL DEFAULT 'Pending',
    "region" TEXT NOT NULL,
    "coachId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Enterprise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Assessment" (
    "id" SERIAL NOT NULL,
    "enterpriseId" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "responses" JSONB NOT NULL,
    "createdBy" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Assessment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Iap" (
    "id" SERIAL NOT NULL,
    "enterpriseId" INTEGER NOT NULL,
    "tasks" JSONB NOT NULL,
    "signedByCoach" BOOLEAN NOT NULL DEFAULT false,
    "signedByOwner" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Iap_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CoachingVisit" (
    "id" SERIAL NOT NULL,
    "enterpriseId" INTEGER NOT NULL,
    "sessionNo" INTEGER NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "keyFocusArea" TEXT NOT NULL,
    "keyIssuesIdentified" TEXT NOT NULL,
    "actionsAgreed" TEXT NOT NULL,
    "evidenceUrls" TEXT[],
    "followUpDate" TIMESTAMP(3),
    "followUpType" TEXT NOT NULL,
    "measurableResults" JSONB NOT NULL,
    "createdBy" INTEGER NOT NULL,
    "qcStatus" TEXT NOT NULL DEFAULT 'pending',
    "qcNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CoachingVisit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingSession" (
    "id" SERIAL NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "moduleName" TEXT NOT NULL,
    "location" TEXT NOT NULL DEFAULT 'Not specified',
    "trainerId" INTEGER NOT NULL,
    "attendance" JSONB NOT NULL,

    CONSTRAINT "TrainingSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Graduation" (
    "id" SERIAL NOT NULL,
    "enterpriseId" INTEGER NOT NULL,
    "hasBaseline" BOOLEAN NOT NULL DEFAULT false,
    "completedVisits" INTEGER NOT NULL DEFAULT 0,
    "hasEvidence" BOOLEAN NOT NULL DEFAULT false,
    "certificateIssued" BOOLEAN NOT NULL DEFAULT false,
    "graduatedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Graduation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Graduation_enterpriseId_key" ON "Graduation"("enterpriseId");

-- AddForeignKey
ALTER TABLE "Assessment" ADD CONSTRAINT "Assessment_enterpriseId_fkey" FOREIGN KEY ("enterpriseId") REFERENCES "Enterprise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Iap" ADD CONSTRAINT "Iap_enterpriseId_fkey" FOREIGN KEY ("enterpriseId") REFERENCES "Enterprise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CoachingVisit" ADD CONSTRAINT "CoachingVisit_enterpriseId_fkey" FOREIGN KEY ("enterpriseId") REFERENCES "Enterprise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Graduation" ADD CONSTRAINT "Graduation_enterpriseId_fkey" FOREIGN KEY ("enterpriseId") REFERENCES "Enterprise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
