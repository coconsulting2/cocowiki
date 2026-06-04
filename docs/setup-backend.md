# 🚀 Setup del Backend

Guía completa para echar a andar el proyecto **TC3005B.501-Backend** en tu máquina local.

> [!TIP]
> **Flujo recomendado del equipo:** desarrollo con **Docker** (Postgres, Mongo, Bun/Prisma y API con hot-reload). Instala [Docker](https://www.docker.com/products/docker-desktop/) y, si quieres usar los scripts del `package.json`, [Bun](https://bun.sh/). Guía detallada: [Setup Docker](setup-docker.md).

---

## 1. Requisitos previos

Asegúrate de tener instalado lo siguiente antes de continuar:

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| **Node.js** | v18+ | [nodejs.org](https://nodejs.org/) |
| **Bun** | v1+ | [bun.sh](https://bun.sh/) |
| **PostgreSQL** | 14+ | [postgresql.org](https://www.postgresql.org/download/) |
| **MongoDB** | 6.0+ | [mongodb.com](https://www.mongodb.com/docs/manual/installation/) |
| **OpenSSL** | — | Incluido en Git Bash / macOS / Linux |
| **Git** | — | [git-scm.com](https://git-scm.com/) |

---

## 2. Clonar el repositorio

```sh
# Con git
git clone https://github.com/coconsulting2/TC3005B.501-Backend

# O con GitHub CLI
gh repo clone coconsulting2/TC3005B.501-Backend
```

```sh
cd TC3005B.501-Backend
```

---

## 3. Instalar Bun

Si aún no tienes **Bun**, instálalo con alguna de estas opciones:

### Opción A — Script de instalación (recomendado)

```sh
# macOS / Linux
curl -fsSL https://bun.sh/install | bash

# Windows (PowerShell)
powershell -c "irm bun.sh/install.ps1 | iex"
```

### Opción B — Con npm

```sh
npm install -g bun
```

Verifica la instalación:

```sh
bun --version
```

---

## 4. Instalar dependencias del proyecto

Desde la raíz del repositorio:

```sh
bun install
```

> [!NOTE]
> También puedes usar `npm install`, pero se recomienda **Bun** para mantener consistencia con el equipo.

---

## 5. Instalar y configurar PostgreSQL

### 5.1 Descargar PostgreSQL

| SO | Instrucción |
|---|---|
| **Windows** | Descarga el instalador desde [postgresql.org/download/windows](https://www.postgresql.org/download/windows/). Durante la instalación, **anota el usuario y la contraseña** que configures. |
| **macOS** | `brew install postgresql@16` |
| **Linux (Debian/Ubuntu)** | `sudo apt install postgresql` |

### 5.2 Iniciar el servicio

```sh
# Linux
sudo systemctl start postgresql
sudo systemctl enable postgresql   # para que inicie con el sistema

# macOS (Homebrew)
brew services start postgresql@16

# Windows
# El servicio se inicia automáticamente si lo activaste en el instalador.
# También puedes iniciarlo desde "Servicios" de Windows o con:
net start postgresql-x64-16
```

### 5.3 Crear la base de datos y un usuario para el proyecto

Conéctate a PostgreSQL con el usuario administrador:

```sh
# Linux / macOS
sudo -u postgres psql

# Windows (usa la contraseña del instalador)
psql -U postgres
```

```sql
CREATE USER tu_usuario WITH PASSWORD 'tu_contraseña';
CREATE DATABASE "CocoScheme" OWNER tu_usuario;
GRANT ALL PRIVILEGES ON DATABASE "CocoScheme" TO tu_usuario;
\q
```

> [!IMPORTANT]
> El **usuario** y **contraseña** que crees aquí son los que usarás en la variable `DATABASE_URL` del archivo `.env`.

### 5.4 Inicializar la base de datos

Desde la raíz del repositorio:

```sh
# Con datos de prueba (recomendado para desarrollo)
bun run dummy_db

# Solo estructura + datos de referencia (sin datos dummy)
bun run empty_db
```

Estos scripts aplican el schema de Prisma (`prisma/schema.prisma`) y ejecutan los seeds correspondientes.

---

## 6. Instalar y configurar MongoDB

### 6.1 Descargar MongoDB

| SO | Instrucción |
|---|---|
| **Windows** | Descarga el instalador MSI de [MongoDB Community](https://www.mongodb.com/try/download/community). Selecciona la opción **"Install as a Service"**. |
| **macOS** | `brew tap mongodb/brew && brew install mongodb-community` |
| **Linux (Ubuntu)** | Sigue la [guía oficial de MongoDB para Ubuntu](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/). |

### 6.2 Instalar mongosh (Shell interactivo)

Se recomienda para interactuar directamente con las bases:

- [Descargar mongosh](https://www.mongodb.com/try/download/shell)

### 6.3 Iniciar el servicio

```sh
# Linux
sudo systemctl start mongod
sudo systemctl enable mongod

# macOS (Homebrew)
brew services start mongodb-community

# Windows
# Si lo instalaste como servicio, ya debería estar corriendo.
# De lo contrario, abre PowerShell como administrador:
net start MongoDB
```

### 6.4 Verificar que MongoDB está corriendo

```sh
# Linux
sudo systemctl status mongod

# Cualquier SO — intenta conectarte
mongosh
# Si se conecta correctamente, verás el prompt de mongo.
# Escribe exit para salir.
```

---

## 7. Generar certificados HTTPS

El backend usa HTTPS localmente. Para generar los certificados necesitas el archivo de configuración `openssl.cnf` y el script `create_certs.sh`.

### 7.1 Crear el archivo `openssl.cnf`

> [!IMPORTANT]
> El archivo `openssl.cnf` **no se sube al repositorio**. Debes crearlo manualmente en la carpeta `/certs`.

Crea el archivo `certs/openssl.cnf` con el siguiente contenido:

```ini
[req]
default_bits       = 4096
default_md         = sha256
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt             = no

[req_distinguished_name]
C  = MX
ST = Nuevo Leon
L  = Monterrey
O  = CoConsulting
OU = Development
CN = localhost

[v3_req]
basicConstraints     = CA:FALSE
keyUsage             = digitalSignature, keyEncipherment
subjectAltName       = @alt_names

[v3_ca]
basicConstraints     = critical, CA:TRUE
keyUsage             = critical, digitalSignature, cRLSign, keyCertSign

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1  = 127.0.0.1
IP.2  = ::1
```

### 7.2 Ejecutar el script de generación

```sh
cd certs
chmod +x create_certs.sh
./create_certs.sh
```

> [!TIP]
> **En Windows** usa **Git Bash** para ejecutar el script `.sh`, ya que PowerShell/CMD no soportan `chmod` ni scripts bash de forma nativa.

Al finalizar deberías tener estos archivos en `/certs`:

| Archivo | Descripción |
|---|---|
| `ca.key` | Llave privada de la CA |
| `ca.crt` | Certificado raíz de la CA |
| `server.key` | Llave privada del servidor |
| `server.csr` | Solicitud de firma de certificado |
| `server.crt` | Certificado firmado del servidor |

> [!CAUTION]
> **Nunca subas los certificados generados al repositorio.** Ya están en el `.gitignore`, pero verifica antes de hacer commit.

---

## 8. Variables de entorno (`.env`)

### 8.1 Crear el archivo `.env`

```sh
cp .env.example .env
```

### 8.2 Editar con tus credenciales

Abre el archivo `.env` y modifica los valores según tu configuración local:

```ini
# Server Configuration
PORT=3000
NODE_ENV=development

# PostgreSQL (usado por Prisma)
DATABASE_URL=postgresql://tu_usuario:tu_contraseña@localhost:5432/CocoScheme?schema=public

# Orígenes permitidos para CORS (separados por coma)
CORS_ORIGIN=http://localhost:4321,https://localhost:4321

# MongoDB
MONGO_URI=mongodb://localhost:27017

# Llaves de encriptación
# Reemplaza con las llaves del SharePoint o genera las tuyas para desarrollo
AES_SECRET_KEY=<llave_de_32_caracteres>
JWT_SECRET=<llave_secreta>

# Correo (usa las credenciales del SharePoint para las reales)
MAIL_USER=test.mail@outlook.com
MAIL_PASSWORD=password
```

> [!IMPORTANT]
> - `DATABASE_URL` sigue el formato `postgresql://USUARIO:CONTRASEÑA@HOST:PUERTO/BASEDEDATOS?schema=public`. El usuario y contraseña deben coincidir con los que configuraste al [instalar PostgreSQL](#51-descargar-postgresql). El puerto por defecto de PostgreSQL es `5432`.
> - Las llaves `AES_SECRET_KEY` y `JWT_SECRET` las puedes encontrar en el SharePoint del equipo, o para desarrollo local puedes usar cualquier texto con la longitud indicada.
> - Consulta `.env.example` en el repositorio para ver todas las variables disponibles (AWS S3, Wise, Banxico, VAPID, etc.).

---

## 9. Ejecutar el servidor

Asegúrate de que tanto **PostgreSQL** como **MongoDB** estén corriendo, luego ejecuta:

```sh
# Con Bun (recomendado)
bun run dev

# O con npm
npm run dev
```

Deberías ver un mensaje de confirmación indicando que el servidor está corriendo en el puerto configurado y que la conexión a la base de datos fue exitosa.

---

## 10. Documentación de la API (Swagger)

El backend incluye documentación interactiva de la API con Swagger UI.

### 10.1 Acceder a la documentación

1. Levanta el backend (`bun run dev` o con Docker).
2. Abre en tu navegador: **https://localhost:3000/api-docs**

### 10.2 Módulos documentados

| Módulo | Contenido |
|--------|-----------|
| **M1** | CFDI XML parser, tipo de cambio (Wise/Banxico), export contable |
| **M2** | Roles y permisos granulares, workflow rules engine |
| **M3** | Organizaciones, API keys, notificaciones push |

> [!NOTE]
> La documentación usa `swagger-ui-express` con el título "CocoAPI Docs" y sirve el archivo consolidado `openapi/swagger.yaml`. La configuración se encuentra en `app.js`.

---

## 🔍 Troubleshooting

| Problema | Posible solución |
|---|---|
| `bun: command not found` | Revisa la [sección de instalación de Bun](#3-instalar-bun). |
| `password authentication failed for user` | Tu usuario o contraseña de PostgreSQL en `DATABASE_URL` no coinciden. Verifica con `psql -U tu_usuario -d CocoScheme`. |
| `P1001: Can't reach database server` | PostgreSQL no está corriendo o el puerto/host en `DATABASE_URL` es incorrecto. Inicia el servicio con `systemctl start postgresql` o `brew services start postgresql@16`. |
| `MongoServerError: connect ECONNREFUSED` | MongoDB no está corriendo. Inicia el servicio con `systemctl start mongod` o `net start MongoDB`. |
| Error al ejecutar `create_certs.sh` | Asegúrate de tener `openssl.cnf` en `/certs` y de usar Git Bash en Windows. |
| `EADDRINUSE: port already in use` | Otro proceso usa el puerto. Cambia `PORT` en `.env` o cierra el proceso conflictivo. |
