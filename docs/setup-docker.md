# Docker — Backend y Frontend (desarrollo y release)

Guía para levantar **TC3005B.501-Backend** y **TC3005B.501-Frontend** con Docker, alineada con el trabajo de containerización del repo (commits de **Mariano Carretero**, `MVRer`, y contribuciones posteriores en backend).

> [!IMPORTANT]
> **El flujo canónico del equipo es Docker** (backend y frontend). Las dependencias y el runtime coherentes (Linux, Bun en las imágenes, Postgres/Mongo en backend) viven en contenedores. Usa los scripts `docker:*` del `package.json` de cada repo para **build, tests o Prisma** sin depender de un `node_modules` correcto en Windows. Bun en el host solo sirve como atajo para invocar `docker compose`.

---

## 1. Qué instalar en tu máquina (host)

| Herramienta | ¿Para qué? | Enlace / notas |
|-------------|------------|----------------|
| **Docker Desktop** (Windows/macOS) o **Docker Engine + Compose** (Linux) | Incluye **`docker`** y **`docker compose`** (v2). Es el requisito imprescindible. | [Docker Desktop](https://www.docker.com/products/docker-desktop/) · [Instalación Linux](https://docs.docker.com/engine/install/) |
| **Bun** (opcional pero recomendado) | Los `package.json` exponen atajos como `bun run docker:dev`. Sin Bun, puedes usar los mismos comandos sustituyendo por `docker compose ...` como se indica abajo. | [bun.sh](https://bun.sh/docs/installation) |

> [!IMPORTANT]
> No hace falta instalar **Node**, **pnpm**, **Postgres** ni **Mongo** en el host para desarrollar con Docker: van dentro de los contenedores. El backend usa **Bun** dentro de la imagen para `install` / `prisma`; el runtime del API en dev es **Node 22** (imagen base del Dockerfile del backend).

Verifica:

```sh
docker --version
docker compose version
```

---

## 2. Historial en Git (referencia — trabajo Docker)

Los cambios principales quedaron documentados en estos commits (repositorios `coconsulting2`):

### Backend (`TC3005B.501-Backend`)

| Commit | Autor | Mensaje (resumen) |
|--------|--------|-------------------|
| `d32f87e` | Mariano Carretero (MVRer) | `chore: dockerize for dev + GHCR, migrate pnpm→bun, fix Prisma 7 fallout` — base del flujo dev + imagen GHCR. |
| `6225650` | Héctor Lugo | `feat: implement container entrypoint for automated cert generation, migrations, and seeding...` — entrypoint producción, certs, migraciones. |
| Merge `b2284ec` | — | Integra rama `fix/back/docker-windows-crlf` (normalización CRLF en scripts Docker en Windows). |

Relacionado con PRs del backend: por ejemplo `chore/dockerize-and-bun-migration`, `fix/back/docker-windows-crlf`.

### Frontend (`TC3005B.501-Frontend`)

| Commit | Autor | Mensaje (resumen) |
|--------|--------|-------------------|
| `5c2cb5d` | Mariano Carretero (MVRer) | `chore: dockerize for dev + GHCR, migrate pnpm→bun, add CI` — `docker-compose.dev.yml` + Dockerfile multi-stage. |

Relacionado con PR: `chore/dockerize-and-bun-migration` (merge en historial del frontend).

---

## 3. Resumen de archivos Docker por repo

### Backend

| Archivo | Propósito |
|---------|-----------|
| `Dockerfile` | Targets **`deps`** (dev: Bun + Node 22 + Prisma generate) y **`production`** (imagen publicada en GHCR). |
| `docker-compose.dev.yml` | **Desarrollo:** Postgres 16, Mongo 7, job **`migrate`** (bun install → prisma generate → db push → seed la primera vez), servicio **`backend`** con hot-reload (`node --watch`), certificados HTTPS en volumen `certs`, `node_modules` en volumen Linux. |
| `docker-compose.yml` | **Release / demo:** levanta imagen `ghcr.io/coconsulting2/tc3005b-501-backend:latest`, Postgres y Mongo (sin montar el código fuente del host). |

Puertos típicos en dev: **3000** (API HTTPS), **5432** (Postgres), **27017** (Mongo).

### Frontend

| Archivo | Propósito |
|---------|-----------|
| `Dockerfile` | Targets **`deps`** (dev), **`build`** y **`production`** (SSR Astro con `bun run build`). |
| `docker-compose.dev.yml` | **Solo frontend:** servicio `frontend`, Astro dev con hot-reload, volumen `node_modules_dev`. |

Puerto: **4321**.

> [!NOTE]
> El compose del frontend **no** incluye el backend. El navegador llama a `https://localhost:3000`; las peticiones SSR desde *dentro* del contenedor usan `INTERNAL_API_BASE_URL` apuntando a `host.docker.internal` (ver `docker-compose.dev.yml` del frontend).

---

## 4. Desarrollo local (flujo recomendado)

### 4.1 Backend (terminal 1)

Desde la raíz de **TC3005B.501-Backend**:

```sh
# Con Bun (atajo del package.json)
bun run docker:dev

# Equivalente sin Bun
docker compose -f docker-compose.dev.yml up
```

Variantes útiles:

| Comando | Efecto |
|---------|--------|
| `bun run docker:dev:build` | `up --build` (reconstruye imágenes). |
| `bun run docker:dev:down` | Apaga contenedores y red. |
| `bun run docker:dev:clean` | `down -v` — **borra volúmenes** (Postgres, Mongo, certs, `node_modules` del contenedor, sentinel de seed). Usar para reset completo. |

**Primera ejecución:** el servicio `migrate` instala dependencias, genera Prisma, hace `db push` y ejecuta **seed** una sola vez (marcador en volumen). Si necesitas volver a sembrar desde cero, usa `docker:dev:clean` y vuelve a subir el stack.

**Tests y Prisma dentro del contenedor** (con el stack ya en marcha):

```sh
bun run docker:test
bun run docker:test:watch
bun run docker:prisma -- validate
```

### 4.2 Frontend (terminal 2)

Desde la raíz de **TC3005B.501-Frontend**:

```sh
bun run docker:dev
# o
docker compose -f docker-compose.dev.yml up
```

Variantes: `docker:dev:build`, `docker:dev:down`, `docker:dev:clean` (misma convención que el backend).

Abre el sitio en **http://localhost:4321** (o la URL que muestre Astro). El backend debe estar accesible en **https://localhost:3000** en el host.

**Con el contenedor `frontend` ya en marcha** (`docker:dev` en primer plano o en segundo plano), puedes validar el proyecto sin instalar dependencias en el host:

```sh
bun run docker:build      # astro build dentro del contenedor
bun run docker:typecheck  # astro check
```

(Requieren que el servicio `frontend` esté corriendo; si el contenedor no existe aún, levanta antes con `bun run docker:dev`.)

---

## 5. Solo imagen de producción del backend (sin clonar el repo completo)

Según comentarios en `docker-compose.yml` del backend:

```sh
curl -O https://raw.githubusercontent.com/coconsulting2/TC3005B.501-Backend/main/docker-compose.yml
docker compose up -d
```

Configura secretos reales en un `.env` junto al compose (`AES_SECRET_KEY`, `JWT_SECRET`, correo, etc.).

---

## 6. Troubleshooting rápido

| Problema | Posible causa / solución |
|----------|---------------------------|
| `docker compose` no encontrado | Instala Docker Desktop o el plugin `docker-compose-plugin`. En versiones antiguas existía el binario `docker-compose` separado; el proyecto asume **Compose V2** (`docker compose`). |
| Frontend no llega al API | Asegúrate de que el backend dev esté **levantado** y escuchando en el puerto 3000 del host. Revisa `PUBLIC_API_BASE_URL` e `INTERNAL_API_BASE_URL` en el compose del frontend. |
| Seed duplicado o BD “rara” | `bun run docker:dev:clean` en el backend y vuelve a levantar. |
| Certificados HTTPS en dev | El backend dev genera certs en el volumen `certs` al arrancar. Si falla en Windows, revisa que los scripts en imagen no tengan CRLF (rama `fix/back/docker-windows-crlf`). |
| Puerto 5432 o 27017 ocupado | Otro Postgres/Mongo local choca con los puertos publicados. Para el servicio local o cambia los mapeos en el compose (solo con cuidado en equipo). |

---

## 7. Enlaces relacionados en esta wiki

- [Setup Backend (sin Docker)](setup-backend.md) — flujo histórico con pnpm/MariaDB en host; el equipo prioriza Docker para alinear dependencias.
- [Setup Frontend (sin Docker)](setup-frontend.md)
- [Estilo de código y documentación](estiloCodigo-documentacion.md)
