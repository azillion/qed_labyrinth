import { FastifyInstance, FastifyRequest } from 'fastify';
import { connectionManager } from '../connectionManager';

export async function websocketRoutes(server: FastifyInstance, options: any, done: () => void) {
  server.get('/websocket', { websocket: true }, (connection: any, req: FastifyRequest) => {
    const token = (req.query as any).token;
    
    if (!token) {
      connection.socket.close(1008, 'No token provided');
      return;
    }
    
    try {
      const payload = server.jwt.verify(token) as any;
      const userId = payload.userId;
      
      connectionManager.add(userId, connection.socket);
      
      connection.socket.on('close', () => {
        connectionManager.remove(userId);
      });
      
      connection.socket.on('message', (message: Buffer) => {
        console.log('Received message:', message.toString());
        connection.socket.send(message.toString());
      });
      
    } catch (error) {
      console.error('JWT verification failed:', error);
      connection.socket.close(1008, 'Invalid token');
    }
  });
  
  done();
}