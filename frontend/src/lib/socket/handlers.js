import { handleAuthMessage } from "../auth";

export const handleMessage = (event, handlers) => {
	try {
		const data = JSON.parse(event.data);
		const [type, payload] = Array.isArray(data) ? data : [Object.keys(data)[0], data[Object.keys(data)[0]]];

		console.log('Received message:', type, payload);

		// Route message to appropriate handlers
		if (type.startsWith('Auth')) {
			handleAuthMessage(event);
			handlers.auth.forEach(handler => handler(type, payload));
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
