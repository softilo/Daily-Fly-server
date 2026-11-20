import { describe, expect, it, vi, beforeEach } from 'vitest';
import { DashboardService } from './dashboard.service.js';
import { PrismaService } from '../../database/prisma.service.js';
import { LeadStage, QuotationStatus } from '../../generated/prisma/client.js';

describe('DashboardService', () => {
  let service: DashboardService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      lead: {
        groupBy: vi.fn(),
      },
      quotation: {
        groupBy: vi.fn(),
        aggregate: vi.fn(),
      },
      package: {
        count: vi.fn(),
      },
      followUpTask: {
        count: vi.fn(),
        findMany: vi.fn(),
      },
    };
    service = new DashboardService(prismaMock as unknown as PrismaService);
  });

  it('aggregates grouped lead stages and quotation statuses with zero defaults', async () => {
    prismaMock.lead.groupBy.mockResolvedValue([
      { stage: LeadStage.NEW, _count: { _all: 3 } },
      { stage: LeadStage.WON, _count: { _all: 2 } },
    ]);
    prismaMock.quotation.groupBy.mockResolvedValue([
      { status: QuotationStatus.APPROVED, _count: { _all: 4 } },
    ]);
    prismaMock.package.count.mockResolvedValue(5);
    prismaMock.followUpTask.count
      .mockResolvedValueOnce(6)
      .mockResolvedValueOnce(1);
    prismaMock.quotation.aggregate.mockResolvedValue({
      _sum: { grandTotal: 250000 },
    });
    prismaMock.followUpTask.findMany.mockResolvedValue([{ id: 'task-1' }]);

    const summary = await service.getSummary();

    expect(summary.leads).toEqual({
      total: 5,
      byStage: {
        NEW: 3,
        QUALIFIED: 0,
        QUOTED: 0,
        FOLLOW_UP: 0,
        WON: 2,
        LOST: 0,
      },
    });
    expect(summary.quotations).toEqual({
      total: 4,
      draft: 0,
      approved: 4,
      draftCount: 0,
      approvedCount: 4,
      wonRevenue: 250000,
    });
    expect(summary.followUps).toEqual({
      openCount: 6,
      overdueCount: 1,
      upcomingTasks: [{ id: 'task-1' }],
    });
    expect(summary.packages).toEqual({ activeCount: 5 });
  });
});
