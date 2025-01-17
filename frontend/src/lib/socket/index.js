import { createSignal } from 'solid-js';
import { handleConnection, handleDisconnect } from './connection';
import { handleMessage } from './handlers';
import { SOCKET_URL } from '../constants';
import { authToken } from '../auth';

export const [socket, setSocket] = createSignal(null);
export const [connectionStatus, setConnectionStatus] = createSignal('disconnected');

// Message handler registry
export const handlers = {
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
	const ws = new WebSocket(`${SOCKET_URL}?token=${authToken()}`);

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
