# Setup del Backend

Guía completa para echar a andar el proyecto **TC3005B.501-Backend** en tu máquina local.

> [!TIP]
> **Flujo recomendado del equipo:** desarrollo con **Docker** (Postgres, LocalStack S3, Bun/Prisma y API con hot-reload). Instala [Docker](https://www.docker.com/products/docker-desktop/) y, si quieres usar los scripts del `package.json`, [Bun](https://bun.sh/). Guía detallada: [Setup Docker](setup-docker.md).

---

## 1. Requisitos previos

Asegúrate de tener instalado lo siguiente antes de continuar:

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| **Node.js** | v18+ | [nodejs.org](https://nodejs.org/) |
| **Bun** | v1.1+ | [bun.sh](https://bun.sh/) |
| **PostgreSQL** | **16** | [postgresql.org](https://www.postgresql.org/download/) |
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

Si aún no tienes **Bun**, instálalo:

### macOS / Linux

```sh
curl -fsSL https://bun.sh/install | bash
```

### Windows (PowerShell)

```sh
powershell -c "irm bun.sh/install.ps1 | iex"
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
> El proyecto usa **Bun** como gestor de paquetes y runner de scripts (lockfile `bun.lock`). Bun se usa para instalar y para tooling (`bunx prisma`, `bun run`); el servidor en sí arranca con Node (`node --watch`, ver paso 8).

---

## 5. Instalar y configurar PostgreSQL

El almacén relacional es **PostgreSQL** (base `CocoScheme` en desarrollo), accedido vía **Prisma** (esquema en `prisma/schema.prisma`).

### 5.1 Descargar PostgreSQL

| SO | Instrucción |
|---|---|
| **Windows** | Instalador desde [postgresql.org/download/windows](https://www.postgresql.org/download/windows/). **Anota la contraseña** del usuario `postgres`. |
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
# El servicio se inicia automáticamente tras la instalación.
```

### 5.3 Crear la base de datos y un usuario

Conéctate como superusuario y crea la base y un usuario dedicado:

```sh
psql -U postgres
```

```sql
CREATE DATABASE "CocoScheme";
CREATE USER cocoscheme WITH PASSWORD 'cocoscheme_dev';
GRANT ALL PRIVILEGES ON DATABASE "CocoScheme" TO cocoscheme;
\q
```

> [!IMPORTANT]
> El usuario, contraseña y nombre de base que uses aquí van en la variable `DATABASE_URL` del `.env` (paso 7).

### 5.4 Inicializar el esquema y los datos

Desde la raíz del repositorio, con `DATABASE_URL` ya configurada en el `.env`:

```sh
# Esquema + datos de referencia + datos de prueba (recomendado para desarrollo)
bun run dummy_db

# Solo esquema + datos de referencia (sin datos de prueba)
bun run empty_db
```

> [!NOTE]
> `dummy_db` ejecuta `bunx prisma db push --force-reset && node prisma/seed.js dev`. `empty_db` ejecuta `bunx prisma db push --force-reset && node prisma/seed.js` (sin argumento `dev`, solo datos de referencia). Ambos **borran** la base antes de recrearla.

> [!IMPORTANT]
> `dummy_db` **no** ejecuta `seed-usability.js`. Si necesitas los usuarios de demostración de CocoUAT (`angel.montemayor`, `erick.morales`, `eder.cantero`, `santino.im`, `kevin.esquivel`, `mariano.carretero`, contraseña `Fuego2026!`), ejecútalo por separado:
> ```sh
> node prisma/seed-usability.js
> ```

---

## 6. Generar certificados HTTPS

El backend usa HTTPS localmente. Para generar los certificados necesitas el archivo de configuración `openssl.cnf` y el script `create_certs.sh`.

### 6.1 Crear el archivo `openssl.cnf`

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

### 6.2 Ejecutar el script de generación

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

## 7. Variables de entorno (`.env`)

### 7.1 Crear el archivo `.env`

```sh
cp .env.example .env
```

### 7.2 Editar con tus credenciales

Abre el archivo `.env` y modifica los valores según tu configuración local:

```ini
# Server Configuration
PORT=3000
NODE_ENV=development

# PostgreSQL (usado por Prisma)
# Nativo: Postgres local en :5432. Con el stack Docker se publica en el host como :5434.
DATABASE_URL=postgresql://cocoscheme:cocoscheme_dev@localhost:5432/CocoScheme?schema=public

# Orígenes permitidos para CORS (separados por coma)
CORS_ORIGIN=http://localhost:4321,https://localhost:4321

# Llaves de encriptación (usa las del SharePoint o genera unas para desarrollo)
AES_SECRET_KEY=<llave_de_32_caracteres>   # exactamente 32 caracteres
JWT_SECRET=<llave_secreta>

# Correo (credenciales reales en el SharePoint)
MAIL_USER=test.mail@outlook.com
MAIL_PASSWORD=password
```

> [!IMPORTANT]
> - `DATABASE_URL` debe coincidir con el usuario, contraseña, host, puerto y base que configuraste en PostgreSQL (paso 5). Puerto por defecto nativo: `5432`; con el stack Docker: `5434`.
> - `AES_SECRET_KEY` debe tener **exactamente 32 caracteres**. Para generar una clave válida en desarrollo:
>   ```sh
>   bun -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
>   ```
>   El resultado tiene 64 caracteres hex, que cubren los 32 bytes requeridos por AES-256.
> - `.env.example` incluye además variables **opcionales** para integraciones (AWS S3/LocalStack, Wise, Banxico, SAT, Web Push/VAPID, Duffel). No son necesarias para el desarrollo básico.

---

## 8. Ejecutar el servidor

Asegúrate de que **PostgreSQL** esté corriendo, luego ejecuta:

```sh
bun run dev    # node --watch index.js, HTTPS en :3000
```

Verás el banner ASCII y un mensaje como `Server running on port 3000 with HTTPS`.

---

## 9. Documentación de la API (Swagger)

El backend incluye documentación interactiva de la API con Swagger UI.

### 9.1 Acceder a la documentación

1. Levanta el backend (`bun run dev` o con Docker).
2. Abre en tu navegador: **https://localhost:3000/api-docs**

### 9.2 Módulos documentados

| Módulo | Contenido |
|--------|-----------|
| **M1** | CFDI XML parser, tipo de cambio (Wise/Banxico), export contable |
| **M2** | Roles y permisos granulares, workflow rules engine |
| **M3** | Organizaciones, API keys, notificaciones push |

> [!NOTE]
> La documentación usa `swagger-ui-express` con el título "CocoAPI Docs" y sirve el archivo consolidado `openapi/swagger.yaml`. La configuración se encuentra en `app.js`.
>
> Swagger documenta la **administración** de API keys (`/api/keys/*`). El **consumo ERP** (`/api/external/*`) no está en OpenAPI; ver [API integración ERP](../desarrollo/api-integracion-erp.md).

---

## Troubleshooting

| Problema | Posible solución |
|---|---|
| `bun: command not found` | Revisa la [sección de instalación de Bun](#3-instalar-bun). |
| `password authentication failed` / `database "CocoScheme" does not exist` | Tu `DATABASE_URL` no coincide con el usuario/contraseña/base de PostgreSQL (paso 5). |
| `P1001: Can't reach database server` | PostgreSQL no está corriendo o el host/puerto en `DATABASE_URL` es incorrecto. Inícialo con `systemctl start postgresql` o `brew services start postgresql@16`. |
| Error al ejecutar `create_certs.sh` | Asegúrate de tener `openssl.cnf` en `/certs` y de usar Git Bash en Windows. |
| `EADDRINUSE: port already in use` | Otro proceso usa el puerto. Cambia `PORT` en `.env` o cierra el proceso conflictivo. |
