import { onMount, createEffect, Show } from "solid-js";
import { Router, Route } from "@solidjs/router";

import GamePage from "@pages/game";
import { CharacterSheetPage } from "@pages/character/sheet";

import { setCurrentTheme } from "@stores/themeStore";
import { socketManager, registerCoreHandlers } from '@lib/socket';
import { ConnectionStatus } from "@components/shared/ConnectionStatus";
import { initAuth, authToken } from "@features/auth/stores/auth";
import LoginPage from "@pages/auth";
import CharacterPage from "@pages/character";
import { isCharacterSelected } from "@features/auth/stores/character";
import { InventoryPage } from "@pages/inventory";

const App = (props) => {
	onMount(async () => {
		await initAuth();
		registerCoreHandlers();
	});

	createEffect(() => {
		const token = authToken();
		console.log('Auth token changed:', token ? 'Token exists' : 'No token');
		if (token) {
			console.log('Token length:', token.length);
			if (!socketManager.getSocket() || socketManager.getSocket()?.readyState === WebSocket.CLOSED) {
				console.log('Initializing socket connection...');
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
		<div class="h-screen bg-black text-gray-100 font-mono flex flex-col">
			<Show when={authToken()} fallback={<LoginPage />}>
				<Show when={isCharacterSelected()} fallback={<CharacterPage />}>
					<Router>
						<Route path="/" component={GamePage} />
						<Route path="/inventory" component={InventoryPage} />
						<Route path="/sheet" component={CharacterSheetPage} />
					</Router>
				</Show>
			</Show>
			<ConnectionStatus />
		</div>
	);
};

export default App;
