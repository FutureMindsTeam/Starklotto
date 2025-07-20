import type { ISourceOptions } from "@tsparticles/engine";
import { loadCurvesPath } from "@tsparticles/path-curves";

/* ─────────── 1. Starfield  ─────────── */
export const starfield: ISourceOptions = {
  fullScreen: { enable: false },
  fpsLimit: 60,
  detectRetina: true,
  background: { color: "transparent" },
  particles: {
    number: { value: 120, density: { enable: true, width: 900 } },
    color: { value: ["#FFD600", "#FFF451", "#ffffff"] },
    links: { enable: false },
    move: { enable: true, speed: 0.3 },
    size: { value: 1 },
    opacity: { value: 0.4 },
  },
};

/* ─────────── 5. Hex Grid Stark  ─────────── */
export const hexGridStark: ISourceOptions = {
  ...starfield,
  particles: {
    ...starfield.particles,
    number: { value: 100, density: { enable: true, width: 900 } },
    color: { value: ["#FFD600", "#FFF451"] },
    size: { value: { min: 2, max: 3 } },
    opacity: {
      value: { min: 0.15, max: 0.5 },
      animation: { enable: true, speed: 0.5, sync: false },
    },
    links: {
      enable: true,
      distance: 70,
      color: "#FFD600",
      opacity: 0.25,
      width: 1.2,
    },
    move: { enable: true, speed: 0.12, straight: true },
  },
  interactivity: {
    events: {
      onHover: { enable: true, mode: "grab" },
      resize: { enable: true },
    },
    modes: {
      grab: {
        distance: 120,
        links: { opacity: 0.4, color: "#FFF451" },
      },
    },
  },
};

/* ───────────  Export agrupado ─────────── */
export const particlePresets = {
  starfield,
  hexGridStark,
} as const;

/* ───────────  Plugin Orbit ─────────── */
export async function loadOrbitPlugin(
  engine: import("@tsparticles/engine").Engine,
) {
  await loadCurvesPath(engine);
}
