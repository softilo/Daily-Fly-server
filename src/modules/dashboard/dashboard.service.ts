import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service.js';
import { FollowUpStatus, LeadStage, QuotationStatus } from '../../generated/prisma/client.js';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary() {
    const now = new Date();

    const [
      leadStageGroups,
      quotationStatusGroups,
      activePackages,
      openFollowUps,
      overdueFollowUps,
      wonRevenueRaw,
      upcomingTasks,
    ] = await Promise.all([
      this.prisma.lead.groupBy({
        by: ['stage'],
        _count: { _all: true },
      }),
      this.prisma.quotation.groupBy({
        by: ['status'],
        where: {
          status: { in: [QuotationStatus.DRAFT, QuotationStatus.APPROVED] },
        },
        _count: { _all: true },
      }),
      this.prisma.package.count({ where: { isArchived: false } }),
      this.prisma.followUpTask.count({ where: { status: FollowUpStatus.OPEN } }),
      this.prisma.followUpTask.count({
        where: {
          status: FollowUpStatus.OPEN,
          dueAt: { lt: now },
        },
      }),
      this.prisma.quotation.aggregate({
        where: {
          status: QuotationStatus.APPROVED,
          lead: { stage: LeadStage.WON },
        },
        _sum: {
          grandTotal: true,
        },
      }),
      this.prisma.followUpTask.findMany({
        where: { status: FollowUpStatus.OPEN },
        orderBy: { dueAt: 'asc' },
        take: 5,
        include: {
          lead: {
            select: {
              id: true,
              customerName: true,
              customerPhone: true,
              stage: true,
            },
          },
          assignedTo: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      }),
    ]);

    const leadsByStage: Record<LeadStage, number> = {
      [LeadStage.NEW]: 0,
      [LeadStage.QUALIFIED]: 0,
      [LeadStage.QUOTED]: 0,
      [LeadStage.FOLLOW_UP]: 0,
      [LeadStage.WON]: 0,
      [LeadStage.LOST]: 0,
    };
    let totalLeads = 0;
    for (const row of leadStageGroups) {
      const count = row._count._all;
      leadsByStage[row.stage] = count;
      totalLeads += count;
    }

    let draftQuotes = 0;
    let approvedQuotes = 0;
    for (const row of quotationStatusGroups) {
      if (row.status === QuotationStatus.DRAFT) {
        draftQuotes = row._count._all;
      } else if (row.status === QuotationStatus.APPROVED) {
        approvedQuotes = row._count._all;
      }
    }

    return {
      leads: {
        total: totalLeads,
        byStage: leadsByStage,
      },
      quotations: {
        total: draftQuotes + approvedQuotes,
        draft: draftQuotes,
        approved: approvedQuotes,
        draftCount: draftQuotes,
        approvedCount: approvedQuotes,
        wonRevenue: Number(wonRevenueRaw._sum.grandTotal || 0),
      },
      followUps: {
        openCount: openFollowUps,
        overdueCount: overdueFollowUps,
        upcomingTasks: upcomingTasks ?? [],
      },
      packages: {
        activeCount: activePackages,
      },
      generatedAt: now.toISOString(),
    };
  }
}

