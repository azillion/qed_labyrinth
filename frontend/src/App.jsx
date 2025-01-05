import { GameLayout } from "./components/templates/GameLayout";
import { setCurrentTheme } from "./stores/themeStore";

const App = () => {
  const ws = new WebSocket("ws://localhost:3030/websocket");
  window.ws = ws;
  ws.onopen = () => {
    console.log("Connected to server");
  };
  ws.onmessage = (event) => {
    console.log(event.data);
  };
  ws.onclose = () => {
    console.log("Disconnected from server");
  };
  // Switch theme
  setCurrentTheme("red"); // or "red" or "green"

  return <GameLayout />;
};

export default App;
