type Point = ServerData.StatsPoint;
type Status = ServerData.StatsStatus;

export function findMaxCount(points: Point[]): number {
  return Math.max(...points.map((p) => p.count || 0));
}

export function findFirstCategorizedPoints(points: Point[]): Point[] {
  const exists = points.find((p) =>
    p.status === "approved" || p.status === "incorrect" || p.status === "timeout" || p.status === "other"
  );

  if (exists != null) {
    return points.filter((p) => p.status === exists.status);
  }

  return [];
}

export class Totals {
  passes: number;
  fails: number;

  constructor(passes: number, fails: number) {
    this.passes = passes;
    this.fails = fails;
  }

  isEmpty(): boolean {
    return this.passes === 0 && this.fails === 0;
  }
}

export function calculateTotals(points: Point[]): Totals {
  const totals = new Totals(0, 0);

  points.forEach((point) => {
    if (point.status === "approved") {
      totals.passes += point.count || 0;
    } else if (point.status === "incorrect" || point.status === "timeout" || point.status === "other") {
      // 目前来讲，除了 approved 以外的状态都是失败
      totals.fails += point.count || 0;
    }
  });

  return totals;
}

export function statusCount(points: Point[], status: Status): number[] {
  return points.filter((p) => p.status === status).map((p) => {
    if (p.count == null) {
      return 0;
    } else {
      return p.count;
    }
  });
}
