# CocoAPI — Flujos de pantallas por rol

| Metadato | Valor |
|----------|--------|
| **Versión del documento** | 1.0.2 |
| **Última actualización** | 2026-06-02 |
| **Relacionado** | [Flujos — arquitectura de datos y navegación](../arquitectura-datos/flujos.md) |

Las imágenes se enlazan en markdown como **`./images/diagrams/pantallas/…`**. Aunque este archivo vive en **`docs/guias-usuario/`**, un plugin de Docsify (en `index.html`) reescribe los prefijos `./images/` y `/images/` a rutas absolutas desde la raíz del sitio, por lo que esa forma funciona desde cualquier subcarpeta sin usar `../images/…`.

Mapeo de pantallas accesibles, acciones disponibles y transiciones por cada uno de los 7 roles del sistema. Alcance completo: Módulo 1 + 2 + 3.

---

## 1. Solicitante

Empleado viajero. Crea solicitudes, sube comprobantes (nacionales o internacionales), consulta su wallet y da seguimiento a lo pendiente.

**Rutas exclusivas del Solicitante:**

| Ruta | Descripción |
|------|-------------|
| `/subir-comprobante/[id]` | Sube por primera vez los comprobantes de una solicitud en estado "Comprobación gastos del viaje". |
| `/resubir-comprobante/[id]` | Sube de nuevo un comprobante rechazado por Cuentas por Pagar. |
| `/comprobar-solicitud/[id]` | Pantalla de detalle de comprobación de la solicitud. |

Cuando la solicitud se encuentra en estado **"Comprobación gastos del viaje"**, el detalle de la solicitud (`RequestDetail`) muestra un banner informativo con el botón **"Subir comprobantes"** (`showUploadCTA`). Al hacer clic, el sistema navega a `/comprobar-solicitud/[id]`.

![Flujo de pantallas del Solicitante](./images/diagrams/pantallas/01_solicitante.png)

---

## 2. N1 · Jefe directo

Primer aprobador. Su trabajo es la bandeja de pendientes de su equipo directo. Tiene dos decisiones paralelas por solicitud: el viaje y el anticipo.

![Flujo de pantallas del N1](./images/diagrams/pantallas/02_n1_jefe_directo.png)

---

## 3. N2 · Jefe de área

Alcance más amplio que N1 (varios equipos). Solo ve solicitudes que escalaron a su nivel por las reglas del tenant. Tiene además el dashboard ejecutivo del área.

![Flujo de pantallas del N2](./images/diagrams/pantallas/03_n2_jefe_area.png)

---

## 4. Cuentas por pagar · Finanzas

Interviene solo después del viaje. Valida los comprobantes uno a uno, calcula el saldo final considerando el anticipo, asocia gastos a cuentas contables y expone el lote en la API para que el ERP externo lo jale.

![Flujo de pantallas de Cuentas por pagar](./images/diagrams/pantallas/04_soi_finanzas.png)

---

## 5. Agencia de viajes

Rol acotado. Solo ve solicitudes aprobadas donde se pidió avión u hotel. Reserva usando integración con agencias digitales (Expedia, AMEX, KAYAK).

![Flujo de pantallas de la Agencia](./images/diagrams/pantallas/05_agencia.png)

---

## 6. Admin de la organización

Cliente de Ditta que administra su propia empresa. Configura políticas, workflow de aprobación, roles y ve el dashboard ejecutivo. No toca datos operativos.

Su sidebar incluye la opción **LLAVES API** (`/admin/api-keys`) además de las rutas estándar de administración.

![Flujo de pantallas del Admin organización](./images/diagrams/pantallas/06_admin_organizacion.png)

---

## 7. Admin Ditta

Super-admin del sistema. Consultor Ditta encargado del onboarding de empresas, catálogos contables maestros, API Keys y log global de auditoría.

Su sidebar incluye la opción **LLAVES API** (`/admin/api-keys`). A diferencia del Administrador de organización, no tiene acceso a **REGLAS DE WORKFLOW**.

![Flujo de pantallas del Admin Ditta](./images/diagrams/pantallas/07_admin_ditta.png)

---

## Patrones compartidos

**Login único con switch por rol.** El JWT + IP binding es el mismo para todos, pero la ruta post-login difiere: solicitante llega a "Mis solicitudes", aprobadores a su bandeja, Cuentas por pagar a bandeja contable, agencia a reservas, admins a su panel respectivo.

**Detalle de solicitud reutilizable.** Esta pantalla la ven casi todos los roles (solicitante, N1, N2, Cuentas por pagar, agencia) pero con vista y acciones distintas según rol y estado. Candidato a un componente único con slots condicionales, no 5 pantallas separadas.

**Chat de comentarios transversal.** US-22 aparece en solicitante, N1, N2 y Cuentas por pagar sobre la misma solicitud. Otro componente compartido.

**Sesión expirada.** Cuando el backend responde con un 401 con código `TOKEN_EXPIRED`, `INVALID_TOKEN` o `MISSING_TOKEN`, el frontend limpia las cookies de sesión y muestra un modal de advertencia: *"Tu sesion ha expirado. Por favor inicia sesion nuevamente."* El usuario hace clic en aceptar y el sistema redirige automáticamente a `/login`. Un mecanismo de guarda evita que el diálogo aparezca más de una vez si se reciben varios 401 simultáneos.

**Principio de RBAC estricto (US-14).** Si un rol no tiene el permiso, la pantalla no existe para ese usuario — no aparece en gris ni bloqueada. El menú se renderiza dinámicamente según los permisos del rol activo.
