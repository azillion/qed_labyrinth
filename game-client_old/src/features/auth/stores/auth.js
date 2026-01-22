import { createSignal } from 'solid-js';
import fetcher from '@lib/fetcher';
import { ENDPOINTS } from '@lib/constants';
import { socketManager } from '@lib/socket';

// Auth state management
export const [isAuthenticated, setIsAuthenticated] = createSignal(false);
export const [authToken, setAuthToken] = createSignal(null);
export const [authError, setAuthError] = createSignal(null);
export const [userRole, setUserRole] = createSignal(null);

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
export const login = async (email, password) => {
	try {
		const response = await fetcher.post(ENDPOINTS.login, { email, password });
		if (response.token) {
			setAuthState(response.token);
			setUserRole(response.role);
			setAuthError(null);
		} else {
			setAuthError('Invalid response from server');
		}
	} catch (error) {
		setAuthError('Login failed');
		setAuthState(null);
	}
};

export const register = async (email, password) => {
	try {
		const response = await fetcher.post(ENDPOINTS.register, { email, password });
		if (response?.token && typeof response.token === 'string') {
			setAuthState(response.token);
			setUserRole(response.role);
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

export const authHandlers = {
	'UserRole': (payload) => {
		setUserRole(payload.role);
	},
};
