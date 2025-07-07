import Fastify from 'fastify';
import fastifyJwt from '@fastify/jwt';
import fastifyWebsocket from '@fastify/websocket';
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

    server.register(fastifyWebsocket);
    server.register(authRoutes, { prefix: '/auth' });
    server.register(websocketRoutes);

    await server.listen({ port: 3001, host: '0.0.0.0' });
    server.log.info(`Server listening on port 3001`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

startEgressService();

start();