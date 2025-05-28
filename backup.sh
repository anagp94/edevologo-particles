#!/bin/bash

# Script para realizar backups del contenedor Docker y los archivos de configuración
# Implementa la regla backup-per-tenant: Estrategia de backup individualizada por tenant

# Configuración
BACKUP_DIR="/home/ec2-user/backups/edevo-web"
DATE=$(date +%Y-%m-%d-%H%M)
BACKUP_FILE="$BACKUP_DIR/edevo-web-$DATE.tar.gz"
LOG_FILE="/home/ec2-user/backups/backup-log.txt"

# Crear directorio de backup si no existe
mkdir -p $BACKUP_DIR

echo "=== Iniciando backup de www.edevo.es (puerto 3000) - $(date) ===" >> $LOG_FILE

# Crear backup de los archivos del proyecto
echo "Creando backup de archivos del proyecto..." >> $LOG_FILE
tar -czf $BACKUP_FILE /home/ec2-user/edevologo-particles --exclude="node_modules" --exclude=".next"

# Crear backup de la configuración de Nginx
echo "Creando backup de configuración de Nginx..." >> $LOG_FILE
cp /etc/nginx/conf.d/edevo.conf $BACKUP_DIR/nginx-edevo-$DATE.conf

# Crear backup del volumen Docker (opcional)
if [ -d "/var/lib/docker/volumes" ]; then
  echo "Creando backup de volúmenes Docker..." >> $LOG_FILE
  sudo tar -czf $BACKUP_DIR/docker-volumes-$DATE.tar.gz /var/lib/docker/volumes/edevologo-particles_*
fi

# Limpiar backups antiguos (mantener solo los últimos 7 días)
echo "Limpiando backups antiguos..." >> $LOG_FILE
find $BACKUP_DIR -name "edevo-web-*.tar.gz" -type f -mtime +7 -delete
find $BACKUP_DIR -name "nginx-edevo-*.conf" -type f -mtime +7 -delete
find $BACKUP_DIR -name "docker-volumes-*.tar.gz" -type f -mtime +7 -delete

echo "=== Backup completado: $BACKUP_FILE ($(du -h $BACKUP_FILE | cut -f1)) ===" >> $LOG_FILE
echo "=== Fin del backup - $(date) ===" >> $LOG_FILE

# Instrucciones de uso:
# 1. Dar permisos de ejecución: chmod +x backup.sh
# 2. Configurar en crontab para ejecución diaria:
#    0 2 * * * /home/ec2-user/edevologo-particles/backup.sh
