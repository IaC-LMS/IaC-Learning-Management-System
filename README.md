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
├── terraform/       # Archivos de infraestructura (provisionamiento)
├── ansible/         # Playbooks de configuración
├── docs/            # Documentación adicional
└── README.md        # Este archivo
