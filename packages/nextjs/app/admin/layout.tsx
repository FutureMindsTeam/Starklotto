import { ReactNode } from "react";
//import Sidebar from "~~/layout/Sidebar";
//import Topbar from "~~/layout/Topbar";

export default function AdminLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return (
    <div className="w-full h-screen overflow-x-hidden flex">
      {/* <Sidebar style={{ flex: 1.3 }} /> */}
      <main className="w-full flex flex-col gap-2" style={{ flex: 5 }}>
        {/* <Topbar /> */}
        <main className="w-full h-full overflow-x-hidden text-white p-2">
          {children}
        </main>
      </main>
    </div>
  );
}
