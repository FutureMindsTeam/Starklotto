import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  daisyui: {
    themes: [
      {
        mytheme: {

          primary: "#794BFC",

          secondary: "F4F1FD",

          accent: "#ff00ff",

          neutral: "#ff00ff",

          "base-100": "#ffffff",

          info: "#0000ff",

          success: "#00ffff",

          warning: "#00ff00",

          error: "#ff0000",
          
          primary: "#000000",

          secondary: "#0B192C",

          accent: "#1E3E62",

          neutral: "#FF6500",

          "base-100": "#ffffff",

          info: "#000000",

          success: "#0B192C",

          warning: "#1E3E62",

          error: "#FF6500",
        },
      },
    ],
  },
  theme: {
    extend: {
      fontFamily: {
        montserrat: ["Montserrat", "sans-serif"],
      },

      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic":
          "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
      },
    },
  },
  plugins: [require("daisyui")],
};
export default config;
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./utils/**/*.{js,ts,jsx,tsx}",
  ],
  plugins: [require("daisyui")],
  darkTheme: "dark",
  // DaisyUI theme colors
  daisyui: {
    themes: [
      {
        light: {
          primary: "#000000",
          "primary-content": "#0B192C",
          secondary: "#1E3E62",
          "secondary-content": "#FF6500",
          accent: "#000000",
          "accent-content": "#0B192C",
          neutral: "#1E3E62",
          "neutral-content": "#FF6500",
          "base-100": "#ffffff",
          "base-200": "#f4f8ff",
          "base-300": "#ffffff",
          "base-content": "#212638",
          info: "#93BBFB",
          success: "#34EEB6",
          warning: "#FFCF72",
          error: "#FF8863",
          ".bg-gradient-modal": {
            "background-image":
              "linear-gradient(270deg, #A7ECFF -17.42%, #E8B6FF 109.05%)",
          },
          ".bg-modal": {
            background:
              "linear-gradient(270deg, #ece9fb -17.42%, #e3f4fd 109.05%)",
          },
          ".modal-border": {
            border: "1px solid #5c4fe5",
          },
          ".bg-gradient-nav": {
            background: "#000000",
          },
          ".bg-main": {
            background: "#FFFFFF",
          },
          ".bg-underline": {
            background:
              "linear-gradient(270deg, #A7ECFF -17.42%, #E8B6FF 109.05%)",
          },
          ".bg-container": {
            background: "transparent",
          },
          ".bg-btn-wallet": {
            "background-image":
              "linear-gradient(270deg, #A7ECFF -17.42%, #E8B6FF 109.05%)",
          },
          ".bg-input": {
            background: "rgba(0, 0, 0, 0.07)",
          },
          ".bg-component": {
            background: "rgba(255, 255, 255, 0.55)",
          },
          ".bg-function": {
            background:
              "linear-gradient(270deg, #A7ECFF -17.42%, #E8B6FF 109.05%)",
          },
          ".text-function": {
            color: "#3C1DFF",
          },
          ".text-network": {
            color: "#7800FF",
          },
          "--rounded-btn": "9999rem",

          ".tooltip": {
            "--tooltip-tail": "6px",
          },
          ".link": {
            textUnderlineOffset: "2px",
          },
          ".link:hover": {
            opacity: "80%",
          },
          ".contract-content": {
            background: "white",
          },
          "base-content": "#000000",
          info: "#0B192C",
          success: "#1E3E62",
          warning: "#FF6500",
          error: "#FF6500",
          "--rounded-btn": "9999rem",
        },
      },
      {
        dark: {
          primary: "#212638",
          "primary-content": "#DAE8FF",
          secondary: "#8b45fd",
          "secondary-content": "#0FF",
          accent: "#4969A6",
          "accent-content": "#F9FBFF",
          neutral: "#F9FBFF",
          "neutral-content": "#385183",
          "base-100": "#1C223B",
          "base-200": "#2A3655",
          "base-300": "#141a30",
          "base-content": "#F9FBFF",
          info: "#385183",
          success: "#34EEB6",
          warning: "#FFCF72",
          error: "#FF8863",
          ".bg-gradient-modal": {
            background: "#385183",
          },
          ".bg-modal": {
            background: "linear-gradient(90deg, #2B2243 0%, #253751 100%)",
          },
          ".modal-border": {
            border: "1px solid #4f4ab7",
          },
          ".bg-gradient-nav": {
            "background-image":
              "var(--gradient, linear-gradient(90deg, #42D2F1 0%, #B248DD 100%))",
          },
          ".bg-main": {
            background: "#141A31",
          },
          ".bg-underline": {
            background: "#5368B4",
          },
          ".bg-container": {
            background: "#141a30",
          },
          ".bg-btn-wallet": {
            "background-image":
              "linear-gradient(180deg, #3457D1 0%, #8A45FC 100%)",
          },
          ".bg-input": {
            background: "rgba(255, 255, 255, 0.07)",
          },
          ".bg-component": {
            background:
              "linear-gradient(113deg,rgba(43, 34, 67, 0.6) 20.48%,rgba(37, 55, 81, 0.6) 99.67%)",
          },
          ".bg-function": {
            background: "rgba(139, 69, 253, 0.37)",
          },
          ".text-function": {
            color: "#1DD6FF",
          },
          ".text-network": {
            color: "#D0A6FF",
          },

          "--rounded-btn": "9999rem",

          ".tooltip": {
            "--tooltip-tail": "6px",
            "--tooltip-color": "oklch(var(--p))",
          },
          ".link": {
            textUnderlineOffset: "2px",
          },
          ".link:hover": {
            opacity: "80%",
          },
          ".contract-content": {
            background:
              "linear-gradient(113.34deg, rgba(43, 34, 67, 0.6) 20.48%, rgba(37, 55, 81, 0.6) 99.67%)",
          },
          primary: "#000000",
          "primary-content": "#0B192C",
          secondary: "#1E3E62",
          "secondary-content": "#FF6500",
          accent: "#000000",
          "accent-content": "#0B192C",
          neutral: "#1E3E62",
          "neutral-content": "#FF6500",
          "base-100": "#1E3E62",
          "base-200": "#0B192C",
          "base-300": "#000000",
          "base-content": "#FF6500",
          info: "#0B192C",
          success: "#1E3E62",
          warning: "#FF6500",
          error: "#FF6500",
          "--rounded-btn": "9999rem",
        },
      },
    ],
  },
  theme: {
    extend: {
      fontFamily: {
        montserrat: ["Montserrat", "sans-serif"],
      },
      boxShadow: {
        center: "0 0 12px -2px rgb(0 0 0 / 0.05)",
      },
      animation: {
        "pulse-fast": "pulse 1s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      backgroundImage: {
        "gradient-light":
          "linear-gradient(270deg, #000000 -17.42%, #0B192C 109.05%)",
        "gradient-dark":
          "var(--gradient, linear-gradient(90deg, #1E3E62 0%, #FF6500 100%))",
        "gradient-vertical":
          "linear-gradient(180deg, #000000 0%, #FF6500 100%)",
        "gradient-icon":

          "var(--gradient, linear-gradient(90deg, #42D2F1 0%, #B248DD 100%))",
          "var(--gradient, linear-gradient(90deg, #0B192C 0%, #1E3E62 100%))",
      },
    },
  },
};
