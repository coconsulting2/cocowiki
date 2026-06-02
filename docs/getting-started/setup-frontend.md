# 🎨 Setup del Frontend

Guía completa para echar a andar el proyecto **TC3005B.501-Frontend** en tu máquina local.

> [!TIP]
> **Flujo recomendado:** levantar el **backend con Docker** y, en otra terminal, el frontend con Docker o localmente. Ver [Setup Docker](setup-docker.md) (incluye Bun, `docker compose` y comandos `bun run docker:dev`).

---

## 1. Requisitos previos

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| **Node.js** | v18+ | [nodejs.org](https://nodejs.org/) |
| **pnpm** | v8+ | [pnpm.io](https://pnpm.io/installation) |
| **Git** | — | [git-scm.com](https://git-scm.com/) |

> [!TIP]
> Si aún no tienes **pnpm**, revisa la [guía de instalación de pnpm](setup-backend.md#3-instalar-pnpm) en el Setup del Backend.

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
pnpm install
```

> [!NOTE]
> También puedes usar `npm install`, pero se recomienda **pnpm** para mantener consistencia con el equipo.

---

## 4. Variables de entorno

El frontend usa variables de entorno definidas en `astro.config.mjs`. Crea un archivo `.env` en la raíz del frontend:

```sh
touch .env
```

Agrega las siguientes variables:

```ini
# URL base del backend (donde corre tu servidor Express)
PUBLIC_API_BASE_URL=https://localhost:3000

# Modo de desarrollo (true para desarrollo local)
PUBLIC_IS_DEV=true
```

> [!IMPORTANT]
> - `PUBLIC_API_BASE_URL` debe apuntar a la URL donde corre tu **Backend**. Si seguiste el [Setup del Backend](setup-backend.md), será `https://localhost:3000` (con HTTPS porque el backend usa certificados).
> - Asegúrate de que el Backend esté corriendo **antes** de intentar hacer requests desde el Frontend.

---

## 5. Ejecutar el servidor de desarrollo

```sh
# Con pnpm (recomendado)
pnpm run dev

# O con npm
npm run dev
```

Se abrirá una ventana del navegador automáticamente y deberías ver el dashboard.

---

## 6. Configuración de roles (modo mock)

Si el Backend aún no está conectado o quieres probar distintos dashboards localmente, puedes cambiar el rol editando el archivo `src/data/cookies.ts`:

```typescript
import type { UserRole } from "@type/roles";

const mockCookies = {
    username: "John Doe",
    // CAMBIA ESTE VALOR para ver distintos dashboards:
    // 'Applicant' | 'Authorizer' | 'Admin' | 'AccountsPayable' | 'TravelAgency'
    role: "Authorizer" as UserRole
};

export const getCookie = (key: keyof typeof mockCookies): string | UserRole => {
    return mockCookies[key];
};
```

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

## 🔍 Troubleshooting

| Problema | Posible solución |
|---|---|
| `pnpm: command not found` | Revisa la [guía de instalación de pnpm](setup-backend.md#3-instalar-pnpm). |
| `EADDRINUSE: port already in use` | Otro proceso usa el puerto. Cierra el proceso o cambia el puerto en `astro.config.mjs`. |
| Errores de certificado SSL en el navegador | Es normal con certificados auto-firmados. Acepta el riesgo en el navegador o usa `PUBLIC_IS_DEV=true`. |
| No se conecta al Backend | Verifica que `PUBLIC_API_BASE_URL` en `.env` apunte al Backend corriendo y que las URLs coincidan. |
