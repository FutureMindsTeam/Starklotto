export type ActivityItem = {
  id: string;
  amount: number;
  unit: "STRKP" | "STRK";
  status: "pending" | "won" | "lost";
  when: string;
};

export type NotificationItem = {
  id: string;
  type: "prize" | "draw";
  title: string;
  desc: string;
  cta?: { label: string; href: string };
};

export type DashboardMock = {
  balances: { strkp: number; strk: number };
  wizard: {
    hasStrkp: boolean;
    ticketsCount: number;
    pendingPrize: number;
    convertiblePrize: number;
  };
  draw: {
    active: boolean;
    blocksRemaining: number | null;
    progressPct: number;
  };
  history: ActivityItem[];
  notifications: NotificationItem[];
};

const base: DashboardMock = {
  balances: { strkp: 123.45, strk: 0.78 },
  wizard: {
    hasStrkp: true,
    ticketsCount: 2,
    pendingPrize: 12.5,
    convertiblePrize: 0,
  },
  draw: { active: true, blocksRemaining: 134, progressPct: 73 },
  history: [
    {
      id: "a1",
      amount: 5,
      unit: "STRKP",
      status: "pending",
      when: "2 hours ago",
    },
    { id: "a2", amount: 12.5, unit: "STRKP", status: "won", when: "1 day ago" },
    { id: "a3", amount: 3, unit: "STRKP", status: "lost", when: "2 days ago" },
  ],
  notifications: [
    {
      id: "n1",
      type: "prize",
      title: "Pending Prize to Claim",
      desc: "You have 12.5 STRKP waiting to be claimed",
      cta: { label: "Claim Now", href: "/claims" },
    },
    {
      id: "n2",
      type: "draw",
      title: "New Draw Starting",
      desc: "Draw #156 will begin in 2 hours",
      cta: { label: "View Details", href: "/draws" },
    },
  ],
};

export function fetchDashboardMock(): DashboardMock {
  return base;
}
