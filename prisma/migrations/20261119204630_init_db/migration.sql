-- CreateEnum
CREATE TYPE "StaffRole" AS ENUM ('OWNER_ADMIN', 'SALES_AGENT');

-- CreateEnum
CREATE TYPE "StaffStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "ServiceCategory" AS ENUM ('TOUR', 'HAJJ_UMRAH', 'WORK_PERMIT', 'STUDENT_VISA');

-- CreateEnum
CREATE TYPE "LeadStage" AS ENUM ('NEW', 'QUALIFIED', 'QUOTED', 'FOLLOW_UP', 'WON', 'LOST');

-- CreateEnum
CREATE TYPE "LeadSource" AS ENUM ('PHONE', 'WEBSITE', 'MESSENGER', 'WHATSAPP', 'OTHER');

-- CreateEnum
CREATE TYPE "QuotationStatus" AS ENUM ('DRAFT', 'APPROVED', 'VOID');

-- CreateEnum
CREATE TYPE "FollowUpStatus" AS ENUM ('OPEN', 'DONE', 'CANCELLED');

-- CreateEnum
CREATE TYPE "AiDraftType" AS ENUM ('CUSTOMER_REPLY', 'QUALIFICATION', 'PACKAGE_SUGGESTION', 'QUOTATION_EXPLANATION');

-- CreateEnum
CREATE TYPE "AiDraftReviewStatus" AS ENUM ('DRAFT', 'ACCEPTED', 'EDITED', 'DISCARDED');

-- CreateEnum
CREATE TYPE "CountryCoverageStatus" AS ENUM ('ACTIVE', 'LIMITED', 'PAUSED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "VisaCategory" AS ENUM ('WORK_VISA', 'WORK_PERMIT', 'STUDENT_VISA', 'TOURIST_VISA', 'BUSINESS_VISA', 'OTHER');

-- CreateEnum
CREATE TYPE "VisaPublicationStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "AgencyServiceStatus" AS ENUM ('ACCEPTING_INQUIRIES', 'LIMITED', 'TEMPORARILY_PAUSED', 'NOT_OFFERED');

-- CreateTable
CREATE TABLE "staff_users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "StaffRole" NOT NULL DEFAULT 'SALES_AGENT',
    "status" "StaffStatus" NOT NULL DEFAULT 'ACTIVE',
    "refreshTokenHash" TEXT,
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "staff_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agency_settings" (
    "id" TEXT NOT NULL,
    "agencyName" TEXT NOT NULL DEFAULT 'TravelPilot Agency',
    "legalName" TEXT,
    "logoUrl" TEXT,
    "address" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "website" TEXT,
    "defaultCurrency" TEXT NOT NULL DEFAULT 'BDT',
    "taxRate" DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    "quotationTerms" TEXT NOT NULL,
    "quotationValidityDays" INTEGER NOT NULL DEFAULT 7,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "agency_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "packages" (
    "id" TEXT NOT NULL,
    "category" "ServiceCategory" NOT NULL DEFAULT 'TOUR',
    "title" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "durationDays" INTEGER NOT NULL,
    "durationNights" INTEGER NOT NULL,
    "description" TEXT NOT NULL,
    "inclusions" TEXT[],
    "exclusions" TEXT[],
    "requiredDocuments" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "structuredSpecs" JSONB,
    "basePrice" DECIMAL(12,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "validFrom" TIMESTAMP(3),
    "validUntil" TIMESTAMP(3),
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "packages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "leads" (
    "id" TEXT NOT NULL,
    "trackingCode" TEXT,
    "category" "ServiceCategory" NOT NULL DEFAULT 'TOUR',
    "customerName" TEXT NOT NULL,
    "customerPhone" TEXT,
    "customerEmail" TEXT,
    "source" "LeadSource" NOT NULL DEFAULT 'PHONE',
    "destination" TEXT,
    "travelStartDate" TIMESTAMP(3),
    "travelEndDate" TIMESTAMP(3),
    "travelerCount" INTEGER,
    "budget" DECIMAL(12,2),
    "requirements" TEXT,
    "stage" "LeadStage" NOT NULL DEFAULT 'NEW',
    "eligibilityStatus" TEXT,
    "documentChecklist" JSONB,
    "milestoneChecklist" JSONB,
    "metadata" JSONB,
    "assignedToId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "leads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lead_notes" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lead_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "follow_up_tasks" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "assignedToId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "note" TEXT,
    "dueAt" TIMESTAMP(3) NOT NULL,
    "status" "FollowUpStatus" NOT NULL DEFAULT 'OPEN',
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "follow_up_tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quotations" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "quoteNumber" TEXT NOT NULL,
    "revision" INTEGER NOT NULL DEFAULT 1,
    "status" "QuotationStatus" NOT NULL DEFAULT 'DRAFT',
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "subtotal" DECIMAL(12,2) NOT NULL,
    "discount" DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    "taxAmount" DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    "grandTotal" DECIMAL(12,2) NOT NULL,
    "validUntil" TIMESTAMP(3) NOT NULL,
    "termsAndConditions" TEXT NOT NULL,
    "notes" TEXT,
    "createdById" TEXT NOT NULL,
    "approvedById" TEXT,
    "approvedAt" TIMESTAMP(3),
    "sharedAt" TIMESTAMP(3),
    "sharedByStaffId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "quotations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quotation_items" (
    "id" TEXT NOT NULL,
    "quotationId" TEXT NOT NULL,
    "packageId" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "unitPrice" DECIMAL(12,2) NOT NULL,
    "totalPrice" DECIMAL(12,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "orderIndex" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "quotation_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_drafts" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "authorStaffId" TEXT NOT NULL,
    "type" "AiDraftType" NOT NULL DEFAULT 'CUSTOMER_REPLY',
    "language" TEXT NOT NULL DEFAULT 'en',
    "promptSummary" TEXT,
    "suggestedText" TEXT NOT NULL,
    "missingInformation" TEXT[],
    "sourcePackageIds" TEXT[],
    "modelProvider" TEXT NOT NULL DEFAULT 'openai',
    "modelName" TEXT NOT NULL DEFAULT 'gpt-4o-mini',
    "reviewStatus" "AiDraftReviewStatus" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_drafts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "actorId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "metadata" JSONB,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "countries" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "isoCode" VARCHAR(3) NOT NULL,
    "slug" TEXT NOT NULL,
    "flagEmoji" VARCHAR(16),
    "flagUrl" TEXT,
    "coverImageUrl" TEXT,
    "shortIntro" TEXT NOT NULL,
    "detailedDescription" TEXT,
    "coverageStatus" "CountryCoverageStatus" NOT NULL DEFAULT 'ACTIVE',
    "isFeatured" BOOLEAN NOT NULL DEFAULT false,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "seoTitle" TEXT,
    "seoDescription" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "countries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "visa_services" (
    "id" TEXT NOT NULL,
    "countryId" TEXT NOT NULL,
    "category" "VisaCategory" NOT NULL,
    "customCategoryLabel" TEXT,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "shortDescription" TEXT NOT NULL,
    "fullDescription" TEXT NOT NULL,
    "eligibilityInfo" TEXT,
    "applicationProcessSteps" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "estimatedProcessingTime" TEXT,
    "agencyServiceFee" DECIMAL(12,2),
    "governmentFeeInfo" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "importantNotes" TEXT,
    "disclaimer" TEXT NOT NULL DEFAULT 'Information is provided for general guidance. Visa requirements and decisions are determined by the relevant authorities and may change.',
    "informationSourceUrl" TEXT,
    "lastVerifiedAt" TIMESTAMP(3),
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "isFeatured" BOOLEAN NOT NULL DEFAULT false,
    "publicationStatus" "VisaPublicationStatus" NOT NULL DEFAULT 'DRAFT',
    "serviceStatus" "AgencyServiceStatus" NOT NULL DEFAULT 'ACCEPTING_INQUIRIES',
    "seoTitle" TEXT,
    "seoDescription" TEXT,
    "createdById" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "visa_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "visa_service_requirements" (
    "id" TEXT NOT NULL,
    "visaServiceId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "isMandatory" BOOLEAN NOT NULL DEFAULT true,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "visa_service_requirements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "visa_inquiries" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "countryId" TEXT NOT NULL,
    "visaServiceId" TEXT,
    "category" "VisaCategory" NOT NULL,
    "fullName" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "message" TEXT,
    "consentGiven" BOOLEAN NOT NULL DEFAULT true,
    "source" "LeadSource" NOT NULL DEFAULT 'WEBSITE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "visa_inquiries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "staff_users_email_key" ON "staff_users"("email");

-- CreateIndex
CREATE INDEX "staff_users_role_status_idx" ON "staff_users"("role", "status");

-- CreateIndex
CREATE INDEX "packages_category_destination_isArchived_idx" ON "packages"("category", "destination", "isArchived");

-- CreateIndex
CREATE INDEX "leads_trackingCode_idx" ON "leads"("trackingCode");

-- CreateIndex
CREATE INDEX "leads_category_stage_assignedToId_idx" ON "leads"("category", "stage", "assignedToId");

-- CreateIndex
CREATE INDEX "leads_createdAt_idx" ON "leads"("createdAt");

-- CreateIndex
CREATE INDEX "lead_notes_leadId_idx" ON "lead_notes"("leadId");

-- CreateIndex
CREATE INDEX "follow_up_tasks_assignedToId_status_dueAt_idx" ON "follow_up_tasks"("assignedToId", "status", "dueAt");

-- CreateIndex
CREATE INDEX "quotations_leadId_status_idx" ON "quotations"("leadId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "quotations_quoteNumber_revision_key" ON "quotations"("quoteNumber", "revision");

-- CreateIndex
CREATE INDEX "quotation_items_quotationId_idx" ON "quotation_items"("quotationId");

-- CreateIndex
CREATE INDEX "ai_drafts_leadId_idx" ON "ai_drafts"("leadId");

-- CreateIndex
CREATE INDEX "audit_logs_entityType_entityId_idx" ON "audit_logs"("entityType", "entityId");

-- CreateIndex
CREATE INDEX "audit_logs_createdAt_idx" ON "audit_logs"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "countries_name_key" ON "countries"("name");

-- CreateIndex
CREATE UNIQUE INDEX "countries_isoCode_key" ON "countries"("isoCode");

-- CreateIndex
CREATE UNIQUE INDEX "countries_slug_key" ON "countries"("slug");

-- CreateIndex
CREATE INDEX "countries_coverageStatus_isFeatured_displayOrder_idx" ON "countries"("coverageStatus", "isFeatured", "displayOrder");

-- CreateIndex
CREATE INDEX "visa_services_countryId_publicationStatus_serviceStatus_idx" ON "visa_services"("countryId", "publicationStatus", "serviceStatus");

-- CreateIndex
CREATE INDEX "visa_services_category_publicationStatus_isFeatured_idx" ON "visa_services"("category", "publicationStatus", "isFeatured");

-- CreateIndex
CREATE UNIQUE INDEX "visa_services_countryId_slug_key" ON "visa_services"("countryId", "slug");

-- CreateIndex
CREATE INDEX "visa_service_requirements_visaServiceId_displayOrder_idx" ON "visa_service_requirements"("visaServiceId", "displayOrder");

-- CreateIndex
CREATE INDEX "visa_inquiries_leadId_idx" ON "visa_inquiries"("leadId");

-- CreateIndex
CREATE INDEX "visa_inquiries_countryId_category_idx" ON "visa_inquiries"("countryId", "category");

-- CreateIndex
CREATE INDEX "visa_inquiries_visaServiceId_idx" ON "visa_inquiries"("visaServiceId");

-- CreateIndex
CREATE INDEX "visa_inquiries_createdAt_idx" ON "visa_inquiries"("createdAt");

-- AddForeignKey
ALTER TABLE "leads" ADD CONSTRAINT "leads_assignedToId_fkey" FOREIGN KEY ("assignedToId") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lead_notes" ADD CONSTRAINT "lead_notes_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "leads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lead_notes" ADD CONSTRAINT "lead_notes_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "staff_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follow_up_tasks" ADD CONSTRAINT "follow_up_tasks_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "leads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follow_up_tasks" ADD CONSTRAINT "follow_up_tasks_assignedToId_fkey" FOREIGN KEY ("assignedToId") REFERENCES "staff_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "leads"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "staff_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotations" ADD CONSTRAINT "quotations_sharedByStaffId_fkey" FOREIGN KEY ("sharedByStaffId") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotation_items" ADD CONSTRAINT "quotation_items_quotationId_fkey" FOREIGN KEY ("quotationId") REFERENCES "quotations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotation_items" ADD CONSTRAINT "quotation_items_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "packages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_drafts" ADD CONSTRAINT "ai_drafts_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "leads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_drafts" ADD CONSTRAINT "ai_drafts_authorStaffId_fkey" FOREIGN KEY ("authorStaffId") REFERENCES "staff_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_services" ADD CONSTRAINT "visa_services_countryId_fkey" FOREIGN KEY ("countryId") REFERENCES "countries"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_services" ADD CONSTRAINT "visa_services_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_services" ADD CONSTRAINT "visa_services_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "staff_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_service_requirements" ADD CONSTRAINT "visa_service_requirements_visaServiceId_fkey" FOREIGN KEY ("visaServiceId") REFERENCES "visa_services"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_inquiries" ADD CONSTRAINT "visa_inquiries_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "leads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_inquiries" ADD CONSTRAINT "visa_inquiries_countryId_fkey" FOREIGN KEY ("countryId") REFERENCES "countries"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visa_inquiries" ADD CONSTRAINT "visa_inquiries_visaServiceId_fkey" FOREIGN KEY ("visaServiceId") REFERENCES "visa_services"("id") ON DELETE SET NULL ON UPDATE CASCADE;
