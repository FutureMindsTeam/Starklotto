"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useAccount } from "~~/hooks/useAccount";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { notification } from "~~/utils/scaffold-stark";
import { CustomConnectButton } from "~~/components/scaffold-stark/CustomConnectButton";
import Header from "~~/components/landing-page/layout/hader";
import Link from "next/link";
import { useDisconnect } from "@starknet-react/core";

const AdminLotteryPage = () => {
  // State hooks at the top
  const [isAdmin, setIsAdmin] = useState(false);
  const [isCheckingAdmin, setIsCheckingAdmin] = useState(true);
  const [duration, setDuration] = useState("");
  const [price, setPrice] = useState("");
  const [confirmAction, setConfirmAction] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const { disconnect } = useDisconnect();

  // Remove enable toggles - backend will handle when actions are available

  // Numeric validation
  const durationValid = useMemo(() => {
    if (!duration) return false;
    const n = Number(duration);
    return Number.isInteger(n) && n > 0;
  }, [duration]);

  const priceValid = useMemo(() => {
    if (!price) return false;
    const n = Number(price);
    return Number.isFinite(n) && n > 0;
  }, [price]);

  // All hooks at the top level
  const { address, isConnected } = useAccount();
  
  // Contract read hook - always call it, but use 'enabled' to control execution
  const { data: ownerAddress } = useScaffoldReadContract({
    contractName: "Lottery",
    functionName: "owner",
    args: [],
    enabled: isConnected && !!address,
  });

  // Admin override via env for testing/demo
  const adminOverride = useMemo(() => {
    const overrideFlag = process.env.NEXT_PUBLIC_ADMIN_OVERRIDE === 'true';
    const overrideAddress = (process.env.NEXT_PUBLIC_ADMIN_ADDRESS || '').toLowerCase();
    const userAddr = (address || '').toLowerCase();
    return overrideFlag || (overrideAddress && overrideAddress === userAddr);
  }, [address]);

  // Remaining blocks (read-only) PLACEHOLDER - update function name when available
  const remainingBlocksText = useMemo(() => {
    return "N/A";
  }, []);

  // Contract write hooks - configured per function
  const { sendAsync: sendSetDuration } = useScaffoldWriteContract({
    contractName: "Lottery",
    functionName: "setDurationBlocks",
  } as any);
  const { sendAsync: sendSetPrice } = useScaffoldWriteContract({
    contractName: "Lottery",
    functionName: "setTicketPrice",
  } as any);
  const { sendAsync: sendStart } = useScaffoldWriteContract({
    contractName: "Lottery",
    functionName: "startNewLottery",
  } as any);
  const { sendAsync: sendEnd } = useScaffoldWriteContract({
    contractName: "Lottery",
    functionName: "endLottery",
  } as any);

  // Admin check effect
  useEffect(() => {
    const checkAdminStatus = async () => {
      try {
        setIsCheckingAdmin(true);

        // Honor override first for local testing/demo
        if (adminOverride) {
          setIsAdmin(true);
          return;
        }
        

        if (!isConnected || !address) {
          setIsAdmin(false);
          return;
        }

        if (!ownerAddress) {
          setIsAdmin(false);
          return;
        }

        const isOwner = ownerAddress.toString().toLowerCase() === address.toLowerCase();
        setIsAdmin(isOwner);
      } catch (error) {
        console.error('Error checking admin status:', error);
        setIsAdmin(false);
      } finally {
        setIsCheckingAdmin(false);
      }
    };

    checkAdminStatus();
  }, [ownerAddress, address, isConnected, adminOverride]);

  // Show loading state while checking admin status
  if (isCheckingAdmin) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4">Verifying admin access...</p>
        </div>
      </div>
    );
  }

  const handleAction = async (action: string) => {
    if (!isConnected || !address) return;
    
    try {
      setIsLoading(true);
      
      switch (action) {
        case 'setDuration':
          if (!durationValid) {
            notification.error("Invalid");
            break;
          }
          await sendSetDuration({ args: [BigInt(duration || '0')] } as any);
          notification.success("Success");
          setDuration("");
          break;
          
        case 'setPrice':
          if (!priceValid) {
            notification.error("Invalid");
            break;
          }
          await sendSetPrice({ args: [BigInt(price || '0')] } as any);
          notification.success("Success");
          setPrice("");
          break;
          
        case 'startLottery':
          await sendStart();
          notification.success("Success");
          break;
          
        case 'endLottery':
          await sendEnd();
          notification.success("Success");
          break;
      }
      
      setConfirmAction(null);
    } catch (error) {
      console.error("Error executing action", error);
      notification.error("Error");
    } finally {
      setIsLoading(false);
    }
  };


  const renderConfirmDialog = (title: string, description: string, onConfirm: () => void, onCancel: () => void) => (
    <div className="fixed inset-0 z-50">
      <div className="fixed inset-0 bg-black/70 backdrop-blur-sm" onClick={onCancel} />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <div
          className="w-full max-w-md rounded-xl border border-white/10 bg-[#191c2a] text-white shadow-2xl"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="p-5">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xl font-bold">{title}</h3>
              <button
                className="text-white/60 hover:text-white transition"
                onClick={onCancel}
                aria-label="Close"
              >
                ✕
              </button>
            </div>
            <p className="text-white/80 mb-6">{description}</p>
            <div className="flex justify-end gap-3">
              <button
                className="px-4 py-2 rounded-md border border-white/15 text-white/90 hover:bg-white/5"
                onClick={onCancel}
                disabled={isLoading}
              >
                Cancel
              </button>
              <button
                className="px-4 py-2 rounded-md font-semibold text-white bg-gradient-to-r from-[#8A3FFC] to-[#9B51E0] hover:opacity-90"
                onClick={onConfirm}
                disabled={isLoading}
              >
                {isLoading ? 'Processing...' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderActionConfirmation = (action: string, message?: string) => (
    <div className="fixed inset-0 z-50">
      <div className="fixed inset-0 bg-black/70 backdrop-blur-sm" onClick={() => setConfirmAction(null)} />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <div
          className="w-full max-w-md rounded-xl border border-white/10 bg-[#191c2a] text-white shadow-2xl"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="p-5">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xl font-bold">Confirm Action</h3>
              <button
                className="text-white/60 hover:text-white transition"
                onClick={() => setConfirmAction(null)}
                aria-label="Close"
              >
                ✕
              </button>
            </div>
            <p className="text-white/80 mb-6">{message || 'Are you sure you want to proceed with this action?'}</p>
            <div className="flex justify-end gap-3">
              <button
                className="px-4 py-2 rounded-md border border-white/15 text-white/90 hover:bg-white/5"
                onClick={() => setConfirmAction(null)}
                disabled={isLoading}
              >
                Cancel
              </button>
              <button
                className="px-4 py-2 rounded-md font-semibold text-black bg-starkYellow hover:bg-starkYellow-light"
                onClick={() => handleAction(action)}
                disabled={isLoading}
              >
                {isLoading ? 'Processing...' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  if (!isConnected) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Please connect your wallet</h2>
          <div className="flex justify-center">
            <CustomConnectButton />
          </div>
        </div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-2">Access Denied</h2>
          <p className="mb-2">You don&apos;t have permission to access this page.</p>
          <div className="mt-4 text-sm opacity-80">
            <p>Connected: {address}</p>
            <p>Owner: {ownerAddress ? ownerAddress.toString() : 'Loading...'}</p>
            <p>Override: {adminOverride ? 'enabled' : 'disabled'}</p>
          </div>
          <div className="mt-6 flex items-center justify-center gap-3">
            <Link href="/" className="px-4 py-2 rounded-md border border-white/15 text-white/90 hover:bg-white/5">Back to Home</Link>
            <button className="px-4 py-2 rounded-md bg-starkYellow text-black hover:bg-starkYellow-light" onClick={() => disconnect()}>Disconnect</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col bg-[#101326] text-white min-h-screen">
      <Header />
      {/* Hero-like header to match home aesthetics */}
      <section className="relative flex items-center justify-center min-h-[40svh] overflow-hidden pt-20">
        <div className="absolute inset-0 -z-20 bg-gradient-to-b from-heroDarker to-heroDark" />
        <div
          className="absolute inset-0 -z-10 opacity-25"
          style={{
            background:
              "radial-gradient(circle at 50% 30%, rgba(255,214,0,0.25), transparent 60%)",
          }}
        />
        <div className="relative z-10 w-full px-6 sm:px-10 lg:px-16 py-10">
          <div className="flex flex-col items-center justify-center text-center max-w-6xl mx-auto">
            <div className="absolute top-4 right-4 flex items-center gap-3">
              <Link href="/" className="px-4 py-2 rounded-md border border-white/15 text-white/90 hover:bg-white/5">Back to Home</Link>
              <button className="px-4 py-2 rounded-md bg-starkYellow text-black hover:bg-starkYellow-light" onClick={() => disconnect()}>Disconnect</button>
            </div>
            <h1 className="text-3xl md:text-5xl font-extrabold leading-tight">
              <span className="bg-clip-text text-transparent bg-gradient-to-r from-starkYellow via-starkYellow-light to-white bg-[length:400%_100%] animate-slower-shimmer">
                Lottery Administration
              </span>
            </h1>
            <p className="mt-3 text-white/80 max-w-2xl">
              Configure parameters and control the lifecycle of on-chain lottery rounds
            </p>
          </div>
        </div>
        <div className="absolute bottom-0 left-0 w-full h-12 bg-gradient-to-t from-heroDark to-transparent pointer-events-none" />
      </section>

      {/* Content */}
      <div className="container mx-auto px-4 py-10">
        {/* Current Owner - moved to top */}
        <div className="mb-8">
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg max-w-md">
            <div className="p-5">
              <h2 className="text-lg font-semibold text-white">Current Owner</h2>
              <p className="text-sm text-white/70 break-all mt-1">Current owner address: {ownerAddress ? ownerAddress.toString() : "Loading..."}</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Duration Configuration */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div>
                <h2 className="text-lg font-semibold text-white">Duration Configuration</h2>
                <p className="text-sm text-white/60">Set the duration of each lottery in blocks</p>
              </div>

              <div className="form-control w-full mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Duration</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="number"
                    placeholder="Enter duration"
                    className={`input flex-1 bg-black/30 text-white placeholder:text-white/40 ${duration && !durationValid ? 'input-error' : ''}`}
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    disabled={isLoading}
                    min={1}
                  />
                  <button
                    className="btn border-0 text-black font-semibold bg-starkYellow hover:bg-starkYellow-light"
                    onClick={() => setConfirmAction('setDuration')}
                    disabled={!durationValid || isLoading}
                  >
                    Save
                  </button>
                </div>
                {duration && !durationValid && (
                  <span className="text-error text-sm mt-1">Enter a positive integer</span>
                )}
              </div>
            </div>
          </div>

          {/* Price Configuration */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div>
                <h2 className="text-lg font-semibold text-white">Price Configuration</h2>
                <p className="text-sm text-white/60">Set the price per ticket</p>
              </div>

              <div className="form-control w-full mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Price</span>
                </label>
                <div className="flex gap-2">
                  <input
                    type="number"
                    placeholder="Enter price"
                    className={`input flex-1 bg-black/30 text-white placeholder:text-white/40 ${price && !priceValid ? 'input-error' : ''}`}
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    disabled={isLoading}
                    min={1}
                  />
                  <button
                    className="btn border-0 text-black font-semibold bg-starkYellow hover:bg-starkYellow-light"
                    onClick={() => setConfirmAction('setPrice')}
                    disabled={!priceValid || isLoading}
                  >
                    Save
                  </button>
                </div>
                {price && !priceValid && (
                  <span className="text-error text-sm mt-1">Enter a positive number</span>
                )}
              </div>
            </div>
          </div>

          {/* Start New Lottery */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div>
                <h2 className="text-lg font-semibold text-white">Lottery Control</h2>
                <p className="text-sm text-white/60">Start a new lottery round</p>
              </div>
              <div className="mt-4 flex justify-center">
                <button
                  className="btn min-w-[180px] border border-starkYellow text-starkYellow-light bg-transparent hover:bg-transparent hover:shadow-[0_0_8px_0_rgba(255,214,0,0.6)]"
                  onClick={() => setConfirmAction('startLottery')}
                  disabled={isLoading}
                >
                  Start New Lottery
                </button>
              </div>
            </div>
          </div>

          {/* End Current Lottery */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div>
                <h2 className="text-lg font-semibold text-white">End Current Lottery</h2>
                <p className="text-sm text-white/60">End the current lottery round</p>
              </div>

              <div className="form-control w-full mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Remaining Blocks</span>
                </label>
                <input
                  type="text"
                  className="input w-full bg-black/30 text-white placeholder:text-white/40"
                  value={remainingBlocksText}
                  readOnly
                  disabled
                />
              </div>

              <div className="mt-4 flex justify-center">
                <button
                  className="btn min-w-[180px] border-0 text-white font-semibold bg-gradient-to-r from-red-500 to-rose-600 hover:opacity-90"
                  onClick={() => setConfirmAction('endLottery')}
                  disabled={isLoading}
                >
                  End Current Lottery
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Action confirmation */}
      {confirmAction && renderActionConfirmation(confirmAction, undefined)}
    </div>
  );
};

export default AdminLotteryPage;
