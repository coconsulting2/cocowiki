#!/usr/bin/env bash
#
# deploy-all.sh — orquesta TODO el despliegue de coco, de cero a corriendo:
#   1) provisiona la infra en AWS (aws-provision.sh)
#   2) espera SSH y copia install.sh a la instancia
#   3) corre install.sh en la instancia (build + up + seeders)
#
# Corre en tu Mac con el AWS CLI configurado y ssh/scp disponibles.
# Idempotente: aws-provision.sh reutiliza recursos por tag; install.sh re-deploya.
#
# Uso:
#   ./deploy-all.sh [--seed=demo|admin|none] [--force-seed]
#
# Variables de entorno opcionales (se PROPAGAN a install.sh en la instancia):
#   BRANCH_BACKEND, BRANCH_FRONTEND, BRANCH_COCOWIKI  (desplegar una rama/PR)
#   MAIL_USER, MAIL_PASSWORD, MAIL_SMTP_HOST, MAIL_SMTP_PORT,
#   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_MAILTO, BANXICO_API_KEY,
#   DUFFEL_ACCESS_TOKEN, FLIGHT_PROVIDER, DITTA_ADMIN_INITIAL_PASSWORD,
#   AES_SECRET_KEY, JWT_SECRET (vacías => install.sh las autogenera)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SEED_ARGS=()
for a in "$@"; do SEED_ARGS+=("$a"); done

log() { printf '\033[1;35m[deploy-all]\033[0m %s\n' "$*"; }

# 1) Provisionar infra (escribe coco-infra.env).
log "Paso 1/3 — provisionando infraestructura AWS..."
bash "${SCRIPT_DIR}/aws-provision.sh"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/coco-infra.env"
HOST="${PUBLIC_DNS:-$PUBLIC_IP}"
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=20 -o ServerAliveInterval=30 -o ServerAliveCountMax=40 -i "${SCRIPT_DIR}/${KEY_FILE}")

# 2) Esperar SSH.
log "Paso 2/3 — esperando SSH en ${SSH_USER}@${HOST}..."
for i in $(seq 1 30); do
	if ssh "${SSH_OPTS[@]}" "${SSH_USER}@${HOST}" 'echo ok' >/dev/null 2>&1; then
		log "SSH listo."; break
	fi
	sleep 10
done

# 3) Construir el set de variables a exportar en la instancia y correr install.sh.
#    Las integraciones/branches presentes en TU entorno se reenvían al server.
FORWARD_KEYS=(
	BRANCH_BACKEND BRANCH_FRONTEND BRANCH_COCOWIKI
	MAIL_USER MAIL_PASSWORD MAIL_SMTP_HOST MAIL_SMTP_PORT
	VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY VAPID_MAILTO
	BANXICO_API_KEY DUFFEL_ACCESS_TOKEN FLIGHT_PROVIDER
	DITTA_ADMIN_INITIAL_PASSWORD AES_SECRET_KEY JWT_SECRET
)
ENV_PREFIX="AWS_S3_BUCKET=$(printf '%q' "$AWS_S3_BUCKET") AWS_REGION=$(printf '%q' "$AWS_REGION")"
for k in "${FORWARD_KEYS[@]}"; do
	if [ -n "${!k:-}" ]; then ENV_PREFIX="${ENV_PREFIX} ${k}=$(printf '%q' "${!k}")"; fi
done

log "Paso 3/3 — instalando en la instancia (esto tarda varios minutos)..."
# Pre-responde el prompt de S3 bucket con el del provisioning (host se auto-detecta;
# DB local por defecto con un password generado aquí para el contenedor co-locado).
DB_PASS="$(openssl rand -hex 24)"
# Respuestas a configure_env (no interactivo): db host/port/name/user/pass, host público (vacío=auto), region, bucket
ANSWERS=$(printf '%s\n' '' '' '' '' "$DB_PASS" '' "$AWS_REGION" "$AWS_S3_BUCKET")

ssh "${SSH_OPTS[@]}" "${SSH_USER}@${HOST}" \
	"curl -fsSL https://raw.githubusercontent.com/coconsulting2/cocowiki/${BRANCH_COCOWIKI:-main}/deploy/install.sh -o install.sh && printf '%s' $(printf '%q' "$ANSWERS") | ${ENV_PREFIX} bash install.sh ${SEED_ARGS[*]}"

log "Listo. Abre: https://${HOST}  (acepta el cert auto-firmado)"
log "SSH:  ssh -i ${SCRIPT_DIR}/${KEY_FILE} ${SSH_USER}@${HOST}"
