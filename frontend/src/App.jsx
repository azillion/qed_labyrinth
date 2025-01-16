import { GameLayout } from "./components/templates/GameLayout";
import { setCurrentTheme } from "./stores/themeStore";
import { onMount, createEffect } from "solid-js";
import { initializeWebSocket } from "./lib/socket";
import { ConnectionStatus } from "./components/molecules/ConnectionStatus";
import { initAuth, authToken } from "./lib/auth";


const App = () => {
	onMount(async () => {
		await initAuth();
	});

	createEffect(() => {
		if (authToken())
			initializeWebSocket();
	}, [authToken()]);

	setCurrentTheme("red");

	return (
		<>
			<GameLayout />
			<ConnectionStatus />
		</>
	);
};

export default App;
