"use client";
export const dynamic = "force-dynamic";

import { useEffect, useState } from "react";
import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";
import BalancesCard from "~~/components/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/StepsWizard";
import DrawStatusCard from "~~/components/dashboard/DrawStatusCard";
import RecentActivityCard from "~~/components/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/Skeleton";

export default function DashboardPage() {
  const [data, setData] = useState<DashboardMock | null>(null);

  useEffect(() => {
    // ⬇️ SIN .then porque no es una promesa
    const mock = fetchDashboardMock();
    setData(mock);
  }, []);

  // Loader mientras no hay datos
  if (!data) {
    return (
      <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
        <div className="space-y-4 lg:col-span-2">
          <Skeleton className="h-40" />
          <Skeleton className="h-28" />
          <Skeleton className="h-36" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-28" />
          <Skeleton className="h-40" />
        </div>
      </div>
    );
  }

  const {
    balances = { strkp: 0, strk: 0 },
    wizard = { hasStrkp: false, ticketsCount: 0, pendingPrize: 0, convertiblePrize: 0 },
    draw = { active: false, blocksRemaining: 0, progressPct: 0 },
    history = [],
    notifications = [],
  } = data || {};

  return (
    <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
      {/* Columna izquierda */}
      <div className="space-y-4 lg:col-span-2">
        <StepsWizard {...wizard} />
        <DrawStatusCard
          active={draw?.active ?? false}
          blocksRemaining={draw?.blocksRemaining ?? 0}
          progressPct={draw?.progressPct ?? 0}
        />
        <RecentActivityCard items={history} />
      </div>

      {/* Columna derecha */}
      <div className="space-y-4">
        <BalancesCard strkp={balances?.strkp ?? 0} strk={balances?.strk ?? 0} />
        <NotificationsCard list={notifications} />
      </div>
    </div>
  );
}
