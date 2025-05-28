#!/bin/bash

# Script para monitorear el estado del contenedor y recursos de la instancia EC2
# Implementa la regla tenant-monitoring: Monitoreo independiente por tenant

# Verificar si el contenedor está ejecutándose
check_container() {
  if [ $(docker ps -q -f name=edevo-web) ]; then
    echo "[$(date)] ✅ Contenedor edevo-web está funcionando correctamente."
    return 0
  else
    echo "[$(date)] ❌ ALERTA: Contenedor edevo-web no está funcionando."
    # Intentar reiniciar el contenedor
    docker-compose -f /home/ec2-user/edevologo-particles/docker-compose.yml up -d
    echo "[$(date)] 🔄 Intentando reiniciar el contenedor."
    return 1
  fi
}

# Verificar uso de CPU y memoria
check_resources() {
  # Aplicando regla resource-quotas: Monitoreamos los límites de recursos por tenant
  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  MEM_USAGE=$(free -m | awk '/Mem/{print $3}')
  MEM_TOTAL=$(free -m | awk '/Mem/{print $2}')
  MEM_PERC=$(awk "BEGIN { pc=100*${MEM_USAGE}/${MEM_TOTAL}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  
  echo "[$(date)] 📊 Uso de CPU: ${CPU_USAGE}%"
  echo "[$(date)] 📊 Uso de Memoria: ${MEM_USAGE}MB/${MEM_TOTAL}MB (${MEM_PERC}%)"
  
  # Alerta si los recursos están por encima del umbral
  if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    echo "[$(date)] ⚠️ ALERTA: Uso de CPU alto (${CPU_USAGE}%)"
  fi
  
  if [ "$MEM_PERC" -gt 80 ]; then
    echo "[$(date)] ⚠️ ALERTA: Uso de Memoria alto (${MEM_PERC}%)"
  fi
}

# Verificar el estado de Nginx
check_nginx() {
  # Aplicando regla tenant-health-checks: Health checks por tenant
  if systemctl is-active --quiet nginx; then
    echo "[$(date)] ✅ Nginx está funcionando correctamente."
  else
    echo "[$(date)] ❌ ALERTA: Nginx no está funcionando."
    echo "[$(date)] 🔄 Intentando reiniciar Nginx..."
    sudo systemctl restart nginx
  fi
}

# Función principal
main() {
  echo "====================== INICIO DE MONITOREO ======================"
  echo "[$(date)] 🔍 Iniciando monitoreo para www.edevo.es (puerto 3000)"
  
  # Implementando tenant-trace-correlation: Trazabilidad que incluye tenant context
  echo "[$(date)] 🏢 Tenant: www.edevo.es"
  echo "[$(date)] 🖥️ Servidor: $(hostname)"
  
  check_container
  check_resources
  check_nginx
  
  echo "====================== FIN DE MONITOREO ======================"
}

# Ejecutar la función principal
main

# Instrucciones de uso:
# 1. Dar permisos de ejecución: chmod +x monitoring.sh
# 2. Configurar en crontab para ejecución periódica:
#    */15 * * * * /home/ec2-user/edevologo-particles/monitoring.sh >> /home/ec2-user/edevologo-particles/monitoring.log 2>&1
