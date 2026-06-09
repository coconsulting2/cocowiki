# Requerimientos No Funcionales (RNF) — CocoAPI

> Proyecto: **CocoAPI** · Cliente: **Ditta Consulting** · Equipo: **COCONSULTING2**
> Documento de especificación de Requerimientos No Funcionales y matriz de trazabilidad US ↔ Requerimientos.

---

## Índice

- [Resumen por categoría](#resumen-por-categoría)
- [Catálogo de RNF](#catálogo-de-rnf)
  - [Seguridad](#seguridad)
  - [Rendimiento](#rendimiento)
  - [Usabilidad](#usabilidad)
  - [Disponibilidad](#disponibilidad)
  - [Confiabilidad](#confiabilidad)
  - [Mantenibilidad](#mantenibilidad)
  - [Trazabilidad](#trazabilidad-rnf)
- [Matriz de Trazabilidad US ↔ Requerimientos](#matriz-de-trazabilidad-us--requerimientos)

---

## Resumen por categoría

| Categoría | # RNF | IDs |
|---|---|---|
| Seguridad | 10 | RNF-01 → RNF-10 |
| Rendimiento | 5 | RNF-11 → RNF-15 |
| Usabilidad | 5 | RNF-16 → RNF-20 |
| Disponibilidad | 2 | RNF-21, RNF-22 |
| Confiabilidad | 3 | RNF-23 → RNF-25 |
| Mantenibilidad | 6 | RNF-26 → RNF-31* |
| Trazabilidad | 4 | RNF-31 → RNF-34 |

\* RNF-31 aparece bajo Trazabilidad en el catálogo original.

---

## Catálogo de RNF

### Seguridad

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-01** | El sistema debe autenticar cada request protegido mediante JWT con verificación de firma y expiración. | Todas | 0 requests sin auth acceden a rutas protegidas | Alta |
| **RNF-02** | Los tokens expirados, inválidos o ausentes deben retornar error en formato estándar `{statusCode, message, error}`. | Todas | 100% de errores de auth siguen formato estándar | Alta |
| **RNF-03** | Los archivos en S3 deben tener encryption at rest (AES-256) y políticas IAM restrictivas. | US-01, US-02 | 0 archivos sin encriptación en bucket | Alta |
| **RNF-04** | Las URLs de descarga de archivos deben ser pre-signed con TTL de 15 minutos. | US-01, US-02 | URLs no accesibles después de 15 min | Alta |
| **RNF-05** | La descarga de archivos debe requerir autenticación y verificar pertenencia a la organización. | US-01, US-02 | 0 accesos cross-org a archivos | Alta |
| **RNF-06** | Las API Keys deben almacenarse como hash SHA-256, nunca en texto plano. | US-17 | 0 keys en texto plano en BD | Alta |
| **RNF-07** | Las peticiones sin API Key válida deben retornar HTTP 401 sin revelar información interna. | US-17 | Respuesta genérica sin stack traces | Alta |
| **RNF-08** | Los datos de cada organización deben estar completamente aislados (multi-tenancy). | US-13, US-14 | 0 data leaks entre organizaciones | Alta |
| **RNF-09** | El sistema de permisos debe validar por permiso específico, no por rol. | US-14 | Middleware verifica permiso, no nombre de rol | Alta |
| **RNF-10** | Los permisos expirados deben invalidarse automáticamente sin intervención manual. | US-14 | Permiso expirado retorna 403 inmediatamente | Alta |

### Rendimiento

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-11** | Los endpoints principales deben responder en menos de 500ms bajo carga normal. | Todas | p95 < 500ms con 50 usuarios concurrentes | Alta |
| **RNF-12** | El sistema debe soportar al menos 100 usuarios concurrentes sin degradación. | Todas | K6: 0 errores con 100 VUs | Alta |
| **RNF-13** | El tipo de cambio de Banxico debe cachearse diariamente para evitar llamadas excesivas. | US-04 | Máx 1 llamada a Banxico por día por moneda | Media |
| **RNF-14** | El dashboard debe actualizar datos sin recargar la página (polling o WebSocket). | US-18 | Datos actualizados en < 60 segundos | Alta |
| **RNF-15** | El auto-guardado de borradores debe ejecutarse cada 30 segundos sin bloquear la UI. | US-21 | Guardado no produce lag visible en formulario | Media |

### Usabilidad

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-16** | Todas las vistas deben ser responsive desde 320px de ancho (mobile-first). | US-07, Todas | Sin overflow horizontal en 320px | Alta |
| **RNF-17** | Los botones de acción primaria deben ser táctilmente accesibles (mínimo 44x44 px). | US-07, US-08 | Todos los CTAs ≥ 44x44px en móvil | Alta |
| **RNF-18** | La aplicación debe funcionar correctamente en Chrome, Safari y Edge (últimas 2 versiones). | Todas | 0 errores críticos cross-browser | Alta |
| **RNF-19** | Los componentes deben tener tipado completo en TypeScript (sin `any`). | Todas | 0 usos de `any` en código frontend | Media |
| **RNF-20** | Los mensajes de error deben ser claros y específicos para el usuario. | Todas | Cada error tiene mensaje legible (no stack trace) | Alta |

### Disponibilidad

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-21** | Si la API del SAT no está disponible, el sistema debe mostrar un mensaje y permitir continuar sin bloquear. | US-03 | Mock server activo como fallback | Alta |
| **RNF-22** | Si la API de Banxico no responde, el sistema debe usar el último tipo de cambio conocido (cache). | US-04 | Fallback a cache sin error visible al usuario | Alta |

### Confiabilidad

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-23** | Los correos de notificación deben enviarse dentro de los 5 minutos posteriores al evento. | US-20 | 95% de correos entregados en < 5 min | Media |
| **RNF-24** | Las transacciones de base de datos deben ser atómicas (rollback en caso de error). | US-02, US-05 | 0 registros huérfanos en caso de error | Alta |
| **RNF-25** | El sistema debe mantener consistencia entre MariaDB y MongoDB/S3. | US-01, US-02 | 0 archivos huérfanos en S3 sin registro en BD | Alta |

### Mantenibilidad

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-26** | El código debe pasar ESLint + Prettier sin errores. | Todas | `make lint` retorna 0 errores | Media |
| **RNF-27** | El entorno dockerizado debe levantarse con un solo comando (`docker compose up`). | Todas | Entorno funcional en Mac, Linux y Windows | Alta |
| **RNF-28** | La cobertura de pruebas unitarias del backend debe ser mayor al 70%. | Todas | `jest --coverage` ≥ 70% | Alta |
| **RNF-29** | Cada migración de base de datos debe ser reversible (up/down). | US-05 | Todas las migraciones tienen rollback funcional | Alta |
| **RNF-30** | Los design tokens (colores, espaciado, tipografía) deben estar centralizados. | Todas (Frontend) | 1 archivo de tokens, 0 valores hardcoded | Media |

### Trazabilidad (RNF)

| ID | Requerimiento No Funcional | US Relacionada(s) | Criterio de Medición | Prioridad |
|---|---|---|---|---|
| **RNF-31** | El historial de cada solicitud debe ser inmutable (solo lectura, no modificable). | US-19 | 0 registros de historial modificados post-creación | Alta |
| **RNF-32** | Cada consumo de API Key debe quedar registrado en log de auditoría. | US-17 | 100% de consumos loggeados con timestamp | Alta |
| **RNF-33** | Los comentarios por solicitud deben ser inmutables una vez guardados. | US-22 | No existen endpoints PUT/DELETE para comentarios | Media |
| **RNF-34** | Cada sincronización de empleados debe generar un log con resultados detallados. | US-15 | Log incluye: nuevos, actualizados, inactivos, errores | Alta |

---

## Matriz de Trazabilidad US ↔ Requerimientos

| US | Título | Req Funcionales | Req No Funcionales | Épica | Módulo |
|---|---|---|---|---|---|
| **US-01** | Interfaz de Carga de Comprobantes XML/PDF | RF-01, RF-02, RF-03, RF-04, RF-05, RF-10 | RNF-03, RNF-04, RNF-05, RNF-16, RNF-17, RNF-20 | Automatización Fiscal | M1 |
| **US-02** | Extracción de Datos de CFDI (Backend) | RF-06, RF-07, RF-08, RF-09, RF-10 | RNF-11, RNF-24, RNF-25 | Automatización Fiscal | M1 |
| **US-03** | Verificación de CFDI ante el SAT | RF-11, RF-12, RF-13 | RNF-11, RNF-21 | Automatización Fiscal | M1 |
| **US-04** | Tipo de Cambio Automático vía Banxico | RF-14, RF-15, RF-16 | RNF-13, RNF-22 | Automatización Fiscal | M1 |
| **US-05** | Migración de DB — Tabla CFDI | RF-17, RF-18 | RNF-24, RNF-29 | Automatización Fiscal | M1 |
| **US-06** | Límite de tiempo de reembolsos | RF-37, RF-38, RF-39 | RNF-11, RNF-20 | Control de Viajes | M2 |
| **US-07** | Interfaz Móvil para Aprobaciones | RF-26, RF-27 | RNF-16, RNF-17, RNF-18 | Aprobaciones | M2 |
| **US-08** | Aprobar o Rechazar Solicitudes | RF-28, RF-29, RF-30, RF-31 | RNF-11, RNF-20, RNF-31 | Aprobaciones | M2 |
| **US-09** | Gestión de Agencia de Viajes Digital | RF-40, RF-41 | RNF-11 | Control de Viajes | M3 |
| **US-10** | Gastos Individuales por Tramo | RF-19, RF-20, RF-21 | RNF-11, RNF-24 | Automatización Fiscal | M1 |
| **US-11** | API de exportación contable | RF-22, RF-23, RF-24, RF-25 | RNF-07, RNF-11, RNF-32 | Automatización Fiscal | M1 |
| **US-12** | Configuración de Políticas de Viaje | RF-42, RF-43, RF-44, RF-45, RF-46 | RNF-08, RNF-20 | Control de Viajes | M2 |
| **US-13** | Registro de Nueva Empresa | RF-47, RF-48, RF-49 | RNF-08 | Onboarding | M3 |
| **US-14** | Creación de Permisos | RF-50, RF-51, RF-52, RF-53, RF-54, RF-55, RF-56 | RNF-08, RNF-09, RNF-10 | Onboarding | M2 |
| **US-15** | Sincronización de Empleados y Proveedores | RF-57, RF-58, RF-59, RF-60, RF-61 | RNF-24, RNF-34 | Onboarding | M3 |
| **US-16** | Configuración Dinámica de Workflow | RF-62, RF-63, RF-64, RF-65, RF-66 | RNF-08, RNF-20 | Onboarding | M2 |
| **US-17** | Autenticación de Sistemas Externos vía API Key | RF-67, RF-68, RF-69, RF-70, RF-71 | RNF-06, RNF-07, RNF-32 | API Contable | M3 |
| **US-18** | Dashboard de Viáticos por Centro de Costos | RF-82, RF-83, RF-84, RF-85 | RNF-14, RNF-16 | Reportería | M3 |
| **US-19** | Historial y Trazabilidad de Solicitud | RF-86, RF-87, RF-88, RF-89 | RNF-31 | Reportería | M3 |
| **US-20** | Notificaciones Push y por Correo | RF-99, RF-100, RF-101, RF-102 | RNF-23 | Experiencia | M3 |
| **US-21** | Borrador Automático de Solicitud | RF-90, RF-91, RF-92, RF-93, RF-94 | RNF-15 | Experiencia | M3 |
| **US-22** | Comentarios y Mensajería Interna | RF-95, RF-96, RF-97, RF-98 | RNF-33 | Experiencia | M3 |
| **US-23** | Roles de Notificación vs. Autorización | RF-32, RF-33, RF-34, RF-35, RF-36 | RNF-09, RNF-10 | Aprobaciones | M2 |
| **US-24** | Catálogo Contable Maestro | RF-72, RF-73, RF-74, RF-75, RF-76 | RNF-08 | API Contable | M3 |
| **US-25** | Asociación de Cuentas a Tipos de Gasto | RF-77, RF-78, RF-79, RF-80, RF-81 | RNF-08 | API Contable | M3 |
