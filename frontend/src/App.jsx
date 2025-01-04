import { GameLayout } from "./components/templates/GameLayout";
import { setCurrentTheme } from "./stores/themeStore";

const App = () => {
  // Switch theme
  setCurrentTheme("blue");  // or "red" or "green"

  return <GameLayout />;
};

export default App;
