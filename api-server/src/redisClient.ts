import { createClient } from 'redis';

const redisHost = process.env.REDIS_HOST || '127.0.0.1';
const redisPort = process.env.REDIS_PORT || 6379;

const redisClient = createClient({
  url: `redis://${redisHost}:${redisPort}`
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

redisClient.connect();

const redisSubscriber = createClient({
  url: `redis://${redisHost}:${redisPort}`
});

redisSubscriber.on('error', (err) => console.error('Redis Subscriber Error', err));

redisSubscriber.connect();

export default redisClient;
export { redisSubscriber };