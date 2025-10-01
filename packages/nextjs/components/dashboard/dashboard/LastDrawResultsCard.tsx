"use client";

import Card from "~~/components/dashboard/dashboard/Card";
import { LastDrawResults } from "~~/components/LastDrawResults";

interface LastDrawResultsCardProps {
  variant?: "card" | "full";
}

export default function LastDrawResultsCard({
  variant = "card",
}: LastDrawResultsCardProps) {
  if (variant === "card") {
    return (
      <Card className="p-6">
        <LastDrawResults />
      </Card>
    );
  }

  return (
    <div className="w-full">
      <LastDrawResults />
    </div>
  );
}
