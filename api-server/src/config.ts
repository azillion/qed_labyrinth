import { config } from 'dotenv';
config();

export const dbConfig = {
  host: process.env.QED_DB_HOST || 'localhost',
  port: parseInt(process.env.QED_DB_PORT || '5432', 10),
  user: process.env.QED_DB_USER || 'postgres',
  password: process.env.QED_DB_PASSWORD || '',
  database: process.env.QED_DB_NAME || 'qed_labyrinth',
};

export const jwtConfig = {
  secret: process.env.JWT_SECRET || 'your-shared-secret-make-this-secure',
};