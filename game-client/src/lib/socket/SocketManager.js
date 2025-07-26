import { createSignal } from 'solid-js';
import { DEBUG, SOCKET_URL } from '../constants';
import { authToken, setAuthState } from '@features/auth/stores/auth';
import { setCharacter } from '@features/auth/stores/character';

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
        this.messageQueue = [];
        // Indicates the server has confirmed which character the user controls.
        this.characterReady = false;
        // Commands allowed before character has been selected
        this.immediateTypes = new Set([
            'CreateCharacter',
            'ListCharacters',
            'SelectCharacter',
            'RequestAdminMetrics'
        ]);
    }

    initialize() {
        if (this.manuallyDisconnected) return;
        setCharacter(null);

        const token = authToken();
        if (!token) {
            console.error('No auth token available');
            return;
        }
        
        console.log('Using token for WebSocket connection:', token.substring(0, 50) + '...');

        try {
            const wsUrl = `${SOCKET_URL}?token=${encodeURIComponent(token)}`;
            console.log('Creating WebSocket connection to:', wsUrl);
            
            const ws = new WebSocket(wsUrl);
            
            ws.onopen = () => {
                console.log('WebSocket connection opened');
                this.handleOpen(ws);
            };
            ws.onclose = (e) => {
                console.log('WebSocket connection closed:', e.code, e.reason);
                this.handleClose(e);
            };
            ws.onmessage = (e) => this.handleMessage(e);
            ws.onerror = (e) => {
                console.error('WebSocket error:', e);
                this.handleError(e);
            };

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

    // New method to handle actual sending once the socket is ready
    sendMessage(type, payload) {
        const ws = this.socket[0]();
        try {
            const message = payload ? JSON.stringify([type, payload]) : JSON.stringify([type]);
            ws.send(message);
            DEBUG && console.log('Sent:', type, payload);
        } catch (error) {
            console.error('Error sending message:', error);
        }
    }

    send(type, payload) {
        const ws = this.socket[0]();
        // If character is not yet ready and this command depends on a character, queue it.
        if (!this.characterReady && !this.immediateTypes.has(type)) {
            this.messageQueue.push({ type, payload });
            DEBUG && console.warn('Character not ready. Message queued:', type);
            return;
        }

        if (ws?.readyState === WebSocket.OPEN) {
            this.sendMessage(type, payload);
        } else {
            // Queue the message for later sending once the socket is open
            this.messageQueue.push({ type, payload });
            console.warn('WebSocket not connected. Message queued:', type);
        }
    }

    setCharacterReady(ready = true) {
        this.characterReady = ready;
        if (ready) {
            this.flushQueue();
        }
    }

    // Flush any queued messages; should be called once the server is ready to
    // accept character-scoped commands (e.g., after CharacterSelected).
    flushQueue() {
        const ws = this.socket[0]();
        if (!ws || ws.readyState !== WebSocket.OPEN) return;

        while (this.messageQueue.length > 0) {
            const { type, payload } = this.messageQueue.shift();
            this.sendMessage(type, payload);
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
        // Character not yet ready after a fresh connection
        this.characterReady = false;

        // Send any queued immediate commands (e.g., SelectCharacter)
        if (this.messageQueue.length > 0) {
            const remaining = [];
            for (const { type, payload } of this.messageQueue) {
                if (this.immediateTypes.has(type)) {
                    this.sendMessage(type, payload);
                } else {
                    remaining.push({ type, payload });
                }
            }
            this.messageQueue = remaining;
        }
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
            
            // Handle command acknowledgements from the server
            if (data.status === 'command_received') {
                DEBUG && console.log('Received ack for command:', data.type);
                return;
            }

            // Handle standard data messages from the server
            if (data && data.type && data.payload !== undefined) {
                const { type, payload } = data;
                DEBUG && console.log('Received:', type, payload);

                const handler = this.handlers.get(type);
                if (handler) {
                    handler(payload);
                } else {
                    console.warn('No handler registered for message type:', type);
                }
            } else {
                console.warn('Unknown message format received:', data);
            }
        } catch (error) {
            console.error('Error handling message:', error, 'Raw Data:', event.data);
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