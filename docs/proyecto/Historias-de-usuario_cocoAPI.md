![][image1]

**Historias de usuario** 

Proyecto: Sistema de Gestión de Viáticos (CocoAPI) Cliente: Ditta Consulting 

**Equipo 1 \- COCO-CONSULTING2** 

Curso: TC3005B.501 

10 de marzo de 2026  
Ditta Consulting 

\- Empresa partner de SAP   
\- Crear el portal web con tecnologías no SAP, que se pueda conectar con cualquier ERP, Analizar bien los niveles de Autorización 

\- N2 y N1, responsables de centros de costos \- revisar posibles mejorar, para tener un flujo más dinámico, por diferentes parametros, por nivel organizacional e importes, Responsive y de negocio 

No crear modelo de base de datos de contabilidad, estructura de datos exponer como api Consumir api del sat alv 

Hacer una api que consuma los datos de los empleados y proveedores, para no tener datos duplicados 

Sistema de notificaciones   
Sistema de Cambio de monedas   
Internacional no hay xml, porque lo genera el SAT   
A partir de solicitante, ver cuales son sus n1, y n2   
Ditta consulting 

cosas ya hechas:   
Facturas y cfdi   
viáticos diarios   
reembolsos en base a tickets 

Cosas que quieren: 

viaje multi destino (ya tenemos)   
Unificar el proceso de la agencia de viajes, no hacer subcontrataciones, integrar algún tipo de agencia digital 

Captura automática de datos desde CFDI   
Cada viaje tiene de forma individual sus gastos, aunque sea multi destino. Simplemente es como una forma de agrupar para la contabilidad general 

Integración de API de banxico para tipo de cambio.   
Integración de API de SAT para verificación de facturas CFDI en viajes nacionales .  
Historias de Usuario 

**Épica 1: Automatización y Validación Fiscal de Gastos** 

**US \- 01** 

| Título: Interfaz de Carga de Comprobantes XML/pdf |  |
| :---- | :---- |
| **Descripción:  Como** Solicitante,  **quiero** poder arrastrar y soltar mis archivos XML y PDF en una zona de carga dentro del formulario de gastos,  **para** adjuntar mis comprobantes de forma rápida sin tener que buscar archivo por archivo en el explorador. |  |
| **Criterios de Validación:**  1\. Se guarda de manera correcta en el sistema el XML. 2\. La zona de carga debe reaccionar visualmente cuando se arrastra un archivo sobre ella (ej. cambio de color). 3\. El sistema debe mostrar una barra de progreso o un indicador de "Cargando..." mientras se sube el archivo. 4\. Solo debe aceptar extensiones .xml y .pdf; de lo contrario, mostrar un error. | **Prioridad:** Alta |

**US \- 02** 

| Título: Extracción de Datos de CFDI (Backend) |  |
| :---- | :---- |
| **Descripción:  Como** Sistema,  **quiero** analizar el archivo XML de un CFDI subido,  **para** extraer automáticamente el RFC emisor, Fecha, Monto Total y UUID sin intervención manual. |  |
| **Criterios de Validación:**  1\. El sistema mapea correctamente los nodos del estándar del SAT.  2\. Si el XML no cumple la estructura, devuelve un mensaje de error específico.  3\. El sistema valida si el UUID ya existe en la base de datos para evitar duplicados. | **Prioridad:** Alta |

US \- 03

| Título: Verificación de CFDI ante el SAT |
| :---- |

| Descripción:  Como administrador financiero  Quiero que el sistema valide automáticamente cada CFDI contra el servicio del SAT Para asegurar la autenticidad y vigencia de las facturas en viajes nacionales. |  |
| :---- | :---- |
| **Criterios de Validación:**  1\. El sistema consume la API del SAT (WSDL/ALV) con el UUID del comprobante.  2\. Se muestra el estatus de validación (Vigente / Cancelado / No encontrado).  3\. No se permite aprobar un reembolso con CFDI inválido o cancelado. | **Prioridad:** Media/Baja |

US \- 04 

| Título: Tipo de Cambio Automático vía Banxico o Wise |  |
| :---- | :---- |
| **Descripción:  Como solicitante** con gastos en moneda extranjera  **quiero que** el sistema obtenga automáticamente el tipo de cambio oficial **Para** que mis reembolsos se conviertan correctamente sin ingresar el tipo de cambio manualmente. |  |
| **Criterios de Validación:**  1\. El sistema consume la API de Banxico para obtener el tipo de cambio del día.  2\. El importe en moneda extranjera se convierte automáticamente a MXN.  3\. Se muestra la fuente y fecha del tipo de cambio aplicado.  4\. El sistema consume la API de Wise para obtener el tipo de cambio del día. | **Prioridad:** Media/Baja |

US \- 05

| Título: Migración de DB — Tabla de datos fiscales CFDI |
| :---- |
| **Descripción:  Como sistema** de base de datos  **quiero que** se agregue una tabla con los campos de facturación necesarios que contiene un |

| CFDI  Para registrar automáticamente los datos y asegurar su trazabilidad |  |
| ----- | :---- |
| **Criterios de Validación:**  1\. Se debe crear una nueva tabla con los campos: UUID, RFC emisor, RFC receptor, fecha de emisión, monto, impuestos (JSON con desglose de impuestos),  2\. Se debe crear un archivo de migración con nombre timestamp para que sea replicable en el desarrollo y producción. | **Prioridad: Alta** |

**US \- 06** 

| Título: Límite de tiempo de reembolsos |  |
| :---- | :---- |
| **Descripción:  Como** Administrador de Ditta,  **quiero** Limitar el tiempo en el que se puede solicitar un reembolso,  **para** llevar un mejor control de los presupuestos de cada viaje. |  |
| **Criterios de Validación:**  1\. Se le asigna una fecha límite para solicitar reembolso (dos semanas)  2\. Un administrador revisa la solicitud de reembolso y la aprueba o rechaza  3\. Se realiza la devolución de dinero correspondiente al trabajador | **Prioridad:** Alta |

**US \- 25**

| Título: Carga de Comprobantes para Gastos Internacionales |  |
| :---- | :---- |
| **Descripción:  Como** Solicitante con gastos fuera de México, **quiero** poder subir una foto o PDF del recibo e ingresar manualmente los datos del gasto (monto, moneda, país y fecha), **para** reportar mis gastos internacionales cuando no existe un CFDI que validen el SAT. |  |
| **Criterios de Validación:**  1\. La zona de carga acepta extensiones .jpg, .jpeg, .png, .heic y .pdf cuando el gasto se marca como internacional. 2\. El sistema valida MIME type además de la extensión para evitar archivos renombrados. 3\. Al marcar el gasto como internacional, se ocultan los campos fiscales (RFC emisor, UUID y validación SAT) y se muestran los manuales. 4\. Los campos manuales obligatorios son: monto, moneda, país, fecha del gasto y descripción. 5\. El sistema marca internamente el gasto como tipo "internacional" para diferenciarlo en reportes y en la API contable (US-11). 6\. Se muestra el equivalente en MXN usando el tipo de cambio del día (US-04), indicando que es referencia interna y no tipo FIX fiscal. | **Prioridad:** Alta |

**Épica 2: Aplicación Dinámica para Aprobaciones y Movilidad** 

**US \- 07**

| Título: Interfaz Móvil para Aprobaciones |  |
| ----- | :---- |
| **Descripción:  Como** jefe de departamento (N1-NX),  **quiero** poder aceptar solicitudes desde mi dispositivo móvil,  **para** no detener el flujo de trabajo cuando estoy afuera de la oficina. |  |
| **Criterios de Validación:**  1\. La vista de la bandeja de aprobación y el detalle de solicitud deben tener un diseño 100% responsive. | **Prioridad:** Media. |

| 2\. Los botones de acción primaria ("Aprobar",  "Rechazar") deben ser accesibles táctilmente (tamaño adecuado para pantallas móviles). |  |
| :---- | :---- |

**US \- 23** 

| Título: Roles de Notificación vs. Autorización en el Workflow |  |
| :---- | :---- |
| **Descripción:  Como** Administrador de la organización,  **quiero** poder diferenciar en el flujo de aprobación entre usuarios que tienen poder de autorizar una solicitud y usuarios que solo deben ser notificados del resultado, y además poder reasignar una tarea de aprobación a otro usuario,  **para** que el flujo nunca se bloquee por ausencia de un aprobador. |  |
| **Criterios de Validación:**  1\. Al configurar un nivel del workflow, se puede marcar a un participante como "Autorizador" (puede aprobar/rechazar) o como "Solo notificación" (recibe el aviso pero no tiene acción disponible).  2\. Los usuarios marcados como "Solo notificación" ven la solicitud en modo lectura, sin botones de acción.  3\. Un Autorizador puede reasignar su tarea de aprobación a otro usuario con el mismo rol o superior, dejando registro del motivo y la reasignación en el historial de trazabilidad (US-19).  4\. Si un Autorizador no ha tomado acción en 48 horas, el sistema notifica automáticamente al siguiente nivel disponible para reasignación.  5\. No se puede reasignar a un usuario con rol de "Solo notificación". | **Prioridad:** Alta |

**Épica 3: Planificación Integrada y Control de Viajes** 

**US \- 08**

| Título: Aprobar o Rechazar Solicitudes |
| :---- |
| **Descripción:  Como** Aprobador (N1, N2),  **quiero** revisar el detalle de una solicitud y aprobar o rechazarla,  p**ara** gestionar el flujo de autorización de mi equipo. |

| Criterios de Validación:  1\. El aprobador ve el resumen completo: solicitante, monto, destino, comprobantes adjuntos.  2\. Puede aprobar o rechazar; el rechazo requiere comentario obligatorio.  3\. El sistema registra quién aprobó/rechazó y en qué fecha/hora.  4\. El solicitante recibe notificación del resultado. | Prioridad: Media. |
| ----- | :---- |

**US \- 09** 

| Título: Gestión de Agencia de Viajes Digital |  |
| :---- | :---- |
| **Descripción:  Como** Agencia de Viajes,  **quiero** visualizar opciones de vuelo/hotel integradas en el portal,  **para** no depender de sitios externos. |  |
| **Criterios de Validación:**  1\. Interfaz para seleccionar vuelos/hoteles pre-aprobados 2\. El costo se carga automáticamente a la solicitud 3\. Confirmacion automatica al aprobarse el viaje | **Prioridad:** Media |

**US \- 10** 

| Título: Gastos Individuales por Tramo en Viaje Multidestino |  |
| :---- | :---- |
| **Descripción:  Como** solicitante de un viaje multidestino  **Quiero** registrar los gastos de forma individual por cada tramo o destino  **Para** tener un desglose claro y que contabilidad pueda agruparlos correctamente. |  |
| **Criterios de Validación:**  1\. Cada tramo del viaje permite asociar sus propios comprobantes y gastos.  2\. El sistema muestra un resumen agrupado de todos los tramos para contabilidad.  3\. El total general consolidado los importes de todos los tramos del viaje. | **Prioridad:** Media |

**US \- 11**

| Título: API de exportacion contable (XML data) |
| :---- |

| Descripción:  Como Sistema ERP externo  quiero consumir un endpoint seguro que me entregue los datos estructurados de las facturas (xml) aprobadas,  para automatizar la póliza contable en el sistema financiero sin captura manual. |  |
| :---- | :---- |
| **Criterios de Validación:**  1\. Endpoint REST/JSON seguro (con API Key o JWT de servicio, cubierto por US-17).  2\. La estructura de respuesta incluye obligatoriamente: { UUID, RFC\_Emisor, RFC\_Receptor, Fecha\_Documento, Fecha\_Contabilizacion, Importe\_Cargo (positivo), Importe\_Abono (negativo), Indicador\_Impuesto, Moneda, Texto\_Cabecera, Texto\_Posicion\_Cargo,  Texto\_Posicion\_Abono, Centro\_Costos, Monto\_Total, Impuestos\_Desglosados, Conceptos, Fecha\_Timbrado }. 3\. Filtros disponibles: rango de fechas, estatus ("Aprobado para Pago"), centro de costos y moneda.  4\. Flag de "Sincronizado" para evitar descargar la misma póliza dos veces.  5\. Las fechas Fecha\_Documento y Fecha\_Contabilizacion son campos independientes: la primera es la fecha del CFDI timbrado, la segunda es la fecha en que el sistema registra contablemente el gasto tras aprobación.  6\. Los importes de cargo y abono se generan automáticamente a partir de la cuenta contable asociada al tipo de gasto (ver US-28). | **Prioridad:** Alta |

**US \- 12** 

| Título: Configuración de Políticas de Viaje (Viáticos y Topes) |
| :---- |
| **Descripción:  Como** Administrador de la organización,  **quiero** definir montos máximos de viáticos diarios y topes por tipo de gasto (hotel, vuelo), **para** que el sistema valide automáticamente si una solicitud cumple la política antes de enviarla a aprobación. |

**Criterios de Validación:**   
1.Se configuran montos de viáticos por categoría de empleado y destino (nacional / internacional). 

2.Se definen topes por tipo de gasto: hotel por noche, vuelo   
**Prioridad:** Alta

| por trayecto, comidas por día.  3.El sistema alerta al solicitante cuando un gasto supera la política, antes de enviar.  4.Un aprobador puede autorizar excepciones con justificación escrita.  5.Las políticas tienen vigencia (fecha inicio / fin) para actualizaciones anuales. |  |
| :---- | :---- |

**Épica 4: Onboarding y Configuración de nueva Organizacion** 

**US \- 13** 

| Título: Registro de Nueva Empresa (Organización) |  |
| ----- | :---- |
| **Descripción:  Como** Administrador de Ditta,  **quiero** registrar una nueva empresa en el sistema con su información básica, **para** habilitarla como Organización (nueva) activa dentro de la plataforma. |  |
| **Criterios de Validación:**  1\. Se capturan datos básicos: nombre de empresa, RFC, logo, zona horaria, moneda base.  2\. Al crear el tenant se genera un entorno aislado (subdominio o identificador único).  3\. El tenant queda en estado "En configuración" hasta completar el onboarding. | **Prioridad:** Alta |

**US \- 14**

| Título: Creación de Permisos |  |
| :---- | :---- |
| **Descripción:  Como** Administrador de la nueva organización,  **quiero** poder definir roles y permisos a los empleados dentro de la organización, **para** que puedan realizar sus actividades según su rol. |  |
| **Criterios de Validación:**  1\. El administrador puede crear roles con nombre personalizado (ej. "Analista de viajes", "Gerente Regional"). 2\. Al crear o editar un rol, se despliega el catálogo completo | **Prioridad:** Alta |

| de permisos disponibles para asignarle los que correspondan. 3\. Los permisos de vista son restrictivos: si un rol no tiene el permiso de una pantalla, esa pantalla simplemente no existe para el usuario, no aparece bloqueada ni en gris.  4\. Si el rol tiene capacidad de aprobar solicitudes, se le configura un monto máximo de autorización. Solicitudes que superen ese monto escalan automáticamente al siguiente nivel. 5\. Un rol sin monto de autorización configurado no puede aprobar solicitudes aunque tenga el permiso de "aprobar". 6\. No se puede eliminar un rol que tenga usuarios activos asignados; el sistema muestra advertencia.  7\. Debe existir siempre al menos un rol con permisos de administración para evitar organizaciones sin administrador activo. |  |
| :---- | :---- |

**US \- 15**

| Título: Sincronización de Empleados y Proveedores desde Fuente Externa |  |
| :---- | :---- |
| **Descripción:  Como** Administrador de Ditta,  **quiero** que el sistema importe y mantenga actualizado el catálogo de empleados y proveedores de cada organización,  para evitar datos duplicados y que la información siempre refleje la fuente oficial de la empresa. |  |
| **Criterios de Validación:**  1\. El sistema importa los registros según la configuración definida (API o CSV) y los asocia a la organización correspondiente.  2\. Si un registro ya existe, el sistema lo actualiza en lugar de duplicarlo, usando RFC o correo como identificador único.  3\. Si un empleado ya no existe en la fuente externa, el sistema lo marca como inactivo sin eliminarlo para preservar el historial.  4\. El administrador de Ditta puede ejecutar una sincronización manual en cualquier momento además de la automática. | **Prioridad:** Alta |

| 5\. El sistema genera un log de cada sincronización: registros nuevos, actualizados, inactivos y errores encontrados. |  |
| :---- | :---- |

**US \- 16** 

| Título: Configuración Dinámica de Workflow de Aprobación |  |
| :---- | :---- |
| **Descripción:  Como** Administrador de la organización,  **quiero** configurar las reglas del flujo de aprobación por diferentes parámetros (importe, nivel organizacional, tipo de gasto),  **para que** cada organización tenga un workflow adaptado a sus políticas internas. |  |
| **Criterios de Validación:**  Se pueden definir niveles de aprobación por rango de importes.  Se pueden asignar aprobadores por centro de costos o nivel organizacional.  El workflow permite saltar niveles si el importe es menor a un umbral configurable, los cambios de configuración aplican solo a solicitudes nuevas (no retroactivas).  El administrador puede simular el flujo con un importe de prueba antes de activarlo. | **Prioridad:** Alta |

**Epica 5: API Contable (ERP)** 

**US \- 17**

| Título: Autenticación de Sistemas Externos vía API Key |
| :---- |
| **Descripción:  Como** sistema ERP externo,  **quiero** autenticarme con una API Key de servicio para consumir los endpoints contables, |

| para acceder a los datos de forma segura sin usar credenciales de usuario. |  |
| :---- | :---- |
| **Criterios de Validación:**  El administrador de Ditta puede generar y revocar API Keys por organización desde el panel.  Cada key tiene un scope definido (ej. solo lectura contable). Las peticiones sin key válida retornan HTTP 401 con mensaje genérico.  Se registra en log de auditoría cada consumo: quién, cuándo, qué endpoint y código de respuesta.  Las keys tienen fecha de expiración configurable (ej. 1 año). | **Prioridad:** Alta |

**Épica 6: Inteligencia y Reporteria para la Toma de Decisiones** 

**US \- 18** 

| Título: Dashboard de Viáticos por Centro de Costos |  |
| :---- | :---- |
| **Descripción:  Como** Gerente o Administrador financiero,  **Quiero** ver un dashboard con el resumen de gastos de viaje agrupados por centro de costos, **Para** tomar decisiones de presupuesto en tiempo real sin exportar manualmente a Excel. |  |
| **Criterios de Validación:**  1\. El dashboard muestra gráficas de gasto acumulado por mes/trimestre por centro de costos.  2\. Permite filtrar por periodo, tipo de gasto y estatus de solicitud.  3\. Muestra alertas visuales cuando un centro de costos supera el 80% de su presupuesto asignado.  4\. Los datos se actualizan en tiempo real sin necesidad de recargar la página. | **Prioridad:** Alta |

**US \- 19**

| Título: Historial y Trazabilidad Completa de una Solicitud |  |
| :---- | :---- |
| **Descripción:  Como** Solicitante o Auditor,  **quiero** ver el historial completo de cambios de estado de mi solicitud con fecha, hora y responsable de cada acción,  **para** tener trazabilidad total del proceso y facilitar auditorías internas. |  |
| **Criterios de Validación:**  1\. Cada solicitud tiene una sección "Línea de tiempo" que muestra todos los cambios de estado en orden cronológico. 2\. Se registra quién realizó cada acción (nombre, rol, timestamp).  3\. Se muestran los comentarios de rechazo o excepciones en la misma línea de tiempo.  4\. El historial es de solo lectura y no puede ser modificado por ningún usuario. | **Prioridad:** Alta |

**US \- 20** 

| Título: Notificaciones Push y por Correo Configurables |  |
| :---- | :---- |
| **Descripción:  Como** usuario del sistema (solicitante o aprobador),  **quiero** configurar qué notificaciones quiero recibir y por qué canal (correo electrónico o notificación en el portal),  **para** no saturarme de alertas irrelevantes y no perder las que sí importan. |  |
| **Criterios de Validación:**  1\. El usuario puede activar/desactivar notificaciones por evento: solicitud enviada, aprobada, rechazada, pendiente de acción.  2\. Cada notificación puede configurarse para enviarse por correo, en el portal, o ambos.  3\. Las notificaciones en el portal se muestran en un ícono de campana con contador de no leídos.  4\. El correo enviado incluye un link directo a la solicitud correspondiente. | **Prioridad:** Media/ Baja |

**Épica 7: Experiencia del Solicitante**  
**US \- 21** 

| Título: Borrador Automático de Solicitud |  |
| :---- | :---- |
| **Descripción:  Como** Solicitante,  **quiero** que el sistema guarde automáticamente mi solicitud como borrador mientras la estoy llenando,  **para** no perder información si cierro el navegador o se interrumpe mi conexión. |  |
| **Criterios de Validación:**  1\. El sistema guarda el borrador automáticamente cada 30 segundos mientras el formulario tiene cambios no guardados. 2\. Al volver a entrar, el sistema ofrece continuar el último borrador guardado.  3\. El usuario puede ver y gestionar sus borradores desde una sección "Mis borradores".  4\. Un borrador no enviado después de 30 días genera una notificación de limpieza al usuario.  5\. Un borrador nunca es visible para aprobadores ni contabilidad hasta que sea enviado formalmente. | **Prioridad:** Media/ Baja |

**US \- 22**

| Título: Comentarios y Mensajería Interna por Solicitud |  |
| :---- | :---- |
| **Descripción:  Como** Aprobador,  **quiero** poder dejar comentarios directamente en una solicitud y que la otra parte los reciba como notificación,  **para** aclarar dudas sin salir del sistema ni usar correo externo y el solicitante pueda realizar los cambios necesarios. |  |
| **Criterios de Validación:**  1\. Cada solicitud tiene una sección de comentarios tipo chat visible para el solicitante y todos los aprobadores involucrados.  2\. Al agregar un comentario, todos los participantes de esa solicitud reciben una notificación.  3\. Los comentarios son inmutables una vez guardados (no se pueden editar ni eliminar).  4\. El administrador de Ditta puede ver todos los comentarios de todas las solicitudes para fines de auditoría. | **Prioridad:** Media/ Baja |

| 5\. Los comentarios se incluyen en el historial de trazabilidad de la solicitud (US-19). |  |
| :---- | :---- |

**US \- 23** 

| Título: Catálogo Contable Maestro (Cuentas e Indicadores de Impuestos) |  |
| :---- | :---- |
| **Descripción:  Como** Administrador contable de Ditta,  **quiero** registrar y mantener el catálogo de cuentas contables por tipo de cuenta y el catálogo de indicadores de impuestos,  **para** que el sistema pueda generar automáticamente la estructura correcta al exportar datos al ERP. |  |
| **Criterios de Validación:**  1\. El administrador puede crear cuentas contables con los campos: número de cuenta, descripción, tipo (Anticipos / Gastos / Acreedores) y moneda.  2\. El administrador puede crear indicadores de impuesto con: clave del indicador, descripción, porcentaje aplicable y tipo (IVA trasladado, IVA retenido, ISR retenido, etc.). 3\. Las cuentas e indicadores son a nivel organización: cada tenant tiene su propio catálogo aislado.  4\. No se puede eliminar una cuenta o indicador que esté asociado a un tipo de gasto activo (ver US-28); el sistema muestra advertencia.  5\. El catálogo puede exportarse como CSV para revisión del equipo contable externo. | **Prioridad:** Alta |

**US \- 24**

| Título: Asociación de Cuentas Contables a Tipos de Gasto |
| :---- |
| **Descripción:  Como** Administrador contable de Ditta,  **quiero** asociar cada tipo de gasto o reembolso (avión, hotel, alimentos, etc.) a su cuenta contable de cargo y abono correspondiente,  **para** que al exportar una póliza al ERP los importes se registren automáticamente en las cuentas correctas sin intervención manual. |

| Criterios de Validación:  1\. El administrador puede asociar cada tipo de gasto (avión, hotel, alimentos, transporte, anticipo, etc.) a una cuenta contable de cargo y una de abono del catálogo maestro (US-24).  2\. Se puede asignar un indicador de impuesto por defecto a cada tipo de gasto.  3\. Si un gasto llega al endpoint de exportación (US-11) sin asociación contable configurada, el sistema lo marca como "Pendiente de mapeo contable" y no lo incluye en la póliza hasta que se resuelva.  4\. El administrador ve un panel de estado que muestra qué tipos de gasto tienen y cuáles no tienen asociación contable configurada.  5\. Los cambios en la asociación aplican solo a solicitudes nuevas, no de forma retroactiva, con registro del cambio y fecha. | Prioridad: Alta |
| :---- | :---- |

[image1]: <data:image/png;base64,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>