import { renderHook, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";
import { useStarkPlayFee } from "../useStarkPlayFee";

// Mockeamos el módulo principal de hooks scaffold-stark
vi.mock("~~/hooks/scaffold-stark", () => ({
  useScaffoldReadContract: vi.fn(),
}));

// Importamos la función mockeada para manipular su comportamiento en los tests
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark";
const mockUseScaffoldReadContract = useScaffoldReadContract as unknown as ReturnType<typeof vi.fn>;

describe("useStarkPlayFee", () => {
  // Limpiamos mocks antes de cada test
  beforeEach(() => {
    vi.clearAllMocks();
  });

  /**
   * Simula el valor de retorno del hook useScaffoldReadContract.
   * @param data Valor simulado devuelto por el contrato (en basis points, bigint)
   * @param isLoading Estado de carga
   * @param error Error simulado, si aplica
   */
  const mockRead = (
    data: bigint | undefined,
    isLoading = false,
    error: unknown = undefined,
  ) => {
    mockUseScaffoldReadContract.mockReturnValue({
      data,
      isLoading,
      error,
      refetch: vi.fn(),
    });
  };

  it("convierte basis-points a porcentaje decimal", async () => {
    // Simulamos el valor 50n (0.5%)
    mockRead(50n, false);
    const { result } = renderHook(() => useStarkPlayFee());
    await waitFor(() => expect(result.current.isLoading).toBe(false));
    expect(result.current.feePercent).toBeCloseTo(0.005); // 0.5%
    expect(result.current.error).toBeUndefined();
  });

  it("muestra isLoading mientras carga", () => {
    // Simulamos el estado de carga
    mockRead(undefined, true);
    const { result } = renderHook(() => useStarkPlayFee());
    expect(result.current.isLoading).toBe(true);
    expect(result.current.feePercent).toBeUndefined();
  });

  it("expone error cuando falla la llamada", () => {
    // Simulamos un error al obtener el fee
    mockRead(undefined, false, new Error("RPC error"));
    const { result } = renderHook(() => useStarkPlayFee());
    expect(result.current.error).toBeDefined();
    expect(result.current.feePercent).toBeUndefined();
  });
});