import { FC } from "react";

import { Settings } from "lucide-react";
import { useRouter } from "next/navigation";

const SettingsCard: FC = () => {
  const router = useRouter();

  return (
    <div className="w-full max-w-xs bg-black/70 border border-zinc-800 text-white p-6 rounded-2xl shadow-md text-center">
      <div className="flex flex-col items-center space-y-4">
        <div className="bg-[#8A3FFC]/30 p-3 rounded-full">
          <Settings className="w-8 h-8 text-[#8A3FFC]" />
        </div>
        <h2 className="text-xl font-semibold">Settings</h2>
        <p className="text-base text-gray-400">
          Manage all aspects of the system
        </p>
        <button
          className="bg-purple-600 hover:bg-purple-700 px-4 text-sm py-2 rounded-md text-white flex items-center space-x-2"
          onClick={() => router.push("/configure")}
        >
          <span>Go to Settings</span>
          <span className="ml-1">→</span>
        </button>
      </div>
    </div>
  );
};

export default SettingsCard;
