import { WebSocket } from 'ws';

export class ConnectionManager {
  private connections: Map<string, WebSocket> = new Map();

  add(userId: string, socket: WebSocket): void {
    this.connections.set(userId, socket);
  }

  remove(userId: string, socket: WebSocket): void {
    const existing = this.connections.get(userId);
    // Only delete if the existing socket is the same instance to avoid race conditions
    if (existing === socket) {
      this.connections.delete(userId);
    }
  }

  get(userId: string): WebSocket | undefined {
    return this.connections.get(userId);
  }
}

export const connectionManager = new ConnectionManager();