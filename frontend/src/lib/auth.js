import { createSignal } from 'solid-js';
import { socket } from './socket';

// Auth state management
export const [isAuthenticated, setIsAuthenticated] = createSignal(false);
export const [authToken, setAuthToken] = createSignal(null);
export const [currentUser, setCurrentUser] = createSignal(null);
export const [authError, setAuthError] = createSignal(null);

// Message handlers for different response types
const messageHandlers = {
	AuthSuccess: ({ token, user_id }) => {
		setAuthToken(token);
		setCurrentUser({ id: user_id });
		setIsAuthenticated(true);
		setAuthError(null);
		// Store auth token for persistence
		localStorage.setItem('auth_token', token);
	},
	Error: ({ message }) => {
		setAuthError(message);
	}
};

// Handle incoming WebSocket messages
export const handleAuthMessage = (event) => {
	try {
		const data = JSON.parse(event.data);
		// Get the message type (first element) and payload (second element)
		const [type, payload] = Array.isArray(data) ? data : [Object.keys(data)[0], data[Object.keys(data)[0]]];

		const handler = messageHandlers[type];
		if (handler) {
			handler(payload);
		}
	} catch (err) {
		console.error('Error handling auth message:', err);
	}
};

// Auth actions
export const login = (username, password) => {
	socket()?.send(JSON.stringify(["Login", { username, password }]));
};

export const register = (username, password, email) => {
	socket()?.send(JSON.stringify(["Register", { username, password, email }]));
};

export const logout = () => {
	setAuthToken(null);
	setCurrentUser(null);
	setIsAuthenticated(false);
	localStorage.removeItem('auth_token');
};

// Check for existing auth token on startup
export const initAuth = () => {
	const token = localStorage.getItem('auth_token');
	if (token) {
		setAuthToken(token);
		// Here you could verify the token with the server
	}
};
