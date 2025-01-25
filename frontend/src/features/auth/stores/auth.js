import { createSignal } from 'solid-js';
import fetcher from '@lib/fetcher';
import { ENDPOINTS } from '@lib/constants';
import { socketManager } from '@lib/socket';

// Auth state management
export const [isAuthenticated, setIsAuthenticated] = createSignal(false);
export const [authToken, setAuthToken] = createSignal(null);
export const [authError, setAuthError] = createSignal(null);

export const setAuthState = (token) => {
	if (token && typeof token !== 'string') {
		console.error('Invalid token type');
		return;
	}
	
	setAuthToken(token);
	setIsAuthenticated(!!token);
	
	if (token) {
		localStorage.setItem('auth_token', token);
	} else {
		localStorage.removeItem('auth_token');
		socketManager.disconnect();
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
	try {
		const response = await fetcher.post(ENDPOINTS.register, { username, password, email });
		if (response?.token && typeof response.token === 'string') {
			setAuthState(response.token);
			setAuthError(null); // Clear any previous errors
		} else {
			setAuthError('Invalid response from server');
		}
	} catch (error) {
		setAuthError('Registration failed');
		setAuthState(null);
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
