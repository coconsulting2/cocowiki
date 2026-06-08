#!/usr/bin/env bash
#
# aws-provision.sh — provisiona la infraestructura AWS para el stack coco.
#
# Corre en tu Mac con el AWS CLI v2 configurado (`aws configure`). Región
# us-east-1. Crea (de forma IDEMPOTENTE) en el VPC existente:
#   - Subnet pública + Internet Gateway + route table
#   - Security group (22 desde tu IP; 80/443 públicos)
#   - Bucket S3 privado con SSE-S3 y block public access
#   - IAM role + instance profile (acceso S3 least-priv vía instance role)
#   - Key pair coco-deploy (.pem local, chmod 400)
#   - Instancia t4g.small (AL2023 arm64) con IMDSv2 hop-limit 2
#   - Elastic IP asociada
#
# Todo se etiqueta Project=coco y se busca por tag/nombre antes de crear.
#
# Uso:
#   ./aws-provision.sh
# Variables overridables:
#   VPC_ID, REGION, INSTANCE_TYPE

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Vars
# ──────────────────────────────────────────────────────────────────────────
REGION="${REGION:-us-east-1}"
VPC_ID="${VPC_ID:-vpc-0f7bd8ada126a095b}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t4g.small}"
PROJECT="coco"
SUBNET_CIDR="10.0.0.0/25"
KEY_NAME="coco-deploy"
KEY_FILE="${KEY_NAME}.pem"
SG_NAME="coco-sg"
ROLE_NAME="coco-ec2-role"
PROFILE_NAME="coco-ec2-profile"
POLICY_NAME="coco-s3-access"
ROOT_VOLUME_GB="30"
AMI_SSM_PARAM="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"

AWS=(aws --region "$REGION" --output text)

log()  { printf '\033[1;34m[aws]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[aws]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[aws]\033[0m %s\n' "$*" >&2; }

# Filtro de tag estándar.
tag_filter() { echo "Name=tag:Project,Values=${PROJECT}"; }

# ──────────────────────────────────────────────────────────────────────────
# 0. Cuenta + verificación
# ──────────────────────────────────────────────────────────────────────────
ACCOUNT_ID="$("${AWS[@]}" sts get-caller-identity --query Account)"
log "Cuenta AWS: ${ACCOUNT_ID} · región: ${REGION} · VPC: ${VPC_ID}"

# VPCs no-default suelen traer DNS hostnames deshabilitado → las instancias no
# obtienen PublicDnsName. Habilitarlo (idempotente) para tener nombre DNS público.
"${AWS[@]}" ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support >/dev/null 2>&1 || true
"${AWS[@]}" ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames >/dev/null 2>&1 || true

# ──────────────────────────────────────────────────────────────────────────
# 1. Subnet pública
# ──────────────────────────────────────────────────────────────────────────
AZ="$("${AWS[@]}" ec2 describe-availability-zones \
	--query 'AvailabilityZones[0].ZoneName')"

SUBNET_ID="$("${AWS[@]}" ec2 describe-subnets \
	--filters "$(tag_filter)" "Name=vpc-id,Values=${VPC_ID}" \
	--query 'Subnets[0].SubnetId')"

if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
	log "Creando subnet pública ${SUBNET_CIDR} en ${AZ}..."
	SUBNET_ID="$("${AWS[@]}" ec2 create-subnet \
		--vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR" \
		--availability-zone "$AZ" \
		--tag-specifications "ResourceType=subnet,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=coco-public}]" \
		--query 'Subnet.SubnetId')"
	"${AWS[@]}" ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch
else
	log "Reutilizando subnet ${SUBNET_ID}."
fi

# ──────────────────────────────────────────────────────────────────────────
# 2. Internet Gateway + route table
# ──────────────────────────────────────────────────────────────────────────
IGW_ID="$("${AWS[@]}" ec2 describe-internet-gateways \
	--filters "$(tag_filter)" "Name=attachment.vpc-id,Values=${VPC_ID}" \
	--query 'InternetGateways[0].InternetGatewayId')"

if [ "$IGW_ID" = "None" ] || [ -z "$IGW_ID" ]; then
	log "Creando Internet Gateway..."
	IGW_ID="$("${AWS[@]}" ec2 create-internet-gateway \
		--tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=coco-igw}]" \
		--query 'InternetGateway.InternetGatewayId')"
	"${AWS[@]}" ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
else
	log "Reutilizando IGW ${IGW_ID}."
fi

RTB_ID="$("${AWS[@]}" ec2 describe-route-tables \
	--filters "$(tag_filter)" "Name=vpc-id,Values=${VPC_ID}" \
	--query 'RouteTables[0].RouteTableId')"

if [ "$RTB_ID" = "None" ] || [ -z "$RTB_ID" ]; then
	log "Creando route table..."
	RTB_ID="$("${AWS[@]}" ec2 create-route-table --vpc-id "$VPC_ID" \
		--tag-specifications "ResourceType=route-table,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=coco-rtb}]" \
		--query 'RouteTable.RouteTableId')"
else
	log "Reutilizando route table ${RTB_ID}."
fi

# Ruta default → IGW (idempotente: create-route falla si ya existe).
"${AWS[@]}" ec2 create-route --route-table-id "$RTB_ID" \
	--destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null 2>&1 \
	|| log "Ruta default ya existe."

# Asociar subnet a la route table (idempotente).
if ! "${AWS[@]}" ec2 describe-route-tables --route-table-ids "$RTB_ID" \
	--query 'RouteTables[0].Associations[].SubnetId' | tr '\t' '\n' | grep -qx "$SUBNET_ID"; then
	"${AWS[@]}" ec2 associate-route-table --route-table-id "$RTB_ID" --subnet-id "$SUBNET_ID" >/dev/null
	log "Subnet asociada a la route table."
else
	log "Subnet ya asociada a la route table."
fi

# ──────────────────────────────────────────────────────────────────────────
# 3. Security group
# ──────────────────────────────────────────────────────────────────────────
MY_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
log "Tu IP pública detectada: ${MY_IP}/32 (SSH se limita a ella)."

SG_ID="$("${AWS[@]}" ec2 describe-security-groups \
	--filters "$(tag_filter)" "Name=vpc-id,Values=${VPC_ID}" "Name=group-name,Values=${SG_NAME}" \
	--query 'SecurityGroups[0].GroupId')"

if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
	log "Creando security group ${SG_NAME}..."
	SG_ID="$("${AWS[@]}" ec2 create-security-group \
		--group-name "$SG_NAME" --description "coco stack" --vpc-id "$VPC_ID" \
		--tag-specifications "ResourceType=security-group,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=${SG_NAME}}]" \
		--query 'GroupId')"
else
	log "Reutilizando security group ${SG_ID}."
fi

# Reglas de ingreso (idempotentes: ignoran error si la regla ya existe).
"${AWS[@]}" ec2 authorize-security-group-ingress --group-id "$SG_ID" \
	--protocol tcp --port 22 --cidr "${MY_IP}/32" >/dev/null 2>&1 || log "Regla SSH ya presente."
"${AWS[@]}" ec2 authorize-security-group-ingress --group-id "$SG_ID" \
	--protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1 || log "Regla 80 ya presente."
"${AWS[@]}" ec2 authorize-security-group-ingress --group-id "$SG_ID" \
	--protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null 2>&1 || log "Regla 443 ya presente."

# ──────────────────────────────────────────────────────────────────────────
# 4. Bucket S3
# ──────────────────────────────────────────────────────────────────────────
BUCKET="coco-consulting-prod-${ACCOUNT_ID}"
if "${AWS[@]}" s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
	log "Reutilizando bucket S3 ${BUCKET}."
else
	log "Creando bucket S3 ${BUCKET}..."
	# us-east-1 NO lleva LocationConstraint.
	"${AWS[@]}" s3api create-bucket --bucket "$BUCKET" >/dev/null
	"${AWS[@]}" s3api put-bucket-tagging --bucket "$BUCKET" \
		--tagging "TagSet=[{Key=Project,Value=${PROJECT}}]"
fi

log "Aplicando block public access + SSE (AES256)..."
"${AWS[@]}" s3api put-public-access-block --bucket "$BUCKET" \
	--public-access-block-configuration \
	BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
"${AWS[@]}" s3api put-bucket-encryption --bucket "$BUCKET" \
	--server-side-encryption-configuration \
	'{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' >/dev/null

# ──────────────────────────────────────────────────────────────────────────
# 5. IAM role + instance profile
# ──────────────────────────────────────────────────────────────────────────
TRUST_DOC='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
S3_POLICY="$(cat <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::${BUCKET}/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${BUCKET}"
    }
  ]
}
JSON
)"

if "${AWS[@]}" iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
	log "Reutilizando IAM role ${ROLE_NAME}."
else
	log "Creando IAM role ${ROLE_NAME}..."
	"${AWS[@]}" iam create-role --role-name "$ROLE_NAME" \
		--assume-role-policy-document "$TRUST_DOC" \
		--tags "Key=Project,Value=${PROJECT}" >/dev/null
fi

log "Actualizando inline policy de S3 (least-priv)..."
"${AWS[@]}" iam put-role-policy --role-name "$ROLE_NAME" \
	--policy-name "$POLICY_NAME" --policy-document "$S3_POLICY" >/dev/null

if "${AWS[@]}" iam get-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1; then
	log "Reutilizando instance profile ${PROFILE_NAME}."
else
	log "Creando instance profile ${PROFILE_NAME}..."
	"${AWS[@]}" iam create-instance-profile --instance-profile-name "$PROFILE_NAME" \
		--tags "Key=Project,Value=${PROJECT}" >/dev/null
fi

# Agregar el role al profile (idempotente).
if ! "${AWS[@]}" iam get-instance-profile --instance-profile-name "$PROFILE_NAME" \
	--query 'InstanceProfile.Roles[].RoleName' | tr '\t' '\n' | grep -qx "$ROLE_NAME"; then
	"${AWS[@]}" iam add-role-to-instance-profile \
		--instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME" >/dev/null
	log "Role agregado al instance profile (propagación IAM ~10s)."
	sleep 10
fi

# ──────────────────────────────────────────────────────────────────────────
# 6. Key pair
# ──────────────────────────────────────────────────────────────────────────
if "${AWS[@]}" ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
	log "Key pair ${KEY_NAME} ya existe (no se re-descarga la clave privada)."
	if [ ! -f "$KEY_FILE" ]; then
		warn "No se encontró ${KEY_FILE} localmente. Si la perdiste, borra el key pair en AWS y re-ejecuta."
	fi
else
	log "Creando key pair ${KEY_NAME} → ${KEY_FILE}..."
	"${AWS[@]}" ec2 create-key-pair --key-name "$KEY_NAME" \
		--tag-specifications "ResourceType=key-pair,Tags=[{Key=Project,Value=${PROJECT}}]" \
		--query 'KeyMaterial' > "$KEY_FILE"
	chmod 400 "$KEY_FILE"
fi

# ──────────────────────────────────────────────────────────────────────────
# 7. AMI AL2023 arm64
# ──────────────────────────────────────────────────────────────────────────
AMI_ID="$("${AWS[@]}" ssm get-parameters --names "$AMI_SSM_PARAM" \
	--query 'Parameters[0].Value')"
log "AMI AL2023 arm64: ${AMI_ID}"

# ──────────────────────────────────────────────────────────────────────────
# 8. Instancia EC2
# ──────────────────────────────────────────────────────────────────────────
INSTANCE_ID="$("${AWS[@]}" ec2 describe-instances \
	--filters "$(tag_filter)" "Name=tag:Name,Values=coco-app" \
	"Name=instance-state-name,Values=pending,running,stopping,stopped" \
	--query 'Reservations[0].Instances[0].InstanceId')"

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
	log "Lanzando instancia ${INSTANCE_TYPE}..."
	INSTANCE_ID="$("${AWS[@]}" ec2 run-instances \
		--image-id "$AMI_ID" \
		--instance-type "$INSTANCE_TYPE" \
		--key-name "$KEY_NAME" \
		--subnet-id "$SUBNET_ID" \
		--security-group-ids "$SG_ID" \
		--iam-instance-profile "Name=${PROFILE_NAME}" \
		--metadata-options "HttpTokens=required,HttpPutResponseHopLimit=2,HttpEndpoint=enabled" \
		--block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=${ROOT_VOLUME_GB},VolumeType=gp3,DeleteOnTermination=true}" \
		--tag-specifications "ResourceType=instance,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=coco-app}]" \
		--query 'Instances[0].InstanceId')"
	log "Esperando a que la instancia esté running..."
	"${AWS[@]}" ec2 wait instance-running --instance-ids "$INSTANCE_ID"
else
	log "Reutilizando instancia ${INSTANCE_ID}."
fi

# ──────────────────────────────────────────────────────────────────────────
# 9. Elastic IP
# ──────────────────────────────────────────────────────────────────────────
ALLOC_ID="$("${AWS[@]}" ec2 describe-addresses \
	--filters "$(tag_filter)" \
	--query 'Addresses[0].AllocationId')"

if [ "$ALLOC_ID" = "None" ] || [ -z "$ALLOC_ID" ]; then
	log "Asignando Elastic IP..."
	ALLOC_ID="$("${AWS[@]}" ec2 allocate-address --domain vpc \
		--tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Project,Value=${PROJECT}},{Key=Name,Value=coco-eip}]" \
		--query 'AllocationId')"
fi

# Asociar EIP a la instancia (idempotente).
ASSOC_INSTANCE="$("${AWS[@]}" ec2 describe-addresses --allocation-ids "$ALLOC_ID" \
	--query 'Addresses[0].InstanceId')"
if [ "$ASSOC_INSTANCE" != "$INSTANCE_ID" ]; then
	"${AWS[@]}" ec2 associate-address --allocation-id "$ALLOC_ID" --instance-id "$INSTANCE_ID" >/dev/null
	log "Elastic IP asociada a la instancia."
fi

PUBLIC_IP="$("${AWS[@]}" ec2 describe-addresses --allocation-ids "$ALLOC_ID" \
	--query 'Addresses[0].PublicIp')"
PUBLIC_DNS="$("${AWS[@]}" ec2 describe-instances --instance-ids "$INSTANCE_ID" \
	--query 'Reservations[0].Instances[0].PublicDnsName')"

# ──────────────────────────────────────────────────────────────────────────
# 10. Resumen
# ──────────────────────────────────────────────────────────────────────────
cat <<EOF

──────────────────────────────────────────────────────────────────────────
 Infraestructura coco provisionada.

   Instancia:   ${INSTANCE_ID} (${INSTANCE_TYPE})
   IP pública:  ${PUBLIC_IP}
   DNS público: ${PUBLIC_DNS}
   Bucket S3:   ${BUCKET}  (región ${REGION})

 1) Conéctate por SSH:
      ssh -i ${KEY_FILE} ec2-user@${PUBLIC_DNS}

 2) Dentro de la instancia, descarga y corre install.sh (auto-clona cocowiki):
      curl -fsSL https://raw.githubusercontent.com/coconsulting2/cocowiki/main/deploy/install.sh -o install.sh
      bash install.sh

    (Alternativa: copia tu install.sh local con scp)
      scp -i ${KEY_FILE} install.sh ec2-user@${PUBLIC_DNS}:~/

 3) Durante install.sh, cuando pida S3, introduce:
      AWS_REGION    = ${REGION}
      AWS_S3_BUCKET = ${BUCKET}
    Deja AWS_ACCESS_KEY_ID/SECRET en blanco: el instance role los provee.

 4) Abre:  https://${PUBLIC_DNS}   (acepta el cert auto-firmado)

 ── Control de costos (presupuesto: \$56) ───────────────────────────────────
   t4g.small + EBS + EIP ≈ \$12–15/mes mientras corre.
   Pausar (deja de cobrar cómputo; EBS+EIP siguen menores):
      aws ec2 stop-instances --instance-ids ${INSTANCE_ID} --region ${REGION}
   Reanudar:
      aws ec2 start-instances --instance-ids ${INSTANCE_ID} --region ${REGION}
   Terminar TODO (revisa antes de borrar datos):
      aws ec2 terminate-instances --instance-ids ${INSTANCE_ID} --region ${REGION}
      aws ec2 release-address --allocation-id ${ALLOC_ID} --region ${REGION}
   (El bucket S3 y los recursos IAM persisten; bórralos manualmente si terminas.)
──────────────────────────────────────────────────────────────────────────
EOF
