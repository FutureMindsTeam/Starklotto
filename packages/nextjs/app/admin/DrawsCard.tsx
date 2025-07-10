import { Trophy, ArrowRight } from "lucide-react";
import { Card, CardContent } from "~~/components/ui/card";
import { Button } from "~~/components/ui/button";
import Link from "next/link";

export default function DrawsCard() {
  return (
    <Card className="w-full max-w-xs bg-black/70 border border-zinc-800 text-white p-6 rounded-2xl shadow-md text-center">
      <CardContent className="flex flex-col items-center space-y-4">
        <div className="bg-[#e6c22b]/30 p-3 rounded-full">
          <Trophy className="w-8 h-8 text-[#e6c22b]" />
        </div>
        <h3 className="text-xl font-semibold">Draws</h3>
        <p className="text-base text-gray-400">Manage draws and results</p>

        <Link href="/admin/draws">
          <Button className="bg-purple-600 hover:bg-purple-700 text-sm py-2 rounded-md text-white flex items-center space-x-2">
            <span>Go to Draws</span>
            <span className="ml-1">→</span>
            {/* <ArrowRight className="h-4 w-4" /> */}
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}
