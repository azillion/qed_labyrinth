import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { findByUsername, comparePassword, createUser, hashPassword } from '../models/user';

interface LoginRequest {
  username: string;
  password: string;
}

interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export async function authRoutes(server: FastifyInstance, options: any, done: () => void) {
  server.post('/login', async (request: FastifyRequest<{ Body: LoginRequest }>, reply: FastifyReply) => {
    const { username, password } = request.body;
    
    if (!username || !password) {
      return reply.status(400).send({ error: 'Username and password are required' });
    }
    
    try {
      const user = await findByUsername(username);
      
      if (!user) {
        return reply.status(401).send({ error: 'Invalid credentials' });
      }
      
      const isValidPassword = await comparePassword(password, user.password_hash);
      
      if (!isValidPassword) {
        return reply.status(401).send({ error: 'Invalid credentials' });
      }
      
      const token = server.jwt.sign({ userId: user.id, username: user.username });
      
      return reply.send({ token });
    } catch (error) {
      console.error('Login error:', error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
  
  server.post('/register', async (request: FastifyRequest<{ Body: RegisterRequest }>, reply: FastifyReply) => {
    const { username, email, password } = request.body;
    
    if (!username || !email || !password) {
      return reply.status(400).send({ error: 'Username, email, and password are required' });
    }
    
    try {
      const existingUser = await findByUsername(username);
      
      if (existingUser) {
        return reply.status(409).send({ error: 'Username already exists' });
      }
      
      const hashedPassword = await hashPassword(password);
      const user = await createUser(username, email, hashedPassword);
      
      const token = server.jwt.sign({ userId: user.id, username: user.username });
      
      return reply.status(201).send({ token, user: { id: user.id, username: user.username, email: user.email } });
    } catch (error) {
      console.error('Registration error:', error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
  
  done();
}