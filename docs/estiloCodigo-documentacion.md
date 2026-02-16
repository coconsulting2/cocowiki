## 1. Estilo de Código y Documentación

### Nombrado — ¿Por qué cada estilo?

| Contexto | Estilo | Ejemplo | ¿Por qué? |
|----------|--------|---------|------------|
| Componentes React/Astro | PascalCase | `LoginForm.tsx`, `Button.astro` | React **exige** PascalCase para distinguir componentes (`<LoginForm />`) de tags HTML (`<form>`). Si usas minúsculas, React lo interpreta como elemento nativo. |
| Funciones JS/TS | camelCase | `getUserData()`, `handleSubmit()` | Convención estándar de JavaScript (ECMAScript). Toda la documentación oficial de Node.js, Express y React usa camelCase. Mantiene consistencia con el ecosistema. |
| Variables | camelCase | `formData`, `userId` | Misma razón que funciones. Al usar el mismo estilo para variables y funciones, el código se lee de forma uniforme sin mezclar convenciones. |
| Constantes globales | UPPER_SNAKE_CASE | `MAX_FILE_SIZE`, `JWT_SECRET` | Convención universal para valores que **nunca cambian**. Al verlas en mayúsculas, sabes inmediatamente que es una constante y no debes reasignarla. |
| Campos de BD | snake_case | `user_id`, `beginning_date` | Estándar de SQL (MariaDB/MySQL/PostgreSQL). Los motores de BD son case-insensitive por defecto, y `snake_case` evita ambigüedades con columnas como `userId` vs `userid`. |
| Rutas API | kebab-case | `/travel-agent`, `/accounts-payable` | Estándar de URLs según RFC 3986. Los navegadores y proxies tratan las URLs como case-insensitive, así que `/TravelAgent` y `/travelagent` podrían ser lo mismo. `kebab-case` elimina esa ambigüedad y es más legible en URLs. |

### Lenguajes por Capa — `.js` (Backend) vs `.tsx/.ts` (Frontend)

| Capa | Extensión | ¿Por qué? |
|------|-----------|------------|
| **Backend** | `.js` (JavaScript puro) | El backend usa Node.js + Express sin compilador de TypeScript. Los archivos se ejecutan directamente con `node`. Agregar TS requeriría configurar `tsconfig.json`, un paso de build (`tsc`), y migrar todos los archivos existentes. **Se mantiene JS para no romper el pipeline actual.** |
| **Frontend** | `.tsx` / `.ts` (TypeScript) | Astro y React ya incluyen soporte nativo de TypeScript. Los componentes React usan `.tsx` porque contienen JSX. Los archivos de utilidades, tipos e interfaces usan `.ts`. **TypeScript en el frontend da tipado estático, autocompletado y detección de errores en compilación.** |
| **Frontend (Astro)** | `.astro` | Los componentes Astro usan su propia extensión. Dentro de ellos se puede escribir TypeScript en el frontmatter (`---`) y JSX en el template. |

> **Convención establecida:** Seguiremos usando `.js` en Backend y `.tsx/.ts` en Frontend. No se migra el backend a TypeScript. Si en el futuro se decide migrar, se hará como un esfuerzo separado y planificado.

---

### Branches — Convención de Nombres

Se usa el formato: **`tipo/area/descripcion-corta`**

#### Tipos

| Prefijo | Cuándo usarla | Ejemplo |
|---------|---------------|---------|
| `feat/` | Nueva funcionalidad o feature completa | `feat/back/audit-log`, `feat/front/export-pdf` |
| `fix/` | Corregir un bug en funcionalidad existente | `fix/back/login-cookie-expire`, `fix/front/wallet-negative` |
| `hotfix/` | Bug crítico en producción que urge | `hotfix/back/auth-bypass`, `hotfix/back/db-connection-leak` |
| `refactor/` | Reestructurar código sin cambiar funcionalidad | `refactor/back/centralize-error-handling`, `refactor/front/split-form` |
| `docs/` | Solo documentación (README, JSDoc, guías) | `docs/back/api-endpoints`, `docs/wiki/setup-guide` |
| `test/` | Agregar o modificar pruebas | `test/back/authorizer-integration`, `test/front/receipt-validation` |
| `chore/` | Mantenimiento (actualizar deps, config, CI/CD) | `chore/back/update-dependencies`, `chore/front/eslint-config` |

#### Áreas

| Área | Cuándo usarla |
|------|---------------|
| `back` | Cambios en el Backend (`TC3005B.501-Backend/`) |
| `front` | Cambios en el Frontend (`TC3005B.501-Frontend/`) |
| `qa` | Cambios solo en pruebas/testing |
| `docs` | Cambios solo en documentación o wiki |
| `full` | Cambios que tocan **Backend + Frontend** a la vez |

**Reglas:**
- Siempre en **minúsculas** y con **guiones** (`-`), nunca espacios ni `_`.
- Descripción **corta** (2-4 palabras máximo).
- La rama `main` está protegida: no se hacen push directos, solo **Pull Requests**.

**Ejemplo de flujo:**
```bash
# 1. Crear rama desde main
git checkout main
git pull origin main
git checkout -b feat/back/audit-log

# 2. Hacer commits (ver convención abajo)
git add .
git commit -m "feat: add Audit_Log table migration"

# 3. Push y Pull Request
git push origin feat/back/audit-log
# → Crear PR en GitHub hacia main
```

---

### Commits — Conventional Commits

Se usa el formato: **`tipo: descripción en inglés`**

| Tipo | Significado | Ejemplo |
|------|-------------|---------|
| `feat:` | Nueva funcionalidad | `feat: add audit log service` |
| `fix:` | Corrección de bug | `fix: prevent wallet from going negative` |
| `refactor:` | Cambio de código sin cambiar comportamiento | `refactor: replace try/catch with next(err) in adminController` |
| `docs:` | Solo documentación | `docs: add JSDoc to authorizerService` |
| `test:` | Agregar o modificar pruebas | `test: add unit tests for errorHandler middleware` |
| `chore:` | Mantenimiento, deps, config | `chore: install jest and supertest` |
| `style:` | Formato (espacios, comas, etc.), sin cambio lógico | `style: fix indentation in applicantModel` |

**Reglas:**
- El mensaje va en **inglés**, en **presente imperativo** ("add", no "added" ni "adding").
- Si el commit necesita más contexto, dejar línea vacía y agregar cuerpo:
```
feat: add audit trail for status changes

Records who changed the request status (user_id),
what the previous and new status were, and when.
Affects authorizerModel, applicantModel, accountsPayableModel.
```

---

### Arquitectura

**Backend:** MVC + Servicios
```
Ruta → Middleware → Controlador → Servicio → Modelo
```

**Frontend:** Astro + React
```
Página Astro (SSR) → Componentes React (interactivos)
```

### Documentación (JSDoc)

```javascript
/**
 * Author: Nombre del autor
 * Description: Breve descripción del archivo/función
 *
 * @param {number} userId - ID del usuario
 * @returns {Promise<Object>} Datos del usuario
 */
export async function getUserById(userId) { }
```

### Imports

**Backend (ES Modules):**
```javascript
import express from "express";
import { authenticateToken } from "../middleware/auth.js";
import userController from "../controllers/userController.js";
```

**Frontend (Alias de ruta):**
```typescript
import Button from "@components/Button";
import { apiRequest } from "@utils/apiClient";
import type { FormData } from "@/types/FormData";
```

### Manejo de Errores

**Backend:**
```javascript
try {
  const result = await service.doSomething();
  return res.status(200).json(result);
} catch (error) {
  if (error.status) {
    return res.status(error.status).json({ error: error.message });
  }
  return res.status(500).json({ error: "Internal server error" });
}
```

**Frontend:**
```typescript
try {
  await apiRequest('/endpoint', { method: 'POST', data });
  handleSetToast('Éxito', 'success');
} catch (error) {
  handleSetToast('Error al procesar', 'error');
}
```

### Estructura de Carpetas

```
Backend/                    Frontend/
├── controllers/            ├── src/
├── models/                 │   ├── components/
├── services/               │   ├── pages/
├── routes/                 │   ├── layouts/
├── middleware/             │   ├── types/
├── database/config/        │   ├── utils/
└── index.js                │   └── config/
```

### Stack Tecnológico

| Backend | Frontend |
|---------|----------|
| Node.js + Express | Astro 5 + React 19 |
| MariaDB + MongoDB | Tailwind CSS 4 |
| JWT + bcrypt | TypeScript |
| Nodemailer | Cypress (testing) |

---

## 2. Equipos y Code Ownership

### Estructura de Equipos

Cada equipo tiene un **Owner** (responsable técnico de su área) y un **Lead** que aprueba los Merge Requests.

---

#### 🔧 Backend

| Rol | Responsabilidad |
|-----|-----------------|
| **Alcance** | APIs, lógica de negocio, base de datos, integraciones, rendimiento y seguridad del servidor |
| **Carpetas que les pertenecen** | `controllers/`, `models/`, `services/`, `routes/`, `middleware/`, `database/`, `index.js` |
| **Aprueba MRs de** | Cualquier archivo dentro de `TC3005B.501-Backend/` |

**Integrantes:** Mariano Carretero · Kevin Esquivel · Santino Im · Héctor Lugo

---

#### 🎨 Frontend

| Rol | Responsabilidad |
|-----|-----------------|
| **Alcance** | Interfaz de usuario, experiencia de usuario, integración con APIs, accesibilidad |
| **Carpetas que les pertenecen** | `src/components/`, `src/pages/`, `src/layouts/`, `src/utils/`, `src/types/`, `src/config/` |
| **Aprueba MRs de** | Cualquier archivo dentro de `TC3005B.501-Frontend/` |

**Integrantes:** Leonardo Rodríguez · Emiliano Deyta

---

#### 🧪 QA / Testing

| Rol | Responsabilidad |
|-----|-----------------|
| **Alcance** | Pruebas unitarias, de integración, funcionales y validación UAT. Calidad antes de producción |
| **Carpetas que les pertenecen** | `tests/`, `cypress/`, archivos `*.test.js`, `*.spec.ts` |
| **Aprueba MRs de** | Archivos de pruebas en ambos repos. También revisan MRs de Backend/Frontend para validar cobertura |

**Integrantes:** Ángel Montemayor · Erick Morales · Eder Cantero · Emiliano Delgadillo

---

#### 📝 Docs

| Rol | Responsabilidad |
|-----|-----------------|
| **Alcance** | Documentación técnica, JSDoc, guías de uso, OpenAPI/Swagger, README, diagramas |
| **Carpetas que les pertenecen** | `openapi/`, `docs/`, archivos `*.md`, `database/SQL_CONTRIBUITING.md` |
| **Aprueba MRs de** | Cualquier archivo `.md` o de documentación en ambos repos |

**Integrantes:** *(por asignar)*

---

### Flujo de Aprobación de MRs

```
Developer crea rama (feat/...) → Push → Crea MR en GitHub
                                           │
                                    ┌──────┴──────┐
                                    │  ¿Qué área  │
                                    │  toca el MR? │
                                    └──────┬──────┘
                          ┌────────┬───────┼───────┬────────┐
                       Backend  Frontend   QA    Docs    Mixto
                          │        │       │      │        │
                      Owner BE  Owner FE  Owner QA Owner D  Todos los
                      aprueba   aprueba   aprueba aprueba  owners
                          │        │       │      │    involucrados
                          └────────┴───────┴──────┴────────┘
                                           │
                                     Merge a main
```

**Reglas:**
- Todo MR necesita **mínimo 1 aprobación** del Owner del equipo correspondiente.
- Si un MR toca **Backend + Frontend**, necesita aprobación de ambos Owners.
- QA puede bloquear un MR si no incluye pruebas para la funcionalidad nueva.
- El autor del MR **nunca** aprueba su propio MR.

