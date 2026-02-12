# Análisis de Esfuerzo / WBS

**Equipo 1 COCONSULTIG2**
**11 de febrero del 2026**

**Planeación de sistemas de software**

**Profesor:**
Eduardo Rubinstein Meizner

---

## Diagrama de Roles

### Backend Developer's

**Función:**
Construcción de:
- APIs
- lógica de la aplicación
- base de datos
- integraciones

Responsable de rendimiento y seguridad del servidor.

**Candidatos Idóneos:** Mariano Carretero, Kevin Esquivel, Santino Im, Hector Lugo

---

### Frontend Developer's

**Función:**
Implementación de:
- interfaz de usuario
- experiencia de usuario
- integración con APIs
- alineación con estándares de accesibilidad

Responsable de usabilidad, consistencia visual y accesibilidad.

**Candidatos Idóneos:** Leonardo Rodriguez, Emiliano Deyta

---

### QA / Testing Engineer

**Función:**
Diseña y ejecuta:
- pruebas unitarias
- pruebas de integración
- pruebas funcionales
- validación UAT

Responsable de calidad antes de producción.

**Candidatos Idóneos:** Ángel Montemayor, Erick Morales, Eder Cantero, Emiliano Delgadillo

---

## 1. Capacidad del Equipo

### 1.1 Capacidad Semanal

| Rol | Personas | Horas/día | Horas/semana |
|-----|----------|-----------|--------------|
| Backend/BD | 3 | 5-6h | 75-90h |
| Frontend | 3 | 5-6h | 75-90h |
| QA/Documentación | 3 | 5-6h | 75-90h |
| Lead (incluye doc) | 1 | 5-6h | 25-30h |
| **TOTAL** | **10** | - | **250-300h** |

### 1.2 Capacidad Total del Proyecto

- **Capacidad mínima:** 15 semanas × 250h = 3,750 horas
- **Capacidad máxima:** 15 semanas × 300h = 4,500 horas
- **Capacidad promedio:** 15 semanas × 275h = **4,125 horas disponibles**

### 1.3 Capacidad Individual por Persona

| Rol | Horas totales (15 semanas) |
|-----|----------------------------|
| Backend/BD (c/u) | 375-450h |
| Frontend (c/u) | 375-450h |
| QA/Doc (c/u) | 375-450h |
| Lead | 375-450h |

---

## 2. Estrategia del Proyecto

### 2.1 Prioridades

1. **Máximo esfuerzo:** Deuda técnica
2. **Mínimo necesario:** MVP a definir
3. **Entregables obligatorios:** Documentación según asignaciones de equipo
4. **Soporte continuo:** Testing en paralelo

### 2.2 Deuda Técnica - Clasificación

**Crítica (Debe resolverse - 57h)**
- Auth endpoint upload: 15h
- Servicio Agencia de Viajes: 30h
- Sesión mock: 12h

**Media (Resolver si hay tiempo - 95h)**
- Logging estructurado: 25h
- Tests unitarios básicos: 40h
- Paginación: 30h

**Baja (No prioritaria - diferir)**
- Departamentos hardcodeados
- Protección CSRF completa
- Suite completa de tests
- Optimizaciones de performance

**Total deuda técnica máxima a abordar: 152h**

---

## 3. Estructura de Trabajo Breakdown (WBS)

### FASE 1: DEFINICIÓN Y ENTREGABLES INICIALES

**Duración:** Semana 1 (11-17 febrero 2026)
**Esfuerzo total:** 300 horas

**NOTA:** Todos los entregables de clase están programados para completarse en la Semana 1.

#### 1.1 Análisis Sistema Actual (120h)

| Actividad | Backend | Frontend | QA/Doc | Total |
|-----------|---------|----------|--------|-------|
| Estudio arquitectura y código | 40h | 40h | 40h | 120h |

**Detalle por equipo:**

**Backend/BD (40h):**
- Análisis arquitectura Express.js: 15h
- Estudio servicios existentes: 15h
- Revisión esquema BD (12 tablas + MongoDB): 10h

**Frontend (40h):**
- Análisis stack (Astro + React + TypeScript): 15h
- Estudio componentes reutilizables: 15h
- Mapeo de rutas y guards: 10h

**QA/Documentación (40h):**
- Mapeo flujos de negocio (7 etapas): 15h
- Análisis roles y permisos: 15h
- Documentación sistema actual: 10h

---

#### 1.2 Entregables Obligatorios de Clase (150h)

Todos estos entregables deben completarse en la Semana 1:

##### 1.2.1 Definición del Nombre, Misión, Visión y Valores (4h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Investigación y análisis organizacional | Lead + QA/Doc | 1h |
| Propuesta de identidad corporativa | Todo el equipo (workshop) | 2h |
| Redacción y refinamiento | Lead | 1h |

**Entregable:** Documento formal con identidad de la Oficina de Planeación de Proyectos

##### 1.2.2 Lista de Requerimientos V0.1 (30h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Levantamiento con cliente | Lead + 1 de cada equipo | 15h |
| Documentación requerimientos funcionales | Backend + Frontend | 10h |
| Documentación requerimientos no funcionales | QA/Doc | 5h |

**Entregable:** Documento con lista inicial de requerimientos del sistema

##### 1.2.3 Mapa de Arquitectura (Blueprint) (30h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Análisis arquitectura actual | Backend | 12h |
| Diseño arquitectura propuesta | Backend + Lead | 10h |
| Diagramas y documentación | Backend + QA/Doc | 8h |

**Entregable:** Diagrama de arquitectura del sistema (componentes, capas, tecnologías)

---

##### 1.2.4 Plan de Comunicación (20h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Definición de stakeholders | Lead | 6h |
| Estrategia de comunicación | Lead + QA/Doc | 8h |
| Herramientas y canales | Todo el equipo | 6h |

**Entregable:** Plan de comunicación del proyecto (interno y con cliente)

##### 1.2.5 Benthana (Plan de Riesgos) (20h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Identificación de riesgos | Todo el equipo (workshop) | 8h |
| Análisis y priorización | Lead | 6h |
| Planes de mitigación | Lead + Líderes técnicos | 6h |

**Entregable:** Documento de gestión de riesgos del proyecto

##### 1.2.6 Historias de Usuario (20h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Elaboración historias de usuario | Todo el equipo | 15h |
| Refinamiento y priorización | Lead + Cliente | 5h |

**Entregable:** Documento con historias de usuario en formato estándar

---

#### 1.3 Setup Proyecto (30h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Ambientes de desarrollo | Backend/BD | 10h |
| Estructura repositorio para nuevos módulos | Frontend | 8h |
| Plan de pruebas base | QA | 7h |
| Plantillas documentación | Lead + QA | 5h |

**Resumen Semana 1:**
- Análisis sistema actual: 120h
- Entregables de clase: 150h
- Setup proyecto: 30h
- **Total Semana 1: 300h**

---

### FASE 2: DEUDA TÉCNICA CRÍTICA

**Duración:** Semanas 2-3
**Esfuerzo total:** 240 horas

#### 2.1 Backend (90h de 150h disponibles)

| Tarea | Esfuerzo | Detalle |
|-------|----------|---------|
| Auth endpoint upload | 20h | Middleware (12h) + Tests (8h) |
| Servicio Agencia de Viajes | 40h | Lógica mínima (25h) + Integración (15h) |
| Sesión mock | 15h | Solución producción |
| Preparación infraestructura | 15h | Setup base para nuevos módulos |

**Total Backend Fase 2: 90h**

#### 2.2 Frontend (70h de 150h disponibles)

| Tarea | Esfuerzo | Detalle |
|-------|----------|---------|
| Componentes base reutilizables | 40h | Forms genéricos (20h) + Tablas (20h) |
| Paginación básica | 30h | Solo vistas críticas |

**Total Frontend Fase 2: 70h**

**Tiempo restante (80h):** Setup estructura para nuevos módulos

#### 2.3 QA/Documentación (80h de 200h disponibles)

| Tarea | Esfuerzo | Detalle |
|-------|----------|---------|
| Tests regresión críticos | 40h | Solo flujos que nuevos módulos usarán |
| Documentación técnica base | 40h | Guía desarrollo (20h) + Estándares (20h) |

**Total QA/Doc Fase 2: 80h**

**Tiempo restante (120h):** Preparación testing para nuevos módulos

---

### FASE 3: DESARROLLO DE NUEVOS MÓDULOS

**Duración:** Semanas 4-12 (9 semanas)
**Esfuerzo total:** 2,700 horas

**NOTA:** El alcance específico de cada módulo se definirá con el socio formador, aún no se tiene la fecha. Las estimaciones siguientes son plantillas base que se ajustarán según la complejidad real.

#### 3.1 Tipología de Módulos (Estimaciones Base)

##### Tipo A: Módulo Simple (600-800h total)

**Características:** CRUD básico, sin flujos complejos, pocas validaciones

| Componente | Esfuerzo Estimado |
|------------|-------------------|
| Backend/BD | 200-250h |
| Frontend | 250-300h |
| QA/Documentación | 150-250h |

**Ejemplos típicos:** Catálogos administrativos, Reportes de consulta, Dashboards informativos

##### Tipo B: Módulo Medio (800-1,000h total)

**Características:** Flujo de trabajo, múltiples validaciones, estados

| Componente | Esfuerzo Estimado |
|------------|-------------------|
| Backend/BD | 250-300h |
| Frontend | 350-400h |
| QA/Documentación | 200-300h |

**Ejemplos típicos:** Procesos de aprobación, Módulos con workflow, Gestión con reglas de negocio

##### Tipo C: Módulo Complejo (1,000-1,200h total)

**Características:** Integración externa, lógica compleja, múltiples roles

| Componente | Esfuerzo Estimado |
|------------|-------------------|
| Backend/BD | 350-400h |
| Frontend | 400-500h |
| QA/Documentación | 250-300h |

**Ejemplos típicos:** Integraciones con sistemas externos, Motores de reglas, Workflows multi-nivel

---

#### 3.2 Desarrollo de 3 Módulos Principales

**Capacidad disponible:** 9 semanas × 300h = 2,700h

**Distribución propuesta (ajustable):** 3 módulos de tipo B (medio) = 900h cada uno

---

##### Módulo 1 (Semanas 4-7: 900h)

**Sprint 1 - Desarrollo Core (Semanas 4-5: 450h)**

| Equipo | Actividades | Horas |
|--------|-------------|-------|
| Backend/BD | Diseño modelo de datos y migraciones + Endpoints principales (CRUD) + Lógica de negocio core + Tests unitarios básicos | 150h |
| Frontend | Componentes principales + Formularios y validaciones + Integración con API + Navegación y rutas | 150h |
| QA/Doc | Plan de pruebas del módulo + Casos de prueba + Tests exploratorios + Documentación funcional + Manual de usuario borrador | 150h |

**Sprint 2 - Refinamiento y Cierre (Semanas 6-7: 450h)**

| Equipo | Actividades | Horas |
|--------|-------------|-------|
| Backend/BD | Endpoints secundarios + Validaciones y manejo de errores + Optimizaciones + Tests de integración | 150h |
| Frontend | Componentes secundarios + Estados y manejo de errores + Refinamiento UX/UI + Tests de componentes | 150h |
| QA/Doc | Ejecución de tests completos + Gestión de bugs y regresión + Documentación final + Videos tutoriales | 150h |

**Total Módulo 1: 900h**

---

##### Módulo 2 (Semanas 6-9: 900h)

**Estrategia:** Inicio en Semana 6 con overlap parcial

**Semanas 6-7:** Equipo dividido 50/50
- 50% finalizando Módulo 1
- 50% iniciando Módulo 2 (Sprint 1)

**Semanas 8-9:** Todo el equipo en Módulo 2 (Sprint 2)

Estructura idéntica a Módulo 1:
- Sprint 1 - Desarrollo Core: 450h
- Sprint 2 - Refinamiento: 450h

**Total Módulo 2: 900h**

##### Módulo 3 (Semanas 9-12: 900h)

**Semanas 9-10:** Sprint 1 - Desarrollo Core (450h)
**Semanas 11-12:** Sprint 2 - Refinamiento (450h)

Estructura idéntica a módulos anteriores

**Total Módulo 3: 900h**

---

#### 3.3 Desglose Detallado por Sprint (Plantilla)

**Backend/BD - Sprint Core (150h):**
- Diseño modelo de datos: 30-35h
- Implementación endpoints CRUD: 60-70h
- Lógica de negocio: 30-40h
- Tests unitarios básicos: 10-15h

**Backend/BD - Sprint Refinamiento (150h):**
- Endpoints adicionales: 45-55h
- Validaciones y errores: 35-45h
- Optimizaciones: 25-35h
- Tests de integración: 25-30h

**Frontend - Sprint Core (150h):**
- Componentes principales: 70-85h
- Formularios y validaciones: 40-50h
- Integración API: 15-25h
- Rutas y navegación: 5-10h

**Frontend - Sprint Refinamiento (150h):**
- Componentes secundarios: 55-65h
- Manejo de estados y errores: 35-45h
- Refinamiento UX/UI: 30-40h
- Tests de componentes: 10-20h

**QA/Documentación - Sprint Core (150h):**
- Plan de pruebas: 20-30h
- Casos de prueba: 25-35h
- Tests exploratorios: 35-45h
- Documentación funcional: 30-40h
- Manual usuario borrador: 15-25h

**QA/Documentación - Sprint Refinamiento (150h):**
- Ejecución tests: 55-65h
- Bugs y regresión: 40-50h
- Documentación final: 25-35h
- Videos tutoriales: 10-20h

---

#### 3.4 Flexibilidad de Módulos

Dependiendo de la complejidad real de cada módulo definido con el cliente, se pueden ajustar las combinaciones:

**Opción A:** 3 módulos medianos (900h cada uno) - **RECOMENDADO**

**Opción B:** 2 módulos complejos (1,100h cada uno) + 1 simple (500h)

**Opción C:** 1 complejo (1,200h) + 2 medianos (750h cada uno)

**Opción D:** 4 módulos simples (675h cada uno) - Solo si todos son realmente simples

---

### FASE 4: INTEGRACIÓN Y TESTING FINAL

**Duración:** Semana 13
**Esfuerzo total:** 300 horas

#### 4.1 Testing Integral (200h)

| Equipo | Actividades | Horas |
|--------|-------------|-------|
| Backend/BD | Tests de integración entre módulos + Performance testing básico + Validación de integridad de datos | 65h |
| Frontend | Tests E2E de flujos principales + Cross-browser testing + Pruebas de usabilidad | 65h |
| QA/Doc | Tests de aceptación de usuario + Regresión completa del sistema + Reporte de bugs críticos | 70h |

#### 4.2 Correcciones Críticas (100h)

| Equipo | Actividades | Horas |
|--------|-------------|-------|
| Backend/BD | Fixes de bugs bloqueantes | 35h |
| Frontend | Fixes de bugs bloqueantes | 35h |
| QA/Doc | Re-testing y validación | 30h |

---

### FASE 5: DESPLIEGUE Y CIERRE

**Duración:** Semanas 14-15
**Esfuerzo total:** 300 horas

#### 5.1 Preparación para Producción (150h)

| Equipo | Actividades | Horas |
|--------|-------------|-------|
| Backend/BD | Scripts de migración de BD + Configuración ambiente producción + Validación de ambientes | 60h |
| Frontend | Build optimizado + Configuración de deploy + Smoke tests en producción | 50h |
| QA/Doc | Tests en ambiente de producción + Validación final de funcionalidades | 40h |

#### 5.2 Documentación Final y Entregables (100h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Manual de usuario completo | QA/Doc + Lead | 35h |
| Manual técnico del sistema | QA/Doc + Lead | 30h |
| Documento de pruebas | QA/Doc | 20h |
| Documentación de API | Lead + Backend | 10h |
| Presentación final del proyecto | Todo el equipo | 5h |

#### 5.3 Capacitación y Transferencia (50h)

| Actividad | Responsable | Horas |
|-----------|-------------|-------|
| Sesiones de capacitación a usuarios | Todo el equipo | 30h |
| Transferencia de conocimiento técnico | Líderes técnicos | 20h |

---

## 4. Resumen de Esfuerzo por Fase

| Fase | Semanas | Backend | Frontend | QA/Doc | Total |
|------|---------|---------|----------|--------|-------|
| 1. Onboarding, Definición y Entregables | 1 | 75h | 75h | 150h | 300h |
| 2. Deuda Técnica Crítica | 2-3 | 90h | 70h | 80h | 240h |
| 3. Módulo 1 | 4-7 | 300h | 300h | 300h | 900h |
| 3. Módulo 2 | 6-9 | 300h | 300h | 300h | 900h |
| 3. Módulo 3 | 9-12 | 300h | 300h | 300h | 900h |
| 4. Testing e Integración | 13 | 65h | 65h | 170h | 300h |
| 5. Despliegue y Cierre | 14-15 | 60h | 50h | 190h | 300h |
| **TOTAL** | **15** | **1,190h** | **1,160h** | **1,490h** | **3,840h** |

---

### Distribución Porcentual por Equipo

| Equipo | Horas Totales | Porcentaje del Total | Horas por Persona |
|--------|---------------|----------------------|-------------------|
| Backend/BD | 1,190h | 31.0% | 397h |
| Frontend | 1,160h | 30.2% | 387h |
| QA/Documentación | 1,490h | 38.8% | 373h (sin Lead) / 497h (con Lead) |
| Lead (parte de QA/Doc) | Aprox 120h | Incluido arriba | En coordinación y docs |
| **Total Proyecto** | **3,840h** | **100%** | **384h promedio** |

---

## 5. Análisis de Capacidad vs Planificación

| Concepto | Horas |
|----------|-------|
| Capacidad total disponible (15 semanas) | 4,125h |
| Esfuerzo planificado | 3,840h |
| Margen/Buffer | 285h |
| **Porcentaje de utilización** | **93.1%** |

---

### Distribución del Buffer (285h)

- Imprevistos y bloqueos: 140h (49%)
- Ajustes por complejidad de módulos: 90h (32%)
- Tiempo de coordinación adicional: 55h (19%)

### Análisis de Riesgo de Capacidad

**NOTA:** Con 93.1% de utilización, el margen es ajustado pero manejable. Recomendaciones:

1. Definir alcance claro en Semana 1 - No hay espacio para ambigüedades
2. Priorizar despiadadamente - Si un módulo es más complejo, otro debe simplificarse
3. Control semanal estricto - Detectar desviaciones temprano
4. Comunicación constante con cliente - Manejar expectativas desde el inicio

---

## 6. Timeline de Ejecución con Overlaps

**Semana 1 (11-17 feb):** Onboarding completo + TODOS los entregables de clase
- Todo el equipo trabajando en paralelo
- Prioridad: Completar todos los entregables obligatorios

**Semanas 2-3:** Deuda Técnica Crítica (equipo completo)

**Semanas 4-5:** Módulo 1 Sprint 1 (equipo completo al 100%)
- 3 Backend en Módulo 1
- 3 Frontend en Módulo 1
- 4 QA/Doc en Módulo 1 (incluye Lead)

**Semanas 6-7:** Overlap Módulos 1 y 2
- 50% del equipo: Finalizando Módulo 1 (Sprint 2)
  - 1.5 Backend
  - 1.5 Frontend
  - 2 QA/Doc
- 50% del equipo: Iniciando Módulo 2 (Sprint 1)
  - 1.5 Backend
  - 1.5 Frontend
  - 2 QA/Doc

**Semanas 8-9:** Módulo 2 completo (equipo completo al 100%)

**Semanas 9-10:** Módulo 3 Sprint 1 (equipo completo)

**Semanas 11-12:** Módulo 3 Sprint 2 (equipo completo)

**Semana 13:** Testing e Integración Final (equipo completo)

**Semanas 14-15:** Despliegue y Documentación (equipo completo)

---

## 7. Cronograma de Entregables de Clase

Todos los entregables de clase están programados para la Semana 1 (11-17 febrero 2026):

| Entregable | Esfuerzo | Responsables Principales |
|------------|----------|--------------------------|
| Definición: Nombre, Misión, Visión, Valores | 30h | Lead + QA/Doc + Todo (workshop) |
| Lista de Requerimientos V0.1 | 30h | Lead + Backend + Frontend |
| Mapa de Arquitectura (Blueprint) | 30h | Backend + Lead + QA/Doc |
| Plan de Comunicación | 20h | Lead + QA/Doc + Todo |
| Benthana (Gestión de Riesgos) | 20h | Lead + Todo (workshop) |
| Historias de Usuario | 20h | Todo el equipo |

**Total Entregables Semana 1: 150h**

Estos entregables se desarrollan en paralelo con:
- Análisis del sistema actual: 120h
- Setup del proyecto: 30h

**Total Semana 1: 300h de capacidad disponible**

---

## 8. Consideraciones

### 8.1 Supuestos de Estimación

1. **Complejidad de módulos:** Se asume complejidad media (tipo B) para los 3 módulos principales, ajustable según definición con cliente en Semana 1
2. **Alcance por definir:** Las estimaciones son plantillas que se refinan una vez se conozcan los requerimientos específicos
3. **Reutilización de código:** Los componentes desarrollados en Módulo 1 pueden acelerar desarrollo de Módulos 2 y 3
4. **Curva de aprendizaje:** Ya contemplada en la Semana 1 de onboarding
5. **Disponibilidad del equipo:** Se asume 100% de disponibilidad del equipo durante las 15 semanas
6. **Deuda técnica mínima:** Solo se aborda lo crítico que podría bloquear nuevos desarrollos
7. **Sistema base funcional:** Se asume que el sistema heredado funciona y solo requiere mejoras
8. **Entregables Semana 1:** Se pueden completar en paralelo con análisis del sistema debido a que se nutren del mismo trabajo

---

### 8.2 Riesgos que Pueden Afectar el Esfuerzo

| Riesgo | Probabilidad | Impacto en Horas | Mitigación |
|--------|--------------|------------------|------------|
| Módulos más complejos de lo esperado | Media-Alta | +150-300h por módulo | Usar buffer, negociar alcance temprano, simplificar funcionalidades |
| Requerimientos ambiguos o cambiantes | Media | +100-200h | Validación continua, documentación clara, control de cambios |
| Integraciones externas no contempladas | Media | +150-250h por integración | Identificar en Semana 1, evaluar viabilidad |
| Bloqueos por dependencias del cliente | Media | +50-100h | Comunicación semanal, decisiones documentadas |
| Bugs críticos en sistema heredado | Baja-Media | +100-150h | Resolver solo lo bloqueante, documentar workarounds |
| Ausencias del equipo (enfermedad, etc.) | Baja | Variable | Buffer del 7% ayuda, redistribución de tareas |
| Dificultades técnicas imprevistas | Media | +80-120h | Investigación temprana, consulta con expertos |
| Sobrecarga en Semana 1 por entregables | Media | +30-50h | Distribución eficiente, trabajo en paralelo, priorización |

---

## 9. Recomendaciones

### 9.1 Para Maximizar Efectividad

**Semana 1 es crítica - Validación de complejidad**

Dedicar tiempo suficiente a entender qué quiere el cliente. Si algún módulo es muy complejo (mayor a 1,000h), considerar:
- Reducir alcance a MVP real
- Eliminar funcionalidad no esencial
- Postergar funcionalidades para fase 2
- Replantear combinación de módulos (2 complejos + 1 simple)

**Establecer ceremonias ágiles ligeras:**
- Daily standups: 15min diarios (ya incluido en el cálculo)
- Sprint reviews: cada 2 semanas al finalizar cada sprint
- Retrospectivas: al final de cada módulo
- Demo a cliente: al completar cada módulo

**Control semanal de avance:**
- Tracking de horas reales vs estimadas
- Identificar desviaciones tempranas
- Ajustar plan si es necesario
- Comunicar al cliente cualquier riesgo inmediatamente

**Calidad técnica desde el inicio:**
- Code reviews obligatorios
- Tests unitarios en cada desarrollo
- Documentación inline en código
- Estándares de código definidos en Semanas 2-3

---

### 9.2 Estrategia para Semana 1

**Distribución de Trabajo:**

**Días 1-2 (Miércoles 11 - Jueves 12):**
- Reunión inicial con cliente (4h)
- Inicio análisis sistema actual (todos los equipos)
- Workshop identidad corporativa (Misión/Visión/Valores)

**Días 3-4 (Viernes 13 - Lunes 16):**
- Continuación análisis técnico
- Levantamiento de requerimientos con cliente
- Inicio de Blueprint de arquitectura
- Elaboración de Historias de Usuario

**Día 5 (Martes 17):**
- Cierre de todos los entregables
- Plan de Comunicación
- Benthana (Gestión de Riesgos)
- Setup de proyecto completado

**Trabajo en Paralelo:**

**Backend/BD (75h):**
- 40h análisis sistema
- 20h requerimientos + arquitectura
- 10h setup ambientes
- 5h workshops

**Frontend (75h):**
- 40h análisis sistema
- 20h requerimientos + historias usuario
- 8h setup repositorio
- 7h workshops

**QA/Doc (150h con Lead):**
- 40h análisis sistema
- 30h todos los documentos de clase
- 20h levantamiento requerimientos
- 30h plan comunicación + Benthana
- 15h historias usuario + workshops
- 15h coordinación general

---

### 9.3 Estrategia de Negociación con Cliente

Si al definir los módulos en Semana 1 se detecta que la complejidad total excede las 2,700h disponibles para desarrollo de módulos:

**Opción 1: Reducir alcance de módulos**
- Convertir algunos en MVPs más pequeños
- Posponer funcionalidades no críticas a fase 2
- Simplificar flujos complejos

**Opción 2: Reducir número de módulos**
- De 3 módulos a 2 módulos más robustos
- Priorizar el módulo de mayor valor de negocio

**Opción 3: Posponer deuda técnica no crítica**
- Si la deuda técnica identificada no bloquea, diferirla
- Ganar 95h adicionales (deuda técnica media)

**Opción 4: Combinar opciones**
- 2 módulos completos + 1 módulo ultra-simple
- 3 módulos reducidos a su mínima expresión

---

### 9.4 Decisiones Pendientes con Cliente

**Sobre los Módulos:**

1. **¿Cuáles son los 3 módulos prioritarios?**
   - Nombre y descripción de cada uno (1 párrafo)
   - Problema que resuelve
   - Usuarios principales

2. **¿Qué tipo de módulos son?**
   - ¿CRUD simple o flujo complejo?
   - ¿Requieren aprobaciones multi-nivel?
   - ¿Hay cálculos o reglas de negocio complejas?
   - ¿Necesitan integrarse con sistemas externos?

3. **¿Cuál es el alcance mínimo aceptable (MVP)?**
   - ¿Qué funcionalidades son "must have"?
   - ¿Qué puede dejarse para una fase 2?
   - ¿Hay flexibilidad si un módulo resulta muy complejo?

**Sobre la Operación del Proyecto:**

4. **Comunicación y seguimiento**
   - ¿Con qué frecuencia quiere demos? (recomendado: quincenal)
   - ¿Cuál es el canal de comunicación preferido?
   - ¿Quién es el punto de contacto para decisiones?

5. **Validación y testing**
   - ¿Habrá usuarios reales para UAT?
   - ¿Cuándo pueden participar en pruebas?
   - ¿Qué define que un módulo está "terminado"?

6. **Restricciones y dependencias**
   - ¿Hay sistemas externos que debamos conocer?
   - ¿Hay restricciones técnicas (tecnologías, plataformas)?
   - ¿Hay datos de prueba disponibles?

---

Revisión completa de todas las secciones
Validación de consistencia entre tablas
Corrección de formato en encabezados
Ajuste de numeración de secciones

---

Ajuste decimales en porcentajes
Corrección alineación tablas
Validación sumas totales por fase

---

Revisión distribución horas Backend
Ajuste estimaciones Frontend
Validación cálculos QA/Doc

---

Ajuste probabilidades riesgos
Mejora descripciones mitigación
Validación impactos en horas

---

Clarificación distribución equipo Semanas 6-7
Ajuste descripción overlaps Módulo 2 y 3
Validación coherencia timeline completo

---

Refinamiento distribución trabajo días 1-5
Validación horas paralelo por equipo
Corrección descripción actividades

---

Corrección ortografía general
Ajuste puntuación
Unificación terminología

---

Verificación suma horas por fase
Validación porcentajes distribución
Confirmación total 3,840h

---

Unificación ancho columnas
Ajuste alineación contenido
Corrección bordes tablas

---

Validación referencias cruzadas
Verificación coherencia estimaciones
Ajuste terminología consistente

---

Unificación nombres equipos
Ajuste títulos roles
Corrección abreviaturas

---

Refinamiento horas documentación
Ajuste tiempos testing
Validación total QA/Doc 1,490h

---

Mejora claridad estrategias
Ajuste descripción ceremonias ágiles
Refinamiento estrategia Semana 1

---

Validación final 4,125h disponibles
Confirmación 93.1% utilización
Verificación buffer 285h

---

Revisión final completa
Validación todos los entregables
Confirmación estructura y contenido
Documento aprobado para entrega

