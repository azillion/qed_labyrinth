import { FastifyInstance, FastifyRequest } from 'fastify';
import { WebSocket } from 'ws';
import { connectionManager } from '../connectionManager';
import { publishPlayerCommand } from '../services/commandService';

// Registers WebSocket endpoint and handles authenticated player commands.
export async function websocketRoutes(server: FastifyInstance, _options: any) {
  server.log.info('Registering WebSocket route');

  // Note: The first parameter provided by fastify-websocket *is* the ws "WebSocket" instance ‑-
  // it is **not** an object with a `.socket` property. We therefore interact with the
  // parameter directly.
  server.get('/websocket', { websocket: true }, (socket: WebSocket, req: FastifyRequest) => {
    const token = (req.query as any).token;

    if (!token) {
      socket.close(1008, 'No token provided');
      return;
    }

    let userId: string;

    try {
      const payload = server.jwt.verify(token) as any;
      userId = payload.userId;
    } catch (err) {
      server.log.error({ err }, 'JWT verification failed');
      socket.close(1008, 'Invalid token');
      return;
    }

    // Store the socket for later use (eg. server-push events).
    connectionManager.add(userId, socket);

    socket.on('close', () => {
      connectionManager.remove(userId);
    });

    socket.on('message', async (message: Buffer) => {
      try {
        const messageText = message.toString();
        const rawData = JSON.parse(messageText);

        // Accept either [type, payload] or { type, payload } formats
        let commandData: { type: string; payload: any };

        if (Array.isArray(rawData)) {
          const [type, payload] = rawData as [string, any];
          commandData = { type, payload: payload ?? {} };
        } else if (rawData && typeof rawData === 'object' && 'type' in rawData) {
          commandData = rawData as { type: string; payload: any };
        } else {
          socket.send(JSON.stringify({ error: 'Invalid command format' }));
          return;
        }

        await publishPlayerCommand(userId, commandData);

        socket.send(
          JSON.stringify({ status: 'command_received', type: commandData.type })
        );
      } catch (err) {
        server.log.error({ err }, 'Error processing command');
        socket.send(JSON.stringify({ error: 'Failed to process command' }));
      }
    });
  });
}