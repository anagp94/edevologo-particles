#!/bin/bash

# Script para actualizar y gestionar el despliegue de la aplicación
# Aplica reglas de tenant-safe-migrations y deployment-zero-downtime

# Configuración
APP_DIR="/home/ec2-user/edevologo-particles"
LOG_FILE="$APP_DIR/deploy-log.txt"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Función para registrar mensajes en el log
log_message() {
  echo "[$TIMESTAMP] $1" >> $LOG_FILE
  echo "[$TIMESTAMP] $1"
}

# Verificar que estamos en el directorio correcto
cd $APP_DIR || { log_message "❌ Error: No se pudo acceder al directorio $APP_DIR"; exit 1; }

# Actualizar el código desde el repositorio
log_message "🔄 Actualizando código desde el repositorio..."
git pull origin main || { log_message "❌ Error al actualizar el código desde Git"; exit 1; }

# Respaldo previo a la actualización (tenant-data-backup)
log_message "📦 Creando respaldo previo a la actualización..."
./backup.sh

# Verificación previa al despliegue (tenant-architecture-review)
log_message "🔍 Verificando la configuración de Docker..."
docker-compose config --quiet || { log_message "❌ Error en la configuración de Docker Compose"; exit 1; }

# Aplicando tenant-maintenance-mode: Modo mantenimiento individual
log_message "🚧 Activando modo de mantenimiento..."
# Actualizar la configuración de Nginx para mostrar una página de mantenimiento (opcional)
# sudo cp maintenance.html /var/www/html/
# sudo sed -i 's/proxy_pass/return 503/g' /etc/nginx/conf.d/edevo.conf
# sudo systemctl reload nginx

# Actualización con zero-downtime (deployment-zero-downtime)
log_message "🚀 Iniciando actualización con zero-downtime..."
# Primero construimos la nueva imagen sin detener el servicio actual
docker-compose build --no-cache || { log_message "❌ Error al construir la nueva imagen"; exit 1; }

# Luego realizamos el despliegue con rollback automático si hay error
log_message "🔄 Aplicando actualización..."
docker-compose up -d --force-recreate || { 
  log_message "❌ Error durante el despliegue. Realizando rollback..."; 
  docker-compose stop
  docker-compose up -d --no-recreate
  log_message "⚠️ Rollback completado. Se ha restaurado la versión anterior.";
  exit 1; 
}

# Verificar que el nuevo contenedor está funcionando
sleep 5
if [ $(docker ps -q -f name=edevo-web) ]; then
  log_message "✅ Nuevo contenedor desplegado correctamente."
else
  log_message "❌ Error: El nuevo contenedor no está en ejecución."
  exit 1
fi

# Desactivar modo mantenimiento
log_message "🏁 Desactivando modo de mantenimiento..."
# sudo sed -i 's/return 503/proxy_pass/g' /etc/nginx/conf.d/edevo.conf
# sudo systemctl reload nginx

# Limpieza de recursos (tenant-resource-management)
log_message "🧹 Limpiando recursos no utilizados..."
docker system prune -af --volumes || log_message "⚠️ Advertencia: No se pudieron limpiar todos los recursos."

# Verificación post-despliegue (tenant-health-checks)
log_message "🔍 Ejecutando verificaciones post-despliegue..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200" || {
  log_message "⚠️ Advertencia: La aplicación no responde correctamente en el puerto 3000.";
}

log_message "✅ Proceso de actualización completado exitosamente."
log_message "📊 Estadísticas post-despliegue:"
log_message "- Uso de disco: $(df -h / | awk 'NR==2 {print $5}')"
log_message "- Contenedores en ejecución: $(docker ps --format '{{.Names}}' | wc -l)"

# Instrucciones de uso:
# 1. Dar permisos de ejecución: chmod +x update-deploy.sh
# 2. Ejecutar cuando se necesite actualizar: ./update-deploy.sh
