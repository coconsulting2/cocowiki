#!/usr/bin/env bash
#
# install.sh — instala y arranca el stack coco en una instancia EC2.
#
# Idempotente: re-ejecutar = git pull de los repos + rebuild + up -d.
# Al final instala un timer systemd (coco-redeploy) que hace CD continuo por
# git-poll: detecta cuando main avanza y reconstruye solo entonces. Sin SSH,
# sin registry, sin credenciales (repos públicos).
# Pensado para Amazon Linux 2023 (arm64) o Ubuntu. Ejecuta como ec2-user/ubuntu
# (con sudo disponible). No requiere autenticación: los repos son públicos.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/coconsulting2/cocowiki/main/deploy/install.sh -o install.sh
#   bash install.sh [--seed=demo|admin|none] [--force-seed]
#
# Flags:
#   --seed=demo   (default) reference + admin + TODOS los seeders demo
#                 (seed.js dev + seed-usability.js + seed.demo.js)
#   --seed=admin  solo reference + admin (sin datos demo/UAT)
#   --seed=none   solo el esquema (sin datos; no habrá admin para login)
#   --force-seed  re-corre los seeders demo aunque el .env ya exista (re-deploy)
#
# Variables de entorno (opcionales) — se escriben al .env si están presentes:
#   COCO_HOME, BRANCH_COCOWIKI, BRANCH_BACKEND, BRANCH_FRONTEND
#   Secretos/integraciones (si no se pasan quedan vacías y se pueden editar en
#   el .env luego): MAIL_USER, MAIL_PASSWORD, MAIL_SMTP_HOST, MAIL_SMTP_PORT,
#   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_MAILTO, BANXICO_API_KEY,
#   DUFFEL_ACCESS_TOKEN, FLIGHT_PROVIDER, WISE_CLIENT_ID, WISE_CLIENT_SECRET,
#   DITTA_ADMIN_INITIAL_PASSWORD, SCHEDULER_ENABLED. AES_SECRET_KEY/JWT_SECRET
#   se autogeneran si van vacías.

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

# Integraciones opcionales que se propagan del entorno → .env (si vienen seteadas).
OPTIONAL_ENV_KEYS=(
	MAIL_USER MAIL_PASSWORD MAIL_SMTP_HOST MAIL_SMTP_PORT
	VAPID_PUBLIC_KEY VAPID_PRIVATE_KEY VAPID_MAILTO
	BANXICO_API_KEY DUFFEL_ACCESS_TOKEN FLIGHT_PROVIDER
	WISE_CLIENT_ID WISE_CLIENT_SECRET
	DITTA_ADMIN_INITIAL_PASSWORD SCHEDULER_ENABLED
)

# Flags (se parsean en main).
SEED_MODE="demo"        # demo | admin | none
FORCE_SEED="false"
FRESH_INSTALL="false"   # true cuando configure_env crea el .env por primera vez

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
			git -C "$dir" fetch --depth 1 origin HEAD
			git -C "$dir" checkout -B main FETCH_HEAD
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

# ask <varname> <prompt> <default> — usa la env var si está seteada; si no y hay
# TTY, pregunta; si no hay TTY (CI/orquestador), usa el default. Permite que
# install.sh corra interactivo O totalmente no-interactivo por variables.
ask() {
	local _var="$1" _prompt="$2" _default="${3:-}" _ans
	if [ -n "${!_var:-}" ]; then printf '%s' "${!_var}"; return; fi
	if [ -t 0 ]; then read -rp "$_prompt" _ans; else _ans=""; fi
	printf '%s' "${_ans:-$_default}"
}

configure_env() {
	local file="${DEPLOY_DIR}/.env"
	if [ -f "$file" ]; then
		log ".env ya existe en ${DEPLOY_DIR} — se conservan los valores actuales."
		return
	fi
	FRESH_INSTALL="true"
	log "Generando .env en ${DEPLOY_DIR}..."
	cp "${DEPLOY_DIR}/.env.example" "$file"

	# --- Base de datos ---
	local db_host db_port db_name db_user db_pass db_pass_enc db_url
	db_host="$(ask POSTGRES_HOST "DB host [postgres = contenedor local]: " postgres)"
	db_port="$(ask POSTGRES_PORT "DB port [5432]: " 5432)"
	db_name="$(ask POSTGRES_DB   "DB nombre [coco]: " coco)"
	db_user="$(ask POSTGRES_USER "DB usuario [coco]: " coco)"
	db_pass="${POSTGRES_PASSWORD:-}"
	if [ -z "$db_pass" ] && [ -t 0 ]; then read -rsp "DB password (vacío=autogenerar): " db_pass; echo; fi
	if [ -z "$db_pass" ]; then db_pass="$(openssl rand -hex 24)"; log "DB password autogenerado (contenedor local)."; fi
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
	pub_host="${PUBLIC_HOST:-}"
	if [ -z "$pub_host" ]; then
		if [ -t 0 ]; then read -rp "Host público [${auto_host:-introduce manualmente}]: " pub_host; fi
		pub_host="${pub_host:-$auto_host}"
	fi
	while [ -z "$pub_host" ]; do
		[ -t 0 ] || { err "PUBLIC_HOST requerido (sin TTY y sin auto-detección)."; exit 1; }
		read -rp "Host público (requerido): " pub_host
	done
	set_env PUBLIC_HOST         "$pub_host"
	set_env PUBLIC_API_BASE_URL "https://${pub_host}/api"
	set_env CORS_ORIGIN         "https://${pub_host}"
	set_env PUBLIC_IS_DEV       "false"
	# Caddy necesita un host (no vacío) para emitir el cert: con `tls internal`
	# genera uno auto-firmado para este host; con dominio real haría ACME.
	set_env SITE_ADDRESS        "$pub_host"

	# --- S3 ---
	local aws_region aws_bucket
	aws_region="$(ask AWS_REGION "AWS_REGION [us-east-1]: " us-east-1)"
	aws_bucket="${AWS_S3_BUCKET:-}"
	if [ -z "$aws_bucket" ] && [ -t 0 ]; then read -rp "AWS_S3_BUCKET (requerido): " aws_bucket; fi
	while [ -z "$aws_bucket" ]; do
		[ -t 0 ] || { err "AWS_S3_BUCKET requerido (sin TTY)."; exit 1; }
		read -rp "AWS_S3_BUCKET (requerido): " aws_bucket
	done
	set_env AWS_REGION    "$aws_region"
	set_env AWS_S3_BUCKET "$aws_bucket"

	# --- Secretos (autogenerados criptográficamente con openssl rand) ---
	# Se generan SIEMPRE si no se proveen por entorno y se persisten en el .env
	# (chmod 600) para que sobrevivan reinicios/redeploys.
	local aes jwt
	aes="${AES_SECRET_KEY:-}"
	if [ -z "$aes" ]; then
		aes="$(openssl rand -hex 16)"  # 16 bytes => 32 chars hex (requerido: 32)
		log "AES_SECRET_KEY autogenerado (cripto, 32 chars)."
	fi
	set_env AES_SECRET_KEY "$aes"

	jwt="${JWT_SECRET:-}"
	if [ -z "$jwt" ]; then
		jwt="$(openssl rand -base64 48 | tr -d '\n')"  # 48 bytes aleatorios
		log "JWT_SECRET autogenerado (cripto)."
	fi
	set_env JWT_SECRET "$jwt"

	# Cifrado de comentarios/chat: 64 hex chars (32 bytes) c/u. Requeridos en prod.
	set_env CHAT_CURSOR_SECRET  "${CHAT_CURSOR_SECRET:-$(openssl rand -hex 32)}"
	set_env CHAT_MESSAGE_SECRET "${CHAT_MESSAGE_SECRET:-$(openssl rand -hex 32)}"
	log "CHAT_CURSOR_SECRET y CHAT_MESSAGE_SECRET autogenerados (cripto, 64 hex)."

	# --- Integraciones opcionales: se toman del entorno si vienen seteadas ---
	local k
	for k in "${OPTIONAL_ENV_KEYS[@]}"; do
		if [ -n "${!k:-}" ]; then
			set_env "$k" "${!k}"
			log "Integración ${k} tomada del entorno."
		fi
	done

	# --- Seeding según modo ---
	# SEED_DUMMY_DATA controla el seed base (reference + admin) en el entrypoint
	# del backend. Los seeders demo (usability + demo) corren post-up.
	case "$SEED_MODE" in
		none) set_env SEED_DUMMY_DATA "false"; set_env SEED_DEMO "false" ;;
		admin) set_env SEED_DUMMY_DATA "true"; set_env SEED_DEMO "false" ;;
		demo|*) set_env SEED_DUMMY_DATA "true"; set_env SEED_DEMO "true" ;;
	esac

	chmod 600 "$file"
	log ".env generado (chmod 600)."
}

# ──────────────────────────────────────────────────────────────────────────
# 5/6. Perfil de Postgres + build + up
# ──────────────────────────────────────────────────────────────────────────
env_get() { grep -E "^$1=" "${DEPLOY_DIR}/.env" 2>/dev/null | head -n1 | cut -d= -f2-; }

db_uses_localdb() {
	case "$(env_get POSTGRES_HOST)" in
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
# 6.5. Seeders demo (todos): usability + demo. El base (seed.js dev) lo hace
#      el entrypoint del backend cuando SEED_DUMMY_DATA=true.
# ──────────────────────────────────────────────────────────────────────────
wait_backend_healthy() {
	local i
	for i in $(seq 1 36); do
		if [ "$(sudo docker inspect -f '{{.State.Health.Status}}' coco-backend-1 2>/dev/null || echo none)" = "healthy" ]; then
			return 0
		fi
		sleep 5
	done
	return 1
}

maybe_seed_demo() {
	cd "$DEPLOY_DIR"
	if [ "$(env_get SEED_DEMO)" != "true" ]; then
		log "Seeding demo desactivado (modo ${SEED_MODE}) — solo reference + admin."
		return
	fi
	# Por defecto los seeders demo solo corren en la instalación inicial; en
	# re-deploys (CI/CD) se omiten salvo --force-seed, para no resetear datos.
	if [ "$FRESH_INSTALL" != "true" ] && [ "$FORCE_SEED" != "true" ]; then
		log "Seeders demo omitidos (no es instalación inicial; usa --force-seed para forzar)."
		return
	fi
	log "Esperando a que el backend esté saludable para sembrar datos demo..."
	wait_backend_healthy || { warn "Backend no saludable a tiempo; omito seeders demo (puedes correrlos luego)."; return; }
	log "Sembrando datos demo (TODOS los seeders): seed-usability.js + seed.demo.js ..."
	# seed.js dev ya corrió en el entrypoint (reference + admin + orgs cliente).
	dc exec -T backend node prisma/seed-usability.js || warn "seed-usability.js terminó con avisos."
	dc exec -T backend node prisma/seed.demo.js       || warn "seed.demo.js terminó con avisos."
	log "Seeders demo completados."
}

# ──────────────────────────────────────────────────────────────────────────
# 7. Health + resumen
# ──────────────────────────────────────────────────────────────────────────
wait_health() {
	local i host
	host="$(env_get PUBLIC_HOST)"
	log "Esperando a que el origen responda en https://${host}/ ..."
	for i in $(seq 1 30); do
		if curl -fsSk -o /dev/null "https://${host}/" 2>/dev/null || curl -fsSk -o /dev/null "https://localhost/" 2>/dev/null; then
			log "Origen arriba."
			break
		fi
		sleep 5
	done

	cd "$DEPLOY_DIR"
	dc ps || true

	cat <<EOF

──────────────────────────────────────────────────────────────────────────
 Stack coco desplegado.

   URL:  https://${host}

 NOTA TLS: por defecto el certificado es AUTO-FIRMADO (Caddy internal). El
 navegador mostrará una advertencia — acéptala (click-through) para entrar.
 Para TLS válido: define un dominio real (SITE_ADDRESS) en ${DEPLOY_DIR}/.env,
 apunta su DNS a la IP elástica y vuelve a ejecutar este script.

 Seeding (modo ${SEED_MODE}):
   - admin Ditta:  admin_ditta / \${DITTA_ADMIN_INITIAL_PASSWORD:-Ditta!Admin#2026}
   - demo UAT:     angel.montemayor / Fuego2026!  (si modo demo)

 Variables de entorno: ${DEPLOY_DIR}/.env  (chmod 600; .env.example documenta cada una)

 Troubleshooting:
   cd ${DEPLOY_DIR} && sudo docker compose -f ${COMPOSE_FILE} logs -f
──────────────────────────────────────────────────────────────────────────
EOF
}

# ──────────────────────────────────────────────────────────────────────────
# 8. Auto-redeploy (CD server-side por git-poll, sin registry)
# ──────────────────────────────────────────────────────────────────────────
# Instala un timer systemd que corre redeploy.sh cada REDEPLOY_INTERVAL. Ese
# script hace `git fetch` de los repos públicos y, si main avanzó, rebuild + up.
# Así la caja se auto-actualiza al mergear a main, sin SSH ni credenciales.
install_redeploy_timer() {
	local interval="${REDEPLOY_INTERVAL:-2min}"
	local script="${COCO_HOME}/cocowiki/deploy/redeploy.sh"
	if [ ! -f "$script" ]; then
		warn "redeploy.sh no encontrado en ${script}; omito el auto-redeploy."
		return
	fi
	sudo chmod +x "$script" 2>/dev/null || true
	# El timer corre redeploy.sh como root sobre repos de ec2-user → git daría
	# "dubious ownership". Se marca seguro a nivel system (no depende de HOME).
	sudo git config --system --add safe.directory '*' 2>/dev/null || true
	log "Instalando auto-redeploy (timer systemd cada ${interval})..."
	sudo tee /etc/systemd/system/coco-redeploy.service >/dev/null <<EOF
[Unit]
Description=coco git-poll redeploy (rebuild + up cuando main avanza)
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
Environment=COCO_HOME=${COCO_HOME}
ExecStart=${script}
EOF
	sudo tee /etc/systemd/system/coco-redeploy.timer >/dev/null <<EOF
[Unit]
Description=Dispara coco-redeploy periodicamente

[Timer]
OnBootSec=3min
OnUnitActiveSec=${interval}
Unit=coco-redeploy.service

[Install]
WantedBy=timers.target
EOF
	sudo systemctl daemon-reload
	sudo systemctl enable --now coco-redeploy.timer
	log "Auto-redeploy activo. Estado: sudo systemctl status coco-redeploy.timer"
}

# ──────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────
parse_args() {
	for arg in "$@"; do
		case "$arg" in
			--seed=demo|--seed=admin|--seed=none) SEED_MODE="${arg#--seed=}" ;;
			--no-demo)    SEED_MODE="admin" ;;
			--force-seed) FORCE_SEED="true" ;;
			-h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
			*) warn "Flag desconocido: $arg (ignorado)" ;;
		esac
	done
}

main() {
	parse_args "$@"
	log "Modo de seeding: ${SEED_MODE} (force-seed=${FORCE_SEED})"
	install_packages
	enable_docker
	ensure_swap
	sync_repos
	configure_env
	build_and_up
	maybe_seed_demo
	wait_health
	install_redeploy_timer
}

main "$@"
