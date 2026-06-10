# CocoAPI — Flujos de pantallas por rol

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.1.0 |
| **Última actualización** | 2026-06-09 |
| **Relacionado** | [Flujos — arquitectura de datos y navegación](../arquitectura-datos/flujos.md) · [Manual de usuario](manual-usuario.md) · [Manual Admin Ditta](manual-admin.md) |

Las imágenes se enlazan como **`./images/diagrams/pantallas/…`**. Docsify reescribe esos prefijos a rutas absolutas desde la raíz del sitio.

Mapeo de pantallas, acciones y transiciones por cada uno de los 7 roles. Alcance: Módulos 1–3.

---

## 1. Solicitante

Empleado viajero. Crea solicitudes, sube comprobantes (nacionales con CFDI o internacionales con imagen), consulta reembolsos y resumen por tramos.

**Menú lateral:** DASHBOARD · CREAR SOLICITUD · DRAFT SOLICITUDES · GASTOS (COMPROBAR) · RESUMEN POR TRAMOS · REEMBOLSOS · HISTORIAL DE VIAJES

**Rutas clave:**

| Ruta | Descripción |
|------|-------------|
| `/subir-comprobante/[id]` | Registra un gasto: concepto, monto, archivos (PDF+XML o imagen), validación SAT, excepción de política si aplica. |
| `/resubir-comprobante/[id]?replace=` | Sustituye un comprobante rechazado por Cuentas por Pagar. |
| `/comprobar-solicitud/[id]` | Detalle de comprobación con acceso al formulario de subida. |
| `/detalles-solicitud/[id]` | Detalle completo, línea de tiempo, comentarios y banner "Subir comprobantes" cuando aplica. |
| `/perfil-usuario` | Perfil y preferencias de notificación. |

![Flujo de pantallas del Solicitante](./images/diagrams/pantallas/01_solicitante.png)

---

## 2. N1 · Jefe directo

Primer aprobador. Bandeja de pendientes de su equipo. Aprueba o rechaza viaje y anticipo. Revisa excepciones de política de viáticos.

**Menú lateral:** incluye AUTORIZACIONES, GASTO POR CC y las mismas rutas operativas del solicitante cuando crea sus propios viajes.

**Pantalla `/autorizaciones`:** bandeja filtrable + sección **Excepciones de política** (gastos que excedieron topes con justificación del solicitante).

![Flujo de pantallas del N1](./images/diagrams/pantallas/02_n1_jefe_directo.png)

---

## 3. N2 · Jefe de área

Segundo nivel de aprobación. Solo ve solicitudes que escalaron según las reglas de workflow del tenant. Misma operación que N1 (secciones 4.1–4.4 del manual de usuario).

![Flujo de pantallas del N2](./images/diagrams/pantallas/03_n2_jefe_area.png)

---

## 4. Cuentas por pagar · Finanzas

Cotiza solicitudes aprobadas, valida comprobantes CFDI, comenta con el solicitante y exporta pólizas al ERP.

**Menú lateral:** DASHBOARD · TODAS LAS SOLICITUDES · COTIZACIONES · COMPROBACIONES · RESUMEN POR TRAMOS · EXPORTAR ERP · GASTO POR CC

**Pantalla `/comprobar-gastos/[id]`:** validación de comprobantes, liquidación y hilo de **Comentarios de la solicitud** (el motivo de rechazo se publica aquí).

![Flujo de pantallas de Cuentas por pagar](./images/diagrams/pantallas/04_soi_finanzas.png)

---

## 5. Agencia de viajes

Rol acotado. Solo solicitudes aprobadas con vuelo u hotel. Gestiona reservas y revisa viajes cancelados.

**Menú lateral:** DASHBOARD · ATENCIONES

![Flujo de pantallas de la Agencia](./images/diagrams/pantallas/05_agencia.png)

---

## 6. Admin de la organización

Configura usuarios, políticas, catálogo contable, workflow (con simulador), llaves API y reportes. No gestiona otras organizaciones.

**Menú lateral:** incluye **REGLAS DE WORKFLOW** (`/admin/workflow-rules`) y enlace al **Simulador de workflow** (`/admin/workflow-simulator`) desde esa pantalla.

![Flujo de pantallas del Admin organización](./images/diagrams/pantallas/06_admin_organizacion.png)

---

## 7. Admin Ditta

Super-admin. Onboarding multi-tenant, impersonación, catálogos y usuarios cross-org. **No** tiene REGLAS DE WORKFLOW (lo configura cada cliente).

**Menú lateral:** incluye **ORGANIZACIONES** (`/admin/organizations`) además del panel de administración compartido.

![Flujo de pantallas del Admin Ditta](./images/diagrams/pantallas/07_admin_ditta.png)

---

## Matriz de rutas por rol

Permisos según `src/config/routeAccess.ts` y menú en `src/types/menu-config.ts`. El middleware SSR bloquea rutas no autorizadas (RBAC estricto, US-14).

Columnas: **Sol** = Solicitante · **AV** = Agencia · **CPP** = Cuentas por pagar · **N1** / **N2** · **Adm** = Administrador org · **Ditta** = Admin Ditta.

| Ruta | Sol | AV | CPP | N1 | N2 | Adm | Ditta |
|------|:---:|:--:|:---:|:--:|:--:|:---:|:-----:|
| `/dashboard` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/perfil-usuario` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/crear-solicitud` | ✓ | | | ✓ | ✓ | | |
| `/historial` | ✓ | | | ✓ | ✓ | | |
| `/reembolso` | ✓ | | | ✓ | ✓ | | |
| `/solicitudes-draft` | ✓ | | | ✓ | ✓ | | |
| `/comprobar-gastos` | ✓ | | ✓ | ✓ | ✓ | | |
| `/resumen-tramos` | ✓ | | ✓ | ✓ | ✓ | | |
| `/subir-comprobante/*` | ✓ | | | ✓ | ✓ | | |
| `/resubir-comprobante/*` | ✓ | | | | | | |
| `/detalles-solicitud/*` | ✓ | | ✓ | ✓ | ✓ | | |
| `/solicitudes-autorizador` | | | | ✓ | ✓ | | |
| `/autorizaciones` · `/aprobaciones` | | | | ✓ | ✓ | | |
| `/atenciones` | | ✓ | | | | | |
| `/todas-las-solicitudes` | | | ✓ | | | | |
| `/cotizaciones` | | | ✓ | | | | |
| `/comprobaciones` | | | ✓ | | | | |
| `/exportar-contable` | | | ✓ | | | | |
| `/reportes/gastos-por-centro` | | | ✓ | ✓ | ✓ | ✓ | ✓ |
| `/crear-usuario` | | | | | | ✓ | ✓ |
| `/admin/expense-policies` | | | | | | ✓ | ✓ |
| `/admin/employee-categories` | | | | | | ✓ | ✓ |
| `/admin/refund-time-limits` | | | | | | ✓ | ✓ |
| `/admin/onboarding-import` | | | | | | ✓ | ✓ |
| `/admin/catalogo-contable` | | | | | | ✓ | ✓ |
| `/admin/indicadores-impuesto` | | | | | | ✓ | ✓ |
| `/admin/mapeo-gastos` | | | | | | ✓ | ✓ |
| `/admin/api-keys` | | | | | | ✓ | ✓ |
| `/admin/workflow-rules` | | | | | | ✓ | |
| `/admin/organizations` | | | | | | | ✓ |

> Rutas dinámicas (`/editar-solicitud/[id]`, `/autorizar-solicitud/[id]`, `/comprobar-solicitud/[id]`, `/atender-solicitud/[id]`, `/cotizar-solicitud/[id]`, etc.) heredan el gating del flujo padre.
>
> **Simulador de workflow:** accesible desde `/admin/workflow-rules` para el Administrador de organización (enlace interno a `/admin/workflow-simulator`).

---

## Funcionalidades transversales

| Funcionalidad | Dónde | Quién la usa |
|---------------|-------|--------------|
| **Notificaciones** | Campana en el encabezado | Todos los roles autenticados |
| **Preferencias de notificación** | `/perfil-usuario` | Todos |
| **Comentarios en solicitud** | Detalle de solicitud; validación CxP en `/comprobar-gastos/[id]` | Solicitante, N1, N2, CxP |
| **Excepciones de política** | Formulario de comprobante (justificación) + bandeja en `/autorizaciones` | Solicitante, N1, N2 |
| **Tipo de cambio** | Panel en comprobante internacional | Solicitante (y aprobadores con rol de comprobación) |
| **Sesión expirada** | Modal global ante HTTP 401 | Todos |

---

## Patrones de navegación

**Login único por rol.** Tras autenticarse, cada rol llega a su dashboard con menú filtrado.

**Detalle de solicitud reutilizable.** Misma pantalla base con acciones distintas según rol y estado del viaje.

**RBAC estricto.** Si un rol no tiene permiso, la ruta no aparece en el menú y no es accesible por URL directa.
