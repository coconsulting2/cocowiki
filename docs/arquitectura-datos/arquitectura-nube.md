# Arquitectura en la nube (AWS)

| Metadato | Valor |
|----------|--------|
| **Versión** | 1.0.0 |
| **Última actualización** | 2026-06-07 |
| **Alcance** | Despliegue productivo de coco en AWS — lo que levanta el auto-setup vs. la ruta recomendada a producción. |
| **Runbook** | [Despliegue en AWS](getting-started/deploy-aws.md) |
| **Documento padre** | [Documento de Arquitectura](arquitectura-datos/documento-arquitectura.md) · [Diagramas C4](arquitectura-datos/diagramas-c4.md) |

> [!IMPORTANT]
> El despliegue actual es **un solo EC2** con todo co-locado. Es la **decisión
> deliberada** para el presupuesto escolar de **~\$56 USD**: minimiza costo a
> cambio de no tener alta disponibilidad. La arquitectura recomendada de la
> [sección 2](#2-arquitectura-recomendada-producción) es la ruta para llevar
> este mismo sistema a producción real con redundancia y escalado.

---

## 1. Arquitectura actual — "lo que levanta el auto-setup"

Una sola instancia **EC2 t4g.small (ARM, Amazon Linux 2023)** en **una sola
Availability Zone**, dentro de la VPC existente. Docker Compose corre Caddy
(TLS), frontend (Astro SSR), backend (Express) y, opcionalmente, Postgres
co-locado. Los archivos van a un **bucket S3 privado**; el backend accede a S3
con un **IAM instance role** (sin llaves estáticas). Una **Elastic IP** fija la
dirección pública.

![Arquitectura actual — un solo EC2 (auto-setup)](./images/arquitectura-actual.svg)

### Características y compromisos

| Aspecto | Cómo está hoy |
|---------|---------------|
| **Cómputo** | 1 contenedor por servicio en 1 EC2. Si la instancia o la AZ caen, **el sistema cae**. |
| **Base de datos** | Postgres en contenedor co-locado (vol. `pgdata` en el EBS). Sin réplica ni failover gestionado. |
| **TLS** | Caddy con certificado **auto-firmado** por defecto (advertencia en el navegador); ACME automático si se configura un dominio. |
| **Secretos** | En `deploy/.env` (chmod 600) en el disco de la instancia; autogenerados con `openssl rand`. |
| **Almacenamiento** | S3 privado (SSE-S3, block public access). **Esto sí es gestionado y durable** (multi-AZ por defecto en S3). |
| **Acceso a S3** | IAM instance role + IMDSv2 hop-limit 2 — sin llaves estáticas. |
| **Costo** | ≈ **\$12–15/mes** corriendo (t4g.small + EBS + EIP). |

### Specs concretas de este despliegue

| Recurso | Valor usado |
|---------|-------------|
| **Región / AZ** | us-east-1 · **1 sola AZ** (us-east-1a) |
| **VPC / subred** | `vpc-0f7bd8ada126a095b` (10.0.0.0/24) · 1 subnet pública /25 + IGW + route table |
| **Instancia** | **EC2 `t4g.small`** (ARM Graviton, 2 vCPU, 2 GiB RAM) |
| **AMI** | Amazon Linux 2023 **arm64** |
| **Disco** | 30 GB **gp3** + swapfile de 4 GB (para los builds en 2 GiB de RAM) |
| **Red pública** | **Elastic IP** + DNS público de EC2 (sin dominio propio / Route 53 todavía) |
| **Metadata** | IMDSv2 obligatorio, hop-limit 2 (para que el contenedor use el rol IAM) |
| **Contenedores** | Docker Compose: Caddy `:443` · frontend Astro SSR `:4321` · backend Express `:3000` · Postgres 16 (perfil `localdb`) |
| **TLS** | Caddy **auto-firmado** por defecto (Let's Encrypt si se apunta un dominio) |
| **Almacenamiento** | Bucket S3 privado (SSE-S3, block public access) |
| **IAM** | `coco-ec2-role` (instance profile) con permisos S3 mínimos |
| **Security Group** | 22 desde la IP del admin · 80/443 públicos |
| **Secretos** | `deploy/.env` (chmod 600), autogenerados con `openssl rand` |

> **Por qué un solo EC2 (y qué falta).** Con el presupuesto escolar de **~\$56**,
> un stack productivo completo (ver §2: ALB + cómputo redundante + RDS Multi-AZ +
> CloudFront/WAF + Route 53 + Secrets Manager + CloudWatch) cuesta de más. Por eso
> hoy corre **todo co-locado en un `t4g.small`**. Lo que **conscientemente queda
> pendiente** frente a producción: alta disponibilidad multi-AZ, BD gestionada con
> failover, **DNS propio (Route 53) + TLS válido (ACM)**, **WAF/seguridad
> perimetral**, subnets privadas y secretos gestionados. La §2 es la ruta de
> migración cuando el presupuesto lo permita.

---

## 2. Arquitectura recomendada (producción)

Para producción real se distribuye en **dos o más Availability Zones**, se separa
el cómputo de los datos, se añade una **capa de borde con DNS y seguridad** y se
delega la gestión de TLS, secretos y BD a servicios administrados de AWS.

![Arquitectura recomendada — Multi-AZ, segura (producción)](./images/arquitectura-recomendada.svg)

**Capa de borde (DNS + seguridad):** **Amazon Route 53** resuelve el dominio
propio (con health checks); **Amazon CloudFront** entrega el contenido en el edge
con **TLS de ACM**; **AWS WAF** filtra tráfico malicioso a nivel L7 antes de
llegar al origen.

**Red y cómputo:** un **Application Load Balancer** reparte el tráfico entre
**2 AZ**. Las apps corren en **subnets privadas** (sin IP pública) como **ECS
Fargate** (serverless) o un **EC2 Auto Scaling Group**; ambos detrás del ALB. La
elección depende de si se quiere cero gestión de servidores (Fargate) o control
fino del host (ASG).

**Datos y seguridad:** **Amazon RDS PostgreSQL Multi-AZ** (primary + standby con
failover automático, cifrado en reposo) en subnets privadas de BD; **S3** privado
servido vía CloudFront (OAC); **AWS Secrets Manager** para secretos con rotación;
**roles IAM por tarea** (least-privilege, sin llaves estáticas); **Security
Groups por capa** (ALB → App → RDS); y **CloudWatch** para logs, métricas y alarmas.

---

## 3. Comparativa: actual vs. recomendada

| Dimensión | Actual (auto-setup) | Recomendada (producción) |
|-----------|---------------------|--------------------------|
| **Alta disponibilidad** | 1 EC2 en 1 AZ — punto único de falla. | 2+ AZ; ALB redirige tráfico ante caída de una AZ [1]. |
| **Escalado** | Vertical manual (cambiar `INSTANCE_TYPE`). | Horizontal automático: ASG balancea entre AZ [2] o Fargate por demanda [3]. |
| **BD gestionada** | Postgres en contenedor co-locado, sin failover. | RDS PostgreSQL Multi-AZ con standby síncrono y failover automático [4]. |
| **DNS** | DNS público de EC2 (sin dominio propio). | **Amazon Route 53**: dominio propio + health checks. |
| **TLS** | Caddy auto-firmado por defecto (warning) / ACME con dominio [9]. | Certificado público de ACM en el listener HTTPS del ALB [5]. |
| **Seguridad perimetral** | Solo Security Group (puertos). | **AWS WAF** (reglas L7) + CloudFront delante del origen. |
| **Red** | 1 subnet pública; la instancia tiene IP pública. | Subnets **privadas** para app y BD (sin IP pública); SG por capa (ALB→App→RDS). |
| **Secretos** | En `.env` en disco (chmod 600), autogenerados. | AWS Secrets Manager: cifrado en reposo + rotación [6]; sin secretos hard-codeados [10]. |
| **Almacenamiento** | S3 privado (SSE-S3, block public access) [8]. | Igual + versioning; servido vía CloudFront con OAC para contenido privado [7]. |
| **Acceso a AWS** | IAM instance role (sin llaves estáticas) [10]. | Igual (roles por tarea/instancia, least-privilege) [10]. |
| **Observabilidad** | `docker compose logs` en la instancia. | CloudWatch centralizado (logs, métricas, alarmas). |
| **Costo aprox.** | **\$12–15/mes** (t4g.small + EBS + EIP). | **\$120–300+/mes** (ALB + 2× cómputo + RDS Multi-AZ + CloudWatch). |
| **Complejidad** | Baja: 4 scripts, un `docker compose`. | Alta: IaC (CloudFormation/Terraform), red multi-AZ, pipelines. |

---

## 4. Por qué — justificación con fuentes

Las decisiones de la arquitectura recomendada se sustentan en la documentación
oficial de AWS (y de Caddy para el caso TLS). Cada URL fue **verificada** (200
OK) al redactar esta página.

- **Multi-AZ para alta disponibilidad.** El AWS Well-Architected Framework
  (pilar de Confiabilidad) recomienda desplegar y operar **todas las cargas
  productivas en al menos dos Availability Zones** de una región; el nivel de
  riesgo de no hacerlo es "Alto". Cada AZ tiene infraestructura física
  independiente (energía, red), por lo que una falla queda contenida a esa
  zona [1].

- **RDS PostgreSQL Multi-AZ en vez de Postgres en contenedor.** Un despliegue
  Multi-AZ mantiene una réplica standby síncrona en otra AZ y hace **failover
  automático** sin intervención manual, eliminando el punto único de falla de
  la BD del auto-setup [4]. (El Well-Architected explícitamente nota que con RDS
  hay que **habilitar** la replicación Multi-AZ — no viene por defecto [1].)

- **ALB + Auto Scaling / Fargate para escalado.** Un EC2 Auto Scaling Group
  distribuye instancias uniformemente entre AZ y rebalancea cuando una AZ se
  recupera, dando alta disponibilidad y tolerancia a fallos [2]. Alternativa
  serverless: **AWS Fargate** corre contenedores sin provisionar ni escalar
  servidores, con aislamiento por tarea [3]. En ambos casos se coloca un
  **Application Load Balancer** al frente para repartir el tráfico HTTP/HTTPS.

- **TLS gestionado con ACM en el ALB.** Para un listener HTTPS del ALB se
  despliega un certificado SSL/TLS; ACM se integra con el balanceador y se
  selecciona el certificado directamente en el listener [5]. Esto reemplaza el
  certificado **auto-firmado** que Caddy usa por defecto en el auto-setup
  (Caddy es la opción válida y de cero-config para el modelo de un solo host:
  emite y renueva certificados automáticamente, y para sitios sin dominio
  genera su propia CA interna) [9].

- **Secretos en Secrets Manager.** Secrets Manager gestiona, recupera y **rota**
  credenciales, tokens y API keys, y permite eliminar credenciales
  hard-codeadas del código/disco mediante una llamada en runtime [6]. Es la
  evolución natural del `.env` en disco del auto-setup.

- **Roles IAM en vez de llaves estáticas.** AWS recomienda usar un rol IAM para
  gestionar **credenciales temporales** de aplicaciones en EC2: el instance
  profile entrega credenciales de corta duración que se rotan automáticamente,
  sin distribuir llaves de largo plazo [10]. El auto-setup **ya** sigue esta
  práctica (instance role + IMDSv2); la recomendada la mantiene (roles por
  tarea/instancia con least-privilege).

- **S3 + CloudFront para entrega de archivos.** El bucket privado con SSE-S3 y
  block public access ya cumple las buenas prácticas de seguridad de S3
  (cifrado en reposo, no público, least-privilege) [8]. Para servir contenido a
  escala se antepone CloudFront usando **Origin Access Control (OAC)**, que
  manda peticiones autenticadas al origen S3 y evita el acceso directo al
  bucket [7].

- **Single-EC2 como elección consciente para el presupuesto.** La arquitectura
  recomendada (ALB + cómputo redundante + RDS Multi-AZ + CloudWatch) supera con
  creces el presupuesto de **~\$56** del proyecto. Por eso el auto-setup opta
  por **un solo EC2 con todo co-locado**: es lo correcto para el alcance
  escolar, y esta página documenta la ruta de migración cuando el presupuesto
  lo permita.

### Fuentes

Todas verificadas el 2026-06-07 (cada URL resuelve correctamente).

1. AWS Well-Architected Framework — Reliability Pillar, *REL10-BP01 Deploy the workload to multiple locations* — <https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_fault_isolation_multiaz_region_system.html>
2. Amazon EC2 Auto Scaling — *Auto Scaling benefits for application architecture* (distribución entre AZ) — <https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html>
3. Amazon ECS — *Architect for AWS Fargate for Amazon ECS* — <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html>
4. Amazon RDS — *Configuring and managing a Multi-AZ deployment for Amazon RDS* — <https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html>
5. Elastic Load Balancing — *Create an HTTPS listener for your Application Load Balancer* (certificado ACM) — <https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html>
6. AWS Secrets Manager — *What is AWS Secrets Manager?* — <https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html>
7. Amazon CloudFront — *Restrict access to an Amazon S3 origin* (Origin Access Control) — <https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html>
8. Amazon S3 — *Security best practices for Amazon S3* (block public access, cifrado, least-privilege) — <https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html>
9. Caddy — *Automatic HTTPS* — <https://caddyserver.com/docs/automatic-https>
10. AWS IAM — *Use an IAM role to grant permissions to applications running on Amazon EC2 instances* — <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html>

---

## 5. Referencias cruzadas

- [Despliegue en AWS](getting-started/deploy-aws.md) — runbook del auto-setup (scripts, variables, seeding, CI/CD).
- [Diagramas C4](arquitectura-datos/diagramas-c4.md) — Context/Container/Component del sistema.
- [Documento de Arquitectura](arquitectura-datos/documento-arquitectura.md) — RNF y continuidad.
- [Multi-tenancy](arquitectura-datos/multi-tenancy.md) — aislamiento por organización (RLS Postgres).
