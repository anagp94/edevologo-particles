# Despliegue de edevologo-particles en AWS EC2

Este documento describe los pasos para desplegar la aplicación Next.js en una instancia EC2 t2.micro usando Docker.

## Archivos Creados/Modificados

- `Dockerfile`: Configuración para crear la imagen Docker del proyecto
- `docker-compose.yml`: Configuración para gestionar el contenedor Docker
- `nginx.conf`: Configuración de Nginx para routing del dominio www.edevo.es
- `ec2-setup.sh`: Script para configurar la instancia EC2

## Requisitos Previos

- Una instancia EC2 t2.micro con Amazon Linux 2
- Un dominio (edevo.es) configurado para apuntar a la IP de la instancia EC2
- Acceso SSH a la instancia EC2
- Git instalado en la instancia EC2

## Pasos para el Despliegue

### 1. Configurar la Instancia EC2

1. Conéctate a tu instancia EC2 mediante SSH:
   ```
   ssh -i tu-clave.pem ec2-user@tu-ip-publica
   ```

2. Clona el repositorio:
   ```
   git clone https://github.com/tu-usuario/edevologo-particles.git
   cd edevologo-particles
   ```

3. Ejecuta el script de configuración:
   ```
   chmod +x ec2-setup.sh
   ./ec2-setup.sh
   ```

### 2. Desplegar la Aplicación

1. Construye y ejecuta el contenedor Docker:
   ```
   docker-compose up -d
   ```

2. Verifica que el contenedor esté funcionando:
   ```
   docker ps
   ```

### 3. Configuración DNS

1. Asegúrate de que tu dominio www.edevo.es apunte a la IP pública de tu instancia EC2.
2. Verifica la configuración de DNS con:
   ```
   nslookup www.edevo.es
   ```

## Actualización del Proyecto

Para actualizar el proyecto sin eliminar el contenedor:

1. Conéctate a tu instancia EC2
2. Navega al directorio del proyecto:
   ```
   cd ~/edevologo-particles
   ```
3. Actualiza el código fuente desde Git:
   ```
   git pull origin main
   ```
4. Reconstruye y reinicia el contenedor (manteniendo los volúmenes):
   ```
   docker-compose down
   docker-compose up -d --build
   ```

## Notas Importantes

- Esta configuración mantiene el puerto 3000 para www.edevo.es y no interfiere con el contenedor existente en el puerto 5678 (zen.edevo.es).
- Los volúmenes en docker-compose.yml permiten modificar el código sin eliminar el contenedor.
- Se han aplicado las siguientes reglas de despliegue:
  - **tenant-isolation**: Configuración aislada del contenedor en docker-compose.yml 
  - **tenant-specific-logging**: Logs estructurados con Docker para esta aplicación
  - **deployment-zero-downtime**: Configuración que permite actualizaciones sin afectar otros servicios

## Solución de Problemas

Si encuentras problemas con el despliegue:

1. Verifica los logs del contenedor:
   ```
   docker logs edevo-web
   ```

2. Verifica el estado de Nginx:
   ```
   sudo systemctl status nginx
   ```

3. Comprueba que los puertos estén abiertos en la configuración de seguridad de EC2 (grupo de seguridad):
   - Puerto 80 (HTTP)
   - Puerto 443 (HTTPS) si utilizas SSL
   - Puerto 22 (SSH) para administración

## Consideraciones de Seguridad

- Considera configurar HTTPS utilizando Let's Encrypt para asegurar el tráfico web.
- Limita el acceso SSH a direcciones IP específicas en el grupo de seguridad de EC2.
- Mantén el sistema y las dependencias actualizadas regularmente.
