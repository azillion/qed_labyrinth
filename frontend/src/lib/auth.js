import { createSignal } from 'solid-js';
import fetcher from './fetcher';
import { ENDPOINTS } from './constants';

// Auth state management
export const [isAuthenticated, setIsAuthenticated] = createSignal(false);
export const [authToken, setAuthToken] = createSignal(null);
export const [authError, setAuthError] = createSignal(null);

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
	console.log(response);
	if (response.token) {
		setAuthToken(response.token);
		setIsAuthenticated(true);
	}
};

export const register = async (username, password, email) => {
	const response = await fetcher.post(ENDPOINTS.register, { username, password, email });
	if (response.ok) {
		setAuthToken(response.token);
		setCurrentUser(response.user);
		setIsAuthenticated(true);
	}
};

export const logout = () => {
	setAuthToken(null);
	setCurrentUser(null);
	setIsAuthenticated(false);
	localStorage.removeItem('auth_token');
};

// Check for existing auth token on startup
export const initAuth = async () => {
	const token = localStorage.getItem('auth_token');
	if (token) {
		setAuthToken(token);
		await verifyAuth();
	}
};

export const verifyAuth = async () => {
	const response = await fetcher.get(ENDPOINTS.verify);
	if (!response.ok) {
		logout();
	}
};
