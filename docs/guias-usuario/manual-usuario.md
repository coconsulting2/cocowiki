# Manual de Usuario — CocoAPI

| Metadato | Valor |
| ------------------------ | ------------------------- |
| **Versión del documento** | 1.1.0 |
| **Última actualización** | 2026-06-09 |
| **Audiencia** | Usuarios finales del sistema (todos los roles excepto Admin Ditta) |

---

## 1. Bienvenida

### ¿Qué es CocoAPI?

CocoAPI es la plataforma de gestión de viajes corporativos desarrollada por **Estudiantes del Tec de Monterrey - para Ditta Consulting**. A través de ella, usted puede solicitar viajes de negocios, obtener aprobaciones, comprobar sus gastos con comprobantes fiscales (CFDI) y dar seguimiento al ciclo completo de cada viaje: desde la solicitud inicial hasta el reembolso final.

### ¿Para qué le sirve?

- **Solicitar viajes** de negocios con rutas, fechas, necesidades de transporte y hospedaje.
- **Recibir aprobaciones** de sus jefes directos y de área de manera ágil.
- **Comprobar gastos** subiendo comprobantes fiscales digitales (XML y PDF) o imágenes de recibos internacionales.
- **Consultar reembolsos** y el estado de cada solicitud en tiempo real.
- **Exportar información contable** al sistema ERP de su empresa (si su rol lo permite).

### ¿Cómo obtener acceso?

El acceso a CocoAPI no se obtiene por autoregistro. Su **Administrador de organización** o el equipo de **Ditta Consulting** le creará una cuenta con un **nombre de usuario** (por ejemplo, `angel.montemayor`) y una contraseña inicial. Si no tiene acceso, contacte a su administrador.

---

## 2. Primeros pasos

### 2.1 Iniciar sesión

![Pantalla de inicio de sesión](./images/manual-usuario/login.png)

1. Abra CocoAPI en su navegador web.
2. En el panel derecho, ingrese su **nombre de usuario** (por ejemplo, `angel.montemayor`) en el campo correspondiente.
3. Ingrese su **Contraseña** en el campo siguiente.
4. Si desea ver la contraseña mientras la escribe, haga clic en el ícono del ojo junto al campo.
5. Si su administrador le proporcionó un **Id de organización**, ingréselo en el campo opcional. De lo contrario, déjelo vacío.
6. Haga clic en el botón **"Entrar"**.
7. El sistema le redirigirá a su panel principal (Dashboard).

> **Importante:** Si ve el mensaje *"Error al iniciar sesión"*, verifique que su usuario y contraseña sean correctos. Si el problema persiste, contacte a su administrador.

> **Importante:** Si olvidó su contraseña, contacte a su **Administrador de organización** o a **Ditta Consulting** para que le asigne una nueva. El enlace "Recuperar" en la pantalla de login no restablece la contraseña de forma automática.

### 2.2 Conocer la pantalla principal

![Dashboard Solcitante](./images/manual-usuario/dashboard_solicitante.png)

Al iniciar sesión, verá su **Dashboard** (panel principal). La interfaz se compone de:

- **Menú lateral (Sidebar):** A la izquierda de la pantalla. Muestra las opciones de navegación disponibles según su rol. Las opciones cambian automáticamente según los permisos asignados.
- **Barra superior:** Muestra su rol, campana de **notificaciones** (con contador de no leídas), cierre de sesión y acceso a su perfil.
- **Área principal:** Muestra el contenido de la sección seleccionada, incluyendo tarjetas de métricas, listas de solicitudes y acciones disponibles.

![Perfil Solcitante](./images/manual-usuario/sidebard.png)

### 2.3 Navegar por el sistema

1. Haga clic en cualquier opción del **menú lateral** para acceder a esa sección.
2. Las opciones visibles dependen de su rol en el sistema.
3. Para regresar al panel principal, haga clic en **"DASHBOARD"** en el menú lateral.

### 2.4 Consultar y editar su perfil

![Perfil Solcitante](./images/manual-usuario/perfl_usuario.png)

1. Haga clic en sus iniciales en la barra superior o acceda a **Perfil de usuario** (`/perfil-usuario`).
2. Podrá ver sus datos personales: nombre, correo electrónico, rol y departamento.
3. En la sección **Preferencias de notificación** puede activar o desactivar alertas por correo según el tipo de evento (aprobaciones, rechazos, comprobantes, etc.).

### 2.5 Cerrar sesión

1. Localice el botón o enlace de cierre de sesión en la interfaz.
2. Haga clic para cerrar su sesión de forma segura.
3. El sistema le redirigirá a la pantalla de inicio de sesión.

> **Importante:** Cierre siempre su sesión si utiliza un equipo compartido.

### 2.6 Sesión expirada

Si su sesión ha caducado mientras trabaja en el sistema, aparecerá un diálogo de advertencia con el mensaje *"Tu sesion ha expirado. Por favor inicia sesion nuevamente."* Al hacer clic en aceptar, el sistema lo redirigirá automáticamente a la pantalla de inicio de sesión. Vuelva a ingresar con sus credenciales para continuar.

---

## 3. Solicitante

### Descripción del rol

El **Solicitante** es el empleado viajero. Su rol principal es crear solicitudes de viaje, gestionar borradores, subir comprobantes de gastos y dar seguimiento a sus reembolsos. Es el rol más común del sistema.

### Su Dashboard

![Dashboard Solcitante](./images/manual-usuario/dashboard_solicitante_detalle.png)

Al ingresar, verá:

- **Tarjetas de métricas:**
  - *En revisión* — solicitudes pendientes de aprobación.
  - *Por comprobar* — solicitudes que requieren comprobación de gastos.
  - *En proceso* — solicitudes en cotización o atención por agencia.
- **Botón "+ Nueva solicitud"** — para crear una solicitud de viaje.
- **Lista "Requieren tu atención"** — solicitudes activas con su estado y acciones disponibles.

**Menú lateral:** DASHBOARD · CREAR SOLICITUD · DRAFT SOLICITUDES · GASTOS (COMPROBAR) · RESUMEN POR TRAMOS · REEMBOLSOS · HISTORIAL DE VIAJES

### 3.1 Crear una solicitud de viaje

![Dashboard Solcitante](./images/manual-usuario/crear_solicitud_boton.png)
![Dashboard Solcitante](./images/manual-usuario/formulario_solicitud.png)

1. Haga clic en el botón **"+ Nueva solicitud"** en su Dashboard, o seleccione **"CREAR SOLICITUD"** en el menú lateral.

#### Datos de la ruta del viaje

2. En la sección de ruta, seleccione el **país de origen**.
3. Ingrese la **ciudad de origen**.
4. Seleccione el **país de destino**.
5. Ingrese la **ciudad de destino**.
6. Seleccione la **fecha de inicio** del viaje.
7. Seleccione la **hora de inicio**.
8. Seleccione la **fecha de fin** del viaje.
9. Seleccione la **hora de fin**.
10. Si requiere **vuelo**, marque la casilla correspondiente.
11. Si requiere **hotel**, marque la casilla correspondiente.

> **Consejo:** Los campos marcados con asterisco (*) son obligatorios.

#### Agregar rutas adicionales

12. Si su viaje tiene varias escalas o destinos, haga clic en el botón **"+ Agregar Ruta a mi Viaje"**.
13. Complete los datos de la ruta adicional siguiendo los mismos pasos.
14. Para eliminar una ruta adicional, haga clic en el botón de eliminar junto a esa ruta.

#### Detalles generales

![Dashboard Solcitante](./images/manual-usuario/formulario_solicitud_pt2.png)

15. En **"Anticipo Esperado (MXN)"**, ingrese el monto del anticipo que necesita para el viaje (ejemplo: $15,000.00).
16. En **"Observaciones / Comentarios"**, describa el motivo del viaje y cualquier detalle relevante. Este campo es obligatorio.
17. Los campos de **Centro de Costos** y **Departamento** se llenan automáticamente con la información de su cuenta.

#### Enviar o guardar

18. **Opción A — Enviar:** Haga clic en **"Enviar Solicitud"**. La solicitud pasará al estado *"Primera Revisión"* y será enviada a su jefe directo para aprobación.
19. **Opción B — Guardar borrador:** Haga clic en **"Guardar Borrador"**. La solicitud se guardará sin enviarse y podrá completarla después.
20. Si desea limpiar todos los campos, haga clic en **"Limpiar Formulario"**.

> **Importante:** Las fechas de inicio no pueden ser en el pasado. La fecha de fin debe ser igual o posterior a la fecha de inicio. Si las fechas son iguales, la hora de fin debe ser posterior a la hora de inicio.

> **Consejo:** Si no tiene todos los datos listos, use **"Guardar Borrador"** para no perder lo que ya llenó.

### 3.2 Gestionar borradores

![Lista borradores](./images/manual-usuario/lista_borradores.png)

1. Seleccione **"DRAFT SOLICITUDES"** en el menú lateral.
2. Verá la lista de solicitudes guardadas como borrador.
3. Haga clic en un borrador para abrirlo.
4. Complete o modifique los campos necesarios.
5. Haga clic en **"Guardar Cambios"** para actualizar el borrador.
6. Haga clic en **"Enviar Solicitud"** para enviarlo a aprobación.

### 3.3 Editar una solicitud en primera revisión

Solo es posible editar una solicitud si su estado es **"Primera Revisión"**.

1. En su Dashboard, identifique la solicitud con el botón **"Editar"**.
2. Haga clic en **"Editar"**.
3. Modifique los campos necesarios.
4. Haga clic en **"Actualizar Solicitud"** para guardar los cambios.

### 3.4 Cancelar una solicitud

1. En su Dashboard, identifique la solicitud que desea cancelar.
2. Haga clic en el ícono de eliminar () junto a la solicitud.
3. Confirme la cancelación en la ventana de diálogo.

> **Importante:** No es posible cancelar solicitudes que se encuentren en los estados *"Comprobación gastos del viaje"* o *"Validación de comprobantes"*.

### 3.5 Subir comprobantes de gastos

![Subir comprobantes](./images/manual-usuario/subir_comprobantes.png)

Cuando su viaje esté aprobado y en estado *"Comprobación gastos del viaje"*, debe registrar cada gasto con su comprobante.

1. En su Dashboard, haga clic en **"Comprobar"**, en **GASTOS (COMPROBAR)** del menú, o en **"Subir comprobantes"** desde el detalle de la solicitud.
2. El sistema abre el formulario de comprobación (`/subir-comprobante/[id]`).

#### Datos del gasto

3. Seleccione el **Concepto** (Hospedaje, Comida, Transporte, Caseta, Autobús, Vuelo u Otro).
4. Ingrese el **Monto**. En viajes nacionales, al seleccionar el XML el sistema puede autorrellenar el total del CFDI.
5. Si el viaje tiene **varios tramos**, elija el **Tramo del viaje** al que corresponde el comprobante.
6. Para gastos en el extranjero, active **"Gasto en moneda extranjera (sin CFDI mexicano)"**, elija la moneda (USD, EUR, etc.), la **fecha del gasto** y revise la conversión a MXN que muestra el panel de tipo de cambio.

#### Archivos

7. **Viaje nacional:** arrastre o seleccione el **PDF** y el **XML** del CFDI. Ambos son obligatorios.
8. **Viaje internacional:** suba una **imagen** (JPG o PNG) del recibo. No se requiere XML.

#### Política de viáticos y excedentes

9. Antes de subir, el sistema evalúa el gasto contra las **políticas de viáticos** de su organización.
10. Si el monto **supera el tope** permitido, verá una alerta. Haga clic en **Justificar** y escriba el motivo (mínimo 10 caracteres). Su aprobador verá la justificación en su bandeja de autorizaciones.
11. Tras enviar la justificación, confirme de nuevo con **"Subir Comprobante"**.

#### Envío

12. Haga clic en **"Subir Comprobante"** y confirme en el diálogo.
13. El sistema crea el registro, sube los archivos, valida el CFDI ante el SAT (nacionales) y muestra una pantalla de éxito con el resumen fiscal (UUID, RFC emisor/receptor, fecha, total).

> **Importante:** Para viajes nacionales, el XML del CFDI es obligatorio. Sin él, no podrá completar la comprobación.

> **Consejo:** Para viajes internacionales, suba una foto clara del recibo con monto, fecha y concepto visibles.

### 3.6 Resubir un comprobante rechazado

Si el área de Cuentas por Pagar rechaza un comprobante:

1. Revise el motivo del rechazo en el detalle de su solicitud.
2. Acceda a la pantalla de resubida del comprobante (`/resubir-comprobante/[id]`).
3. Suba los archivos corregidos siguiendo el mismo procedimiento de la sección 3.5.

### 3.7 Consultar historial y reembolsos

**Historial de viajes:**

1. Seleccione **"HISTORIAL DE VIAJES"** en el menú lateral.
2. Verá la lista completa de sus solicitudes pasadas con su estado final.

![historial_viajes](./images/manual-usuario/historial_viajes.png)

**Reembolsos:**

1. Seleccione **"REEMBOLSOS"** en el menú lateral.
2. Verá un resumen de sus reembolsos pendientes y completados.

![dashboard_reembolsos](./images/manual-usuario/historial_reembolsos.png)

### 3.8 Ver el detalle de una solicitud

1. En su Dashboard o historial, haga clic sobre una solicitud para ver su detalle (`/detalles-solicitud/[id]`).
2. Verá la información completa: destino, fechas, rutas, anticipo, observaciones.
3. Si la solicitud se encuentra en estado **"Comprobación gastos del viaje"**, aparecerá un banner en la parte superior con el botón **"Subir comprobantes"**. Al hacer clic, el sistema lo redirige a la pantalla de comprobación.
4. La **Línea de tiempo** muestra el recorrido de la solicitud con indicadores visuales:
   - ● Verde = etapa completada
   - ● Azul = etapa actual
   - ○ Gris = etapa pendiente
   - ● Rojo = detenido (rechazado)
5. En la sección de movimientos, podrá ver quién aprobó, rechazó o escaló la solicitud, con fecha y comentarios.
6. También podrá ver los comprobantes ya subidos y el resumen de tramos del viaje.

![timeline_solicitud](./images/manual-usuario/timeline_solicitud.png)

### 3.9 Comentarios en la solicitud

En el detalle de la solicitud verá la sección **Comentarios**. Puede escribir mensajes para pedir aclaraciones a aprobadores o finanzas. Cuando Cuentas por Pagar rechaza un comprobante, el motivo se publica aquí automáticamente.

### 3.10 Resumen por tramos

Seleccione **RESUMEN POR TRAMOS** en el menú lateral para ver un desglose de gastos y comprobantes por cada tramo del viaje (útil en viajes multidestino).

---

## 4. Autorizador N1 — Jefe Directo

### Descripción del rol

El **Autorizador N1** es el primer nivel de aprobación. Revisa las solicitudes de viaje de su equipo directo y decide si aprobarlas o rechazarlas. Además, el N1 puede crear sus propias solicitudes de viaje (tiene todas las capacidades del Solicitante).

### Su Dashboard

![dashboard_autorizador_n1](./images/manual-usuario/dashboard_n1.png)

Al ingresar, verá el panel **"Por revisar"** con:

- **Tarjetas de métricas:**
  - *Pendientes* — cantidad de solicitudes por autorizar.
  - *Requieren atención hoy* — solicitudes urgentes.
- **Lista de solicitudes** con: nombre del solicitante, departamento, destino, fechas y número de solicitud.

### Menú lateral

DASHBOARD · AUTORIZACIONES · SOLICITUDES · CREAR SOLICITUD · DRAFT SOLICITUDES · GASTOS (COMPROBAR) · RESUMEN POR TRAMOS · REEMBOLSOS · GASTO POR CC · HISTORIAL DE VIAJES

### 4.1 Autorizar una solicitud

![autorizar_solicitud](./images/manual-usuario/autorizar_solcitud_n1.png)

1. Acceda al **Dashboard** o seleccione **"AUTORIZACIONES"** en el menú lateral.
2. Verá la lista de solicitudes pendientes de su equipo.
3. Haga clic en una solicitud para abrir su detalle.
4. Revise la información: datos del solicitante, rutas del viaje, fechas y monto de anticipo.
5. Para **aprobar**, haga clic en el botón de aprobación.
6. Opcionalmente, agregue un comentario.
7. Para **rechazar**, haga clic en el botón de rechazo.
8. Ingrese el **motivo del rechazo** (obligatorio).
9. Confirme su decisión.

> **Importante:** Al rechazar una solicitud, el motivo es obligatorio. Sea específico para que el solicitante pueda corregir y reenviar.

> **Consejo:** Si la lista de pendientes tiene más de 5 solicitudes, aparecerá un enlace *"Ver N solicitudes →"* para ver la lista completa.

### 4.2 Crear sus propias solicitudes

Como Autorizador N1, usted también puede crear solicitudes de viaje propias. Siga los mismos pasos descritos en la sección **3.1 Crear una solicitud de viaje**.

### 4.3 Consultar reporte de gastos por centro de costos

1. Seleccione **"GASTO POR CC"** en el menú lateral.
2. Verá un reporte de gastos agrupado por centro de costos.

![reporte_gastos_por_cc](./images/manual-usuario/gasto_cc_n1.png)

### 4.4 Revisar excepciones de política

En **AUTORIZACIONES**, debajo de la bandeja de solicitudes, aparece la sección **Excepciones de política**. Ahí verá gastos que superaron el tope de viáticos y la justificación del solicitante. Apruebe o rechace cada excepción antes de que el comprobante siga su flujo normal.

---

## 5. Autorizador N2 — Jefe de Área

### Descripción del rol

El **Autorizador N2** es el segundo nivel de aprobación. Su funcionalidad es idéntica a la del N1, con una diferencia clave: solo ve las solicitudes que **escalan** a su nivel según las reglas de aprobación configuradas para su organización.

### Diferencia con el N1

- El **N1** ve todas las solicitudes de su equipo directo.
- El **N2** solo ve solicitudes que requieren un segundo nivel de aprobación (por monto, tipo de viaje u otras reglas definidas por el Administrador de su organización).

### Su Dashboard

El panel se muestra como **"Por revisar"** con el subtítulo del rol. Las métricas y la operación son las mismas que las del N1 (secciones 4.1 a 4.4).

![dashboard_autorizador_n2](./images/manual-usuario/autorizar_solcitud_n1.png)

---

## 6. Cuentas por Pagar

### Descripción del rol

El área de **Cuentas por Pagar** interviene después de que el viaje ha sido aprobado y realizado. Sus funciones incluyen: cotizar solicitudes, validar comprobantes CFDI subidos por los solicitantes, y exportar los datos contables al sistema ERP de la empresa.

### Su Dashboard

![dashboard_cuentas_por_pagar](./images/manual-usuario/dashboard_cxp.png)

Al ingresar, verá el panel **"Revisión financiera"** con:

- **Tarjetas de métricas:**
  - *Por cotizar* — solicitudes pendientes de cotización.
  - *Por comprobar* — solicitudes pendientes de validación de comprobantes.
  - *Total pendientes* — suma de ambas.
- **Sección "Solicitudes por cotizar"** — con enlace a la bandeja de cotizaciones.
- **Sección "Solicitudes por comprobar"** — con enlace a la bandeja de comprobaciones.

### Menú lateral

DASHBOARD · TODAS LAS SOLICITUDES · COTIZACIONES · COMPROBACIONES · RESUMEN POR TRAMOS · EXPORTAR ERP · GASTO POR CC

### 6.1 Cotizar una solicitud

![cotizar_solicitud](./images/manual-usuario/cotizaciones_cxp.png)

1. Seleccione **"COTIZACIONES"** en el menú lateral, o haga clic en la sección *"Solicitudes por cotizar"* del Dashboard.
2. Seleccione una solicitud pendiente de cotización.
3. Revise los detalles del viaje: destino, fechas, necesidades de vuelo y hotel.
4. Asigne los costos estimados según las políticas de viáticos de su organización.
5. Confirme la cotización.

### 6.2 Comprobar y validar gastos

![comprobar_gastos_cxp](./images/manual-usuario/validar_gastos_solicitud.png)

1. Seleccione **"COMPROBACIONES"** en el menú lateral, o haga clic en la sección *"Solicitudes por comprobar"* del Dashboard.
2. Seleccione una solicitud pendiente de comprobación.
3. Revise cada comprobante subido por el solicitante.
4. Para cada comprobante, verifique:
   - Los datos fiscales extraídos del CFDI (RFC emisor, RFC receptor, UUID, monto, fecha).
   - El indicador de validación ante el SAT.
5. Para **aprobar** comprobantes, utilice el botón de aprobación.
6. Para **rechazar** comprobantes, utilice el botón de rechazo e ingrese el motivo. El motivo se publica en los comentarios de la solicitud.

7. Use la sección **Comentarios de la solicitud** para pedir aclaraciones al solicitante sin rechazar formalmente el comprobante.

> **Importante:** Verifique que el RFC receptor del comprobante coincida con el RFC de su organización.

> **Consejo:** Si rechaza un comprobante, el solicitante recibirá la notificación y podrá resubir uno nuevo.

### 6.3 Exportar datos contables al ERP

![exportar_contable](./images/manual-usuario/exportar_erp_cxp.png)

1. Seleccione **"EXPORTAR ERP"** en el menú lateral.
2. En la sección **"Rango de fechas"**, seleccione la fecha **"Desde"**.
3. Seleccione la fecha **"Hasta"**.
4. Si desea incluir pólizas ya exportadas previamente, active la casilla **"Incluir ya sincronizados"**.
5. Haga clic en el botón **"Consultar"**.
6. El sistema mostrará las pólizas encontradas con:
   - **Indicadores:** Pólizas, Solicitudes (viajes distintos), Líneas totales (partidas contables), Estado.
   - **Vista previa de cada póliza:** Viaje #, tipo de documento, partidas contables con detalle de Cuenta, Nombre, indicador Debe/Haber (D/H), Monto, Moneda, Centro de Costos y Texto.
   - **Totales** de Debe y Haber.

![vista_previa_polizas](./images/manual-usuario/vista_previa_cc.png)

7. Para ver el detalle de una póliza, haga clic sobre ella para expandirla.
8. Para ver los datos en formato técnico, haga clic en **"Ver JSON crudo (SAP)"**.
9. Para descargar todas las pólizas, haga clic en el botón **"Descargar JSON"**.
10. El archivo se descargará con el nombre `polizas_YYYY-MM-DD_YYYY-MM-DD.json`.

> **Consejo:** Si no aparecen pólizas, amplíe el rango de fechas o active *"Incluir ya sincronizados"*. El filtro usa la fecha de validación del comprobante aprobado.

### 6.4 Consultar todas las solicitudes

1. Seleccione **"TODAS LAS SOLICITUDES"** en el menú lateral.
2. Verá la lista completa de solicitudes de su organización.

---

## 7. Agencia de Viajes

### Descripción del rol

La **Agencia de Viajes** es el rol más acotado del sistema. Solo ve solicitudes ya aprobadas que requieren reserva de vuelo u hotel. Su función es gestionar las reservas de viaje.

### Su Dashboard

![dashboard_agencia_viajes](./images/manual-usuario/dashboard_agencia_viajes.png)

Al ingresar, verá el panel **"Solicitudes por atender"** con:

- **Indicador** de solicitudes pendientes.
- **Tarjeta de métrica:** *Esperando cotización* — solicitudes asignadas a su agencia.
- **Sección "Solicitudes por atender"** — solicitudes pendientes de gestión.
- **Sección "Viajes cancelados"** — viajes que fueron cancelados y pueden requerir cancelación de reservas.

### Menú lateral

DASHBOARD · ATENCIONES

### 7.1 Atender una solicitud

![atender_solicitud_agencia](./images/manual-usuario/atender_solcitudes_agenciaV.png)

1. Seleccione **"ATENCIONES"** en el menú lateral, o haga clic en una solicitud del Dashboard.
2. Seleccione la solicitud por atender.
3. Revise los datos del viaje: destino, fechas, necesidad de vuelo y/o hotel.
4. Gestione la reserva correspondiente.
5. Registre la atención en el sistema.

### 7.2 Revisar viajes cancelados

1. En su Dashboard, revise la sección **"Viajes cancelados"**.
2. Verifique si ya había realizado reservas para alguno de estos viajes.
3. De ser necesario, proceda a cancelar las reservas externas.

---

## 8. Administrador de Organización

### Descripción del rol

El **Administrador** es el responsable de configurar y gestionar su propia empresa dentro de CocoAPI. No toca datos operativos de solicitudes individuales; su función es establecer las reglas del juego: usuarios, políticas de viáticos, cadenas de aprobación y catálogos contables.

### Su Dashboard

![dashboard_administrador](./images/manual-usuario/dashboard_adminOrg.png)

Al ingresar, verá el panel **"Usuarios del sistema"** con:

- **Tarjetas de métricas:** Total usuarios, Roles activos, Organizaciones (vista).
- **Botón "+ Crear usuario"**.
- **Tabla de usuarios** con columnas: ID, Usuario (con iniciales), Email, Rol (con etiqueta de color), Departamento y Acciones (Editar, Eliminar).

### Menú lateral

DASHBOARD · CREAR USUARIO · POLÍTICAS DE VIÁTICOS · CATEGORÍAS DE EMPLEADO · PLAZO DE REEMBOLSO · IMPORTAR USUARIOS · CATÁLOGO CONTABLE · INDICADORES DE IMPUESTO · MAPEO DE GASTOS · REGLAS DE WORKFLOW · LLAVES API · GASTO POR CC

> **Nota:** El menú **REGLAS DE WORKFLOW** es exclusivo del Administrador de organización. El Admin Ditta no lo tiene.

### 8.1 Crear un usuario

![formulario_crear_usuario](./images/manual-usuario/crear_usuario_adminOrg.png)

1. Haga clic en **"+ Crear usuario"** en el Dashboard, o seleccione **"CREAR USUARIO"** en el menú lateral.
2. Complete los datos del nuevo usuario: nombre, correo electrónico, departamento.
3. Seleccione el **rol** que tendrá en el sistema (Solicitante, Autorizador N1, Autorizador N2, Cuentas por pagar, Agencia de viajes).
4. Confirme la creación del usuario.

### 8.2 Editar un usuario

1. En el Dashboard, localice al usuario en la tabla.
2. Haga clic en **"Editar"** en la columna de Acciones.
3. Modifique los datos necesarios (nombre, correo, rol, departamento).
4. Guarde los cambios.

![editar_usuario](./images/manual-usuario/editar_usuario_adminOrg.png)

### 8.3 Eliminar un usuario

1. En el Dashboard, localice al usuario en la tabla.
2. Haga clic en **"Eliminar"** en la columna de Acciones.
3. Confirme en la ventana de diálogo: *"¿Estás seguro de que deseas eliminar al usuario [nombre]? Esta acción no se puede deshacer."*

> **Importante:** La eliminación de un usuario es irreversible. Asegúrese de que es la acción correcta antes de confirmar.

### 8.4 Importar usuarios masivamente

![importar_usuarios](./images/manual-usuario/importarUsuario_adminOrg.png)

1. Seleccione **"IMPORTAR USUARIOS"** en el menú lateral.
2. Arrastre o seleccione un archivo. Los formatos aceptados son **`.json`**, **`.csv`** y **`.txt`** (máx. 2 MB).
3. El sistema generará una **vista previa** de los usuarios detectados con las siguientes características:
   - **Badge "auto-detectado"** junto al rol de cada usuario cuando el sistema infirió el rol a partir del archivo.
   - **Selector de rol por usuario** — puede sobrescribir el rol inferido para cualquier persona antes de importar.
   - **Campo de contraseña por usuario** — puede definir una contraseña individual. Si lo deja vacío, se aplicará la contraseña global.
   - Si elige la opción **"Otro (desde base…)"** en el selector de rol, se abrirá un modal para clonar un rol existente y personalizar sus permisos; al importar se creará un rol nuevo exclusivo para ese usuario.
4. Opcionalmente, ingrese una **contraseña común** para todo el lote en el campo *"Misma contraseña para todo el lote"*.
5. Confirme la importación haciendo clic en **"Importar N usuarios"**.

**Opción "Crear organización nueva" (solo JSON):** Si está disponible y marca esta casilla antes de subir el archivo, el sistema creará primero la organización descrita en el bloque `organization` del JSON y después importará los usuarios en ella. Esta opción solo está activa cuando **no** está impersonando otra organización.

> **Consejo:** Use la importación masiva cuando necesite dar de alta a muchos usuarios al mismo tiempo, por ejemplo al integrar un departamento completo.

### 8.5 Configurar políticas de viáticos

![politicas_viaticos](./images/manual-usuario/politicasViaticos_adminOrg.png)

1. Seleccione **"POLÍTICAS DE VIÁTICOS"** en el menú lateral.
2. Defina los topes de gasto por categoría (alimentación, transporte, hospedaje, etc.).
3. Asocie los topes a las categorías de empleado correspondientes.
4. Guarde los cambios.

### 8.6 Administrar categorías de empleado

1. Seleccione **"CATEGORÍAS DE EMPLEADO"** en el menú lateral.
2. Cree, edite o elimine categorías (por ejemplo: Director, Gerente, Analista).
3. Estas categorías determinan los topes de viáticos aplicables.

### 8.7 Configurar plazos de reembolso

1. Seleccione **"PLAZO DE REEMBOLSO"** en el menú lateral.
2. Establezca los plazos máximos permitidos para la comprobación de gastos y reembolsos.

### 8.8 Administrar catálogo contable

![catalogo_contable](./images/manual-usuario/catalogoContable_adminOrg.png)

1. Seleccione **"CATÁLOGO CONTABLE"** en el menú lateral.
2. Cree, edite o elimine cuentas contables (cuentas GL).
3. Estas cuentas se usarán para la exportación contable al ERP.

### 8.9 Configurar indicadores de impuesto

1. Seleccione **"INDICADORES DE IMPUESTO"** en el menú lateral.
2. Configure los indicadores fiscales aplicables (IVA, ISR, etc.).
3. Estos indicadores se utilizarán en la generación de pólizas contables.

### 8.10 Configurar mapeo de tipos de gasto

![mapeo_gastos](./images/manual-usuario/mapeoGastos_adminOrg.png)

1. Seleccione **"MAPEO DE GASTOS"** en el menú lateral.
2. Asocie cada tipo de gasto a una cuenta contable del catálogo.
3. Cuando todos los tipos de gasto estén mapeados, verá el mensaje *"Todos los tipos de gasto ya están mapeados. Edita un mapeo existente."*

### 8.11 Configurar reglas de workflow (aprobación)

![reglas_workflow](./images/manual-usuario/reglasWorkflow_adminOrg.png)

1. Seleccione **"REGLAS DE WORKFLOW"** en el menú lateral.
2. Defina la cadena de aprobación: quién aprueba qué solicitudes, cuándo se escala a segundo nivel (N2), y bajo qué condiciones.
3. Use el enlace **Simulador de workflow** dentro de la pantalla para probar escenarios antes de guardar.
4. Guarde los cambios.

> **Importante:** Esta pantalla es exclusiva del Administrador de organización. El Admin Ditta no tiene acceso a ella.

### 8.12 Gestionar llaves API

1. Seleccione **"LLAVES API"** en el menú lateral (`/admin/api-keys`).
2. Cree una llave con el alcance necesario (por ejemplo, exportación contable).
3. Copie el secreto `cck_...` en el momento de la creación; solo se muestra una vez.
4. Entregue la llave al equipo que integrará el ERP externo.

### 8.13 Consultar reporte de gastos por centro de costos

1. Seleccione **"GASTO POR CC"** en el menú lateral.
2. Verá un reporte de gastos de su organización agrupado por centro de costos.

---

## 9. Estados de una solicitud de viaje

A lo largo de su ciclo de vida, una solicitud pasa por los siguientes estados:

| Estado | Descripción | ¿Quién actúa? |
|--------|-------------|----------------|
| **Borrador** | Solicitud guardada pero no enviada. | Solicitante |
| **Primera Revisión** | Enviada y esperando aprobación del jefe directo (N1). | Autorizador N1 |
| **Segunda Revisión** | Escalada al segundo nivel de aprobación (N2). | Autorizador N2 |
| **Cotización del Viaje** | Aprobada. Finanzas asigna costos. | Cuentas por Pagar |
| **Atención Agencia de Viajes** | En proceso de reserva de vuelo/hotel. | Agencia de Viajes |
| **Comprobación gastos del viaje** | El solicitante debe subir comprobantes. | Solicitante |
| **Validación de comprobantes** | Finanzas revisa los comprobantes subidos. | Cuentas por Pagar |
| **Cierre** | Proceso completado. | Sistema |
| **Cancelado** | Solicitud cancelada por el solicitante o rechazada. | Solicitante / Autorizador |

---

## 10. Preguntas frecuentes

### General

**1. ¿Cómo obtengo mi usuario y contraseña?**
Su Administrador de organización o el equipo de Ditta Consulting le proporcionará sus credenciales de acceso. No existe un proceso de autoregistro.

**2. ¿Qué hago si olvidé mi contraseña?**
Contacte a su **Administrador de organización** o a Ditta Consulting. Ellos pueden asignarle una contraseña nueva. No existe recuperación automática por correo en la pantalla de login.

**3. ¿Puedo tener más de un rol en el sistema?**
Cada usuario tiene un único rol asignado. Si necesita funcionalidades de otro rol, contacte a su Administrador.

### Solicitudes

**4. ¿Puedo modificar una solicitud después de enviarla?**
Sí, pero solo mientras se encuentre en el estado "Primera Revisión". Una vez que avanza a otro estado, ya no es posible editarla.

**5. ¿Qué pasa si mi solicitud es rechazada?**
Recibirá una notificación con el motivo del rechazo. Puede crear una nueva solicitud corrigiendo los puntos señalados.

**6. ¿Puedo cancelar una solicitud en cualquier momento?**
Puede cancelar solicitudes en la mayoría de los estados, excepto cuando se encuentra en "Comprobación gastos del viaje" o "Validación de comprobantes".

### Comprobantes

**7. ¿Qué archivos necesito subir para un viaje nacional?**
Para viajes nacionales necesita dos archivos: el **PDF** del comprobante y el **XML** del CFDI. Ambos son obligatorios.

**8. ¿Qué archivos necesito subir para un viaje internacional?**
Para viajes internacionales solo necesita una **imagen** (JPG o PNG) del recibo o factura.

**9. ¿Qué pasa si el sistema rechaza mi archivo al subirlo?**
Verifique que el formato del archivo sea correcto (.pdf y .xml para nacionales, .jpg o .png para internacionales). Si el error persiste, intente con otro archivo o contacte a su área de soporte.

**10. ¿Qué significa el indicador de validación SAT?**
El sistema valida automáticamente los CFDI contra el servicio del SAT. El indicador le muestra si el comprobante es válido, cancelado o no encontrado.

**11. ¿Qué pasa si mi gasto supera el tope de viáticos?**
Debe justificar el excedente (mínimo 10 caracteres) antes de subir el comprobante. Su aprobador revisará la excepción en la bandeja de autorizaciones.

### Exportación

**12. ¿En qué formato se exportan los datos contables?**
Los datos se exportan en formato JSON compatible con sistemas SAP. Incluyen pólizas con encabezado y partidas de detalle (cuentas, montos, indicadores Debe/Haber).

**13. ¿Puedo volver a descargar una exportación anterior?**
Sí. En la pantalla de exportación, active la casilla "Incluir ya sincronizados" y consulte el rango de fechas correspondiente.

---

## 11. Glosario

| Término | Definición |
|---------|-----------|
| **Anticipo** | Monto de dinero solicitado antes del viaje para cubrir gastos estimados. |
| **Borrador** | Solicitud de viaje guardada pero aún no enviada para aprobación. |
| **CFDI** | Comprobante Fiscal Digital por Internet. Documento fiscal electrónico emitido y validado por el SAT en México. Se compone de un archivo XML y su representación impresa en PDF. |
| **Centro de costos** | Unidad contable a la que se cargan los gastos de un departamento o proyecto. |
| **Comprobar** | Acción de subir los comprobantes de los gastos realizados durante un viaje. |
| **Cotización** | Proceso en el que Cuentas por Pagar asigna los costos estimados a una solicitud aprobada. |
| **Dashboard** | Panel principal o página de inicio que muestra un resumen de sus actividades y pendientes. |
| **Organización** | Empresa cliente de Ditta Consulting que utiliza CocoAPI. Cada organización tiene sus propios usuarios, políticas y configuración. |
| **Póliza contable** | Registro contable que agrupa las partidas financieras de un viaje para su exportación al sistema ERP. |
| **Reembolso** | Devolución del dinero al empleado por gastos que exceden el anticipo o que no fueron cubiertos previamente. |
| **Ruta** | Trayecto dentro de un viaje, definido por origen, destino, fechas y horarios. Un viaje puede tener múltiples rutas. |
| **SAT** | Servicio de Administración Tributaria. Autoridad fiscal de México que valida los CFDI. |
| **Solicitud de viaje** | Petición formal dentro del sistema para realizar un viaje de negocios. Incluye rutas, fechas, necesidades y anticipo. |
| **Workflow** | Cadena de aprobaciones que sigue una solicitud. Define quién aprueba, cuándo se escala y bajo qué reglas. |
| **Excepción de política** | Justificación formal cuando un gasto supera el tope de viáticos configurado. Requiere aprobación del autorizador. |
| **Notificación** | Alerta en la campana del encabezado sobre eventos de sus solicitudes (aprobaciones, rechazos, comprobantes). |

*© 2026 Ditta Consulting. Todos los derechos reservados.*
*CocoAPI v0.4.2*
