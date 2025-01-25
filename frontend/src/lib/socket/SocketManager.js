import { createSignal } from 'solid-js';
import { DEBUG, SOCKET_URL } from '../constants';
import { authToken, setAuthState } from '@features/auth/stores/auth';

const INITIAL_RETRY_DELAY = 1000;
const MAX_RETRY_DELAY = 30000;
const BACKOFF_FACTOR = 1.5;
const MAX_RETRIES = 5;

export class SocketManager {
    constructor() {
        this.handlers = new Map();
        this.retryCount = 0;
        this.retryDelay = INITIAL_RETRY_DELAY;
        this.isReconnecting = false;
        this.manuallyDisconnected = false;
        this.connectionStatus = createSignal('disconnected');
        this.socket = createSignal(null);
    }

    initialize() {
        if (this.manuallyDisconnected) return;

        const token = authToken();
        if (!token) {
            console.error('No auth token available');
            return;
        }

        try {
            const ws = new WebSocket(`${SOCKET_URL}?token=${encodeURIComponent(token)}`);
            ws.onopen = () => this.handleOpen(ws);
            ws.onclose = (e) => this.handleClose(e);
            ws.onmessage = (e) => this.handleMessage(e);
            ws.onerror = (e) => this.handleError(e);

            this.socket[1](ws);
            this.connectionStatus[1]('connecting');
        } catch (error) {
            console.error('WebSocket initialization error:', error);
            this.handleError(error);
        }
    }

    registerHandler(type, handler) {
        this.handlers.set(type, handler);
    }

    unregisterHandler(type) {
        this.handlers.delete(type);
    }

    send(type, payload) {
        const ws = this.socket[0]();
        if (ws?.readyState === WebSocket.OPEN) {
            try {
                const message = payload ? JSON.stringify([type, payload]) : JSON.stringify([type]);
                ws.send(message);
                DEBUG && console.log('Sent:', type, payload);
            } catch (error) {
                console.error('Error sending message:', error);
            }
        } else {
            console.warn('WebSocket not connected. Message not sent:', type);
        }
    }

    handleOpen(ws) {
        if (DEBUG) {
            console.log('WebSocket connected');
        }
        this.connectionStatus[1]('connected');
        this.isReconnecting = false;
        this.retryCount = 0;
        this.retryDelay = INITIAL_RETRY_DELAY;
    }

    handleClose(event) {
        this.connectionStatus[1]('disconnected');

        if (event.code === 4001) {
            console.log('Connection closed due to authentication error');
            setAuthState(null);
            this.manuallyDisconnected = true;
            return;
        }

        if (this.manuallyDisconnected) {
            return;
        }

        if (this.retryCount >= MAX_RETRIES) {
            console.error('Max reconnection attempts reached');
            this.connectionStatus[1]('failed');
            setAuthState(null);
            return;
        }

        this.isReconnecting = true;
        this.retryCount++;
        this.retryDelay = Math.min(this.retryDelay * BACKOFF_FACTOR, MAX_RETRY_DELAY);

        if (DEBUG) {
            console.log(`Reconnecting in ${this.retryDelay}ms... (Attempt ${this.retryCount}/${MAX_RETRIES})`);
        }

        setTimeout(() => {
            this.initialize();
        }, this.retryDelay);
    }

    handleMessage(event) {
        try {
            if (typeof event.data === 'string' && 
                (event.data === 'Connection terminated' || 
                 event.data === 'Authentication failed' ||
                 event.data === 'Token expired')) {
                console.log('Received termination message:', event.data);
                setAuthState(null);
                this.manuallyDisconnected = true;
                this.disconnect();
                return;
            }

            const data = JSON.parse(event.data);
            const [type, payload] = Array.isArray(data) ? data : [Object.keys(data)[0], data[Object.keys(data)[0]]];

            DEBUG && console.log('Received:', type, payload);

            const handler = this.handlers.get(type);
            if (handler) {
                handler(payload);
            } else {
                console.warn('No handler registered for message type:', type);
            }
        } catch (error) {
            console.error('Error handling message:', error);
        }
    }

    handleError(error) {
        console.error('WebSocket error:', error);
        this.connectionStatus[1]('error');
    }

    disconnect() {
        this.manuallyDisconnected = true;
        const ws = this.socket[0]();
        if (ws) {
            ws.close();
        }
        this.socket[1](null);
        this.isReconnecting = false;
        this.retryCount = 0;
        this.retryDelay = INITIAL_RETRY_DELAY;
    }

    reconnect() {
        this.manuallyDisconnected = false;
        this.initialize();
    }

    getConnectionStatus() {
        return this.connectionStatus[0]();
    }

    getSocket() {
        return this.socket[0]();
    }
}