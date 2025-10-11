// db.js (CORREGIDO)
import mysql from 'mysql2/promise';

export const pool = mysql.createPool({
  // Usamos variables de entorno de AWS/ECS**
  host: process.env.DB_HOST,      // Inyectado por Terraform: el Endpoint de Aurora
  user: process.env.DB_USER,      // Inyectado por Terraform: 'admin'
  password: process.env.DB_PASS,  // Inyectado por Terraform: '123456789'
  database: process.env.DB_NAME,  // Inyectado por Terraform: 'lms_db'
  port: 3306,                     // Puerto estándar de MySQL
  
});