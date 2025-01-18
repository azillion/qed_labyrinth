import { createSignal } from 'solid-js';
import { handleConnection, handleDisconnect } from './connection';
import { handleMessage } from './handlers';
import { SOCKET_URL } from '../constants';
import { authToken } from '@features/auth/stores/auth';

export const [socket, setSocket] = createSignal(null);
export const [connectionStatus, setConnectionStatus] = createSignal('disconnected');

// Message handler registry organized by type
export const handlers = {
  game: new Set(),
  chat: new Set(),
  error: new Set()
};

// Generic message subscription system
export const onMessage = (type, handler) => {
  if (handlers[type]) {
    handlers[type].add(handler);
    return () => handlers[type].delete(handler);
  }
  return () => {};
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

// Initialize feature handlers
export const initializeHandlers = async () => {
  try {
    // Dynamically import handlers to avoid circular dependencies
    const { characterHandlers, initializeCharacterActions } = await import('@features/auth/stores/character');
    
    // Register character message handlers
    Object.entries(characterHandlers).forEach(([type, handler]) => {
      handlers.game.add((msgType, payload) => {
        if (msgType === type) {
          handler(payload);
        }
      });
    });

    // Initialize character actions with messaging capabilities
    initializeCharacterActions({
      send: sendMessage
    });

  } catch (error) {
    console.error('Error initializing handlers:', error);
    handlers.error.forEach(handler => 
      handler('InitError', { message: 'Failed to initialize handlers' })
    );
  }
};

// Initialize WebSocket connection
export const initializeWebSocket = () => {
  try {
    const token = authToken();
    if (!token) {
      throw new Error('No auth token available');
    }

    const ws = new WebSocket(`${SOCKET_URL}?token=${token}`);

    ws.onopen = async () => {
      await initializeHandlers();
      handleConnection(ws);
    };

    ws.onclose = handleDisconnect;
    
    ws.onmessage = (event) => handleMessage(event, handlers);
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
      setConnectionStatus('error');
    };

    setSocket(ws);
  } catch (error) {
    console.error('Error initializing WebSocket:', error);
    setConnectionStatus('error');
  }
};

// Message handler categories with public API
export const messageHandlers = {
  game: {
    subscribe: (handler) => onMessage('game', handler),
    move: (direction) => sendMessage('Move', { direction }),
    action: (type, target) => sendMessage('Action', { type, target })
  },

  chat: {
    subscribe: (handler) => onMessage('chat', handler),
    send: (message) => sendMessage('ChatMessage', { message })
  },

  error: {
    subscribe: (handler) => onMessage('error', handler)
  }
};

// Export initialized handlers for external use
export { messageHandlers as default };