# Sistema de permisos granulares

| Metadato | Valor |
|---|---|
| **Versión** | 1.0.0 |
| **Última actualización** | 2026-04-22 |
| **Fuente** | [permissionMiddleware.js](../../TC3005B.501-Backend/middleware/permissionMiddleware.js), [prisma/seed.js](../../TC3005B.501-Backend/prisma/seed.js), [modelo-er.md](arquitectura-datos/modelo-er.md#sistema-de-permisos-granulares-rbac--directo-a-usuario) |

## TL;DR para agregar un permiso nuevo

1. Edita `TC3005B.501-Backend/prisma/seed.js` → agrega el permiso a `PERMISSION_CATALOG` y al grupo correspondiente en `PERMISSION_GROUPS`.
2. Reinicia el stack: `bun run docker:dev:down && bun run docker:dev`. El migrate service re-aplica la seed de referencia (idempotente) automáticamente — tus compañeros obtendrán el permiso al próximo `up` sin hacer nada.
3. En la ruta backend: `...requirePermission("mi_resource:mi_action")`.
4. En React: `hasPermission(perms, "mi_resource:mi_action")` — los permisos se cargan al login y están en el store.

No necesitas migraciones de Prisma (usamos `db push`), no necesitas tocar JWTs, no necesitas reiniciar nada manualmente más allá de `docker:dev:down && docker:dev`.

---

## Arquitectura en una página

```
Cliente ──(POST /api/user/login)──> Backend
                                       │
                                       ├─ JWT con { user_id, role, ip }
                                       └─ Body JSON:
                                          { token, role, permissions: ["travel_request:create", ...] }
                                                                        ▲
                                                                        │
                         ┌──────────────────────────────────────────────┘
                         │ (resuelto por permissionService.loadEffectivePermissions)
                         │
              ┌──────────┴───────────┐
              │                      │
       role.rolePermissions    role.rolePermissionGroups[*].items
              ∪                      ∪
       user.userPermissions    user.userPermissionGroups[*].items
              └──────────┬───────────┘
                         │ unión deduplicada → Set<permission_code>
                         │
Protege rutas:   ...requirePermission("travel_request:authorize")
                 ↓
                 [authenticateToken, loadPermissions, authorizePermission]
                                                       ↑
                                   nunca se puede saltar authenticateToken
                                   (orden garantizado por el helper)
```

### Modelos Prisma involucrados

Ver [`arquitectura-datos/modelo-er.md`](arquitectura-datos/modelo-er.md#sistema-de-permisos-granulares-rbac--directo-a-usuario) para el diagrama Mermaid completo.

| Tabla | Propósito |
|---|---|
| `Permission` | Permiso atómico con `code` único en formato `resource:action`. |
| `PermissionGroup` | Bundle reutilizable de permisos. |
| `Permission_Group_Item` | Membresía grupo ↔ permiso. |
| `Role_Permission` | Grant directo de un permiso a un rol. |
| `Role_Permission_Group` | Grant de un grupo a un rol (se expande al resolver). |
| `User_Permission` | Grant directo de un permiso a un usuario (aditivo sobre el rol). |
| `User_Permission_Group` | Grant de un grupo a un usuario (aditivo). |

### Semántica

- **Aditivo únicamente** (v1). No existe `deny` explícito: los permisos del usuario se **suman** a los del rol. Para "quitar" un permiso a un usuario específico, tienes que cambiarlo de rol.
- **Sin jerarquía entre roles**. N2 no "hereda" de N1: cada uno está asociado al mismo grupo `TravelRequestApprover` que contiene `travel_request:authorize`.
- **Sin caché entre requests**. Cada request autenticado resuelve permisos con **una** query Prisma (findUnique + includes anidados). Lo suficientemente rápido para el tamaño actual; si hace falta, se puede memoizar en el JWT o en Redis.

---

## Catálogo actual (referencia)

Definido en [`prisma/seed.js`](../../TC3005B.501-Backend/prisma/seed.js) bajo `PERMISSION_CATALOG` y `PERMISSION_GROUPS`.

### Permisos

| Recurso | Acción | Código |
|---|---|---|
| `travel_request` | `create` · `view_own` · `view_any` · `edit_own` · `submit` · `cancel` · `authorize` | `travel_request:create`, `travel_request:view_own`, … |
| `travel_agent` | `attend` | `travel_agent:attend` |
| `accounts_payable` | `attend` | `accounts_payable:attend` |
| `accounting` | `export` | `accounting:export` |
| `receipt` | `upload` · `delete_own` · `validate` | `receipt:upload`, `receipt:delete_own`, `receipt:validate` |
| `expense` | `view` · `submit` | `expense:view`, `expense:submit` |
| `authorizer` | `view_alerts` | `authorizer:view_alerts` |
| `user` | `view_self` · `list` · `create` · `edit` · `manage_permissions` | `user:view_self`, … |
| `permission` | `read` · `write` | `permission:read`, `permission:write` |
| `permission_group` | `manage` | `permission_group:manage` |
| `role` | `manage_permissions` | `role:manage_permissions` |

### Grupos y su asignación a roles

| Grupo | Rol asignado | Incluye |
|---|---|---|
| `TravelRequestAuthor` | Solicitante | Crear/editar/cancelar sus propias solicitudes, subir comprobantes, enviar gastos |
| `TravelRequestApprover` | N1, N2 | Todo lo del Solicitante **+** `travel_request:authorize` + `authorizer:view_alerts` |
| `TravelAgencyOps` | Agencia de viajes | `travel_agent:attend` + `travel_request:view_any` |
| `AccountsPayableOps` | Cuentas por pagar | `accounts_payable:attend` + `receipt:validate` + `accounting:export` + lecturas |
| `OrgAdmin` | Administrador | Gestión de usuarios y del propio sistema de permisos |

---

## Cómo agregar un permiso nuevo a una feature

### 1. Definir el permiso en el seed

En `TC3005B.501-Backend/prisma/seed.js`, añade una entrada al array `PERMISSION_CATALOG`:

```js
{ code: "expense:export", resource: "expense", action: "export", description: "Export expenses to CSV" },
```

El **`code`** es el que usarás en el middleware — convención `resource:action`, todo minúsculas, máx. 80 caracteres.

### 2. Asignarlo a un grupo (o directo al rol)

Si el permiso forma parte de un rol ya existente, agrégalo al array `permissions` del grupo correspondiente en `PERMISSION_GROUPS`:

```js
{
  groupName: "AccountsPayableOps",
  description: "Cuentas por pagar — valida comprobantes y exporta contabilidad",
  permissions: [
    "accounts_payable:attend",
    "accounting:export",
    "expense:export",        // ← nuevo
    "receipt:validate",
    "expense:view",
    "travel_request:view_any",
    "user:view_self",
  ],
},
```

Si necesitas un grupo nuevo, agrega un objeto a `PERMISSION_GROUPS` y un mapeo en `ROLE_GROUP_ASSIGNMENTS`.

### 3. Aplicar el seed

```sh
# Con docker compose (recomendado)
cd TC3005B.501-Backend
bun run docker:dev:down
bun run docker:dev
# El migrate service re-corre `node prisma/seed.js` (idempotente) en cada up.

# O, si ya tienes el backend corriendo nativo:
node prisma/seed.js
```

**No necesitas un `docker:dev:clean`** (que borra datos). El catálogo se aplica vía `upsert` y los join-tables vía `createMany({skipDuplicates:true})` — seguro de correr repetidamente.

### 4. Proteger la ruta backend

En tu archivo de rutas (`TC3005B.501-Backend/routes/*.js`):

```js
import { requirePermission, requireAnyPermission } from "../middleware/permissionMiddleware.js";

// AND — requiere TODOS los códigos listados
router.route("/export-expenses")
  .get(generalRateLimiter, ...requirePermission("expense:export"), handler);

// OR — requiere AL MENOS UNO
router.route("/some-endpoint")
  .get(...requireAnyPermission("travel_request:view_own", "travel_request:view_any"), handler);
```

**Nunca uses `authorizePermission` directamente**. Siempre `requirePermission` / `requireAnyPermission`, que componen `authenticateToken` como primer middleware — así es imposible introducir una ruta sin autenticación.

### 5. Exponer condicionalmente en el frontend

Los permisos efectivos del usuario se cargan en `sessionStorage` la primera vez que cualquier componente llama a `getCachedPermissions()`. El login también los devuelve directamente en el body para poder pre-cargar el store.

```tsx
import { hasPermission } from "@utils/permissions";
import { getCachedPermissions } from "@stores/permissionStore";

const perms = await getCachedPermissions();
if (hasPermission(perms, "expense:export")) {
  // renderiza el botón
}
```

Para decidir **si una pantalla entera existe** para un rol, usa `src/config/routeAccess.ts` (por rol) como hasta ahora; las rutas siguen siendo gated por rol a nivel middleware de Astro. Los permisos granulares son para condicionar acciones **dentro** de una pantalla.

### 6. Agregar test E2E

En `TC3005B.501-Frontend/cypress/e2e/permissions.cy.ts`, agrega un caso al bloque de "Role → effective permission resolution" verificando que el rol esperado incluye el nuevo código. Para grants/revokes de usuario, sigue el patrón del bloque "Direct user grant (additive over role)".

---

## Endpoints admin para gestionar permisos en caliente

Todos bajo `/api/admin/*`, todos requieren permisos meta (`permission:read`, `permission:write`, `permission_group:manage`, `role:manage_permissions`, `user:manage_permissions`). Ver [`routes/permissionRoutes.js`](../../TC3005B.501-Backend/routes/permissionRoutes.js).

### Catálogo
| Método | Ruta | Permiso |
|---|---|---|
| GET    | `/api/admin/permissions` | `permission:read` |
| POST   | `/api/admin/permissions` | `permission:write` |
| PATCH  | `/api/admin/permissions/:id` | `permission:write` |
| DELETE | `/api/admin/permissions/:id` (soft delete → `active=false`) | `permission:write` |

### Grupos
| Método | Ruta | Permiso |
|---|---|---|
| GET    | `/api/admin/permission-groups` | `permission:read` |
| POST   | `/api/admin/permission-groups` | `permission_group:manage` |
| PATCH  | `/api/admin/permission-groups/:id` | `permission_group:manage` |
| DELETE | `/api/admin/permission-groups/:id` | `permission_group:manage` |
| POST   | `/api/admin/permission-groups/:id/permissions` — body `{ permissionIds: number[] }` | `permission_group:manage` |
| DELETE | `/api/admin/permission-groups/:id/permissions/:permissionId` | `permission_group:manage` |

### Asignación a un rol
| Método | Ruta | Permiso |
|---|---|---|
| POST   | `/api/admin/roles/:roleId/permissions` | `role:manage_permissions` |
| DELETE | `/api/admin/roles/:roleId/permissions/:permissionId` | `role:manage_permissions` |
| POST   | `/api/admin/roles/:roleId/permission-groups` | `role:manage_permissions` |
| DELETE | `/api/admin/roles/:roleId/permission-groups/:groupId` | `role:manage_permissions` |

### Asignación directa a un usuario (aditivo)
| Método | Ruta | Permiso |
|---|---|---|
| POST   | `/api/admin/users/:userId/permissions` | `user:manage_permissions` |
| DELETE | `/api/admin/users/:userId/permissions/:permissionId` | `user:manage_permissions` |
| POST   | `/api/admin/users/:userId/permission-groups` | `user:manage_permissions` |
| DELETE | `/api/admin/users/:userId/permission-groups/:groupId` | `user:manage_permissions` |
| GET    | `/api/admin/users/:userId/effective-permissions` | `permission:read` |

### Endpoint self-service (cualquier usuario autenticado)

```
GET /api/user/me/permissions
→ { userId, role, permissions: string[] }
```

---

## Seed y Docker — flujo para nuevos colaboradores

Cuando alguien clona el repo por primera vez o agrega un permiso:

1. **Primer clone**
   ```sh
   cd TC3005B.501-Backend
   bun install
   bun run docker:dev          # postgres + mongo + localstack + migrate + backend
   ```
   El `migrate` service hace `bun install` → `prisma generate` → `prisma db push` → **seed completo** (referencia + dummy). Crea un sentinel `/app/node_modules/.seeded` dentro del volumen para no re-insertar los dummy data.

2. **Un compañero agrega un permiso nuevo (ejemplo: `expense:export`)**
   - Modifica `prisma/seed.js` como en la sección anterior.
   - Hace commit y push.

3. **Tú haces `git pull`** — tienes dos opciones:
   - **Con el stack corriendo** (más rápido, no reinicia nada):
     ```sh
     bun run docker:permissions:sync
     ```
     Ejecuta `node prisma/seed.js` (solo referencia, idempotente) dentro del contenedor backend. Los permisos nuevos aparecen en segundos sin perder datos dummy.
   - **Con el stack apagado**:
     ```sh
     bun run docker:dev:down
     bun run docker:dev
     ```
     El migrate service detecta el sentinel existente y corre **solo la seed de referencia** automáticamente. También idempotente; datos dummy intactos.

### Scripts de reset (cuadro comparativo)

| Comando | Qué hace | Cuándo usarlo | Datos que se pierden |
|---|---|---|---|
| `bun run docker:permissions:sync` | Corre `node prisma/seed.js` dentro del contenedor backend en caliente. Solo aplica la sección de referencia (roles, statuses, **permisos**). Idempotente. | Un compañero agregó un permiso y hiciste `git pull` — quieres que aparezca sin reiniciar nada. | Ninguno. |
| `bun run docker:data:reset` | Dentro del contenedor backend: `bunx prisma db push --force-reset && node prisma/seed.js dev`. **Tira todas las tablas** de Postgres y re-aplica el schema + seed completo. No toca Mongo ni LocalStack. | Datos dummy corruptos, migraciones raras entre ramas, tests E2E contaminaron el estado. | Todo lo que esté en Postgres (requests, usuarios creados a mano, grants directos, comprobantes registrados). Mantiene archivos en Mongo y S3 mock. |
| `bun run docker:dev:clean` | `docker compose down -v` — **borra todos los volúmenes** del proyecto: `pgdata`, `mongodata`, `localstack_data`, `node_modules_dev`, `certs`. | Algo se rompió a nivel docker (certs corruptos, deps medio instaladas, sentinel en mal estado), quieres un "fresh install" completo. | Todo: DB relacional + archivos en Mongo + objetos en S3 local + deps instaladas + certs HTTPS. |
| `bun run docker:dev:down` | Apaga contenedores, deja volúmenes. | Pausar el trabajo del día. | Nada. |

**Orden sugerido cuando algo no funciona**:
1. `docker:permissions:sync` si parece solo desfase de catálogo.
2. `docker:data:reset` si es problema de datos.
3. `docker:dev:clean && docker:dev` si nada de lo anterior arregla.

### Caso real — `Pedro Castillo` fantasma

Durante el desarrollo del sistema de permisos se detectó que la DB tenía un usuario `Pedro Castillo (user_id=1)` inyectado por una versión previa del seed. Los nuevos seeds no lo crean, pero `user_id=1` ya estaba ocupado. Consecuencia: las solicitudes dummy (que referencian `user_id=1`) pertenecían a ese fantasma y no al `andres.gomez` con el que los tests de Cypress hacen login → dashboard vacío → tests fallan.

Esto aparece cuando el **sentinel `.seeded` sigue activo desde una versión anterior del código**. Solución definitiva:

```sh
bun run docker:dev:clean && bun run docker:dev
```

Como regla: si cambias la definición de los usuarios dummy o su orden de inserción, avísale al equipo para que corran `docker:dev:clean`.

### Desarrollo nativo (sin docker para backend)

Si prefieres correr el backend con `bun run dev` directo en el host, la DB sigue viviendo en docker:

```sh
# Una sola vez: levanta solo postgres + mongo
cd TC3005B.501-Backend
docker compose -f docker-compose.dev.yml up -d postgres mongo
# Ajusta tu .env local para apuntar a puerto 5434 (postgres host-side)
DATABASE_URL="postgresql://cocoscheme:cocoscheme_dev@localhost:5434/CocoScheme?schema=public"
# Seed + dev
bun run dummy_db                # o `bun run empty_db` si no quieres dummy data
bun run dev
```

---

## Middleware — resumen de defensa en profundidad

`middleware/permissionMiddleware.js` expone los helpers:

```js
requirePermission("codigo1", "codigo2")     // AND — todos requeridos
requireAnyPermission("codigo1", "codigo2")  // OR  — al menos uno
```

Cada uno retorna un **array** `[authenticateToken, loadPermissions, authorizePermission(...)]`, usado con spread:

```js
router.get("/foo", ...requirePermission("foo:read"), handler);
```

Propiedades garantizadas:

1. **`authenticateToken` siempre corre primero.** No hay forma de llegar a `authorizePermission` sin JWT válido.
2. **`loadPermissions` es idempotente por request.** Si varios middlewares requieren permisos en la misma ruta, se consulta la DB una sola vez (se cachea en `req.user.permissionSet`).
3. **`authorizePermission` falla con 403 si `req.user` o `permissionSet` no existen** — defensa contra casos de mal uso, nunca deja pasar silenciosamente.
4. **Los errores 401/403 usan las clases en `authErrors.js`** — formato de respuesta consistente.

El `requireAuth(roles)` legacy en `authMiddleware.js` **se conserva** y sigue funcionando para código que no se ha migrado o que prefiere cheque por rol. No está deprecado; simplemente hay ahora una opción más granular.

---

## Testing

- **Unit (Jest)**: [`tests/middleware/permissionMiddleware.test.js`](../../TC3005B.501-Backend/tests/middleware/permissionMiddleware.test.js) — verifica AND/OR, idempotencia de `loadPermissions`, composición con `authenticateToken`, manejo de `req.user` ausente.
- **E2E (Cypress)**: [`cypress/e2e/permissions.cy.ts`](../../TC3005B.501-Frontend/cypress/e2e/permissions.cy.ts) — corre contra el stack docker, verifica: resolución por rol para los 6 roles seeded, 401 sin token, 403 sin permiso, CRUD de catálogo, grant/revoke directo a usuario, CRUD de grupos con asignación. Usa `cy.apiLogin(...)` y `cy.apiAs(session, {...})` (en [`cypress/support/commands.ts`](../../TC3005B.501-Frontend/cypress/support/commands.ts)) que manejan JWT + CSRF automáticamente.

Ejecutar E2E:

```sh
# backend corriendo (docker o native)
# frontend corriendo en :4321 (necesario por cypress baseUrl)
cd TC3005B.501-Frontend
bunx cypress run --spec "cypress/e2e/permissions.cy.ts"
```
