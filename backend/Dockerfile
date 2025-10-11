# 1. Usamos una imagen base de Node.js
FROM node:18-alpine

# 2. Creamos un directorio dentro del contenedor
WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
