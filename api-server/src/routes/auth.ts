import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { findByEmail, comparePassword, createUser, hashPassword } from '../models/user';

interface LoginRequest {
  email: string;
  password: string;
}

interface RegisterRequest {
  email: string;
  password: string;
}

export async function authRoutes(server: FastifyInstance, options: any) {
  server.post('/login', async (request: FastifyRequest<{ Body: LoginRequest }>, reply: FastifyReply) => {
    const { email, password } = request.body;
    
    if (!email || !password) {
      return reply.status(400).send({ error: 'Email and password are required' });
    }
    
    try {
      const user = await findByEmail(email);
      
      if (!user) {
        return reply.status(401).send({ error: 'Invalid credentials' });
      }
      
      const isValidPassword = await comparePassword(password, user.password_hash);
      
      if (!isValidPassword) {
        return reply.status(401).send({ error: 'Invalid credentials' });
      }
      
      const token = server.jwt.sign({ userId: user.id, email: user.email });
      
      return reply.send({ token });
    } catch (error) {
      console.error('Login error:', error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
  
  server.post('/register', async (request: FastifyRequest<{ Body: RegisterRequest }>, reply: FastifyReply) => {
    const { email, password } = request.body;
    
    if (!email || !password) {
      return reply.status(400).send({ error: 'Email and password are required' });
    }
    
    try {
      const existingUser = await findByEmail(email);
      
      if (existingUser) {
        return reply.status(409).send({ error: 'Email already exists' });
      }
      
      const hashedPassword = await hashPassword(password);
      const user = await createUser(email, hashedPassword);
      
      const token = server.jwt.sign({ userId: user.id, email: user.email });
      
      return reply.status(201).send({ token, user: { id: user.id, email: user.email } });
    } catch (error) {
      console.error('Registration error:', error);
      return reply.status(500).send({ error: 'Internal server error' });
    }
  });
}