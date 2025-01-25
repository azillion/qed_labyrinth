import { createSignal } from 'solid-js';
import { handleConnection, handleDisconnect } from './connection';
import { handleMessage } from './handlers';
import { DEBUG, SOCKET_URL } from '../constants';
import { authToken } from '@features/auth/stores/auth';

export const [socket, setSocket] = createSignal(null);
export const [connectionStatus, setConnectionStatus] = createSignal('disconnected');

// Send a message through the WebSocket
export const sendMessage = (type, payload) => {
	const ws = socket();
	if (ws?.readyState === WebSocket.OPEN) {
		if (DEBUG) {
			console.log('Sending message:', type, payload);
		}
		if (payload) {
			ws.send(JSON.stringify([type, payload]));
		} else {
			ws.send(JSON.stringify([type]));
		}
	} else {
		console.error('WebSocket is not connected');
	}
};

// Initialize WebSocket connection
export const initializeWebSocket = () => {
	try {
		const ws = new WebSocket(`${SOCKET_URL}?token=${authToken()}`);

		ws.onopen = () => handleConnection(ws);
		ws.onclose = handleDisconnect;
		ws.onmessage = (event) => handleMessage(event);
		ws.onerror = (error) => {
			console.error('WebSocket error:', error);
			setConnectionStatus('error');
		};

		setSocket(ws);
	} catch (error) {
		console.error('Error initializing WebSocket:', error);
		setConnectionStatus('error');
		setAuthToken(null);
	}
};

export const socketActions = {
	game: {
		command: (command) =>
			sendMessage('Command', { command })
	},
	chat: {
		send: (message) =>
			sendMessage('SendChat', { message }),
		emote: (message) =>
			sendMessage('SendEmote', { message }),
		system: (message) =>
			sendMessage('SendSystem', { message }),
		requestChatHistory: () =>
			sendMessage('RequestChatHistory')
	},
	character: {
		select: (characterId) => sendMessage('SelectCharacter', { character_id: characterId }),
		list: () => sendMessage('ListCharacters'),
		create: (characterData) => sendMessage('CreateCharacter', characterData)
	},
	area: {
		move: (direction) => sendMessage('Move', { direction })
	}
};
