import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";

// El componente que estamos testeando
import TokenMint from "~~/components/token-mint";

// Moqueos de los hooks que usa el componente
vi.mock("~~/hooks/useAccount", () => ({
  // useAccount retorna un objeto { address }
  useAccount: () => ({ address: "0xUSER" }),
}));

vi.mock("~~/hooks/scaffold-stark/useScaffoldStrkBalance", () => ({
  default: () => ({
    // Simulamos un saldo de 100 STRK 
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

describe("<TokenMint />", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("muestra el fee dinámico y calcula correctamente feeAmount y mintedAmount", async () => {
    render(<TokenMint />);

    // 1) Verificar que en el detalle aparece "Mint Fee (0.50%)"
    expect(
      screen.getByText(/Mint Fee \(0\.5%\)/, { exact: false })
    ).toBeInTheDocument();

    // 2) Cambiar el input a "10"
    const input = screen.getByPlaceholderText("0.0");
    fireEvent.change(input, { target: { value: "10" } });

    // 3) Verificar que el botón ahora está habilitado
    const button = screen.getByRole("button", { name: /Mint STRKP/i });
    expect(button).not.toBeDisabled();

    // 4) Calcular a mano:
    //    feeAmount = 10 * (0.005) / 100? No, feePercent ya es 0.005 ⇒ feeAmount = 10 * 0.005 = 0.05
    //    mintedAmount = 10 * 1 - 0.05 = 9.95
    // Verificar que la UI muestra estos valores
    await waitFor(() => {
      // El campo "You will receive" arriba de la flecha
      expect(screen.getByText("9.950000")).toBeInTheDocument();
      // El detalle en la sección de fee
      expect(screen.getByText("0.050000 STRK")).toBeInTheDocument();
    });
  });
});
