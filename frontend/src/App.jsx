import { GameLayout } from "./components/templates/GameLayout";
import { setCurrentTheme } from "./stores/themeStore";
import { onCleanup } from "solid-js";
import { setSocket, SOCKET_URL } from "./lib/socket";

const App = () => {
	const ws = new WebSocket(SOCKET_URL);
	setSocket(ws);

	ws.onopen = () => {
		console.log("Connected to server");
	};

	ws.onmessage = (event) => {
		console.log(event.data);
	};

	ws.onclose = () => {
		console.log("Disconnected from server");
	};

	// clean up the websocket on unmount
	onCleanup(() => {
		ws.close();
	});

	setCurrentTheme("red"); // or "red" or "green"

	return <GameLayout />;
};

export default App;

