const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2/promise"); // driver mysql2 compatible con promesas
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const app = express();
app.use(bodyParser.json());

// Configuración
const REGION = process.env.AWS_REGION || "us-east-1";
const snsClient = new SNSClient({ region: REGION });
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

// Configuración de Aurora (Aurora MySQL)
const dbConfig = {
  host: process.env.DB_HOST,     // endpoint de Aurora
  user: process.env.DB_USER,     // usuario configurado en Terraform
  password: process.env.DB_PASS, // contraseña configurada
  database: process.env.DB_NAME, // nombre de la base de datos
};

// Endpoint para crear tarea
app.post("/tasks", async (req, res) => {
  const { title, description, courseId, createdBy } = req.body;

  if (!title || !createdBy) {
    return res.status(400).json({ error: "title y createdBy son requeridos" });
  }

  try {
    const connection = await mysql.createConnection(dbConfig);

    // Insertamos en Aurora
    const [result] = await connection.execute(
      "INSERT INTO tasks (title, description, course_id, created_by, created_at) VALUES (?, ?, ?, ?, NOW())",
      [title, description || "", courseId || "", createdBy]
    );

    await connection.end();

    // Publicamos en SNS
    const message = `Tarea creada: ${title}`;
    const publishParams = {
      TopicArn: SNS_TOPIC_ARN,
      Message: message,
      Subject: "Nueva tarea creada",
    };
    await snsClient.send(new PublishCommand(publishParams));

    return res.json({
      taskId: result.insertId,
      message: "Task creada y notificación enviada",
    });
  } catch (err) {
    console.error("Error:", err);
    return res.status(500).json({ error: "internal error", details: err.message });
  }
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend corriendo en puerto ${PORT}`));
