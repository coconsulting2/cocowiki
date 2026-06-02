# Manual de Administración — CocoAPI (Admin Ditta)

| Metadato                 | Valor                     |
| ------------------------ | ------------------------- |
| **Versión del documento** | 1.0.1                    |
| **Última actualización**  | 2026-06-02               |
| **Audiencia**             | Super Admin de Ditta Consulting (rol "Admin Ditta") |

---

## 1. Introducción al rol de Admin Ditta

### ¿Qué controlas como Admin Ditta?

Eres el **super-administrador** de la plataforma CocoAPI. Tu rol existe únicamente dentro de la organización **ROOT** (Ditta Consulting) y tienes capacidades que ningún otro rol posee:

- **Onboarding de organizaciones** — das de alta y configuras nuevas empresas cliente dentro de la plataforma.
- **Gestión multi-tenant** — ves y administras todas las organizaciones desde un solo lugar.
- **Impersonación** — puedes "ver como" cualquier organización cliente para configurar sus catálogos sin necesidad de pedirles acceso.
- **Usuarios cross-org** — gestionas usuarios de cualquier organización, no solo de Ditta.
- **Catálogos maestros** — configuras el catálogo contable, indicadores de impuesto y mapeo de gastos a nivel plataforma.

### ¿Qué NO controlas?

- **Reglas de workflow** — cada organización cliente configura sus propias cadenas de aprobación a través de su Administrador de organización. Tú no tienes acceso a esa pantalla.
- **Datos operativos de solicitudes** — no gestionas solicitudes de viaje individuales, cotizaciones ni comprobantes directamente.

### Diferencia clave: Admin Ditta vs. Admin de Organización

| Aspecto | Admin Ditta (tú) | Admin de Organización |
|---------|------|------|
| Alcance | Todas las organizaciones de la plataforma | Solo su propia organización |
| Organizaciones | ✅ Crear, activar, suspender, impersonar | ❌ No tiene acceso |
| Reglas de workflow | ❌ No tiene acceso | ✅ Configura su cadena de aprobación |
| Crear usuarios | ✅ En cualquier organización | ✅ Solo en su organización |
| Políticas de viáticos | ✅ | ✅ |
| Categorías de empleado | ✅ | ✅ |
| Plazo de reembolso | ✅ | ✅ |
| Catálogo contable | ✅ | ✅ |
| Indicadores de impuesto | ✅ | ✅ |
| Mapeo de gastos | ✅ | ✅ |
| Importar usuarios | ✅ | ✅ |
| Llaves API | ✅ | ✅ |
| Impersonar organización | ✅ | ❌ |

### Tu menú lateral

Después de iniciar sesión, tu sidebar muestra:

DASHBOARD · ORGANIZACIONES · CREAR USUARIO · POLÍTICAS DE VIÁTICOS · CATEGORÍAS DE EMPLEADO · PLAZO DE REEMBOLSO · IMPORTAR USUARIOS · CATÁLOGO CONTABLE · INDICADORES DE IMPUESTO · MAPEO DE GASTOS · LLAVES API · GASTO POR CC

> **Nota:** Observa que **no** aparece "REGLAS DE WORKFLOW". Esa opción es exclusiva del Administrador de cada organización.

[IMAGEN: sidebar_admin_ditta]

---

## 2. Gestión de organizaciones (multi-tenant)

Esta es tu **pantalla exclusiva** — ningún otro rol tiene acceso.

### Pantalla principal

[IMAGEN: lista_organizaciones]

Accede desde **"ORGANIZACIONES"** en el menú lateral. Verás:

- **Tabla de organizaciones** con columnas:
  - **ID** — identificador único de la organización (formato UUID).
  - **Nombre** — nombre comercial.
  - **RFC** — Registro Federal de Contribuyentes (puede estar vacío).
  - **Tipo** — `ROOT` (Ditta, en morado) o `Cliente`.
  - **Estado** — etiqueta de color según el estado.
  - **Acciones** — hasta cuatro botones contextuales por fila (solo para organizaciones no ROOT):
    - **Ver usuarios** — impersona la organización y navega directamente al `/dashboard`, donde verás la tabla de usuarios de ese cliente.
    - **Ver como** — activa la impersonación sin cambiar de pantalla. Si ya estás impersonando esa org, el botón dice **"Salir"** y la cancela.
    - **Activar** — visible cuando el estado es *"En configuración"* o *"Suspendida"*. Cambia el estado a *"Activa"*.
    - **Suspender** — visible cuando el estado es *"Activa"*. Solicita confirmación y cambia el estado a *"Suspendida"*.

- **Filtros** en la parte superior:
  - **Tipo:** Todos · ROOT (Ditta) · Cliente
  - **Estado:** Todos · En configuración · Activa · Suspendida

- **Botón "+ Nueva organización"**

### Estados de una organización

| Estado | Etiqueta | Color | Significado |
|--------|----------|-------|-------------|
| `CONFIGURING` | En configuración | Gris | Recién creada, se está configurando. |
| `ACTIVE` | Activa | Verde | Operativa, sus usuarios pueden ingresar. |
| `SUSPENDED` | Suspendida | Rojo | Bloqueada, ningún usuario puede ingresar. |

### Tipos de organización

| Tipo | Significado | Restricciones |
|------|-------------|---------------|
| `ROOT` | Ditta Consulting (la plataforma). | No puede ser suspendida ni impersonada. |
| `CLIENT` | Organización cliente. | Puede ser activada, suspendida e impersonada. |

---

### 2.1 Crear una nueva organización

[IMAGEN: wizard_crear_organizacion]

1. Haz clic en el botón **"+ Nueva organización"**.
2. Se abrirá un wizard con dos secciones.

#### Datos fiscales

3. Ingresa el **Nombre comercial** (obligatorio).
4. Ingresa la **Razón social** (opcional).
5. Ingresa el **RFC** (opcional).
6. Verifica la **Zona horaria** — por defecto es `America/Mexico_City`. Cámbiala si el cliente opera en otra zona.
7. Verifica la **Moneda base** — por defecto es `MXN`. Cámbiala si el cliente opera con otra moneda.

#### Administrador inicial

8. Ingresa el **Nombre completo** del administrador del cliente (obligatorio).
9. Ingresa su **Email** corporativo (obligatorio).
10. Ingresa una **Contraseña inicial** (obligatorio).

> **Nota:** Debajo del campo de contraseña verás el texto *"El admin podrá cambiar su contraseña al primer ingreso."* Esto significa que puedes usar una contraseña temporal.

11. Haz clic en **"Crear organización"**.
12. Si todos los datos son correctos, el wizard se cierra y la lista se refresca automáticamente.
13. Si hay un error, verás un mensaje en rojo dentro del wizard. Corrige y vuelve a intentar.

> **Importante:** La organización se crea en estado `CONFIGURING`. Deberás activarla manualmente cuando la configuración esté completa.

> **Consejo:** Después de crear la organización, usa la función "Ver como" para configurar su catálogo contable y mapeo de gastos antes de entregarla al cliente.

---

### 2.2 Activar una organización

1. Localiza la organización en la tabla.
2. Verifica que su estado sea *"En configuración"* o *"Suspendida"*.
3. Haz clic en **"Activar"**.
4. La organización cambiará a estado **"Activa"** y sus usuarios podrán ingresar al sistema.

---

### 2.3 Suspender una organización

[IMAGEN: confirmar_suspension_organizacion]

1. Localiza la organización en la tabla.
2. Verifica que su estado sea *"Activa"*.
3. Haz clic en **"Suspender"**.
4. Confirma en la ventana de diálogo: *"¿Suspender esta organización? Sus usuarios no podrán entrar."*
5. La organización cambiará a estado **"Suspendida"**.

> **Importante:** La organización ROOT (Ditta) **no puede ser suspendida**. El botón "Suspender" no aparece para ella.

> **Importante:** Al suspender una organización, **todos sus usuarios** pierden acceso inmediatamente. Usa esta acción solo cuando sea necesario (por ejemplo: incumplimiento de contrato, mantenimiento, o solicitud del cliente).

---

### 2.4 Impersonar una organización

[IMAGEN: banner_impersonacion]

La impersonación te permite ver y configurar los datos de una organización cliente como si fueras su administrador.

1. Localiza la organización en la tabla.
2. Haz clic en **"Ver como"**.
3. Aparecerá un **banner amarillo** en la parte superior:

> *"Estás viendo datos como org **[ID]**. Las queries usarán X-Organization-Id."*

4. Mientras estés impersonando, todas las pantallas de configuración (catálogo contable, mapeo de gastos, indicadores de impuesto, etc.) mostrarán los datos de **esa organización**, no los de Ditta.
5. Para salir de la impersonación:
   - Haz clic en **"Salir de impersonate"** en el banner amarillo, **o**
   - Haz clic en **"Salir"** junto a la organización en la tabla.

> **Consejo:** Usa la impersonación para configurar los catálogos contables de un cliente nuevo sin pedirle acceso. Es la forma más rápida de preparar una organización antes de entregarla.

> **Importante:** La organización ROOT (Ditta) **no puede ser impersonada**. El botón "Ver como" no aparece para ella.

---

## 3. Gestión de usuarios

### Dashboard de usuarios

[IMAGEN: dashboard_usuarios_admin_ditta]

Tu Dashboard muestra la sección **"Usuarios del sistema"** con:

- **Tarjetas de métricas:**
  - *Total usuarios* — cantidad de usuarios en la plataforma (o en la org impersonada).
  - *Roles activos* — roles distintos asignados.
  - *Organizaciones (vista)* — número de organizaciones visibles.
- **Botón "+ Crear usuario".**
- **Tabla de usuarios** con columnas:
  - ID · Usuario (iniciales + nombre) · Email · Rol (etiqueta de color) · Departamento · Acciones (Editar, Eliminar).

### Colores de las etiquetas de rol

| Rol | Color |
|-----|-------|
| Administrador | Oliva (primary) |
| Admin Ditta | Oliva (primary) |
| Autorizador N1 | Verde (success) |
| Autorizador N2 | Verde (success) |
| Solicitante | Gris (neutral) |
| Agencia de viajes | Ámbar (warning) |
| Cuentas por pagar | Coral (accent) |

---

### 3.1 Crear un usuario

1. Haz clic en **"+ Crear usuario"** en el Dashboard, o selecciona **"CREAR USUARIO"** en el menú lateral.
2. Completa los datos del usuario: nombre, correo electrónico, departamento.
3. Selecciona el **rol** apropiado.
4. Si estás impersonando una organización, el usuario se creará dentro de esa organización.
5. Confirma la creación.

[IMAGEN: formulario_crear_usuario_admin]

---

### 3.2 Editar un usuario

1. Localiza al usuario en la tabla del Dashboard.
2. Haz clic en **"Editar"** en la columna de Acciones.
3. Modifica los datos necesarios: nombre, correo, rol, departamento.
4. Guarda los cambios.

---

### 3.3 Eliminar un usuario

1. Localiza al usuario en la tabla del Dashboard.
2. Haz clic en **"Eliminar"** en la columna de Acciones.
3. Confirma en la ventana de diálogo: *"¿Estás seguro de que deseas eliminar al usuario [nombre]? Esta acción no se puede deshacer."*

> **⚠️ Atención:** Esta acción es **irreversible**. Verifica que estés eliminando al usuario correcto.

---

### 3.4 Importar usuarios masivamente

[IMAGEN: importar_usuarios_admin]

1. Selecciona **"IMPORTAR USUARIOS"** en el menú lateral.
2. Arrastra o selecciona un archivo. Los formatos aceptados son **`.json`**, **`.csv`** y **`.txt`** (máx. 2 MB).
3. El sistema generará una **vista previa** de los usuarios detectados con las siguientes características:
   - **Badge "auto-detectado"** junto al rol de cada usuario cuando el sistema infirió el rol a partir del archivo.
   - **Selector de rol por usuario** — puedes sobrescribir el rol inferido para cualquier persona antes de importar.
   - **Campo de contraseña por usuario** — puedes definir una contraseña individual. Si lo dejas vacío, se aplica la contraseña global del lote.
   - Si eliges la opción **"Otro (desde base…)"** en el selector de rol, se abre un modal para clonar un rol existente (por ejemplo N1) y marcar o desmarcar permisos del catálogo; al importar se creará un **rol nuevo** exclusivo para ese usuario (nombre tipo `Imp·usuario` si no especificas uno).
4. Revisa los datos y corrige errores si los hay.
5. Opcionalmente, ingresa una contraseña común en el campo *"Misma contraseña para todo el lote"*.
6. Confirma la importación haciendo clic en **"Importar N usuarios"**.

**Opción "Crear organización nueva" (solo JSON, sin impersonación activa):** Si marcas esta casilla antes de subir el archivo, el sistema creará primero la organización descrita en el bloque `organization` del JSON y después importará los usuarios en ella. Esta opción **solo está disponible cuando no estás impersonando** otra organización; si hay impersonación activa, la casilla aparece deshabilitada.

> **Consejo:** Si estás impersonando una organización, los usuarios se importarán dentro de esa organización. Esto es útil para el onboarding masivo de un cliente nuevo.

---

## 4. Configuración del sistema

### 4.1 Políticas de viáticos

[IMAGEN: politicas_viaticos_admin]

1. Selecciona **"POLÍTICAS DE VIÁTICOS"** en el menú lateral.
2. Configura los topes de gasto por categoría (alimentación, transporte, hospedaje, etc.).
3. Los topes aplican a la organización que estés viendo (ROOT o impersonada).
4. Guarda los cambios.

> **Nota:** Si estás impersonando una organización cliente, los cambios afectan solo a esa organización.

---

### 4.2 Categorías de empleado

1. Selecciona **"CATEGORÍAS DE EMPLEADO"** en el menú lateral.
2. Crea, edita o elimina categorías de empleado (ej: Director, Gerente, Analista, Practicante).
3. Estas categorías determinan qué topes de viáticos aplican a cada empleado.

---

### 4.3 Plazo de reembolso

1. Selecciona **"PLAZO DE REEMBOLSO"** en el menú lateral.
2. Establece los plazos máximos para la comprobación de gastos y para la ejecución de reembolsos.

---

### 4.4 Catálogo contable

[IMAGEN: catalogo_contable_admin]

1. Selecciona **"CATÁLOGO CONTABLE"** en el menú lateral.
2. Administra las cuentas contables (cuentas GL) que se usan para la exportación al ERP.
3. Puedes crear, editar y eliminar cuentas.
4. Si estás impersonando una organización, el catálogo que ves y editas es el de esa organización.

> **Consejo:** Configura el catálogo contable de un cliente nuevo vía impersonación antes de entregarle el acceso. Así el cliente ya tiene todo listo para comenzar a operar.

---

### 4.5 Indicadores de impuesto

1. Selecciona **"INDICADORES DE IMPUESTO"** en el menú lateral.
2. Configura los indicadores fiscales: IVA, ISR, IEPS, etc.
3. Estos indicadores se utilizan en la generación de pólizas contables para la exportación ERP.

---

### 4.6 Mapeo de tipos de gasto

[IMAGEN: mapeo_gastos_admin]

1. Selecciona **"MAPEO DE GASTOS"** en el menú lateral.
2. Asocia cada tipo de gasto (alimentación, transporte terrestre, vuelo, etc.) a una cuenta contable del catálogo.
3. Cuando todos los tipos de gasto ya estén mapeados, verás el mensaje: *"Todos los tipos de gasto ya están mapeados. Edita un mapeo existente."*

> **Importante:** Sin un mapeo completo, la exportación contable no podrá generar pólizas correctamente. Asegúrate de que todos los tipos de gasto estén asociados antes de activar una organización.

---

## 5. Monitoreo y reportes

### 5.1 Reporte de gastos por centro de costos

[IMAGEN: reporte_gastos_cc_admin]

1. Selecciona **"GASTO POR CC"** en el menú lateral.
2. Verás un reporte de gastos agrupado por centro de costos.
3. El indicador *"Todos los CCs por debajo del 80%"* muestra si los centros de costos están dentro del presupuesto.
4. Si estás impersonando una organización, el reporte corresponde a los datos de esa organización.

---

### 5.2 Exportación contable (vía impersonación)

Cuando impersonas una organización cliente, puedes acceder a la pantalla de **Exportar ERP** para verificar el estado de las pólizas contables y realizar exportaciones de prueba.

1. Impersona la organización deseada (ver sección 2.4).
2. Accede al módulo de exportación contable.
3. Consulta las pólizas por rango de fechas.
4. Descarga el archivo JSON si es necesario.

> **Consejo:** Esto es útil para validar que la configuración contable (catálogo + mapeo + indicadores) de un cliente genera pólizas correctas antes de entregarle el sistema.

---

## 6. Procedimientos de emergencia

### 6.1 Un cliente no puede iniciar sesión

1. Accede a **"ORGANIZACIONES"** en el menú lateral.
2. Localiza la organización del cliente.
3. Verifica su estado:
   - Si está *"Suspendida"*, haz clic en **"Activar"**.
   - Si está *"Activa"*, el problema no es de la organización.
4. Ve al Dashboard de usuarios y verifica que el usuario afectado exista y tenga el rol correcto.
5. Si el problema persiste, pide al usuario que limpie las cookies de su navegador y vuelva a intentar.
6. Si nada funciona, escala al equipo de desarrollo.

---

### 6.2 Un cliente reporta datos incorrectos

1. Usa **"Ver como"** para impersonar la organización del cliente.
2. Navega a la pantalla donde el cliente reporta el error.
3. Verifica los datos. Posibles causas:
   - **Error de configuración:** catálogo contable incorrecto, mapeo de gastos faltante, indicador de impuesto mal configurado. Corrígelo directamente.
   - **Error de datos de usuario:** rol incorrecto, departamento equivocado. Edita al usuario.
   - **Bug del sistema:** documenta el caso (pasos para reproducir, capturas, datos involucrados) y escala a desarrollo.
4. Sal de la impersonación cuando termines.

---

### 6.3 Configuración de emergencia de un cliente nuevo

Si necesitas dar de alta a un cliente rápidamente:

1. **Crea la organización** con los datos mínimos: nombre comercial + admin inicial (ver sección 2.1).
2. **Activa la organización** (ver sección 2.2).
3. **Impersona la organización** (ver sección 2.4).
4. Configura el **catálogo contable** básico (ver sección 4.4).
5. Configura el **mapeo de tipos de gasto** (ver sección 4.6).
6. **Sal de la impersonación**.
7. Comunica al administrador del cliente:
   - Sus credenciales de acceso.
   - Que debe completar: **reglas de workflow**, **políticas de viáticos** e **importación de usuarios**.

> **Consejo:** La configuración mínima para que una organización pueda operar es: catálogo contable + mapeo de gastos + al menos un usuario por cada rol operativo (Solicitante, N1, CxP).

---

### 6.4 Un usuario ve el mensaje "Tu sesion ha expirado"

Cuando el token JWT de una sesión caduca o es inválido, el sistema muestra automáticamente un modal de advertencia y redirige al usuario a `/login`. No se trata de un error del sistema; el usuario solo necesita volver a iniciar sesión.

Si el problema es recurrente (el usuario recibe el mensaje constantemente sin poder trabajar):

1. Verifica que el reloj del servidor y del navegador del usuario estén sincronizados.
2. Pide al usuario que limpie las cookies del navegador e intente de nuevo.
3. Si persiste, escala al equipo de desarrollo indicando el `user_id` y el momento aproximado de los incidentes.

---

### 6.5 Escalar a soporte técnico

Cuando necesites escalar un problema al equipo de desarrollo, recopila la siguiente información:

| Dato | Dónde encontrarlo |
|------|-------------------|
| **ID de organización** | Columna "ID" en la tabla de organizaciones |
| **Usuario afectado** | Email del usuario en el Dashboard |
| **Fecha y hora del incidente** | Pregunta al cliente o revisa los logs |
| **Pasos para reproducir** | Documéntalos tú mismo vía impersonación |
| **Capturas de pantalla** | Usa las herramientas del navegador |

#### Datos técnicos del stack (para referencia)

| Componente | Detalle |
|------------|---------|
| Frontend | Astro + React (puerto :4321 en desarrollo) |
| Backend | API REST (puerto :3000) |
| Base de datos relacional | PostgreSQL |
| Almacenamiento de archivos | MongoDB (GridFS) |
| Almacenamiento S3 | LocalStack (mock en desarrollo), S3 en producción |
| Contenedores | Docker Compose |

#### Comandos Docker útiles (solo en entorno de desarrollo)

| Comando | Qué hace |
|---------|----------|
| `docker:dev:down && docker:dev` | Reinicia todos los contenedores |
| `docker:data:reset` | Resetea las bases de datos |
| `docker:dev:clean` | Reset completo (elimina volúmenes e imágenes) |

> **⚠️ Atención:** Los comandos de reset eliminan datos. Úsalos solo en entornos de desarrollo, nunca en producción.

---

## 7. Checklist de onboarding de una nueva organización

Usa esta lista como guía cada vez que des de alta un nuevo cliente:

- [ ] **Crear organización** — nombre, RFC, razón social, zona horaria, moneda, admin inicial.
- [ ] **Impersonar organización** — para configurar sin pedir acceso al cliente.
- [ ] **Configurar catálogo contable** — cuentas GL que usará el cliente.
- [ ] **Configurar indicadores de impuesto** — IVA, ISR, etc.
- [ ] **Configurar mapeo de tipos de gasto** — asociar cada tipo de gasto a su cuenta GL.
- [ ] **Configurar políticas de viáticos** — topes por categoría.
- [ ] **Configurar categorías de empleado** — si difieren de las estándar.
- [ ] **Importar usuarios** (si el cliente proporcionó archivo `.json`, `.csv` o `.txt`) o crear manualmente al menos los usuarios clave.
- [ ] **Salir de impersonación**.
- [ ] **Activar la organización** — cambiar de "En configuración" a "Activa".
- [ ] **Entregar credenciales** al admin del cliente — email + contraseña temporal.
- [ ] **Comunicar al admin del cliente** que debe configurar: reglas de workflow.

> **Consejo:** Guarda esta checklist como plantilla y personalízala para cada cliente.

---

## 8. Funcionalidades en desarrollo

Las siguientes funcionalidades existen como componentes en el sistema pero **no están habilitadas en la navegación principal** de esta versión:

| Funcionalidad | Componente | Estado |
|---|---|---|
| **Simulador de workflow** | `SimuladorWorkflow.tsx` | Existe la pantalla pero no aparece en el menú lateral ni en las rutas de acceso. Permitiría probar reglas de aprobación antes de activarlas. |
| **Centros de costos (CRUD)** | `CostCenterAdmin.tsx` | Pantalla de administración de centros de costos. No está en las rutas de acceso. |
| **Gestión de roles y permisos** | `RolesAdmin.tsx` | Pantalla CRUD completa para gestionar roles y sus permisos granulares. No está habilitada en navegación. |
| **Notificaciones en tiempo real** | `NotificationBell.tsx` · `NotificationPreferences.tsx` | Los componentes están presentes en la interfaz pero la integración de tiempo real puede no estar activa. |
| **Excepciones de política** | `PolicyExceptionModal.tsx` · `PolicyExceptionsInbox.tsx` | Permitiría a un solicitante justificar gastos que excedan los topes y a un aprobador revisarlos. |
| **Comentarios en solicitudes** | Directorio `comments/` | Sistema de chat/comentarios entre participantes de una solicitud. |
| **Tipo de cambio** | `ExchangeRateDisplay.tsx` | Visualización del tipo de cambio para viajes internacionales. |

> **Nota:** Estas funcionalidades podrían habilitarse en futuras versiones. Si necesitas acceso anticipado a alguna, coordina con el equipo de desarrollo.

---

## 9. Referencia rápida

### Atajos de navegación

| Acción | Ruta |
|--------|------|
| Dashboard | `/dashboard` |
| Organizaciones | `/admin/organizations` |
| Crear usuario | `/crear-usuario` |
| Políticas de viáticos | `/admin/expense-policies` |
| Categorías de empleado | `/admin/employee-categories` |
| Plazo de reembolso | `/admin/refund-time-limits` |
| Importar usuarios | `/admin/onboarding-import` |
| Catálogo contable | `/admin/catalogo-contable` |
| Indicadores de impuesto | `/admin/indicadores-impuesto` |
| Mapeo de gastos | `/admin/mapeo-gastos` |
| Llaves API | `/admin/api-keys` |
| Gastos por CC | `/reportes/gastos-por-centro` |

### Glosario rápido

| Término | Significado |
|---------|-------------|
| **ROOT** | Organización raíz: Ditta Consulting. No puede ser suspendida ni impersonada. |
| **CLIENT** | Organización cliente de Ditta. Puede ser creada, activada, suspendida e impersonada. |
| **Impersonar** | Ver y editar los datos de una organización como si fueras su admin. Usa el header `X-Organization-Id`. |
| **Catálogo contable** | Conjunto de cuentas GL (General Ledger) configuradas para una organización. |
| **Mapeo de gastos** | Asociación entre tipos de gasto (alimentación, transporte, etc.) y cuentas contables. |
| **Workflow** | Cadena de aprobación de solicitudes de viaje. Lo configura el Admin de cada organización, no tú. |
| **Póliza** | Registro contable exportable al ERP. Contiene header SAP + partidas de detalle (debe/haber). |
| **Onboarding** | Proceso de alta e integración de una nueva organización y sus usuarios en la plataforma. |

---

*© 2026 Ditta Consulting. Todos los derechos reservados.*
*CocoAPI v0.4.2*
