import { FastifyInstance, FastifyRequest } from 'fastify';
import { connectionManager } from '../connectionManager';
import { publishPlayerCommand } from '../services/commandService';

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
      
      connection.socket.on('message', async (message: Buffer) => {
        try {
          // Parse the incoming message as JSON
          const messageText = message.toString();
          const commandData = JSON.parse(messageText);
          
          // Validate command format (expect array like ['Move', { direction: 'NORTH' }])
          if (!Array.isArray(commandData) || commandData.length !== 2) {
            console.error('Invalid command format:', commandData);
            connection.socket.send(JSON.stringify({ error: 'Invalid command format' }));
            return;
          }
          
          const [commandType, commandPayload] = commandData;
          
          // Create command object for the service
          const command = {
            type: commandType,
            payload: commandPayload
          };
          
          // Publish the command to Redis
          await publishPlayerCommand(userId, command);
          
          // Send acknowledgment back to client
          connection.socket.send(JSON.stringify({ status: 'command_received', type: commandType }));
          
        } catch (error) {
          console.error('Error processing command:', error);
          connection.socket.send(JSON.stringify({ error: 'Failed to process command' }));
        }
      });
      
    } catch (error) {
      console.error('JWT verification failed:', error);
      connection.socket.close(1008, 'Invalid token');
    }
  });
  
  done();
}