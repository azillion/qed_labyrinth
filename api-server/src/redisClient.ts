import { createClient } from 'redis';

const redisClient = createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

redisClient.connect();

const redisSubscriber = createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

redisSubscriber.on('error', (err) => console.error('Redis Subscriber Error', err));

redisSubscriber.connect();

export default redisClient;
export { redisSubscriber };