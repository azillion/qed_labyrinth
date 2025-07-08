import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyWebsocket from '@fastify/websocket';
import fastifyCors from '@fastify/cors';
import { authRoutes } from './routes/auth';
import { websocketRoutes } from './routes/websocket';
import { jwtConfig } from './config';
import { startEgressService } from './services/egressService';

const server = Fastify({
  logger: true,
});

server.get('/', async (request, reply) => {
  return { hello: 'world' };
});

const start = async () => {
  try {
    server.register(fastifyJwt, {
      secret: jwtConfig.secret,
    });

    server.register(authRoutes, { prefix: '/auth' });
    // Register the websocket plugin *before* CORS so the upgrade handshake
    // isn't altered by the CORS pre-handler.
    server.register(fastifyWebsocket);
    console.log('WebSocket plugin registered');

    server.register(fastifyCors, {
      origin: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'Sec-WebSocket-Protocol', 'Sec-WebSocket-Key', 'Sec-WebSocket-Version', 'Upgrade', 'Connection'],
    });

    server.register(websocketRoutes);
    console.log('All routes registered');

    await server.listen({ port: 3001, host: '0.0.0.0' });
    server.log.info(`Server listening on port 3001`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

startEgressService();

start();