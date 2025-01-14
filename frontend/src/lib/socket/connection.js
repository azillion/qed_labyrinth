import { createSignal } from 'solid-js';
import { setConnectionStatus } from './index';
import { DEBUG } from '../constants';

const INITIAL_RETRY_DELAY = 1000;
const MAX_RETRY_DELAY = 30000;
const BACKOFF_FACTOR = 1.5;
const MAX_RETRIES = 10;

export const [retryCount, setRetryCount] = createSignal(0);
export const [retryDelay, setRetryDelay] = createSignal(INITIAL_RETRY_DELAY);
export const [isReconnecting, setIsReconnecting] = createSignal(false);

let reconnectTimeout;
let manuallyDisconnected = false;

const calculateNextDelay = (currentDelay) => {
	return Math.min(currentDelay * BACKOFF_FACTOR, MAX_RETRY_DELAY);
};

export const handleConnection = (ws) => {
	if (DEBUG) {
		console.log('WebSocket connected');
	}
	setConnectionStatus('connected');
	setIsReconnecting(false);
	setRetryCount(0);
	setRetryDelay(INITIAL_RETRY_DELAY);

	// Reauthorize if we have a token
	if (window.authToken) {
		ws.send(JSON.stringify(['Reauth', { token: window.authToken }]));
	}
};

export const handleDisconnect = (event) => {
	setConnectionStatus('disconnected');

	if (manuallyDisconnected) {
		return;
	}

	const currentRetryCount = retryCount();
	if (currentRetryCount >= MAX_RETRIES) {
		console.error('Max reconnection attempts reached');
		setConnectionStatus('failed');
		return;
	}

	setIsReconnecting(true);
	setRetryCount(currentRetryCount + 1);

	const currentDelay = retryDelay();
	const nextDelay = calculateNextDelay(currentDelay);
	setRetryDelay(nextDelay);

	if (DEBUG) {
		console.log(`Reconnecting in ${nextDelay}ms... (Attempt ${currentRetryCount + 1}/${MAX_RETRIES})`);
	}

	clearTimeout(reconnectTimeout);
	reconnectTimeout = setTimeout(() => {
		initializeWebSocket();
	}, nextDelay);
};

export const manualDisconnect = () => {
	manuallyDisconnected = true;
	clearTimeout(reconnectTimeout);
	setIsReconnecting(false);
	setRetryCount(0);
	setRetryDelay(INITIAL_RETRY_DELAY);
};

export const resetConnection = () => {
	manuallyDisconnected = false;
	clearTimeout(reconnectTimeout);
	handleDisconnect();
};
