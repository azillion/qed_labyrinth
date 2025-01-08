import { GameLayout } from "./components/templates/GameLayout";
import { setCurrentTheme } from "./stores/themeStore";
import { onMount } from "solid-js";
import { initializeWebSocket } from "./lib/socket";
import { ConnectionStatus } from "./components/molecules/ConnectionStatus";
import { initAuth } from "./lib/auth";

const App = () => {
	onMount(() => {
		initAuth();
		initializeWebSocket();
	});

	setCurrentTheme("red");

	return (
		<>
			<GameLayout />
			<ConnectionStatus />
		</>
	);
};

export default App;
