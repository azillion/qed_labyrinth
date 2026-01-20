import bcrypt from 'bcrypt';
import pool from '../db';
import { randomUUID } from 'crypto';

export interface User {
  id: string;
  email: string;
  password_hash: string;
  created_at: Date;
}

export async function findByEmail(email: string): Promise<User | null> {
  const result = await pool.query(
    'SELECT id, email, password_hash, created_at FROM users WHERE email = $1',
    [email]
  );
  return result.rows[0] || null;
}

export async function hashPassword(password: string): Promise<string> {
  const saltRounds = 10;
  return bcrypt.hash(password, saltRounds);
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export async function createUser(email: string, hashedPassword: string): Promise<User> {
  const id = randomUUID();
  const result = await pool.query(
    'INSERT INTO users (id, email, password_hash) VALUES ($1, $2, $3) RETURNING id, email, password_hash, created_at',
    [id, email, hashedPassword]
  );
  return result.rows[0];
}