import type { Metadata } from "next";
import { ScaffoldStarkAppWithProviders } from "~~/components/ScaffoldStarkAppWithProviders";
import "~~/styles/globals.css";
import { ThemeProvider } from "~~/components/ThemeProvider";
import Header from "~~/components/Header";
/* import Footer from "~~/components/Footer"; */

export const metadata: Metadata = {
  title: "StarkLotto",
  description: "Fast track your starknet journey",
  icons: "/logo.ico",
};

const ScaffoldStarkApp = ({ children }: { children: React.ReactNode }) => {
  return (
    <html suppressHydrationWarning lang="en">
      <body
        suppressHydrationWarning
        className="bg-[#0D0D0D] min-h-screen flex flex-col"
      >
        <ThemeProvider enableSystem>
          <ScaffoldStarkAppWithProviders>
            {/* <Header /> */}
            <main className="flex-grow">{children}</main>
            {/* <Footer /> */}
          </ScaffoldStarkAppWithProviders>
        </ThemeProvider>
      </body>
    </html>
  );
};

export default ScaffoldStarkApp;
