import { createSignal } from "solid-js";

const THEMES = {
  red: {
    primary: "red",
    textBase: "text-red-500",
    textDim: "text-red-500/70",
    textDimmer: "text-red-500/50",
    textDimmest: "text-red-500/30",
    textSuccess: "text-green-500",
    textError: "text-red-500",
    border: "border-red-500/30",
    shadow: "shadow-[0_0_2px_rgba(220,38,38,0.5)]",
  },
  green: {
    primary: "green",
    textBase: "text-green-500",
    textDim: "text-green-500/70",
    textDimmer: "text-green-500/50",
    textDimmest: "text-green-500/30",
    textSuccess: "text-green-500",
    textError: "text-red-500",
    border: "border-green-500/30",
    shadow: "shadow-[0_0_2px_rgba(34,197,94,0.5)]",
  },
  blue: {
    primary: "blue",
    textBase: "text-blue-500",
    textDim: "text-blue-500/70",
    textDimmer: "text-blue-500/50",
    textDimmest: "text-blue-500/30",
    textSuccess: "text-blue-500",
    textError: "text-red-500",
    border: "border-blue-500/30",
    shadow: "shadow-[0_0_2px_rgba(59,130,246,0.5)]",
  },
};

const [currentTheme, setCurrentTheme] = createSignal("red");
const theme = () => THEMES[currentTheme()];

export { currentTheme, setCurrentTheme, theme };