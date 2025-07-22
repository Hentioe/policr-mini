export function findMaxCount(points: ServerData.StatsPoint[]): number {
  return Math.max(...points.map((p) => p.count || 0));
}

export function findFirstCategorizedPoints(points: ServerData.StatsPoint[]): ServerData.StatsPoint[] {
  const exists = points.find((p) =>
    p.status === "approved" || p.status === "incorrect" || p.status === "timeout" || p.status === "other"
  );

  if (exists != null) {
    return points.filter((p) => p.status === exists.status);
  }

  return [];
}

export type Totals = {
  passes: number;
  fails: number;
};

export function calculateTotals(points: ServerData.StatsPoint[]): Totals {
  const totals: Totals = { passes: 0, fails: 0 };

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
