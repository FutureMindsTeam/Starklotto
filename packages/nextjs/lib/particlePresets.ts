/* src/lib/particlePresets.ts
   Centraliza presets de tsParticles (v3.x)                    */


   import type { ISourceOptions } from '@tsparticles/engine'
   import { loadCurvesPath } from '@tsparticles/path-curves'
   
   /* ─────────── 1. Starfield ─────────── */
   export const starfield: ISourceOptions = {
     fullScreen: { enable: false },
     fpsLimit: 60,
     detectRetina: true,
     background: { color: 'transparent' },
     particles: {
       number: { value: 120, density: { enable: true, width: 900 } },
       color: { value: ['#F2075D', '#8A26A6', '#ffffff'] },
       links: { enable: false },
       move: { enable: true, speed: 0.3 },
       size: { value: 1 },
       opacity: { value: 0.4 },
     },
   }
   
   /* ─────────── 2. Network (repulse) ─────────── */
   export const network: ISourceOptions = {
     ...starfield,
     particles: {
       ...starfield.particles,
       number: { value: 75, density: { enable: true, width: 800 } },
       links: { enable: true, distance: 130, color: '#ffffff', opacity: 0.25, width: 1 },
       move: { enable: true, speed: 0.6, random: true, outModes: { default: 'bounce' } },
     },
     interactivity: {
       events: {
         onHover: { enable: true, mode: 'repulse' },
         resize: { enable: true },
       },
       modes: { repulse: { distance: 120 } },
     },
   }
   
   /* ─────────── 3. Bubbles (hover) ─────────── */
   export const bubbles: ISourceOptions = {
     ...starfield,
     interactivity: {
       events: {
         onHover: { enable: true, mode: 'bubble' },
         resize: { enable: true },
       },
       modes: { bubble: { distance: 150, size: 6, duration: 2, opacity: 0.1 } },
     },
   }
   
   /* ─────────── 4. Hex Grid ─────────── */
   export const hexGrid: ISourceOptions = {
     ...starfield,
     particles: {
       ...starfield.particles,
       number: { value: 90, density: { enable: true, width: 800 } },
       links: { enable: true, distance: 65, color: '#ffffff', opacity: 0.15, width: 1 },
       move: { enable: true, speed: 0.15, straight: true },
     },
     interactivity: { events: { resize: { enable: true } } },
   }


   /* ─────────── Hex Grid inspirado en StarkLotto ─────────── */
export const hexGridStark: ISourceOptions = {
  ...starfield,
  particles: {
    ...starfield.particles,
    number: { value: 100, density: { enable: true, width: 900 } },
    color: { value: ['#F2075D', '#8A26A6', '#ffffff'] },
    size: { value: { min: 2, max: 3 } },
    opacity: {
      value: { min: 0.15, max: 0.5 },
      animation: { enable: true, speed: 0.5, sync: false },
    },
    links: {
      enable: true,
      distance: 70,
      color: '#F2075D',
      opacity: 0.25,
      width: 1.2,
    },
    move: { enable: true, speed: 0.12, straight: true },
  },
  interactivity: {
    events: {
      onHover: { enable: true, mode: 'grab' },
      resize: { enable: true },
    },
    modes: {
      grab: {
        distance: 120,
        links: { opacity: 0.4, color: '#FF4D88' },
      },
    },
  },
}


   
   /* ─────────── 5. Firefly ─────────── */
   export const firefly: ISourceOptions = {
     ...starfield,
     particles: {
       ...starfield.particles,
       number: { value: 25, density: { enable: true, width: 800 } },
       size: { value: { min: 2, max: 4 } },
       links: { enable: false },
       opacity: {
         value: { min: 0.05, max: 0.4 },
         animation: { enable: true, speed: 1, sync: false },
       },
       move: { enable: true, speed: 0.4, random: true, outModes: { default: 'bounce' } },
     },
     interactivity: { events: { resize: { enable: true } } },
   }
   


 
   export const orbit: ISourceOptions = {
     ...starfield,
     particles: {
       ...starfield.particles,
       number: { value: 60, density: { enable: false, width: 800 } },
       links: { enable: false },
       move: {
         enable: true,
         speed: 2,
         path: { enable: true, delay: { value: 0.1 }, options: { frequency: 2 } },
       },
     },
   }
   
   export async function loadOrbitPlugin(engine: import('@tsparticles/engine').Engine) {
     await loadCurvesPath(engine)
   }
 
   
   /* ---------- Export agrupado ---------- */
   export const particlePresets = {
     starfield,
     network,
     bubbles,
     hexGrid,
     firefly,
     orbit,      
     hexGridStark,    
   } as const
