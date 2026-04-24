# CocoAPI/CocoFront — Changelog de errores resueltos

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.0.0 |
| **Última actualización** | 2026-04-22 |
| **Alcance** | Incidencias detectadas y corregidas por el equipo en esta etapa |

Bitácora viva de seguimiento de errores ya corregidos.  
Incluye únicamente incidentes resueltos por nosotros (backend, frontend y flujo integrado).

---

## 2026-04-22

### 1) Error 500 al autorizar solicitudes (N2)
- **Síntoma:** Al aprobar/rechazar solicitudes desde N2 se presentaba error 500.
- **Causa raíz:** Manejo frágil en flujo de autorización y envío de correo posterior al cambio de estado.
- **Corrección aplicada:** Se robusteció el controlador de autorización para completar transición de estado y encapsular envío de correo en bloque seguro.
- **Estado:** Resuelto.

### 2) `Failed to fetch` y dudas de CSRF
- **Síntoma:** Frontend mostraba error de red genérico durante acciones de autorización.
- **Causa raíz:** En varios casos era backend caído/puerto incorrecto y no un problema puro de CSRF.
- **Corrección aplicada:** Ajustes en `apiClient` para usar base URL consistente y mensajes de error de red más claros para diagnóstico.
- **Estado:** Resuelto.

### 3) Flujo N1/N2 invertido en dashboards
- **Síntoma:** Solicitudes no aparecían en la bandeja esperada (ej. dashboard de Laura/N1).
- **Causa raíz:** Mapeo invertido en filtros de `status_id` por nivel de aprobación.
- **Corrección aplicada:** Se normalizó el mapeo: N1 trabaja con primera revisión y N2 con segunda revisión en vistas y filtros.
- **Estado:** Resuelto.

### 4) Parámetro de autorización en URL (`user_id` vs `role_id`)
- **Síntoma:** Rutas de autorización construidas con supuesto incorrecto de rol.
- **Causa raíz:** El segundo segmento de la ruta era `user_id` y no `role_id`.
- **Corrección aplicada:** Wrappers de aprobación y páginas de autorización actualizadas para tomar `user_id` desde sesión.
- **Estado:** Resuelto.

### 5) Carga de comprobantes antes de N2
- **Síntoma:** Se podía intentar subir comprobantes fuera de la ventana de negocio definida.
- **Causa raíz:** Falta de validación uniforme de estado en backend/frontend.
- **Corrección aplicada:** Política centralizada de carga de comprobantes solo en estados 4 a 7, aplicada en servicios y vistas.
- **Estado:** Resuelto.

### 6) Validación CFDI/UUID y duplicados
- **Síntoma:** Riesgo de registrar CFDI duplicado o inconsistente en flujo de gastos.
- **Causa raíz:** Validación incompleta del UUID en algunos caminos de alta.
- **Corrección aplicada:** Validación previa de UUID, búsqueda insensible a mayúsculas y bloqueo de duplicados en alta de comprobantes/gastos.
- **Estado:** Resuelto.

### 7) UX posterior a envío exitoso de gastos/comprobantes
- **Síntoma:** En ciertos casos el usuario quedaba sin acción clara después de éxito.
- **Causa raíz:** Flujo de confirmación limitado y sin navegación explícita.
- **Corrección aplicada:** Pantalla de éxito con navegación útil (sin depender de alertas nativas bloqueantes).
- **Estado:** Resuelto.

### 8) Sustitución de `window.alert` por alertas de aplicación
- **Síntoma:** Mensajería inconsistente y poco controlable en UI.
- **Causa raíz:** Uso disperso de `window.alert`.
- **Corrección aplicada:** Se implementó sistema de alertas de app (`coco:alert`) con host central y se migraron puntos clave.
- **Estado:** Resuelto.

### 9) Limpieza de ESLint backend (warnings)
- **Síntoma:** Alta deuda de warnings (JSDoc, no-unused-vars, eqeqeq, no-var, no-console en scripts/tests).
- **Causa raíz:** Reglas estrictas sin overrides por contexto y deuda acumulada.
- **Corrección aplicada:** Ajuste de `eslint.config.js` por contexto (app/scripts/tests) + correcciones de código y tests.
- **Estado:** Resuelto (ejecución local de `eslint .` en verde).

---

## Notas de uso
- Este changelog no reemplaza historias de usuario ni PRs; funciona como traza de incidentes corregidos.
- Para nuevas incidencias: agregar una entrada con **síntoma, causa raíz, corrección y estado**.
