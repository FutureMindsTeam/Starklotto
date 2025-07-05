"use client";

import {
  CubeIcon,
  HomeIcon,
  ChartBarIcon,
  UsersIcon,
  Cog6ToothIcon,
  ShieldCheckIcon,
  LockClosedIcon,
  EyeIcon,
  UserIcon,
} from "@heroicons/react/24/solid";
import SettingsCard from "../admin-panel/SettingsCard";
import DrawsCard from "../../app/admin/DrawsCard";
import StatisticsCard from "../../app/admin/statisticsCard";
import UsersCards from "../../app/admin/UsersCard";

export default function AdminHeader() {
  return (
    <div className="min-h-screen bg-black text-white">
      <header className="border-b border-gray-800 bg-black px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-8">
            <div className="flex items-center">
              <CubeIcon className="mr-2 h-6 w-6 text-purple-600" />
              <span className="text-lg font-bold">StarkLotto Admin</span>
            </div>

            <nav className="flex items-center space-x-6">
              <a
                href="#"
                className="flex items-center space-x-2 text-purple-500"
              >
                <HomeIcon className="h-5 w-5" />
                <span>Dashboard</span>
              </a>

              <a
                href="#"
                className="flex items-center space-x-2 text-gray-400 hover:text-white"
              >
                <ChartBarIcon className="h-5 w-5" />
                <span>Draws</span>
              </a>

              <a
                href="#"
                className="flex items-center space-x-2 text-gray-400 hover:text-white"
              >
                <UsersIcon className="h-5 w-5" />
                <span>Users</span>
              </a>

              <a
                href="#"
                className="flex items-center space-x-2 text-gray-400 hover:text-white"
              >
                <Cog6ToothIcon className="h-5 w-5" />
                <span>Settings</span>
              </a>
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            <div className="flex items-center rounded-full bg-gray-900 px-4 py-1.5 text-sm">
              <ShieldCheckIcon className="mr-2 h-4 w-4 text-blue-400" />
              <span>Secure</span>
            </div>

            <div className="flex items-center rounded-full bg-purple-900 px-4 py-1.5 text-sm">
              <LockClosedIcon className="mr-2 h-4 w-4 text-purple-400" />
              <span>Encrypted</span>
            </div>

            <button className="flex items-center rounded-full border border-gray-700 px-4 py-1.5 text-sm hover:bg-gray-800">
              <EyeIcon className="mr-2 h-4 w-4" />
              <span>View Site</span>
            </button>

            <button className="flex items-center rounded-full px-4 py-1.5 text-sm hover:bg-gray-800">
              <UserIcon className="mr-2 h-4 w-4" />
              <span>Admin</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content - Only the title section as shown in the image */}
      <main className="px-8 py-10">
        <div>
          <h1 className="text-4xl font-bold">Administration Panel</h1>
          <p className="text-gray-400">
            Welcome to the StarkLotto administration panel
          </p>

          {/* Grid de tarjetas (llama las tarjetas) */}
          <div className="grid grid-cols-[repeat(auto-fit,minmax(220px,1fr))] gap-2">
            <SettingsCard />
            <DrawsCard />
            <UsersCards />
            <StatisticsCard />
          </div>
        </div>
      </main>
    </div>
  );
}
