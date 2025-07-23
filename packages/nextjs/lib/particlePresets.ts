import type { ISourceOptions } from "@tsparticles/engine";
import { loadCurvesPath } from "@tsparticles/path-curves";

/* ─────────── 1. Starfield ─────────── */
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


export const casinoGlitz: ISourceOptions = {
  ...starfield,
  particles: {
    ...starfield.particles,
    number: { value: 80, density: { enable: true, width: 900 } },
    shape: {
      type: ["circle", "star"],
      options: { star: { sides: 5 } },
    },
    color: { value: ["#FFD600", "#FF004C", "#FFFFFF"] },

    size: {
      value: { min: 3, max: 5 },
      animation: { enable: true, speed: 2, startValue: "min", sync: false },
    },
    opacity: {
      value: { min: 0.3, max: 0.8 },
      animation: { enable: true, speed: 1.2, sync: false },
    },
    stroke: { width: 1, color: "#FFD600" },
    links: {
      enable: true,
      distance: 70,
      color: "#FFD600",
      opacity: 0.2,
      width: 1,
    },
 
    move: {
      enable: false
    },
    rotate: { value: 0, animation: { enable: true, speed: 8, sync: false } },
    wobble: { enable: true, distance: 5, speed: 1 },
    twinkle: {
      particles: { enable: true, frequency: 0.015, opacity: 1 },
      lines: { enable: true, frequency: 0.007, opacity: 1 },
    },
  },
  interactivity: {
    detectsOn: "canvas",
    events: {
      onHover: { enable: true, mode: "grab" },
      onClick: { enable: true, mode: "push" },
      resize: { enable: true },
    },
    modes: {
      grab: {
        distance: 100,
        links: { color: "#FF004C", opacity: 0.6 },
      },
      push: { quantity: 3 },
    },
  },
};

/* ───────────  Export ─────────── */
export const particlePresets = {
  starfield,
  casinoGlitz,
} as const;

/* ───────────  Plugin Orbit ─────────── */
export async function loadOrbitPlugin(
  engine: import("@tsparticles/engine").Engine,
) {
  await loadCurvesPath(engine);
}
