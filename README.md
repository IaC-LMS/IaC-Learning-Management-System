# 📚 Proyecto IaC para LMS: IaC-Learning-Management-System

Una institución educativa desea implementar un Learning Management System (LMS) similar a Canvas, que permita la interacción entre alumnos y profesores a través de una aplicación web. El sistema debe soportar funciones críticas como el envío de notificaciones a estudiantes, garantizar una alta disponibilidad y mantener la seguridad.

Problema:
La institución educativa necesita un LMS tipo Canvas. Actualmente no se garantiza la entrega rápida y confiable de notificaciones 
a los alumnos, ni la disponibilidad continua del sistema. Además, el sistema debe cumplir con requisitos de calidad críticos:

Justicacion
Responder en 1–3s.
Mantener disponibilidad del 99.9% las 24h.
Soportar escalado automático.
Estar distribuido en 2 zonas para tolerancia a fallos.
Asegurar datos cifrados y protegidos contra ataques.
Estar debidamente documentado para mantenimiento futuro

---

## 🚀 Tecnologías Utilizadas
- **Docker en el backend y frontend**
- **Docker hub**

### 🔹 Aprovisionamiento
- **Terraform**: Herramienta para la creación, modificación y administración de infraestructura en múltiples proveedores.
- **Nginx**: Servidor web utilizado en el despliegue inicial*.

### 🔹 Configuración
- **Ansible**: Automatización de la configuración de servidores, instalación de dependencias y despliegue de servicios.
- **Balanceadores de carga**:  
  - **Nginx**: Para la distribución básica de tráfico. 

### 🔹 Versiones de aplicaciones
Docker: v28.4.0
Terraform v1.12.3
Ansible v2.18.19




### 🔹 Servicios de aws a utilizar a futuro:
-WAF:Proteger contra el trafico malicioso
-API GATEWAY
-ALB:Balanceador de carga
-VPC: Red virtual privada
-AUTO SCALING: Ajustar la cantidad de instancias segun la demanda AGREGA/QUITA
-FARGATE: ejecutar contenedores sin servidores
-ECS(elastic container service): Coordinar y Gestionar multiples contenedores
-SNS: Enviar notificaciones asincronas 
-KMS: Gestion de claves de cifrado
-IAM: Roles y usuarios
-CLOUDWATCH: Configurar alarmas,logs y monitoreo con otros servicios
-AURORA: Servicio de base de datos relacional: mysql y postgreSQL
-AMAZON ELASTICACHE: Almacenar en memoria datos frecuentes "reducir la carga"


---

## 📂 Estructura del Repositorio

```bash
IaC-Learning-Management-System
│
├── backend/             # Lógica del servidor (Node.js + Docker)
│   ├── Dockerfile        # Configuración de la imagen Docker para el backend
│   ├── index.js          # Archivo principal de la aplicación backend
│   └── package.json      # Dependencias y scripts de Node.js
│
├── frontend/            # Interfaz de usuario (HTML + Docker)
│   ├── Dockerfile        # Configuración de la imagen Docker para el frontend
│   └── index.html        # Página principal del frontend
│
├── infra/               # Definición de la infraestructura IaC
│   ├── ansible/          # Configuración y automatización con Ansible
│   │   └── playbook.yaml # Playbook con tareas de configuración
│   │
│   └── terraform/        # Despliegue de recursos con Terraform
│       ├── main.tf       # Recursos principales a provisionar
│       ├── outputs.tf    # Variables de salida generadas por Terraform
│       ├── provider.tf   # Configuración del proveedor de infraestructura
│       └── variables.tf  # Variables de entrada para parametrizar el despliegue
│
└── README.md            # Documentación principal del proyecto
```

---

## ⚙️ Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalados:

* [Git](https://git-scm.com/)
* [Node.js](https://nodejs.org/) (v16 o superior)
* [Docker](https://www.docker.com/) y [Docker Compose](https://docs.docker.com/compose/)
* [Terraform](https://www.terraform.io/downloads)
* [Ansible](https://www.ansible.com/)
* Editor recomendado: [Visual Studio Code](https://code.visualstudio.com/)

Y tener estas extenciones en visual code:

* Ansible
* Container Tools
* Docker
* HashiCorp Terraform
* YAML

---

## 📥 Clonar el Repositorio

```bash
  # Clonar el repositorio desde GitHub
  git clone https://github.com/usuario/IaC-Learning-Management-System.git

  # Acceder al directorio del proyecto
  cd IaC-Learning-Management-System

  # Verificar ramas existentes
  git branch -a

  # Entrar a la rama main o elegir la rama a clonar 
  git checkout main

```

---

## 🚀 Backend (Node.js + Docker)

### Instalación y ejecución local

```bash
  # Acceder al directorio backend
    cd backend

  # Instalar dependencias
    npm install

  # Ejecutar el servidor
    node index.js
```

El backend se ejecutará en `http://localhost:3000`.

### Ejecución con Docker

```bash
# Construir la imagen
docker build -t backend-lms .

# Ejecutar el contenedor
docker run -d -p 3000:3000 backend-lms
```

---

## 🎨 Frontend (HTML + Docker)

```bash
# Construir la imagen
docker build -t frontend-lms .
# Ejecutar el contenedor
docker run -d -p 8080:80 frontend-lms
```
El frontend estará disponible en `http://localhost:8080`.

---

## 🏗️ Infraestructura (Terraform + Ansible)

### Terraform

```bash
# Acceder al directorio de Terraform
cd IaC-Learning-Management-System/terraform

# Inicializar Terraform
terraform init

# Validar configuración
terraform validate

# Previsualizar los cambios
terraform plan

# Aplicar configuración
terraform apply -auto-approve

# Destruir la infraestructura
terraform destroy -auto-approve
```

### Ansible

```bash
# Acceder al directorio Ansible
cd IaC-Learning-Management-System/ansible

# Ejecutar el playbook
ansible-playbook playbook.yaml -i inventario.ini
```

---

## 👥 Autores

* **Universidad Privada Antenor Orrego** 
* Curso: Infraestructura como codigo
* Integrantes:
    - Eustaquio Avila, Joel
    - Vergara López, Junior
    - Zumaeta Rodriguez Jeremy
* Año: 2025

