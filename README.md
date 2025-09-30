# 📚 Proyecto IaC para LMS

Este repositorio contiene la infraestructura como código (**IaC**) desarrollada por nuestro equipo de trabajo para el despliegue de un **Learning Management System (LMS)**.  
El objetivo principal es automatizar el aprovisionamiento, configuración y administración de los recursos necesarios para garantizar un entorno escalable, seguro y altamente disponible.

---

## 🚀 Tecnologías Utilizadas

### 🔹 Aprovisionamiento
- **Terraform**: Herramienta para la creación, modificación y administración de infraestructura en múltiples proveedores.
- **Nginx**: Servidor web utilizado en el despliegue inicial.

### 🔹 Configuración
- **Ansible**: Automatización de la configuración de servidores, instalación de dependencias y despliegue de servicios.
- **Balanceadores de carga**:  
  - **Nginx**: Para la distribución básica de tráfico.  
  - **HAProxy**: Para balanceo avanzado y alta disponibilidad.

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

---

## 📥 Clonar el Repositorio

```bash
  # Clonar el repositorio desde GitHub
  git clone https://github.com/usuario/IaC-Learning-Management-System.git

  # Acceder al directorio del proyecto
  cd IaC-Learning-Management-System

  # Verificar ramas existentes
  git branch -a

  # Entrar a la rama main
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

### Ejecución local

```bash
# Acceder al directorio frontend
cd frontend

# Abrir el archivo en un navegador
open index.html   # MacOS
xdg-open index.html   # Linux
start index.html   # Windows
```

### Ejecución con Docker

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
cd infra/terraform

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
cd ../ansible

# Ejecutar el playbook
ansible-playbook playbook.yaml -i inventario.ini
```

---

## 👥 Autores

* **Universidad Privada Antenor Orrego** 
* Curso: *Infraestructura como codigo*
* Integrantes:
    - Eustaquio Avila, Joel
    - Vergara López, Junior
    - Zumaeta Rodriguez Jeremy
* Año: 2025

