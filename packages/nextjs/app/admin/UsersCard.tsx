import React from "react";
import { Users } from "lucide-react";
import Link from "next/link";

// Assuming you have a routes constant or configuration
const ROUTES = {
  USERS_MANAGEMENT: "/admin",
};

const UsersManagementCard = () => {
  return (
    <div className="w-full max-w-xs bg-black/70 border border-zinc-800 text-white p-6 rounded-2xl shadow-md text-center">
      <div className="flex flex-col items-center space-y-4">
        <div className="bg-[#00779c]/30 rounded-full p-3">
          <Users className="text-[#00779c] w-8 h-8" />
        </div>
        <h2 className="text-xl font-semibold">Users</h2>
        <p className="text-base text-gray-400">Manage system users</p>

        <Link
          href={ROUTES.USERS_MANAGEMENT}
          className="w-full flex justify-center"
          aria-label="Go to User Management"
        >
          <button className="bg-purple-600 hover:bg-purple-700 px-4 text-sm py-2 rounded-md text-white flex items-center space-x-2">
            <span>Go to Users</span>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="w-5 h-5 ml-2"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M14 5l7 7m0 0l-7 7m7-7H3"
              />
            </svg>
          </button>
        </Link>
      </div>
    </div>
  );
};

export default UsersManagementCard;
