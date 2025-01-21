import { setAuthState } from "@features/auth/stores/auth";
import { characterHandlers } from "@features/auth/stores/character";
import { DEBUG } from "../constants";
import { areaHandlers } from "../../features/game/stores/area";

export const handleMessage = (event, handlers) => {
	try {
		if (event.data === 'Connection terminated') {
			setAuthState(null);
			return;
		}
		const data = JSON.parse(event.data);
		const [type, payload] = Array.isArray(data) ? data : [Object.keys(data)[0], data[Object.keys(data)[0]]];

		if (DEBUG) {
			console.log('Received message:', type, payload);
		}

		// Route message to appropriate handlers
		if (type.startsWith('Character')) {
			const handler = characterHandlers[type];
			if (handler) {
			  handler(payload);
			}
		} else if (type.startsWith('Area')) {
			const handler = areaHandlers[type];
			if (handler) {
			  handler(payload);
			}
		  } else if (type.startsWith('Game')) {
			handlers.game.forEach(handler => handler(type, payload));
		} else if (type.startsWith('Chat')) {
			handlers.chat.forEach(handler => handler(type, payload));
		} else if (type === 'Error') {
			handlers.error.forEach(handler => handler(type, payload));
		}
	} catch (err) {
		console.error('Error handling message:', err);
		handlers.error.forEach(handler =>
			handler('ParseError', { message: err.message })
		);
	}
};
