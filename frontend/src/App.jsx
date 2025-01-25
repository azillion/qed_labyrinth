import { onMount, createEffect, Show } from "solid-js";
import { Router, Route } from "@solidjs/router";

import GamePage from "@pages/game";
import MapPage from "@pages/map";

import { setCurrentTheme } from "@stores/themeStore";
import { socketManager, registerCoreHandlers } from '@lib/socket';
import { ConnectionStatus } from "@components/shared/ConnectionStatus";
import { initAuth, authToken } from "@features/auth/stores/auth";
import LoginPage from "@pages/auth";
import CharacterPage from "@pages/character";
import { isCharacterSelected } from "@features/auth/stores/character";

const App = (props) => {
	onMount(async () => {
		await initAuth();
		registerCoreHandlers();
	});

	createEffect(() => {
		const token = authToken();
		if (token) {
			if (!socketManager.getSocket() || socketManager.getSocket()?.readyState === WebSocket.CLOSED) {
				socketManager.manuallyDisconnected = false;
				socketManager.initialize();
			}
		} else {
			console.log('Token is null, disconnecting socket');
			socketManager.disconnect();
		}
	}, [authToken()]);

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
