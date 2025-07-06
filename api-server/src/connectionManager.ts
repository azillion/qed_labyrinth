import { WebSocket } from 'ws';

export class ConnectionManager {
  private connections: Map<string, WebSocket> = new Map();

  add(userId: string, socket: WebSocket): void {
    this.connections.set(userId, socket);
  }

  remove(userId: string): void {
    this.connections.delete(userId);
  }

  get(userId: string): WebSocket | undefined {
    return this.connections.get(userId);
  }
}

export const connectionManager = new ConnectionManager();