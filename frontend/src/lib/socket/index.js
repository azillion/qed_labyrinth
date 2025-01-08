import { createSignal } from 'solid-js';
import { handleConnection, handleDisconnect } from './connection';
import { handleMessage } from './handlers';

export const SOCKET_URL = 'ws://localhost:3030/websocket';
export const [socket, setSocket] = createSignal(null);
export const [connectionStatus, setConnectionStatus] = createSignal('disconnected');

// Message handler registry
export const handlers = {
	auth: new Set(),
	game: new Set(),
	chat: new Set(),
	error: new Set()
};

// Subscribe to specific message types
export const onMessage = (type, handler) => {
	if (handlers[type]) {
		handlers[type].add(handler);
		return () => handlers[type].delete(handler);
	}
	return () => { };
};

// Send a message through the WebSocket
export const sendMessage = (type, payload) => {
	const ws = socket();
	if (ws?.readyState === WebSocket.OPEN) {
		ws.send(JSON.stringify([type, payload]));
	} else {
		console.error('WebSocket is not connected');
	}
};

// Initialize WebSocket connection
export const initializeWebSocket = () => {
	const ws = new WebSocket(SOCKET_URL);

	ws.onopen = () => handleConnection(ws);
	ws.onclose = handleDisconnect;
	ws.onmessage = (event) => handleMessage(event, handlers);
	ws.onerror = (error) => {
		console.error('WebSocket error:', error);
		setConnectionStatus('error');
	};

	setSocket(ws);
};

// Message handler categories
export const messageHandlers = {
	auth: {
		subscribe: (handler) => onMessage('auth', handler),
		login: (username, password) =>
			sendMessage('Login', { username, password }),
		register: (username, password, email) =>
			sendMessage('Register', { username, password, email })
	},

	game: {
		subscribe: (handler) => onMessage('game', handler),
		move: (direction) =>
			sendMessage('Move', { direction }),
		action: (type, target) =>
			sendMessage('Action', { type, target })
	},

	chat: {
		subscribe: (handler) => onMessage('chat', handler),
		send: (message) =>
			sendMessage('ChatMessage', { message })
	}
};
