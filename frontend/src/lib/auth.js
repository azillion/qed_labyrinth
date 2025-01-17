import { createSignal } from 'solid-js';
import fetcher from './fetcher';
import { ENDPOINTS } from './constants';

// Auth state management
export const [isAuthenticated, setIsAuthenticated] = createSignal(false);
export const [authToken, setAuthToken] = createSignal(null);
export const [authError, setAuthError] = createSignal(null);

const setAuthState = (token) => {
	setAuthToken(token);
	if (token) {
		localStorage.setItem('auth_token', token);
	} else {
		localStorage.removeItem('auth_token');
	}
	setIsAuthenticated(!!token);
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
export const login = async (username, password) => {
	const response = await fetcher.post(ENDPOINTS.login, { username, password });
	if (response.token) {
		setAuthState(response.token);
	}
};

export const register = async (username, password, email) => {
	const response = await fetcher.post(ENDPOINTS.register, { username, password, email });
	if (response.token) {
		setAuthState(response.token);
	}
};

export const logout = () => {
	setAuthState(null);
};

// Check for existing auth token on startup
export const initAuth = async () => {
	const token = localStorage.getItem('auth_token');
	if (token) {
		setAuthToken(token);
	}
};
