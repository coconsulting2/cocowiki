# 🚀 Setup del Backend

Guía completa para echar a andar el proyecto **TC3005B.501-Backend** en tu máquina local.

---

## 1. Requisitos previos

Asegúrate de tener instalado lo siguiente antes de continuar:

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| **Node.js** | v18+ | [nodejs.org](https://nodejs.org/) |
| **pnpm** | v8+ | [pnpm.io](https://pnpm.io/installation) |
| **MariaDB** | 10.6+ | [mariadb.com](https://mariadb.com/downloads/) |
| **MongoDB** | 6.0+ | [mongodb.com](https://www.mongodb.com/docs/manual/installation/) |
| **OpenSSL** | — | Incluido en Git Bash / macOS / Linux |
| **Git** | — | [git-scm.com](https://git-scm.com/) |

---

## 2. Clonar el repositorio

```sh
# Con git
git clone https://github.com/101-Coconsulting/TC3005B.501-Backend

# O con GitHub CLI
gh repo clone 101-Coconsulting/TC3005B.501-Backend
```

```sh
cd TC3005B.501-Backend
```

---

## 3. Instalar pnpm

Si aún no tienes **pnpm**, instálalo con alguna de estas opciones:

### Opción A — Con npm (la más común)

```sh
npm install -g pnpm
```

### Opción B — Con Corepack (viene con Node.js 16.13+)

```sh
corepack enable
corepack prepare pnpm@latest --activate
```

### Opción C — Script de instalación

```sh
# Windows (PowerShell)
iwr https://get.pnpm.io/install.ps1 -useb | iex

# macOS / Linux
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

Verifica la instalación:

```sh
pnpm --version
```

---

## 4. Instalar dependencias del proyecto

Desde la raíz del repositorio:

```sh
pnpm install
```

> [!NOTE]
> También puedes usar `npm install`, pero se recomienda **pnpm** para mantener consistencia con el equipo.

---

## 5. Instalar y configurar MariaDB

### 5.1 Descargar MariaDB

| SO | Instrucción |
|---|---|
| **Windows** | Descarga el instalador MSI desde [mariadb.com/downloads](https://mariadb.com/downloads/). Durante la instalación, **anota el usuario root y la contraseña** que configures. |
| **macOS** | `brew install mariadb` |
| **Linux (Debian/Ubuntu)** | `sudo apt install mariadb-server` |

### 5.2 Iniciar el servicio

```sh
# Linux
sudo systemctl start mariadb
sudo systemctl enable mariadb   # para que inicie con el sistema

# macOS (Homebrew)
brew services start mariadb

# Windows
# El servicio se inicia automáticamente si lo activaste en el instalador.
# También puedes iniciarlo desde "Servicios" de Windows o con:
net start MariaDB
```

### 5.3 Asegurar la instalación (recomendado)

```sh
sudo mysql_secure_installation
# o en Windows:
mysql_secure_installation
```

Sigue las instrucciones para establecer contraseña de root, eliminar usuarios anónimos, etc.

### 5.4 Crear un usuario para el proyecto

Conéctate a MariaDB y crea un usuario dedicado:

```sh
mariadb -u root -p
```

```sql
CREATE USER 'tu_usuario'@'localhost' IDENTIFIED BY 'tu_contraseña';
GRANT ALL PRIVILEGES ON *.* TO 'tu_usuario'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

> [!IMPORTANT]
> El **usuario** y **contraseña** que crees aquí son los que usarás en el archivo `.env` (variables `DB_USER` y `DB_PASSWORD`).

### 5.5 Inicializar la base de datos

Desde la raíz del repositorio:

```sh
# Con datos de prueba (recomendado para desarrollo)
pnpm dummy_db

# Solo estructura sin datos
pnpm empty_db
```

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

# Database Configuration (MariaDB)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=travel_management
DB_USER=tu_usuario          # ← El usuario que creaste en MariaDB
DB_PASSWORD=tu_contraseña   # ← La contraseña que asignaste en MariaDB

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
> - `DB_USER` y `DB_PASSWORD` deben coincidir **exactamente** con el usuario y contraseña que configuraste al [instalar MariaDB](#51-descargar-mariadb).
> - `DB_PORT` por defecto es `3306` para MariaDB. **No confundir** con el puerto de MongoDB (`27017`).
> - Las llaves `AES_SECRET_KEY` y `JWT_SECRET` las puedes encontrar en el SharePoint del equipo, o para desarrollo local puedes usar cualquier texto con la longitud indicada.

---

## 9. Ejecutar el servidor

Asegúrate de que tanto **MariaDB** como **MongoDB** estén corriendo, luego ejecuta:

```sh
# Con pnpm (recomendado)
pnpm run dev

# O con npm
npm run dev
```

Deberías ver un mensaje de confirmación indicando que el servidor está corriendo en el puerto configurado y que la conexión a la base de datos fue exitosa.

---

## 🔍 Troubleshooting

| Problema | Posible solución |
|---|---|
| `pnpm: command not found` | Revisa la [sección de instalación de pnpm](#3-instalar-pnpm). |
| `ERROR 1045 (28000): Access denied for user` | Tu usuario o contraseña de MariaDB en el `.env` no coinciden. |
| `MongoServerError: connect ECONNREFUSED` | MongoDB no está corriendo. Inicia el servicio con `systemctl start mongod` o `net start MongoDB`. |
| Error al ejecutar `create_certs.sh` | Asegúrate de tener `openssl.cnf` en `/certs` y de usar Git Bash en Windows. |
| `EADDRINUSE: port already in use` | Otro proceso usa el puerto. Cambia `PORT` en `.env` o cierra el proceso conflictivo. |
