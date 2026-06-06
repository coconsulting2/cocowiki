# Estilo de código — Frontend

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.0.0 |
| **Última actualización** | 2026-06-05 |
| **Relacionado** | [Estilo de Código y Documentación](estilo-codigo-documentacion.md) · [Setup Frontend](../getting-started/setup-frontend.md) |

Convenciones específicas del repositorio **`TC3005B.501-Frontend`** (Astro 5 SSR + React 19 + TypeScript + Tailwind 4). Complementa el documento general de [Estilo de Código y Documentación](estilo-codigo-documentacion.md): aquí solo lo propio del frontend.

---

## 1. Lenguajes y extensiones

| Extensión | Uso | Ejemplo |
|-----------|-----|---------|
| `.astro` | Páginas (`src/pages/`) y layouts (`src/layouts/`). SSR: TypeScript en el frontmatter (`---`) + JSX en el template. | `dashboard.astro`, `MainLayout.astro` |
| `.tsx` | Componentes React (islas interactivas) — llevan JSX. | `LoginForm.tsx`, `TravelRequestForm.tsx` |
| `.ts` | Utilidades, tipos, configuración y stores (sin JSX). | `apiClient.ts`, `roles.ts`, `routeAccess.ts` |

- **Componentes** (React y Astro) en **PascalCase**: `Button.tsx`, `Sidebar.astro`.
- **Utilidades, tipos y config** en **camelCase**: `apiClient.ts`, `routeAccess.ts`.
- Funciones y variables en **camelCase**; constantes globales en **UPPER_SNAKE_CASE**.

---

## 2. Estructura de `src/`

| Carpeta | Contenido |
|---------|-----------|
| `assets/` | Imágenes, logos y SVG estáticos. |
| `components/` | Componentes React (`.tsx`) y Astro (`.astro`): UI base (`Button`, `Modal`, `Toast`, `Table`), formularios y paneles de administración. |
| `config/` | Configuración del cliente: `routeAccess.ts` (RBAC de rutas), `role-labels.ts`, etc. |
| `data/` | Acceso a cookies/sesión (`cookies.ts` con el tipo `Session`). |
| `layouts/` | Layouts base de Astro (`Layout.astro`, `MainLayout.astro`). |
| `pages/` | Rutas de Astro (SSR). El nombre del archivo es la URL. |
| `stores/` | Stores de estado del lado del cliente (`organizationStore.ts`, `permissionStore.ts`). |
| `styles/` | CSS global y tokens de Tailwind. |
| `types/` | Interfaces y tipos TypeScript (`roles.ts`, `permissions.ts`, `menu-config.ts`). |
| `utils/` | Utilidades transversales (`apiClient.ts`, `sessionExpiredHandler.ts`, helpers CFDI…). |
| `views/` | Vistas compuestas por rol y subpaneles de admin (`views/admin/`). |

---

## 3. Imports y alias de ruta

Usa **siempre** los alias definidos en `tsconfig.json` en vez de rutas relativas largas (`../../../`). Usa `import type` para los imports que solo aportan tipos.

| Alias | Apunta a |
|-------|----------|
| `@/*` | `src/*` |
| `@assets/*` | `src/assets/*` |
| `@components/*` | `src/components/*` |
| `@config/*` | `src/config/*` |
| `@data/*` | `src/data/*` |
| `@layouts/*` | `src/layouts/*` |
| `@pages/*` | `src/pages/*` |
| `@stores/*` | `src/stores/*` |
| `@styles/*` | `src/styles/*` |
| `@type/*` | `src/types/*` |
| `@utils/*` | `src/utils/*` |
| `@views/*` | `src/views/*` |

```typescript
import Button from "@components/Button";
import { apiRequest } from "@utils/apiClient";
import type { UserRole } from "@type/roles";
```

---

## 4. Componentes React

- **Function components** (sin clases) tipados con una interfaz de props (`Props` o `XxxProps`); los props opcionales se marcan con `?`.
- Hooks estándar: `useState`/`useEffect` para estado y efectos; `useCallback`/`useMemo` cuando hay costo real.
- Los componentes mayores abren con una cabecera JSDoc breve (`Author` + `Description`).

```tsx
/**
 * Author: <nombre>
 * Description: Formulario de creación/edición de usuarios.
 */
interface CreateUserFormProps {
  mode: "create" | "edit";
  token: string;
  initialData?: UserFormData;
}

export default function CreateUserForm({ mode, token, initialData }: CreateUserFormProps) {
  const [form, setForm] = useState<UserFormData>(initialData ?? emptyForm());
  // …
}
```

- **Islas en Astro:** las páginas montan los componentes React con la directiva de cliente adecuada (`client:load`, `client:visible`, `client:only="react"`). Pasa la sesión (`token`, `role`, `user_id`) como props desde el frontmatter SSR, no la leas en el cliente cuando ya la tienes en el servidor.

---

## 5. Llamadas a la API

Toda petición pasa por **`apiRequest`** (`@utils/apiClient`). No uses `fetch` directo en componentes.

```typescript
export async function apiRequest<T = any>(
  path: string,
  options?: { method?: HTTP; data?: any; headers?: Record<string, string>; cookies?: APIContext["cookies"] },
): Promise<T>;
```

`apiRequest` resuelve la URL base (`PUBLIC_API_BASE_URL` / `API_URL_SSR`) y adjunta automáticamente:

- **`Authorization: Bearer <token>`** tomado de la sesión.
- **`csrf-token`** en mutaciones (`POST`/`PUT`/`PATCH`/`DELETE`), excepto en `POST /user/login`.
- **`X-Organization-Id`** cuando un super-admin Ditta (ROOT) impersona otra organización.
- `credentials: "include"` y `Content-Type: application/json`.

```typescript
// GET
const requests = await apiRequest<RequestDTO[]>("/applicant/get-user-requests/1");

// POST con cuerpo
await apiRequest("/applicant/create-request", { method: "POST", data: payload });
```

> En SSR (frontmatter `.astro`) pásale las cookies de Astro: `apiRequest("/...", { cookies: Astro.cookies })`.

---

## 6. Manejo de errores y avisos

Envuelve las llamadas en `try/catch` y comunica el resultado con un toast/alerta; nunca dejes el error silencioso.

```typescript
try {
  await apiRequest("/endpoint", { method: "POST", data });
  showAppAlert("Cambios guardados", "success");
} catch (error) {
  showAppAlert("Error al procesar la solicitud", "error");
}
```

- Avisos vía el componente `Toast` / helper `showAppAlert`, o estado local `{ message, type: "success" | "error" }`.
- La **sesión expirada** la maneja `sessionExpiredHandler`: ante un 401 con `TOKEN_EXPIRED` / `INVALID_TOKEN` / `MISSING_TOKEN`, limpia cookies, muestra un único modal y redirige a `/login`.

---

## 7. Estilos

- **Tailwind CSS 4** utility-first como opción por defecto; clases en el JSX/`.astro`.
- Para temas oscuros y colores de marca se usan tokens en constantes (`COLOR_PRIMARY`, `COLOR_BG_DARK`) aplicados como estilos inline puntuales.
- Evita hojas CSS sueltas por componente; reutiliza utilidades y los tokens globales de `src/styles/`.

---

## 8. Formularios y validación

- Formularios con **`react-hook-form`**; validación con **`zod`** vía `@hookform/resolvers` cuando el esquema lo amerita.
- Mensajes de error claros y en español, junto al campo (`FormErrors`).
- Subida de archivos con `react-dropzone` / el componente `FileDropZone`.

---

## 9. RBAC en el frontend

El control de acceso por rol vive en tres piezas que deben mantenerse alineadas:

1. **`src/config/routeAccess.ts`** — `roleRoutes: Record<UserRole, string[]>`: qué rutas puede ver cada rol.
2. **`src/middleware.ts`** — valida en cada request SSR el `role` de la cookie contra ese whitelist; si no, redirige a `/login`.
3. **`src/types/menu-config.ts`** — `SIDEBAR_CONFIG[role]`: el menú se renderiza dinámicamente por rol (RBAC estricto: lo que no se permite, no se muestra).

Los roles válidos (`UserRole`, `src/types/roles.ts`):

```typescript
type UserRole =
  | "Solicitante"
  | "Agencia de viajes"
  | "Cuentas por pagar"
  | "N1"
  | "N2"
  | "Administrador"
  | "Admin Ditta";
```

> Al agregar una ruta nueva, regístrala en `routeAccess.ts` **y** en `menu-config.ts`; de lo contrario el middleware la bloqueará o no aparecerá en el menú. El mapa rutas × rol está documentado en [Flujos de pantallas por rol](../guias-usuario/flujos-pantallas-por-rol.md).

---

## 10. Testing

| Capa | Herramienta | Ubicación |
|------|-------------|-----------|
| Unitario / componente | Vitest + Testing Library (jsdom) + MSW | `tests/frontend/**/*.test.{ts,tsx}` |
| End-to-end | Cypress | `cypress/e2e/*.cy.ts` |

- Los tests de componente montan con `render` de Testing Library y simulan interacción con `@testing-library/user-event`; el backend se mockea con **MSW** (`tests/setup.ts`).
- Cobertura con umbral del **70%** sobre la lista de `coverage.include` en `vitest.config.ts`.
- Cada archivo de test abre con cabecera JSDoc (`Author` + `Description`).
- Detalle de ejecución y credenciales de los roles en [Setup Frontend §9](../getting-started/setup-frontend.md).

---

## 11. Antes de commitear

```sh
bun run typecheck   # astro check (warnings preexistentes no bloquean)
bun run test        # suite de Vitest en verde
bun run build       # gate real de CI
```

Sigue las convenciones de ramas y commits del [documento general](estilo-codigo-documentacion.md): rama `tipo/front/descripcion-corta`, commits en inglés/imperativo, PR a `main` (protegida) con aprobación del Owner de Frontend. El autor nunca aprueba su propio MR.
