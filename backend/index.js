// Crea y configura el servidor Express
import express from 'express';
import cors from 'cors';
import bcrypt from 'bcrypt';
import { pool } from './db.js';

const app = express();
app.use(cors());
app.use(express.json());

// Registrar usuario
app.post('/api/register', async (req, res) => {
  const { name, email, password } = req.body;
  const hash = await bcrypt.hash(password, 10);
  try {
    await pool.query('INSERT INTO users (name, email, password) VALUES (?, ?, ?)', [name, email, hash]);
    res.json({ message: 'Usuario registrado con éxito' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Iniciar sesión
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) return res.status(400).json({ message: 'Usuario no encontrado' });

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: 'Contraseña incorrecta' });

    res.json({ message: 'Inicio de sesión exitoso', user: { id: user.id, name: user.name, email: user.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// Levanta el servidor
app.listen(3000, () => console.log('✅ Servidor en http://localhost:3000'));
