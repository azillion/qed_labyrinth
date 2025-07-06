import bcrypt from 'bcrypt';
import pool from '../db';

export interface User {
  id: string;
  username: string;
  email: string;
  password_hash: string;
  created_at: Date;
  updated_at: Date;
}

export async function findByUsername(username: string): Promise<User | null> {
  const result = await pool.query(
    'SELECT id, username, email, password_hash, created_at, updated_at FROM users WHERE username = $1',
    [username]
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

export async function createUser(username: string, email: string, hashedPassword: string): Promise<User> {
  const result = await pool.query(
    'INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING id, username, email, password_hash, created_at, updated_at',
    [username, email, hashedPassword]
  );
  
  return result.rows[0];
}