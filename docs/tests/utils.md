# Documentacion de utilidades de pruebas (Backend)

Este documento ofrece un resumen de todos los modulos utilitarios disponibles en el directorio `tests/utils`. Estas utilidades estan disenadas para apoyar las pruebas de la aplicacion TC3005B.501-Backend.

---

## Resumen general

El directorio de utilidades de pruebas contiene funciones auxiliares y clases que facilitan tareas comunes como generacion de tokens de autenticacion, importacion de archivos y control de salida por consola.

### Estructura del directorio

```
tests/utils/
├── createTestAuthToken.js    # Generacion de JWT para pruebas de auth
├── importXML.js              # Utilidad de importacion de archivos fixture
└── muteConsole.js            # Supresion de salida de consola en pruebas
```

---

## Referencia de utilidades

### 1. **createTestAuthToken.js**

**Proposito:** Generar tokens JWT para probar autenticacion y autorizacion.

**Descripcion:**
Este modulo proporciona utilidades para crear JWT firmados con distintos roles de usuario y configuraciones. Incluye constantes de roles predefinidas usadas en toda la aplicacion y funciones auxiliares para generar tokens con parametros personalizados.

**Exports:**

#### `createTestJWT(role, options)`

Crea un token JWT firmado con el rol especificado y parametros opcionales.

**Parametros:**

- `role` (string): Rol de usuario para el token
- `options` (object, optional): Objeto de configuracion con propiedades:
  - `user_id` (number): ID de usuario personalizado (auto incremental si no se envia)
  - `IP` (string): Direccion IP incluida en el token (por defecto "127.0.0.1")
  - `expiresIn` (string): Tiempo de expiracion del token (por defecto "1h")

**Retorna:** (string) Un token JWT firmado

**Ejemplo:**

```javascript
import { createTestJWT, ROLES } from './tests/utils/createTestAuthToken.js';

// Crear token con opciones por defecto
const token = createTestJWT(ROLES.ADMIN);

// Crear token con opciones personalizadas
const customToken = createTestJWT(ROLES.TRAVEL_AGENT, {
    user_id: 42,
    IP: "192.168.1.100",
    expiresIn: "24h"
});
```

#### Objeto `ROLES`

Constante predefinida que contiene todos los roles disponibles en la aplicacion:

- `SOLICITING` (string): "Solicitante" - Creador de solicitud de viaje
- `TRAVEL_AGENT` (string): "Agencia de viajes" - Operador de agencia de viajes
- `ACCOUNTS_PAYABLE` (string): "Cuentas por pagar" - Procesador de cuentas por pagar
- `N1` (string): "N1" - Aprobador de primer nivel
- `N2` (string): "N2" - Aprobador de segundo nivel
- `ADMIN` (string): "Administrador" - Administrador

#### Constante `LOCALHOST`

- `LOCALHOST` (string): "127.0.0.1" - Direccion IP localhost por defecto

---

### 2. **importXML.js**

**Proposito:** Proveer una clase utilitaria para importar y leer archivos XML/texto en entorno de pruebas.

**Descripcion:**
Este modulo define la clase `Importer`, que abstrae operaciones de lectura de archivos usando resolucion de URL con modulos ES6. Es especialmente util para cargar fixtures de pruebas, archivos XML y otros datos de test sin depender de rutas relativas fragiles.

**Exports:**

#### Clase `Importer`

**Constructor:**

```javascript
new Importer(basePath, dirName)
```

**Parametros:**

- `basePath` (string): Ruta base para importaciones (ruta relativa desde `dirName`)
- `dirName` (string, optional): Referencia de directorio para resolucion de URL (por defecto `import.meta.url`)

**Metodos:**

##### `async import(relativePath, options = null)`

Lee de forma asincrona y retorna el contenido de un archivo como string.

**Parametros:**

- `relativePath` (string): Ruta relativa a `basePath`
- `options` (object, optional): Opciones adicionales (actualmente sin uso)

**Retorna:** (Promise<string>) Contenido del archivo como string UTF-8

**Ejemplo:**

```javascript
import { Importer } from './tests/utils/importXML.js';

// Crear instancia del importador
const importer = new Importer('fixtures', import.meta.url);

// Cargar un fixture de prueba
const xmlData = await importer.import('sample.xml');
const jsonData = await importer.import('test-data.json');
```

---

### 3. **muteConsole.js**

**Proposito:** Suprimir salida de `console.log` durante la ejecucion de pruebas para mantener limpio el output.

**Descripcion:**
Este modulo ofrece una funcion utilitaria que envuelve la ejecucion de codigo de prueba y hace mock temporal de `console.log`. Es util cuando pruebas codigo con logs verbosos o cuando quieres evitar ruido en los resultados.

**Exports:**

#### `mutedConsoleLogs(fn)`

Ejecuta una funcion asincrona mientras silencia salida de `console.log`.

**Parametros:**

- `fn` (function): Funcion async a ejecutar con logs silenciados

**Retorna:** (Promise) El valor de retorno de la funcion proporcionada

**Comportamiento:**

- Crea un spy de Jest sobre `console.log`
- Hace mock del spy para prevenir salida
- Ejecuta la funcion proporcionada
- Restaura el spy aun si la funcion lanza error (usando `try/finally`)

**Ejemplo:**

```javascript
import { mutedConsoleLogs } from './tests/utils/muteConsole.js';

// Suprimir salida de consola durante la ejecucion
const result = await mutedConsoleLogs(async () => {
    // Codigo que escribe en consola
    console.log("Esto no sera visible en el output de pruebas");
    return "result";
});

// Se puede usar dentro de casos de prueba
test('debe manejar logging en silencio', async () => {
    const output = await mutedConsoleLogs(async () => {
        // Codigo de prueba que puede loggear en exceso
        await someVerboseOperation();
    });

    expect(output).toBeDefined();
});
```

---

## Uso en pruebas

Estas utilidades normalmente se usan juntas para crear escenarios de prueba mas completos:

### Ejemplo de prueba de autenticacion

```javascript
import { createTestJWT, ROLES } from './tests/utils/createTestAuthToken.js';

describe('Protected Routes', () => {
    test('admin should access admin route', async () => {
        const adminToken = createTestJWT(ROLES.ADMIN);

        const response = await request(app)
            .get('/api/admin/dashboard')
            .set('Authorization', `Bearer ${adminToken}`);

        expect(response.status).toBe(200);
    });
});
```

### Ejemplo de prueba de importacion de archivos

```javascript
import { Importer } from './tests/utils/importXML.js';

describe('XML Processing', () => {
    let importer;

    beforeAll(() => {
        importer = new Importer('fixtures', import.meta.url);
    });

    test('should parse XML correctly', async () => {
        const xmlData = await importer.import('sample.xml');
        const parsed = parseXML(xmlData);

        expect(parsed).toBeDefined();
    });
});
```

### Ejemplo combinando utilidades

```javascript
import { createTestJWT, ROLES } from './tests/utils/createTestAuthToken.js';
import { Importer } from './tests/utils/importXML.js';
import { mutedConsoleLogs } from './tests/utils/muteConsole.js';

describe('Full Integration Test', () => {
    let importer;

    beforeAll(() => {
        importer = new Importer('fixtures', import.meta.url);
    });

    test('should process with auth and quiet output', async () => {
        const token = createTestJWT(ROLES.TRAVEL_AGENT);
        const data = await importer.import('travel-data.xml');

        const result = await mutedConsoleLogs(async () => {
            return await processData(data, token);
        });

        expect(result).toBeDefined();
    });
});
```

---

## Buenas practicas

1. **Generacion de tokens:** Usa siempre constantes `ROLES` en lugar de hardcodear strings de rol para mantener consistencia.
2. **Importacion de archivos:** Prefiere la clase `Importer` para fixtures y evita problemas de resolucion de rutas.
3. **Silenciar consola:** Usa `mutedConsoleLogs` solo cuando el codigo realmente genere salida verbosa durante pruebas.
4. **Variables de entorno:** Asegura que `JWT_SECRET` este configurada antes de ejecutar pruebas.

---

## Requisitos de entorno

- **Node.js:** Soporte para modulos ES6 requerido
- **Dependencias:**
  - `jsonwebtoken` - Para firma de tokens JWT
  - `jest` - Para funcionalidad de mocking de consola
- **Variables de entorno:**
  - `JWT_SECRET` - Requerida para crear tokens JWT
