#!/bin/bash

# Actualizar el sistema
sudo yum update -y

# Docker ya está instalado (versión 25.0.8)
echo "✅ Docker ya instalado (versión 25.0.8)"

# Verificar si Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose ya está instalado"
fi

# Instalar Nginx
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx

# Configurar Nginx para www.edevo.es
sudo cp nginx.conf /etc/nginx/conf.d/edevo.conf
sudo systemctl restart nginx

# Crear directorio para el proyecto
mkdir -p ~/edevo-app

echo "Configuración completada. Ahora puedes clonar el repositorio y ejecutar docker-compose up -d"
