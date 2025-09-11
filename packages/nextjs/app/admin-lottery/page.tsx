"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useAccount } from "~~/hooks/useAccount";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { notification } from "~~/utils/scaffold-stark";
import { CustomConnectButton } from "~~/components/scaffold-stark/CustomConnectButton";
import Header from "~~/components/landing-page/layout/hader";

const AdminLotteryPage = () => {
  // State hooks at the top
  const [isAdmin, setIsAdmin] = useState(false);
  const [isCheckingAdmin, setIsCheckingAdmin] = useState(true);
  const [duration, setDuration] = useState("");
  const [price, setPrice] = useState("");
  const [confirmAction, setConfirmAction] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Per-section enable toggles (disabled by default)
  const [enabledSections, setEnabledSections] = useState({
    duration: false,
    price: false,
    start: false,
    end: false,
  });
  const [pendingEnable, setPendingEnable] = useState<keyof typeof enabledSections | null>(null);

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
  const { address, isConnected, isInitialized } = useAccount();
  
  // Contract read hook - always call it, but use 'enabled' to control execution
  const { data: ownerAddress } = useScaffoldReadContract({
    contractName: "Lottery",
    functionName: "owner",
    args: [],
    enabled: isInitialized && isConnected && !!address,
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

  // Contract write hooks - always call them at the top level
  const { writeContractAsync: setDurationBlocks } = useScaffoldWriteContract("Lottery");
  const { writeContractAsync: setTicketPrice } = useScaffoldWriteContract("Lottery");
  const { writeContractAsync: startNewLottery } = useScaffoldWriteContract("Lottery");
  const { writeContractAsync: endLottery } = useScaffoldWriteContract("Lottery");

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
        
        if (!isInitialized) {
          setIsAdmin(false);
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
  }, [ownerAddress, address, isConnected, isInitialized, adminOverride]);

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
            notification.error("Invalid", "Enter a valid positive integer for duration");
            break;
          }
          await setDurationBlocks({
            functionName: 'setDurationBlocks',
            args: [BigInt(duration || '0')],
          });
          notification.success("Success", "Duration updated successfully");
          setDuration("");
          break;
          
        case 'setPrice':
          if (!priceValid) {
            notification.error("Invalid", "Enter a valid positive number for price");
            break;
          }
          await setTicketPrice({
            functionName: 'setTicketPrice',
            args: [BigInt(price || '0')],
          });
          notification.success("Success", "Ticket price updated successfully");
          setPrice("");
          break;
          
        case 'startLottery':
          await startNewLottery({
            functionName: 'startNewLottery',
          });
          notification.success("Success", "New lottery started successfully");
          break;
          
        case 'endLottery':
          await endLottery({
            functionName: 'endLottery',
          });
          notification.success("Success", "Lottery ended successfully");
          break;
      }
      
      setConfirmAction(null);
    } catch (error) {
      console.error("Error executing action", error);
      notification.error("Error", "Failed to execute action");
    } finally {
      setIsLoading(false);
    }
  };

  const openEnableConfirmation = (section: keyof typeof enabledSections) => {
    setPendingEnable(section);
  };

  const confirmEnableSection = () => {
    if (!pendingEnable) return;
    setEnabledSections(prev => ({ ...prev, [pendingEnable]: true }));
    setPendingEnable(null);
    notification.info("Enabled", "Controls enabled. Proceed with caution.");
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
          <p className="mb-2">You don't have permission to access this page.</p>
          <div className="mt-4 text-sm opacity-80">
            <p>Connected: {address}</p>
            <p>Owner: {ownerAddress || 'Loading...'}</p>
            <p>Override: {adminOverride ? 'enabled' : 'disabled'}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col bg-[#101326] text-white min-h-screen">
      <Header />
      {/* Hero-like header to match home aesthetics */}
      <section className="relative flex items-center justify-center min-h-[32svh] overflow-hidden">
        <div className="absolute inset-0 -z-20 bg-gradient-to-b from-heroDarker to-heroDark" />
        <div
          className="absolute inset-0 -z-10 opacity-25"
          style={{
            background:
              "radial-gradient(circle at 50% 30%, rgba(255,214,0,0.25), transparent 60%)",
          }}
        />
        <div className="relative z-10 w-full px-6 sm:px-10 lg:px-16 py-10">
          <h1 className="text-3xl md:text-5xl font-extrabold leading-tight text-center">
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-starkYellow via-starkYellow-light to-white bg-[length:400%_100%] animate-slower-shimmer">
              Lottery Administration
            </span>
          </h1>
          <p className="mt-3 text-center text-white/80 max-w-2xl mx-auto">
            Configure parameters and control the lifecycle of on-chain lottery rounds
          </p>
        </div>
        <div className="absolute bottom-0 left-0 w-full h-12 bg-gradient-to-t from-heroDark to-transparent pointer-events-none" />
      </section>

      {/* Content */}
      <div className="container mx-auto px-4 py-10">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Duration Configuration */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-white">Duration Configuration</h2>
                  <p className="text-sm text-white/60">Set the duration of each lottery in blocks</p>
                </div>
                <button
                  className="px-3 py-1.5 text-sm rounded-md border border-starkYellow/40 text-starkYellow-light hover:bg-starkYellow/10 transition-colors"
                  onClick={() => openEnableConfirmation('duration')}
                  disabled={enabledSections.duration || isLoading}
                >
                  {enabledSections.duration ? 'Enabled' : 'Enable'}
                </button>
              </div>

              <div className="form-control w-full max-w-xs mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Duration (blocks)</span>
                </label>
                <input
                  type="number"
                  placeholder="Enter blocks"
                  className={`input w-full max-w-xs bg-black/30 text-white placeholder:text-white/40 ${duration && !durationValid ? 'input-error' : ''}`}
                  value={duration}
                  onChange={(e) => setDuration(e.target.value)}
                  disabled={!enabledSections.duration || isLoading}
                  min={1}
                />
                {duration && !durationValid && (
                  <span className="text-error text-sm mt-1">Enter a positive integer</span>
                )}
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  className="btn min-w-[150px] border-0 text-black font-semibold bg-starkYellow hover:bg-starkYellow-light"
                  onClick={() => setConfirmAction('setDuration')}
                  disabled={!enabledSections.duration || !durationValid || isLoading}
                >
                  Save Duration
                </button>
              </div>
            </div>
          </div>

          {/* Price Configuration */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-white">Price Configuration</h2>
                  <p className="text-sm text-white/60">Set the price per ticket</p>
                </div>
                <button
                  className="px-3 py-1.5 text-sm rounded-md border border-starkYellow/40 text-starkYellow-light hover:bg-starkYellow/10 transition-colors"
                  onClick={() => openEnableConfirmation('price')}
                  disabled={enabledSections.price || isLoading}
                >
                  {enabledSections.price ? 'Enabled' : 'Enable'}
                </button>
              </div>

              <div className="form-control w-full max-w-xs mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Price (wei)</span>
                </label>
                <input
                  type="number"
                  placeholder="Enter price in wei"
                  className={`input w-full max-w-xs bg-black/30 text-white placeholder:text-white/40 ${price && !priceValid ? 'input-error' : ''}`}
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  disabled={!enabledSections.price || isLoading}
                  min={1}
                />
                {price && !priceValid && (
                  <span className="text-error text-sm mt-1">Enter a positive number</span>
                )}
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  className="btn min-w-[150px] border-0 text-black font-semibold bg-starkYellow hover:bg-starkYellow-light"
                  onClick={() => setConfirmAction('setPrice')}
                  disabled={!enabledSections.price || !priceValid || isLoading}
                >
                  Save Price
                </button>
              </div>
            </div>
          </div>

          {/* Start New Lottery */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-white">Lottery Control</h2>
                  <p className="text-sm text-white/60">Start a new lottery round</p>
                </div>
                <button
                  className="px-3 py-1.5 text-sm rounded-md border border-starkYellow/40 text-starkYellow-light hover:bg-starkYellow/10 transition-colors"
                  onClick={() => openEnableConfirmation('start')}
                  disabled={enabledSections.start || isLoading}
                >
                  {enabledSections.start ? 'Enabled' : 'Enable'}
                </button>
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  className="btn min-w-[180px] border border-starkYellow text-starkYellow-light bg-transparent hover:bg-transparent hover:shadow-[0_0_8px_0_rgba(255,214,0,0.6)]"
                  onClick={() => setConfirmAction('startLottery')}
                  disabled={!enabledSections.start || isLoading}
                >
                  Start New Lottery
                </button>
              </div>
            </div>
          </div>

          {/* End Current Lottery */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-lg font-semibold text-white">End Current Lottery</h2>
                  <p className="text-sm text-white/60">End the current lottery round</p>
                </div>
                <button
                  className="px-3 py-1.5 text-sm rounded-md border border-starkYellow/40 text-starkYellow-light hover:bg-starkYellow/10 transition-colors"
                  onClick={() => openEnableConfirmation('end')}
                  disabled={enabledSections.end || isLoading}
                >
                  {enabledSections.end ? 'Enabled' : 'Enable'}
                </button>
              </div>

              <div className="form-control w-full max-w-xs mt-4">
                <label className="label">
                  <span className="label-text text-white/80">Remaining Blocks</span>
                </label>
                <input
                  type="text"
                  className="input w-full max-w-xs bg-black/30 text-white placeholder:text-white/40"
                  value={remainingBlocksText}
                  readOnly
                  disabled
                />
              </div>

              <div className="mt-4 flex justify-end">
                <button
                  className="btn min-w-[180px] border-0 text-white font-semibold bg-gradient-to-r from-red-500 to-rose-600 hover:opacity-90"
                  onClick={() => setConfirmAction('endLottery')}
                  disabled={!enabledSections.end || isLoading}
                >
                  End Current Lottery
                </button>
              </div>
            </div>
          </div>

          {/* Current Owner */}
          <div className="rounded-xl bg-white/5 backdrop-blur-md border border-white/10 shadow-lg">
            <div className="p-5">
              <h2 className="text-lg font-semibold text-white">Current Owner</h2>
              <p className="text-sm text-white/70 break-all mt-1">Current owner address: {ownerAddress || "Loading..."}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Enable section confirmation */}
      {pendingEnable && renderConfirmDialog(
        "Enable Controls",
        "These controls are disabled by default. Confirm you want to enable and proceed.",
        confirmEnableSection,
        () => setPendingEnable(null)
      )}

      {/* Action confirmation */}
      {confirmAction && renderActionConfirmation(confirmAction, undefined)}
    </div>
  );
};

export default AdminLotteryPage;
