FROM node:20-alpine AS base

# Configuración del directorio de trabajo
WORKDIR /app

# Instalación de dependencias
COPY package.json pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install

# Copia del código fuente
COPY . .

# Construcción de la aplicación
RUN pnpm build

# Configuración de variables de entorno
ENV NODE_ENV production
ENV PORT 3000

# Exponer el puerto
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["pnpm", "start"]
