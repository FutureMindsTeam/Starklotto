import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";

// The component we are testing
import TokenMint from "~~/components/token-mint";

// Mocking the hooks used by the component
vi.mock("~~/hooks/useAccount", () => ({
  // useAccount returns an object { address }
  useAccount: () => ({ address: "0xUSER" }),
}));

vi.mock("~~/hooks/scaffold-stark/useScaffoldStrkBalance", () => ({
  default: () => ({
    // Simulates a 100 STRK balance
    value: BigInt("100000000000000000000"),
    formatted: "100.0",
  }),
}));

vi.mock("~~/hooks/scaffold-stark/useStarkPlayFee", () => ({
  useStarkPlayFee: () => ({
    feePercent: 0.005,
    isLoading: false,
    error: undefined,
    refetch: vi.fn(),
  }),
}));

vi.mock("~~/hooks/useStrkContract", () => ({
  useStrkContract: () => ({
    approveStrk: vi.fn(),
    strkAddress:
      "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    isReady: true,
  }),
}));

vi.mock("~~/hooks/scaffold-stark/useScaffoldWriteContract", () => ({
  useScaffoldWriteContract: () => ({
    writeContractAsync: vi.fn(),
    isPending: false,
  }),
}));

vi.mock("~~/hooks/scaffold-stark/useScaffoldReadContract", () => ({
  useScaffoldReadContract: () => ({
    data: BigInt("1000000000000000000000"), // 1000 TRKP balance
    isLoading: false,
  }),
}));

vi.mock("~~/hooks/scaffold-stark/useScaffoldEventHistory", () => ({
  useScaffoldEventHistory: () => ({
    data: [],
    isLoading: false,
  }),
}));

vi.mock("~~/hooks/useContractAddresses", () => ({
  useContractAddresses: () => ({
    StarkPlayVault: "0xVAULT",
    StarkPlayERC20: "0xTRKP",
    Strk: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    isValid: true,
  }),
}));

// Mock react-hot-toast
vi.mock("react-hot-toast", () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
    loading: vi.fn(),
    dismiss: vi.fn(),
  },
}));

// Mock Starknet React hooks that may be used indirectly
vi.mock("@starknet-react/core", () => ({
  useAccount: () => ({ address: "0xUSER", account: {} }),
  useNetwork: () => ({ chain: { id: "0x534e5f4d41494e" } }),
  useContract: () => ({}),
}));

describe("<TokenMint />", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("muestra el fee dinámico y calcula correctamente feeAmount y mintedAmount", async () => {
    render(<TokenMint />);

    // 1) Verify that the detail shows "Mint Fee (0.50%)"
    expect(
      screen.getByText(/Mint Fee \(0\.5%\)/, { exact: false }),
    ).toBeInTheDocument();

    // 2) Change the input to "10"
    const input = screen.getByPlaceholderText("0.0");
    fireEvent.change(input, { target: { value: "10" } });

    // 3) Verify that the button is now enabled
    const button = screen.getByRole("button", { name: /Mint \$TRKP/i });
    expect(button).not.toBeDisabled();

    // 4) Calculate manually:
    //    feeAmount = 10 * (0.005) / 100? No, feePercent ya es 0.005 ⇒ feeAmount = 10 * 0.005 = 0.05
    //    mintedAmount = 10 * 1 - 0.05 = 9.95
    // Verify that the UI shows these values
    await waitFor(() => {
      // The "You will receive" field above the arrow
      expect(screen.getByText("9.950000")).toBeInTheDocument();
      // The detail in the fee section
      expect(screen.getByText("0.050000 STRK")).toBeInTheDocument();
    });
  });
});
