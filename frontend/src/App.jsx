import { onMount, createEffect, Show } from "solid-js";
import { Router, Route } from "@solidjs/router";

import GamePage from "@pages/game";
import MapPage from "@pages/map";

import { setCurrentTheme } from "@stores/themeStore";
import { initializeWebSocket } from "@lib/socket";
import { ConnectionStatus } from "@components/shared/ConnectionStatus";
import { initAuth, authToken } from "@features/auth/stores/auth";
import LoginPage from "@pages/auth";
import CharacterPage from "@pages/character";
import { isCharacterSelected } from "@features/auth/stores/character";

const App = (props) => {
	onMount(async () => {
		await initAuth();
	});

	createEffect(() => {
		if (authToken())
			initializeWebSocket();
	}, [authToken]);

	setCurrentTheme("red");

	return (
		<>
			<Show when={authToken()} fallback={<LoginPage />}>
				<Show when={isCharacterSelected()} fallback={<CharacterPage />}>
				<Router>
        <Route path="/" component={GamePage} />
        <Route path="/map" component={MapPage} />
      </Router>	
				</Show>
			</Show>
			<ConnectionStatus />
		</>
	);
};

export default App;
