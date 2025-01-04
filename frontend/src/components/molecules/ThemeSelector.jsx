import { currentTheme, setCurrentTheme } from "../../stores/themeStore";

export const ThemeSelector = () => {
  return (
    <div class="flex gap-2">
      <button
        class={`w-6 h-6 rounded-full bg-red-500 
                ${currentTheme() === "red" ? "ring-2 ring-white" : ""}`}
        onClick={() => setCurrentTheme("red")}
      />
      <button
        class={`w-6 h-6 rounded-full bg-green-500 
                ${currentTheme() === "green" ? "ring-2 ring-white" : ""}`}
        onClick={() => setCurrentTheme("green")}
      />
      <button
        class={`w-6 h-6 rounded-full bg-blue-500 
                ${currentTheme() === "blue" ? "ring-2 ring-white" : ""}`}
        onClick={() => setCurrentTheme("blue")}
      />
    </div>
  );
};