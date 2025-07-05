import Fastify from 'fastify';

const server = Fastify({
  logger: true,
});

server.get('/', async (request, reply) => {
  return { hello: 'world' };
});

const start = async () => {
  try {
    await server.listen({ port: 3001, host: '0.0.0.0' });
    server.log.info(`Server listening on port 3001`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();