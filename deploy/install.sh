#!/usr/bin/env bash
#
# install.sh — instala y arranca el stack coco en una instancia EC2.
#
# Idempotente: re-ejecutar = git pull de los repos + rebuild + up -d.
# Pensado para Amazon Linux 2023 (arm64) o Ubuntu. Ejecuta como ec2-user/ubuntu
# (con sudo disponible). No requiere autenticación: los repos son públicos.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/coconsulting2/cocowiki/main/deploy/install.sh -o install.sh
#   bash install.sh
#
# Variables de entorno opcionales:
#   COCO_HOME          directorio base (default /opt/coco)
#   BRANCH_COCOWIKI    rama a clonar de cocowiki  (default: rama por defecto/main)
#   BRANCH_BACKEND     rama a clonar del backend  (default: rama por defecto/main)
#   BRANCH_FRONTEND    rama a clonar del frontend (default: rama por defecto/main)
#   (usa las BRANCH_* para desplegar una PR antes de mergear; vacías = main)

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Constantes
# ──────────────────────────────────────────────────────────────────────────
COCO_HOME="${COCO_HOME:-/opt/coco}"
COMPOSE_PLUGIN_VERSION="v2.29.7"
REPO_COCOWIKI="https://github.com/coconsulting2/cocowiki.git"
REPO_BACKEND="https://github.com/coconsulting2/TC3005B.501-Backend.git"
REPO_FRONTEND="https://github.com/coconsulting2/TC3005B.501-Frontend.git"
BRANCH_COCOWIKI="${BRANCH_COCOWIKI:-}"
BRANCH_BACKEND="${BRANCH_BACKEND:-}"
BRANCH_FRONTEND="${BRANCH_FRONTEND:-}"
DEPLOY_DIR="${COCO_HOME}/cocowiki/deploy"
COMPOSE_FILE="docker-compose.prod.yml"

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[install]\033[0m %s\n' "$*" >&2; }

# ──────────────────────────────────────────────────────────────────────────
# 1. Paquetes: git, docker, docker compose plugin
# ──────────────────────────────────────────────────────────────────────────
detect_arch() {
	case "$(uname -m)" in
		aarch64|arm64) echo "aarch64" ;;
		x86_64|amd64)  echo "x86_64"  ;;
		*) err "Arquitectura no soportada: $(uname -m)"; exit 1 ;;
	esac
}

install_compose_plugin() {
	local arch dest url
	arch="$(detect_arch)"
	dest="/usr/local/lib/docker/cli-plugins/docker-compose"
	if docker compose version >/dev/null 2>&1; then
		log "docker compose plugin ya presente."
		return
	fi
	url="https://github.com/docker/compose/releases/download/${COMPOSE_PLUGIN_VERSION}/docker-compose-linux-${arch}"
	log "Instalando docker compose plugin (${COMPOSE_PLUGIN_VERSION}, ${arch})..."
	sudo mkdir -p /usr/local/lib/docker/cli-plugins
	sudo curl -fsSL "$url" -o "$dest"
	sudo chmod +x "$dest"
}

install_packages() {
	if command -v dnf >/dev/null 2>&1; then
		log "Gestor de paquetes: dnf (Amazon Linux 2023 / Fedora)."
		sudo dnf install -y docker git
		install_compose_plugin
	elif command -v apt-get >/dev/null 2>&1; then
		log "Gestor de paquetes: apt-get (Ubuntu/Debian)."
		sudo apt-get update -y
		sudo apt-get install -y ca-certificates curl gnupg git
		# Repo oficial de Docker.
		sudo install -m 0755 -d /etc/apt/keyrings
		if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
				| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
			sudo chmod a+r /etc/apt/keyrings/docker.gpg
		fi
		local codename
		codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
			| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
		sudo apt-get update -y
		if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
			warn "Fallback: instalando docker.io + plugin compose manual."
			sudo apt-get install -y docker.io
			install_compose_plugin
		fi
	else
		err "No se encontró dnf ni apt-get. Instala docker, git y compose manualmente."
		exit 1
	fi
}

enable_docker() {
	sudo systemctl enable --now docker
	# Agregar el usuario actual al grupo docker (re-login para que aplique sin sudo).
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
		log "Agregando '$USER' al grupo docker (puede requerir re-login)."
		sudo usermod -aG docker "$USER" || true
	fi
}

# En esta corrida usamos sudo para compose porque la membresía al grupo docker
# aún no aplica hasta re-login.
dc() {
	sudo docker compose -f "$COMPOSE_FILE" "$@"
}

# ──────────────────────────────────────────────────────────────────────────
# 2. Swap (evita OOM en build de astro / bun install en cajas de 2 GB)
# ──────────────────────────────────────────────────────────────────────────
ensure_swap() {
	if swapon --show 2>/dev/null | grep -q .; then
		log "Swap ya configurado."
		return
	fi
	log "Creando swapfile de 4 GB en /swapfile..."
	sudo fallocate -l 4G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
	if ! grep -q '^/swapfile' /etc/fstab; then
		echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
	fi
}

# ──────────────────────────────────────────────────────────────────────────
# 3. Clonar / actualizar repos
# ──────────────────────────────────────────────────────────────────────────
clone_or_pull() {
	local url="$1" dir="$2" branch="${3:-}"
	if [ -d "$dir/.git" ]; then
		log "Actualizando $(basename "$dir")${branch:+ (rama ${branch})}..."
		if [ -n "$branch" ]; then
			git -C "$dir" fetch --depth 1 origin "$branch"
			git -C "$dir" checkout -B "$branch" FETCH_HEAD
		else
			git -C "$dir" pull --ff-only
		fi
	else
		log "Clonando $(basename "$dir")${branch:+ (rama ${branch})}..."
		if [ -n "$branch" ]; then
			git clone --depth 1 --branch "$branch" "$url" "$dir"
		else
			git clone --depth 1 "$url" "$dir"
		fi
	fi
}

sync_repos() {
	sudo mkdir -p "$COCO_HOME"
	sudo chown "$USER":"$USER" "$COCO_HOME"
	clone_or_pull "$REPO_COCOWIKI"  "${COCO_HOME}/cocowiki"             "$BRANCH_COCOWIKI"
	clone_or_pull "$REPO_BACKEND"   "${COCO_HOME}/TC3005B.501-Backend"  "$BRANCH_BACKEND"
	clone_or_pull "$REPO_FRONTEND"  "${COCO_HOME}/TC3005B.501-Frontend" "$BRANCH_FRONTEND"
}

# ──────────────────────────────────────────────────────────────────────────
# 4. .env interactivo
# ──────────────────────────────────────────────────────────────────────────

# URL-encode minimalista para el password (caracteres reservados comunes).
urlencode() {
	local s="$1" out="" c i
	for (( i=0; i<${#s}; i++ )); do
		c="${s:$i:1}"
		case "$c" in
			[a-zA-Z0-9.~_-]) out+="$c" ;;
			*) out+="$(printf '%%%02X' "'$c")" ;;
		esac
	done
	printf '%s' "$out"
}

# set_env KEY VALUE — actualiza o agrega KEY=VALUE en .env (sin duplicar).
set_env() {
	local key="$1" val="$2" file="${DEPLOY_DIR}/.env" tmp
	tmp="$(mktemp)"
	if grep -qE "^${key}=" "$file" 2>/dev/null; then
		# Reemplaza línea existente preservando el resto.
		while IFS= read -r line || [ -n "$line" ]; do
			if [[ "$line" == "${key}="* ]]; then
				printf '%s=%s\n' "$key" "$val"
			else
				printf '%s\n' "$line"
			fi
		done < "$file" > "$tmp"
		mv "$tmp" "$file"
	else
		rm -f "$tmp"
		printf '%s=%s\n' "$key" "$val" >> "$file"
	fi
}

# Detecta el host público vía IMDSv2 (token primero), con fallback a IPv4.
detect_public_host() {
	local token host
	token="$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
		-H "X-aws-ec2-metadata-token-ttl-seconds: 300" 2>/dev/null || true)"
	if [ -n "$token" ]; then
		host="$(curl -fsS -H "X-aws-ec2-metadata-token: $token" \
			"http://169.254.169.254/latest/meta-data/public-hostname" 2>/dev/null || true)"
		if [ -z "$host" ]; then
			host="$(curl -fsS -H "X-aws-ec2-metadata-token: $token" \
				"http://169.254.169.254/latest/meta-data/public-ipv4" 2>/dev/null || true)"
		fi
	fi
	printf '%s' "$host"
}

configure_env() {
	local file="${DEPLOY_DIR}/.env"
	if [ -f "$file" ]; then
		log ".env ya existe en ${DEPLOY_DIR} — se conservan los valores actuales."
		return
	fi
	log "Generando .env interactivo en ${DEPLOY_DIR}..."
	cp "${DEPLOY_DIR}/.env.example" "$file"

	# --- Base de datos ---
	local db_host db_port db_name db_user db_pass db_pass_enc db_url
	read -rp "DB host [postgres = contenedor local]: " db_host
	db_host="${db_host:-postgres}"
	read -rp "DB port [5432]: " db_port
	db_port="${db_port:-5432}"
	read -rp "DB nombre [coco]: " db_name
	db_name="${db_name:-coco}"
	read -rp "DB usuario [coco]: " db_user
	db_user="${db_user:-coco}"
	read -rsp "DB password: " db_pass; echo
	while [ -z "$db_pass" ]; do
		read -rsp "DB password (no puede estar vacío): " db_pass; echo
	done
	db_pass_enc="$(urlencode "$db_pass")"
	db_url="postgresql://${db_user}:${db_pass_enc}@${db_host}:${db_port}/${db_name}?schema=public"

	set_env POSTGRES_HOST     "$db_host"
	set_env POSTGRES_PORT     "$db_port"
	set_env POSTGRES_DB       "$db_name"
	set_env POSTGRES_USER     "$db_user"
	set_env POSTGRES_PASSWORD "$db_pass"
	set_env DATABASE_URL      "$db_url"

	# --- Host público ---
	local auto_host pub_host
	auto_host="$(detect_public_host)"
	read -rp "Host público [${auto_host:-introduce manualmente}]: " pub_host
	pub_host="${pub_host:-$auto_host}"
	while [ -z "$pub_host" ]; do
		read -rp "Host público (requerido): " pub_host
	done
	set_env PUBLIC_HOST         "$pub_host"
	set_env PUBLIC_API_BASE_URL "https://${pub_host}/api"
	set_env CORS_ORIGIN         "https://${pub_host}"
	set_env PUBLIC_IS_DEV       "false"

	# --- S3 ---
	local aws_region aws_bucket
	read -rp "AWS_REGION [us-east-1]: " aws_region
	aws_region="${aws_region:-us-east-1}"
	read -rp "AWS_S3_BUCKET (requerido): " aws_bucket
	while [ -z "$aws_bucket" ]; do
		read -rp "AWS_S3_BUCKET (requerido): " aws_bucket
	done
	set_env AWS_REGION    "$aws_region"
	set_env AWS_S3_BUCKET "$aws_bucket"

	# --- Secretos ---
	local aes jwt
	read -rp "AES_SECRET_KEY (32 chars; vacío = autogenerar): " aes
	if [ -z "$aes" ]; then
		aes="$(openssl rand -hex 16)"  # 32 chars hex
		log "AES_SECRET_KEY autogenerado (32 chars)."
	fi
	set_env AES_SECRET_KEY "$aes"

	read -rp "JWT_SECRET (vacío = autogenerar): " jwt
	if [ -z "$jwt" ]; then
		jwt="$(openssl rand -base64 48 | tr -d '\n')"
		log "JWT_SECRET autogenerado."
	fi
	set_env JWT_SECRET "$jwt"

	# --- Seed ---
	local seed ans
	read -rp "¿Sembrar datos demo? (y/N): " ans
	case "$ans" in
		[yY]*) seed="true" ;;
		*)     seed="false" ;;
	esac
	set_env SEED_DUMMY_DATA "$seed"

	chmod 600 "$file"
	log ".env generado."
}

# ──────────────────────────────────────────────────────────────────────────
# 5/6. Perfil de Postgres + build + up
# ──────────────────────────────────────────────────────────────────────────
db_uses_localdb() {
	local host
	host="$(grep -E '^POSTGRES_HOST=' "${DEPLOY_DIR}/.env" | head -n1 | cut -d= -f2-)"
	case "${host:-}" in
		postgres|localhost|127.0.0.1|"") return 0 ;;
		*) return 1 ;;
	esac
}

build_and_up() {
	cd "$DEPLOY_DIR"
	local profile_args=()
	local localdb=false
	if db_uses_localdb; then
		log "BD local detectada — activando perfil 'localdb' (Postgres co-locado)."
		profile_args=(--profile localdb)
		localdb=true
	else
		log "BD externa detectada — sin perfil localdb."
	fi
	log "Construyendo imágenes (esto puede tardar varios minutos)..."
	dc "${profile_args[@]}" build
	# Si la BD es co-locada, arráncala y espera a que esté saludable ANTES del
	# backend (su entrypoint corre `prisma db push` al iniciar y fallaría si la
	# BD aún no acepta conexiones).
	if [ "$localdb" = true ]; then
		log "Arrancando Postgres co-locado y esperando a que esté saludable..."
		dc "${profile_args[@]}" up -d --wait postgres || warn "No se pudo confirmar salud de Postgres; el backend reintentará vía restart."
	fi
	log "Levantando el stack..."
	dc "${profile_args[@]}" up -d
}

# ──────────────────────────────────────────────────────────────────────────
# 7. Health + resumen
# ──────────────────────────────────────────────────────────────────────────
wait_health() {
	local i pub_host
	log "Esperando a que el origen responda en https://localhost/ ..."
	for i in $(seq 1 30); do
		if curl -fsSk -o /dev/null "https://localhost/"; then
			log "Origen arriba."
			break
		fi
		sleep 5
	done

	cd "$DEPLOY_DIR"
	dc ps || true

	pub_host="$(grep -E '^PUBLIC_HOST=' "${DEPLOY_DIR}/.env" | head -n1 | cut -d= -f2-)"
	cat <<EOF

──────────────────────────────────────────────────────────────────────────
 Stack coco desplegado.

   URL:  https://${pub_host}

 NOTA TLS: por defecto el certificado es AUTO-FIRMADO (Caddy internal). El
 navegador mostrará una advertencia — acéptala (click-through) para entrar.
 Para TLS válido: define un dominio real en ${DEPLOY_DIR}/.env
   SITE_ADDRESS=tudominio.com
 apunta su DNS a la IP elástica, comenta 'tls internal' en deploy/Caddyfile
 y vuelve a ejecutar este script (Caddy emite Let's Encrypt automáticamente).

 Datos demo: si elegiste sembrar, revisa los seeds del backend para las
 credenciales de prueba (prisma/seed*.js).

 Troubleshooting:
   cd ${DEPLOY_DIR} && sudo docker compose -f ${COMPOSE_FILE} logs -f
──────────────────────────────────────────────────────────────────────────
EOF
}

# ──────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────
main() {
	install_packages
	enable_docker
	ensure_swap
	sync_repos
	configure_env
	build_and_up
	wait_health
}

main "$@"
