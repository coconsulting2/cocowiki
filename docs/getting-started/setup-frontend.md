# Setup del Frontend

Guía completa para echar a andar el proyecto **TC3005B.501-Frontend** en tu máquina local.

> [!TIP]
> **Flujo recomendado:** levantar el **backend con Docker** y, en otra terminal, el frontend con Docker o localmente. Ver [Setup Docker](setup-docker.md) (incluye Bun, `docker compose` y comandos `bun run docker:dev`).

---

## 1. Requisitos previos

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| **Node.js** | v18+ | [nodejs.org](https://nodejs.org/) |
| **Bun** | v1.1+ | [bun.sh](https://bun.sh/) |
| **Git** | — | [git-scm.com](https://git-scm.com/) |

> [!TIP]
> Si aún no tienes **Bun**, revisa la [guía de instalación de Bun](setup-backend.md#3-instalar-bun) en el Setup del Backend.

---

## 2. Clonar el repositorio

```sh
# Con git
git clone https://github.com/101-Coconsulting/TC3005B.501-Frontend

# O con GitHub CLI
gh repo clone 101-Coconsulting/TC3005B.501-Frontend
```

```sh
cd TC3005B.501-Frontend
```

---

## 3. Instalar dependencias

```sh
bun install
```

> [!NOTE]
> El proyecto usa **Bun** como gestor de paquetes (lockfile `bun.lock`). No uses `npm install` ni `pnpm install`; el equipo usa Bun para mantener consistencia.

---

## 4. Variables de entorno

Crea un archivo `.env` en la raíz del frontend a partir del ejemplo:

```sh
cp .env.example .env
```

Las variables principales son:

```ini
# URL base del backend (browser → localhost; incluye /api)
PUBLIC_API_BASE_URL=https://localhost:3000/api

# Modo de desarrollo (habilita logs adicionales en el cliente)
PUBLIC_IS_DEV=true
```

Si ejecutas el frontend **dentro de Docker** (con `bun run docker:dev`), el `docker-compose.dev.yml` inyecta automáticamente la variable SSR:

```ini
# SSR dentro del contenedor → el backend es accesible vía host.docker.internal
API_URL_SSR=https://host.docker.internal:3000/api
```

En desarrollo nativo (fuera de Docker) no necesitas definir `API_URL_SSR`; el cliente SSR usará `PUBLIC_API_BASE_URL`.

> [!IMPORTANT]
> `PUBLIC_API_BASE_URL` debe apuntar al backend **incluyendo `/api`**. Si seguiste el [Setup del Backend](setup-backend.md), será `https://localhost:3000/api`.
> Asegúrate de que el backend esté corriendo **antes** de hacer peticiones desde el frontend.

---

## 5. Ejecutar el servidor de desarrollo

```sh
bun run dev    # astro dev, HTTPS en :4321
```

El servidor de Astro queda escuchando en `https://localhost:4321`. Abre esa URL y deberías ver el dashboard.

---

## 6. Sesiones y roles

El frontend no usa cookies simuladas ni configuración de rol manual. Las sesiones son gestionadas por el **backend**:

- Al hacer login (`POST /api/user/login`), el backend establece cookies httpOnly (`token`, `role`, `username`, `user_id`, `department_id`).
- El frontend las lee en SSR a través de `src/data/cookies.ts` (función `getSession` / `getCookie`).
- El middleware de Astro (`src/middleware.ts`) valida el `role` de la cookie contra el whitelist de `src/config/routeAccess.ts` en cada petición SSR.

Los roles válidos del sistema son: **Solicitante**, **N1**, **N2**, **Agencia de viajes**, **Cuentas por pagar**, **Administrador**, **Admin Ditta**.

Para probar distintos roles localmente, inicia sesión con los usuarios del seed correspondiente. Los usuarios de CocoUAT (org 101) y sus contraseñas están en la tabla de la [guía del backend](setup-backend.md#54-inicializar-el-esquema-y-los-datos) y en [Setup Docker](setup-docker.md).

---

## 7. Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Astro 5** | Framework web (SSR) |
| **React 19** | Componentes interactivos |
| **TypeScript** | Tipado estático |
| **Tailwind CSS 4** | Estilos utility-first |
| **Cypress** | Testing E2E |

---

## 8. Tests E2E con Cypress

Las pruebas E2E usan **Cypress** con seis perfiles de usuario (uno por rol). Las credenciales se leen de variables de entorno con prefijo `CYPRESS_*`.

Agrega al `.env` (a partir de `.env.example`):

```ini
# Usuarios CocoUAT — seed-usability.js, org_id 101, contraseña común "Fuego2026!"
CYPRESS_SOLICITANTE_USER=angel.montemayor
CYPRESS_SOLICITANTE_PASSWORD=Fuego2026!
CYPRESS_AV_USER=erick.morales
CYPRESS_AV_PASSWORD=Fuego2026!
CYPRESS_CPP_USER=eder.cantero
CYPRESS_CPP_PASSWORD=Fuego2026!
CYPRESS_N1_USER=santino.im
CYPRESS_N1_PASSWORD=Fuego2026!
CYPRESS_N2_USER=kevin.esquivel
CYPRESS_N2_PASSWORD=Fuego2026!
CYPRESS_ADMIN_USER=mariano.carretero
CYPRESS_ADMIN_PASSWORD=Fuego2026!
```

> [!IMPORTANT]
> Los usuarios anteriores de MariaDB (`andres.gomez`, `laura.flores`, etc.) ya **no existen** en la base de datos. Usa únicamente los usuarios del seed de CocoUAT listados arriba.

Para ejecutar Cypress:

```sh
bunx cypress open   # abre la interfaz interactiva
bunx cypress run    # ejecuta en modo headless (CI)
```

> [!NOTE]
> No existen scripts `bun run cypress:open` ni `bun run cypress:run` en el `package.json`. Usa directamente `bunx cypress`.

---

## Troubleshooting

| Problema | Posible solución |
|---|---|
| `bun: command not found` | Revisa la [guía de instalación de Bun](setup-backend.md#3-instalar-bun). |
| `EADDRINUSE: port already in use` | Otro proceso usa el puerto. Cierra el proceso o cambia el puerto en `astro.config.mjs`. |
| Errores de certificado SSL en el navegador | Es normal con certificados auto-firmados en desarrollo. Acepta la excepción de seguridad en el navegador o instala el certificado raíz (`ca.crt`) del backend como trusted en tu SO. |
| No se conecta al Backend | Verifica que `PUBLIC_API_BASE_URL` en `.env` apunte al backend corriendo y que las URLs coincidan. |
