import { SocketManager } from './SocketManager';
import { areaHandlers } from '@features/game/stores/area';
import { chatHandlers } from '@features/game/stores/chat';
import { characterHandlers } from '@features/auth/stores/character';

export const socketManager = new SocketManager();

// Register core handlers
export function registerCoreHandlers() {
  // Area handlers
  Object.entries(areaHandlers).forEach(([type, handler]) => {
    socketManager.registerHandler(type, handler);
  });

  // Chat handlers
  Object.entries(chatHandlers).forEach(([type, handler]) => {
    socketManager.registerHandler(type, handler);
  });

  // Character handlers
  Object.entries(characterHandlers).forEach(([type, handler]) => {
    socketManager.registerHandler(type, handler);
  });

  socketManager.registerHandler('Error', (payload) => {
    console.error('Server error:', payload);
  });
}

// Export simplified interface
export const send = socketManager.send.bind(socketManager);
export const connectionStatus = socketManager.connectionStatus[0];