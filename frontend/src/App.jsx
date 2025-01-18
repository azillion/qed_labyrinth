import { onMount, createEffect, Show } from "solid-js";

import { setCurrentTheme } from "@stores/themeStore";
import { initializeWebSocket } from "@lib/socket";
import { ConnectionStatus } from "@components/shared/ConnectionStatus";
import { initAuth, authToken } from "@features/auth/stores/auth";
import LoginPage from "@pages/auth";

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
					<props.children />
				</Show>
			</Show>
			<ConnectionStatus />
		</>
	);
};

export default App;
