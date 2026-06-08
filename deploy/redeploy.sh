#!/usr/bin/env bash
#
# redeploy.sh — CD server-side por git-poll (sin registry, sin credenciales).
#
# Lo dispara el timer systemd `coco-redeploy.timer` (lo instala install.sh) cada
# pocos minutos, como root. Para CADA repo: `git fetch` de la rama desplegada
# (normalmente main) y, si avanzó, `git reset --hard`. Si algún repo cambió,
# reconstruye y levanta el stack con `docker compose up -d --build`.
#
# Los repos coconsulting2/* son PÚBLICOS => el fetch no necesita credenciales.
# El build es NATIVO en la caja (arm64), así que no hay problema de arquitectura.
# Solo se reconstruye cuando main recibe un commit nuevo (no en cada tick).
#
# Manual:
#   sudo systemctl status coco-redeploy.timer    # ver estado / próximo disparo
#   sudo systemctl start  coco-redeploy.service  # forzar un ciclo ahora
#   journalctl -u coco-redeploy.service -f       # ver logs del redeploy
set -euo pipefail

COCO_HOME="${COCO_HOME:-/opt/coco}"
DEPLOY_DIR="${COCO_HOME}/cocowiki/deploy"
COMPOSE_FILE="${DEPLOY_DIR}/docker-compose.prod.yml"

log() { printf '[redeploy] %s\n' "$*"; }

dc() { docker compose -f "$COMPOSE_FILE" "$@"; }

env_get() { grep -E "^$1=" "${DEPLOY_DIR}/.env" 2>/dev/null | head -n1 | cut -d= -f2-; }

# Mismo criterio que install.sh: host de BD local => perfil localdb (Postgres
# co-locado); cualquier otro host => BD externa, sin perfil.
db_uses_localdb() {
	case "$(env_get POSTGRES_HOST)" in
		postgres|localhost|127.0.0.1|"") return 0 ;;
		*) return 1 ;;
	esac
}

REPOS=(cocowiki TC3005B.501-Backend TC3005B.501-Frontend)

changed=0
for repo in "${REPOS[@]}"; do
	dir="${COCO_HOME}/${repo}"
	[ -d "${dir}/.git" ] || { log "${repo}: no clonado; lo salto."; continue; }
	# La caja clona los repos como ec2-user; este script corre como root, así que
	# git marcaría "dubious ownership" sin esto.
	git config --global --add safe.directory "$dir" 2>/dev/null || true
	# Sigue la rama desplegada (main por defecto; o la rama de prueba si se
	# desplegó una con BRANCH_*).
	branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
	if ! git -C "$dir" fetch --quiet --depth 1 origin "$branch"; then
		log "${repo}: git fetch falló; lo salto este ciclo."
		continue
	fi
	local_head="$(git -C "$dir" rev-parse HEAD)"
	remote_head="$(git -C "$dir" rev-parse FETCH_HEAD)"
	if [ "$local_head" != "$remote_head" ]; then
		log "${repo}: ${branch} avanzó ${local_head:0:7} -> ${remote_head:0:7}; actualizando."
		git -C "$dir" reset --hard FETCH_HEAD
		changed=1
	fi
done

if [ "$changed" -eq 0 ]; then
	log "Sin cambios en las ramas desplegadas; nada que hacer."
	exit 0
fi

cd "$DEPLOY_DIR"
profile_args=()
if db_uses_localdb; then profile_args=(--profile localdb); fi

log "Reconstruyendo y levantando el stack (cambios detectados)..."
dc "${profile_args[@]}" up -d --build
docker image prune -f >/dev/null 2>&1 || true
log "Redeploy completo."
