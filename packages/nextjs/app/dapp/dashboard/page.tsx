"use client";

import { useEffect, useState } from "react";
import BalancesCard from "~~/components/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/StepsWizard";
import DrawStatusCard from "~~/components/dashboard/DrawStatusCard";
import RecentActivityCard from "~~/components/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/Skeleton";
import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";

export default function DashboardPage() {
  const [data, setData] = useState<DashboardMock | null>(null);

  useEffect(() => {
    const mock = fetchDashboardMock();
    setData(mock);
  }, []);

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

  return (
    <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
      
      <div className="space-y-4 lg:col-span-2">
        <StepsWizard {...data.wizard} />
        <DrawStatusCard {...data.draw} />
        <RecentActivityCard items={data.history} />
      </div>

      
      <div className="space-y-4">
        <BalancesCard {...data.balances} />
        <NotificationsCard list={data.notifications} />
      </div>
    </div>
  );
}
