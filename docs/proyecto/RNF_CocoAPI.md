# Requerimientos No Funcionales (RNF) — CocoAPI

> Proyecto: **CocoAPI** · Cliente: **Ditta Consulting** · Equipo: **COCONSULTING2**
> Catálogo alineado al código (backend `main`, verificado 2026-06-02) y matriz de trazabilidad US ↔ RNF.
> Detalle técnico ampliado (pruebas, evidencia): [Documento de Arquitectura — sección 5](../arquitectura-datos/documento-arquitectura.md#5-requerimientos-no-funcionales).

---

## Índice

- [Leyenda](#leyenda)
- [Resumen por categoría](#resumen-por-categoría)
- [RNF técnicos (RNF-01…RNF-27)](#rnf-técnicos-rnf-01rnf-27)
- [RNF de producto / UX (RNF-P01…RNF-P14)](#rnf-de-producto--ux-rnf-p01rnf-p14)
- [Matriz de Trazabilidad US ↔ RNF](#matriz-de-trazabilidad-us--rnf)

---

## Leyenda

**Estado:** **Cumplido** · **Parcial** · **Pendiente**

- **RNF-01…27:** requerimientos verificados contra implementación (seguridad, rendimiento, infra, fiscal).
- **RNF-P01…14:** criterios de producto/UX del backlog (historias de usuario); no duplican IDs técnicos.

---

## Resumen por categoría

| Categoría | # RNF técnicos | IDs |
|---|---|---|
| Seguridad / privacidad | 10 | RNF-01 → RNF-10 |
| Rendimiento / escalabilidad | 5 | RNF-11 → RNF-15, RNF-17 |
| Disponibilidad / recuperación | 3 | RNF-18 → RNF-20 |
| Mantenibilidad / trazabilidad | 4 | RNF-21 → RNF-24 |
| Confiabilidad / almacenamiento | 1 | RNF-25 |
| Integraciones / fiscal | 2 | RNF-26, RNF-27 |
| **Producto / UX (bloque P)** | 14 | RNF-P01 → RNF-P14 |

---

## RNF técnicos (RNF-01…RNF-27)

| ID | Categoría | Requerimiento | US / Área | Criterio de medición | Estado | Evidencia en código |
|---|---|---|---|---|---|---|
| **RNF-01** | Seguridad | JWT con verificación de firma (HMAC) y expiración (1 h) | Todas | 0 requests sin auth válida acceden a rutas protegidas | Cumplido | `middleware/authMiddleware.js` |
| **RNF-02** | Seguridad | IP binding del JWT: el token queda atado a la IP de emisión | Todas | Token reutilizado desde otra IP → rechazado | Cumplido | `authMiddleware.js` (`TokenMismatchError`) |
| **RNF-03** | Seguridad | Contraseñas hasheadas con bcrypt (cost 10) | US-auth | 0 contraseñas en texto plano en BD | Cumplido | Servicios de usuario / onboarding |
| **RNF-04** | Seguridad | Protección CSRF en mutaciones por cookie | Todas | Mutación sin token CSRF válido → 403 | Cumplido | `app.js` + `csurf` |
| **RNF-05** | Seguridad | Rate limiting: 100 req/15 min global; 5 req/min en login | Todas / login | Exceso → HTTP 429 | Cumplido | `middleware/rateLimiters.js` |
| **RNF-06** | Seguridad | CORS restringido por allowlist con `credentials` | Todas | Origen no permitido → bloqueado | Cumplido | `app.js` (`CORS_ORIGIN`) |
| **RNF-07** | Seguridad | HTTPS/TLS extremo a extremo; S3 con SSE-S3 (AES-256) | US-01, US-02 | 0 tráfico en claro; archivos cifrados en bucket | Cumplido | TLS en prod; `services/storageService.js` |
| **RNF-08** | Seguridad / Aislamiento | Multi-tenant: RLS PostgreSQL (38 tablas) + extensión Prisma + `AsyncLocalStorage` | US-13, US-14, todas | 0 fugas cross-org | Cumplido | `prisma/tenantExtension.js`, `multi-tenancy.md` |
| **RNF-09** | Seguridad | Validación de entrada y queries parametrizadas (Prisma) | Todas | Entrada inválida → 400; sin SQL crudo | Cumplido | `middleware/validation.js` |
| **RNF-10** | Privacidad | Cifrado AES-256-CBC de PII (email, teléfono) | US-user | PII ilegible en dump de BD | Cumplido | `middleware/decryption.js` |
| **RNF-11** | Rendimiento | Tiempo de respuesta API < 500 ms (p95) en lecturas | Todas | Prueba de carga | Pendiente | — |
| **RNF-12** | Escalabilidad | 100 usuarios concurrentes sin degradación | Todas | K6 / Artillery: 0 errores con 100 VUs | Pendiente | — |
| **RNF-13** | Escalabilidad | Backend stateless (JWT) apto para escalado horizontal | Todas | N instancias tras balanceador sin afinidad | Parcial | Sin despliegue multi-instancia medido |
| **RNF-14** | Autorización | RBAC granular `resource:action`, unión aditiva de permisos | US-14 | Acceso sin permiso → 403 | Cumplido | `permissionMiddleware.js`, `permissionService.js` |
| **RNF-15** | Rendimiento | Caché tipo de cambio (BER): máx. 1 llamada externa por par/día | US-04 | 2ª llamada del día → `fromCache=true` | Cumplido | `services/banxicoService.js` |
| **RNF-16** | Confiabilidad | Fallback Banxico → DOF ante fallo de fuente primaria | US-04 | Sistema sigue cotizando | Cumplido | `banxicoService.js` |
| **RNF-17** | Rendimiento | Descargas vía URL prefirmada S3 (TTL 15 min), sin proxy backend | US-01, US-02 | Descarga no atraviesa proceso API | Cumplido | `storageService.js` |
| **RNF-18** | Disponibilidad | SLA de disponibilidad del servicio | Todas | Ver [Documento de Arquitectura — sección 6](../arquitectura-datos/documento-arquitectura.md#6-indicadores-de-continuidad-de-negocio-rto--rpo--sla) | Pendiente | Datos AWS |
| **RNF-19** | Disponibilidad | Healthcheck HTTPS del contenedor backend | Infra | Contenedor unhealthy → reinicio | Cumplido | `docker-compose` healthcheck |
| **RNF-20** | Recuperación | RTO / RPO según infraestructura AWS | Todas | Ver sección 6 del documento de arquitectura | Pendiente | Datos AWS / DR test |
| **RNF-21** | Mantenibilidad | ESLint estricto + validación Prisma en CI | Todas | CI falla ante errores lint/esquema | Cumplido | `.github/workflows/ci.yml` |
| **RNF-22** | Mantenibilidad | Suite automatizada (~88+ tests) en CI | Todas | CI corre tests en push/PR | Parcial | Cobertura FE variable |
| **RNF-23** | Mantenibilidad | JSDoc + Conventional Commits | Todas | Guía de estilo / ESLint | Cumplido | `estilo-codigo-documentacion.md` |
| **RNF-24** | Trazabilidad | Logs cifrados y bitácora API keys (`api_key_logs`) | US-17 | Eventos sensibles auditables | Cumplido | `apiKeyService.js`, logs AES |
| **RNF-25** | Confiabilidad | Integridad: metadata en **PostgreSQL** + binarios en **S3**; sin huérfanos | US-01, US-02 | 0 archivos S3 sin registro en BD | Cumplido | `Receipt` + `storageService.js` |
| **RNF-26** | Seguridad | API keys M2M: hash **scrypt** + pepper, prefijo `cck_` | US-17 | Solo hash persistido; clave en claro una vez | Cumplido | `services/apiKeyService.js` |
| **RNF-27** | Cumplimiento fiscal | Validación CFDI SAT (SOAP) + parseo XML (UUID único) | US-03 | CFDI inválido/duplicado → rechazado | Cumplido | `satConsultaService.js`, `cfdiParserService.js` |

> **Notas de alineación (2026-06):** la base relacional es **PostgreSQL 16** (no MariaDB). Las columnas de archivo en `Receipt` son `pdf_file_id` / `xml_file_id`. Las API keys usan **scrypt**, no SHA-256.

---

## RNF de producto / UX (RNF-P01…RNF-P14)

Requerimientos derivados del backlog de historias de usuario; complementan los RNF técnicos sin reutilizar sus IDs.

| ID | Requerimiento | US | Criterio de medición | Prioridad | Estado |
|---|---|---|---|---|---|
| **RNF-P01** | Vistas responsive desde 320 px (mobile-first) | US-07, todas | Sin overflow horizontal en 320 px | Alta | Parcial |
| **RNF-P02** | Botones primarios táctiles ≥ 44×44 px | US-07, US-08 | CTAs cumplen tamaño en móvil | Alta | Parcial |
| **RNF-P03** | Compatibilidad Chrome, Safari, Edge (últimas 2 versiones) | Todas | 0 errores críticos cross-browser | Alta | Parcial |
| **RNF-P04** | TypeScript sin `any` en frontend | Todas (FE) | 0 usos de `any` | Media | Parcial |
| **RNF-P05** | Mensajes de error claros (sin stack trace al usuario) | Todas | Cada error tiene mensaje legible | Alta | Cumplido |
| **RNF-P06** | Dashboard actualiza datos sin recargar (< 60 s) | US-18 | Polling o SSE activo | Alta | Parcial |
| **RNF-P07** | Auto-guardado de borrador cada 30 s sin bloquear UI | US-21 | Guardado sin lag visible | Media | Parcial |
| **RNF-P08** | Si SAT no responde: mensaje y flujo no bloqueado | US-03 | Mock/fallback activo | Alta | Cumplido |
| **RNF-P09** | Correos de notificación en < 5 min tras el evento | US-20 | 95% entregados en < 5 min | Media | Parcial |
| **RNF-P10** | Migraciones de BD reversibles (up/down) | US-05 | Rollback funcional | Alta | Parcial |
| **RNF-P11** | Design tokens centralizados (colores, espaciado, tipografía) | Frontend | 1 archivo tokens; 0 hardcode | Media | Parcial |
| **RNF-P12** | Historial de solicitud inmutable (solo lectura) | US-19 | 0 modificaciones post-creación | Alta | Cumplido |
| **RNF-P13** | Comentarios inmutables (sin PUT/DELETE) | US-22 | No existen endpoints de edición | Media | Cumplido |
| **RNF-P14** | Log detallado en sync de empleados/proveedores | US-15 | Log: nuevos, actualizados, inactivos, errores | Alta | Cumplido |

**RNF heredados absorbidos por técnicos:**

| Viejo ID | Ahora |
|---|---|
| RNF-02 (formato error auth) | Cubierto por manejadores globales + RNF-P05 |
| RNF-04 (presigned 15 min) | **RNF-17** |
| RNF-05 (archivos cross-org) | **RNF-08**, **RNF-14**, **RNF-17** |
| RNF-06 (API key hash) | **RNF-26** (scrypt) |
| RNF-07 (401 genérico API key) | **RNF-26**, **RNF-P05** |
| RNF-09 (permiso, no rol) | **RNF-14** |
| RNF-10 (permisos expirados) | **RNF-14** + modelo `UserPermission` |
| RNF-13 (caché Banxico) | **RNF-15** |
| RNF-22 (fallback Banxico) | **RNF-16** |
| RNF-24 (transacciones atómicas) | Prisma `$transaction` en servicios críticos |
| RNF-25 (MariaDB/MongoDB) | **RNF-25** (PostgreSQL + S3) |
| RNF-26–28 (lint, docker, cobertura) | **RNF-21**, **RNF-22**, setup Docker en wiki |
| RNF-32 (log API key) | **RNF-24** |

---

## Matriz de Trazabilidad US ↔ RNF

| US | Título | RNF técnicos | RNF producto | Épica | Módulo |
|---|---|---|---|---|---|
| **US-01** | Interfaz de Carga de Comprobantes XML/PDF | RNF-07, RNF-17, RNF-25 | RNF-P01, RNF-P02, RNF-P05 | Automatización Fiscal | M1 |
| **US-02** | Extracción de Datos de CFDI (Backend) | RNF-11, RNF-25, RNF-27 | RNF-P05 | Automatización Fiscal | M1 |
| **US-03** | Verificación de CFDI ante el SAT | RNF-11, RNF-27 | RNF-P08 | Automatización Fiscal | M1 |
| **US-04** | Tipo de Cambio Automático vía Banxico | RNF-15, RNF-16 | — | Automatización Fiscal | M1 |
| **US-05** | Migración de DB — Tabla CFDI | RNF-21 | RNF-P10 | Automatización Fiscal | M1 |
| **US-06** | Límite de tiempo de reembolsos | RNF-11 | RNF-P05 | Control de Viajes | M2 |
| **US-07** | Interfaz Móvil para Aprobaciones | — | RNF-P01, RNF-P02, RNF-P03 | Aprobaciones | M2 |
| **US-08** | Aprobar o Rechazar Solicitudes | RNF-11, RNF-14 | RNF-P02, RNF-P05, RNF-P12 | Aprobaciones | M2 |
| **US-09** | Gestión de Agencia de Viajes Digital | RNF-11 | — | Control de Viajes | M3 |
| **US-10** | Gastos Individuales por Tramo | RNF-11, RNF-25 | — | Automatización Fiscal | M1 |
| **US-11** | API de exportación contable | RNF-11, RNF-24, RNF-26 | — | Automatización Fiscal | M1 |
| **US-12** | Configuración de Políticas de Viaje | RNF-08 | RNF-P05 | Control de Viajes | M2 |
| **US-13** | Registro de Nueva Empresa | RNF-08 | — | Onboarding | M3 |
| **US-14** | Creación de Permisos | RNF-08, RNF-14 | — | Onboarding | M2 |
| **US-15** | Sincronización de Empleados y Proveedores | RNF-25 | RNF-P14 | Onboarding | M3 |
| **US-16** | Configuración Dinámica de Workflow | RNF-08, RNF-14 | RNF-P05 | Onboarding | M2 |
| **US-17** | Autenticación vía API Key | RNF-24, RNF-26 | RNF-P05 | API Contable | M3 |
| **US-18** | Dashboard de Viáticos por Centro de Costos | — | RNF-P01, RNF-P06 | Reportería | M3 |
| **US-19** | Historial y Trazabilidad de Solicitud | RNF-24 | RNF-P12 | Reportería | M3 |
| **US-20** | Notificaciones Push y por Correo | — | RNF-P09 | Experiencia | M3 |
| **US-21** | Borrador Automático de Solicitud | — | RNF-P07 | Experiencia | M3 |
| **US-22** | Comentarios y Mensajería Interna | RNF-24 | RNF-P13 | Experiencia | M3 |
| **US-23** | Roles de Notificación vs. Autorización | RNF-14 | RNF-P12 | Aprobaciones | M2 |
| **US-24** | Catálogo Contable Maestro | RNF-08 | — | API Contable | M3 |
| **US-25** | Asociación de Cuentas a Tipos de Gasto | RNF-08, RNF-25 | — | API Contable | M3 |
