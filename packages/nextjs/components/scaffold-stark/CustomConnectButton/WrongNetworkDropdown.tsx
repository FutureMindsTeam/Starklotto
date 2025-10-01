import { NetworkOptions } from "./NetworkOptions";
import {
  ArrowLeftEndOnRectangleIcon,
  ChevronDownIcon,
} from "@heroicons/react/24/outline";
import { useDisconnect } from "@starknet-react/core";

export const WrongNetworkDropdown = () => {
  const { disconnect } = useDisconnect();

  return (
    <div className="dropdown dropdown-end mr-2">
      <label
        tabIndex={0}
        className="group relative flex items-center gap-2 px-4 py-2 rounded-xl border border-red-500/30 bg-red-500/10 backdrop-blur-md hover:bg-red-500/20 hover:border-red-500/50 transition-all duration-300 font-medium cursor-pointer"
      >
        <span className="text-sm text-red-400 group-hover:text-red-300 transition-colors">Wrong network</span>
        <ChevronDownIcon className="h-4 w-4 text-red-400 group-hover:text-red-300 transition-colors" />
      </label>

      <ul
        tabIndex={0}
        className="dropdown-content menu p-2 mt-1 rounded-xl border border-white/10 bg-white/5 backdrop-blur-md shadow-xl gap-1"
        style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
      >
        {/* TODO: reinstate if needed */}
        {/* <NetworkOptions /> */}
        <li>
          <button
            className="flex items-center gap-3 px-4 py-2.5 text-left hover:bg-red-500/10 transition-all duration-200 text-red-400 hover:text-red-300 rounded-lg"
            type="button"
            onClick={() => disconnect()}
          >
            <ArrowLeftEndOnRectangleIcon className="h-4 w-4" />
            <span className="text-sm font-medium">Disconnect</span>
          </button>
        </li>
      </ul>
    </div>
  );
};
