# Despliegue en AWS (producción)

Guía para desplegar **TC3005B.501-Backend** y **TC3005B.501-Frontend** en una
sola instancia EC2 con Docker Compose, TLS vía Caddy y archivos en S3.

> [!IMPORTANT]
> Esta arquitectura de producción **reemplaza Mongo por S3 + Postgres**. Ya no
> existe `MONGO_URI`: los archivos viven en un bucket S3 privado y los datos en
> Postgres (co-locado en el contenedor o externo tipo RDS).

> [!TIP]
> Todos los scripts viven en `cocowiki/deploy/`. Son **idempotentes**:
> re-ejecutarlos reutiliza lo existente (provisión) o hace pull + rebuild
> (instalación).

---

## 1. Arquitectura

Una instancia EC2 **ARM (t4g.small, Amazon Linux 2023 arm64)** corre cuatro
contenedores con Docker Compose. Solo Caddy se expone a Internet (80/443).

```
                          Internet
                             │
                      :80 / :443 (TLS)
                             │
                 ┌───────────▼────────────┐   EC2 t4g.small (AL2023 arm64)
                 │         caddy           │   ── red Docker "coco" ──
                 │  (reverse proxy + TLS)  │
                 └─────┬───────────────┬───┘
            /api/*  →  │               │  ←  todo lo demás
                       │               │
          ┌────────────▼───┐   ┌───────▼──────────┐
          │    backend     │   │    frontend       │
          │ Express HTTPS  │   │  Astro SSR (HTTP) │
          │ :3000 (selfsig)│   │  :4321            │
          └───┬────────┬───┘   └───────────────────┘
              │        │
   DATABASE_URL│        │ S3 (IAM instance role)
              │        ▼
   ┌──────────▼──┐   ┌──────────────────────────┐
   │  postgres   │   │  Bucket S3 privado (SSE)  │
   │ :5432       │   │  coco-consulting-prod-... │
   │ (perfil     │   └──────────────────────────┘
   │  localdb)   │
   └─────────────┘
```

- **caddy** termina TLS. Por defecto usa un certificado **auto-firmado**
  (funciona con solo la IP/DNS de EC2). Enruta `/api/*` al backend **sin quitar
  el prefijo** y todo lo demás al frontend.
- **backend** sirve HTTPS auto-firmado en `:3000`, todas las rutas bajo `/api`.
  Solo accesible dentro de la red Docker.
- **frontend** sirve Astro SSR en HTTP plano `:4321`, solo interno.
- **postgres** es opcional (perfil `localdb`); puedes usar una BD externa.
- **S3** guarda los archivos. El backend obtiene credenciales del **IAM
  instance role** de la EC2 — sin llaves estáticas.

---

## 2. Prerrequisitos

| Dónde | Herramienta | Notas |
|-------|-------------|-------|
| Tu Mac | **AWS CLI v2** | `aws configure` con un usuario con permisos EC2/S3/IAM. |
| Tu Mac | **bash, curl, openssl** | Incluidos en macOS. |
| AWS | VPC `vpc-0f7bd8ada126a095b` (10.0.0.0/24) | Existente y vacía, en `us-east-1`. |
| AWS | Presupuesto | ≈ **\$12–15/mes** corriendo; presupuesto del proyecto **\$56**. |

Los repos son **públicos**, así que la instancia los clona sin autenticación.

---

## 3. Paso 1 — Provisionar AWS (`aws-provision.sh`)

Desde tu Mac, en `cocowiki/deploy/`:

```sh
cd cocowiki/deploy
./aws-provision.sh
```

Crea (etiquetando todo `Project=coco` y reutilizando lo existente):

1. **Subnet pública** `10.0.0.0/25` + **Internet Gateway** + **route table**
   (`0.0.0.0/0 → igw`).
2. **Security group**: SSH (22) solo desde **tu IP** (detectada vía
   `checkip.amazonaws.com`), HTTP (80) y HTTPS (443) públicos.
3. **Bucket S3** `coco-consulting-prod-<account-id>` con **block public access**
   y **SSE-S3 (AES256)**.
4. **IAM role** `coco-ec2-role` + **instance profile** `coco-ec2-profile` con
   permisos S3 mínimos (`PutObject/GetObject/DeleteObject` sobre `bucket/*` y
   `ListBucket` sobre el bucket).
5. **Key pair** `coco-deploy` → guarda `coco-deploy.pem` local con `chmod 400`.
6. **Instancia** `t4g.small` (AL2023 arm64, 30 GB gp3) con
   **IMDSv2 obligatorio y hop-limit 2** (para que el contenedor del backend
   pueda asumir el instance role).
7. **Elastic IP** asociada.

Al terminar imprime IP/DNS público, el comando `ssh`, el `scp` opcional, el
bucket+región a introducir en el install, y un recordatorio de **costos**.

> [!NOTE]
> Variables overridables: `VPC_ID`, `REGION`, `INSTANCE_TYPE`. Ej.:
> `INSTANCE_TYPE=t4g.medium ./aws-provision.sh`.

---

## 4. Paso 2 — Instalar el stack en la EC2 (`install.sh`)

Conéctate por SSH (usa el comando que imprimió el paso 1):

```sh
ssh -i coco-deploy.pem ec2-user@ec2-XX-XX-XX-XX.compute-1.amazonaws.com
```

Dentro de la instancia, descarga y ejecuta `install.sh` (auto-clona los repos):

```sh
curl -fsSL https://raw.githubusercontent.com/coconsulting2/cocowiki/main/deploy/install.sh -o install.sh
bash install.sh
```

`install.sh` hace, en orden:

1. Instala **git, docker y el plugin compose** (dnf en AL2023 / apt en Ubuntu;
   binario arm64 para AL2023). Habilita docker y agrega tu usuario al grupo.
2. Crea un **swapfile de 4 GB** si no hay swap (evita OOM en `astro build`).
3. Clona/actualiza los **tres repos** como hermanos en `/opt/coco/`
   (`COCO_HOME` configurable): `cocowiki`, `TC3005B.501-Backend`,
   `TC3005B.501-Frontend`.
4. Genera `.env` **interactivo** (si no existe) — ver los prompts abajo.
5. Decide el perfil de Postgres (local vs externo).
6. `docker compose build` + `up -d`.
7. Espera health, imprime estado y la URL final.

### 4.1 Prompts interactivos del `.env`

| Prompt | Default | Qué hace |
|--------|---------|----------|
| DB host | `postgres` | `postgres`/`localhost`/vacío → contenedor local (perfil `localdb`); otro host → BD externa. |
| DB port / nombre / usuario | `5432` / `coco` / `coco` | Partes de la conexión. |
| DB password | — (oculto) | Se **URL-encodea** al ensamblar `DATABASE_URL`. |
| Host público | DNS de EC2 (auto vía IMDSv2) | Deriva `PUBLIC_API_BASE_URL=https://<host>/api` y `CORS_ORIGIN=https://<host>`. |
| `AWS_REGION` | `us-east-1` | Región del bucket. |
| `AWS_S3_BUCKET` | — (requerido) | El bucket del paso 1. |
| `AES_SECRET_KEY` | autogenera (32 chars) | Si lo dejas vacío usa `openssl rand`. |
| `JWT_SECRET` | autogenera | Igual, `openssl rand`. |
| ¿Sembrar demo? | `N` | Setea `SEED_DUMMY_DATA`. |

> [!IMPORTANT]
> Deja `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` **en blanco** en EC2: el
> instance role provee las credenciales automáticamente. Solo se usan para
> correr el stack fuera de EC2.

> [!TIP]
> Re-ejecutar `bash install.sh` hace `git pull` + rebuild + `up -d` conservando
> el `.env` existente. Para regenerar el `.env`, bórralo
> (`/opt/coco/cocowiki/deploy/.env`) y vuelve a correr.

---

## 5. Cómo fluyen los archivos a S3

El backend usa el SDK de AWS apuntando a `AWS_S3_BUCKET` en `AWS_REGION`. Al
correr en EC2, el SDK obtiene credenciales temporales del **IAM instance role**
vía IMDSv2 — por eso el script de provisión fija `HttpPutResponseHopLimit=2`
(hop extra para que el contenedor Docker, no solo el host, alcance el endpoint
de metadatos). No hay llaves estáticas que rotar.

Cargas y descargas de comprobantes/archivos pasan por el backend
(`/api/files/...`), que lee/escribe objetos en el bucket privado. El bucket
tiene **block public access** y **SSE-S3**, por lo que los objetos no son
accesibles públicamente.

---

## 6. TLS válido con un dominio real

Por defecto Caddy sirve un **certificado auto-firmado** (el navegador pide
aceptar la advertencia). Para TLS válido con Let's Encrypt:

1. Apunta el registro **A/AAAA** de tu dominio a la **Elastic IP** de la
   instancia.
2. En `/opt/coco/cocowiki/deploy/.env` define:
   ```
   SITE_ADDRESS=tudominio.com
   ACME_EMAIL=tu@correo.com
   PUBLIC_HOST=tudominio.com
   PUBLIC_API_BASE_URL=https://tudominio.com/api
   CORS_ORIGIN=https://tudominio.com
   ```
3. En `deploy/Caddyfile`, **comenta o borra** la línea `tls internal` (para que
   Caddy use ACME automático).
4. Re-ejecuta `bash install.sh` (rebuild para reinyectar `PUBLIC_API_BASE_URL`
   en el bundle del navegador). Caddy emitirá y renovará el certificado solo.

> [!NOTE]
> `PUBLIC_API_BASE_URL` y `PUBLIC_IS_DEV` se **inyectan en el bundle del
> navegador en tiempo de build**. Cambiar el host requiere **rebuild** del
> frontend, no solo reiniciar.

---

## 7. Control de costos

| Acción | Comando |
|--------|---------|
| **Pausar** (deja de cobrar cómputo) | `aws ec2 stop-instances --instance-ids <id> --region us-east-1` |
| **Reanudar** | `aws ec2 start-instances --instance-ids <id> --region us-east-1` |
| **Terminar** instancia | `aws ec2 terminate-instances --instance-ids <id> --region us-east-1` |
| **Liberar** Elastic IP | `aws ec2 release-address --allocation-id <alloc> --region us-east-1` |

`t4g.small` + EBS + EIP ≈ **\$12–15/mes** mientras corre. Presupuesto del
proyecto: **\$56**. El bucket S3 y los recursos IAM persisten tras terminar la
instancia; bórralos manualmente si haces limpieza total.

---

## 8. Troubleshooting

| Problema | Posible causa / solución |
|----------|---------------------------|
| Navegador advierte "conexión no privada" | Esperado con cert auto-firmado. Acéptalo (click-through) o configura un dominio real (sección 6). |
| Frontend carga pero el login falla / CORS | Revisa que `PUBLIC_API_BASE_URL` apunte al host público con `/api` y `CORS_ORIGIN` al origen `https://<host>`. Cambiar el host requiere **rebuild** del frontend. |
| Build OOM / instancia se cuelga | Verifica el swap: `swapon --show`. `install.sh` crea 4 GB; en `t4g.small` (2 GB RAM) es necesario. |
| `502`/`503` desde Caddy en `/api/*` | El backend aún no está sano. `cd /opt/coco/cocowiki/deploy && sudo docker compose -f docker-compose.prod.yml logs -f backend`. |
| Errores de S3 / `AccessDenied` | Confirma `IMDSv2` con hop-limit 2 (lo fija el provision) y que el instance profile `coco-ec2-profile` esté adjunto. Revisa `AWS_S3_BUCKET`/`AWS_REGION` en `.env`. |
| Migraciones no corren | El backend corre `prisma db push` cuando `RUN_MIGRATIONS=true` (ya está en el compose). Revisa `DATABASE_URL` y logs del backend. |
| Postgres local no levanta | Asegúrate de que `POSTGRES_PASSWORD` esté seteado; el perfil `localdb` solo se activa si el host es `postgres`/`localhost`. |
| Ver logs de todo | `cd /opt/coco/cocowiki/deploy && sudo docker compose -f docker-compose.prod.yml logs -f` |

---

## 9. Enlaces relacionados

- [Setup con Docker (desarrollo)](setup-docker.md)
- [Setup Backend](setup-backend.md) · [Setup Frontend](setup-frontend.md)
- Archivos de despliegue: `cocowiki/deploy/` (`aws-provision.sh`, `install.sh`,
  `docker-compose.prod.yml`, `Caddyfile`, `.env.example`).
