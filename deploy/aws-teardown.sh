#!/usr/bin/env bash
#
# aws-teardown.sh — destruye TODO lo que creó aws-provision.sh (tag Project=coco).
# Útil para una prueba end-to-end desde cero. Corre en tu equipo (Linux/macOS,
# o Windows vía WSL2/Git Bash) con el AWS CLI.
#
# Uso:
#   ./aws-teardown.sh           # pide confirmación
#   ./aws-teardown.sh --yes     # sin confirmación (automatización)
#   KEEP_BUCKET=1 ./aws-teardown.sh   # conserva el bucket S3 (y sus datos)
#
# Orden (respeta dependencias): instancia → EIP → SG → route table → IGW →
# subnet → IAM (profile/role) → key pair → (opcional) bucket S3.

set -uo pipefail

REGION="${REGION:-us-east-1}"
VPC_ID="${VPC_ID:-vpc-0f7bd8ada126a095b}"
PROJECT="coco"
KEY_NAME="coco-deploy"
SG_NAME="coco-sg"
ROLE_NAME="coco-ec2-role"
PROFILE_NAME="coco-ec2-profile"
POLICY_NAME="coco-s3-access"
KEEP_BUCKET="${KEEP_BUCKET:-0}"
AWS=(aws --region "$REGION" --output text)

log()  { printf '\033[1;31m[teardown]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[teardown]\033[0m %s\n' "$*"; }
tagf() { echo "Name=tag:Project,Values=${PROJECT}"; }

ACCOUNT_ID="$("${AWS[@]}" sts get-caller-identity --query Account 2>/dev/null)"
BUCKET="coco-consulting-prod-${ACCOUNT_ID}"

if [ "${1:-}" != "--yes" ]; then
	echo "Esto ELIMINA la infra coco en ${REGION} (instancia, EIP, SG, subnet, IGW,"
	echo "route table, IAM role/profile, key pair${KEEP_BUCKET:+}, y el bucket ${BUCKET} salvo KEEP_BUCKET=1)."
	read -rp "¿Continuar? (escribe 'destroy'): " ans
	[ "$ans" = "destroy" ] || { echo "Cancelado."; exit 1; }
fi

# 1) Instancia(s)
INSTANCE_IDS="$("${AWS[@]}" ec2 describe-instances --filters "$(tagf)" \
	"Name=instance-state-name,Values=pending,running,stopping,stopped" \
	--query 'Reservations[].Instances[].InstanceId' 2>/dev/null)"
if [ -n "${INSTANCE_IDS}" ] && [ "${INSTANCE_IDS}" != "None" ]; then
	log "Terminando instancia(s): ${INSTANCE_IDS}"
	# shellcheck disable=SC2086
	"${AWS[@]}" ec2 terminate-instances --instance-ids ${INSTANCE_IDS} >/dev/null 2>&1
	# shellcheck disable=SC2086
	"${AWS[@]}" ec2 wait instance-terminated --instance-ids ${INSTANCE_IDS} 2>/dev/null
	ok "Instancia(s) terminada(s)."
else
	ok "No hay instancias que terminar."
fi

# 2) Elastic IP
for alloc in $("${AWS[@]}" ec2 describe-addresses --filters "$(tagf)" --query 'Addresses[].AllocationId' 2>/dev/null); do
	[ "$alloc" = "None" ] && continue
	assoc="$("${AWS[@]}" ec2 describe-addresses --allocation-ids "$alloc" --query 'Addresses[0].AssociationId' 2>/dev/null)"
	[ -n "$assoc" ] && [ "$assoc" != "None" ] && "${AWS[@]}" ec2 disassociate-address --association-id "$assoc" >/dev/null 2>&1
	"${AWS[@]}" ec2 release-address --allocation-id "$alloc" >/dev/null 2>&1 && ok "EIP liberada: $alloc"
done

# 3) Security group (tras terminar la instancia)
SG_ID="$("${AWS[@]}" ec2 describe-security-groups --filters "$(tagf)" "Name=group-name,Values=${SG_NAME}" --query 'SecurityGroups[0].GroupId' 2>/dev/null)"
if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
	for i in $(seq 1 6); do
		"${AWS[@]}" ec2 delete-security-group --group-id "$SG_ID" >/dev/null 2>&1 && { ok "SG borrado: $SG_ID"; break; }
		sleep 5
	done
fi

# 4) Route table (desasociar + borrar las no-main del proyecto)
for rtb in $("${AWS[@]}" ec2 describe-route-tables --filters "$(tagf)" "Name=vpc-id,Values=${VPC_ID}" --query 'RouteTables[].RouteTableId' 2>/dev/null); do
	[ "$rtb" = "None" ] && continue
	for assoc in $("${AWS[@]}" ec2 describe-route-tables --route-table-ids "$rtb" --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' 2>/dev/null); do
		"${AWS[@]}" ec2 disassociate-route-table --association-id "$assoc" >/dev/null 2>&1
	done
	"${AWS[@]}" ec2 delete-route-table --route-table-id "$rtb" >/dev/null 2>&1 && ok "Route table borrada: $rtb"
done

# 5) Internet Gateway (detach + delete)
for igw in $("${AWS[@]}" ec2 describe-internet-gateways --filters "$(tagf)" "Name=attachment.vpc-id,Values=${VPC_ID}" --query 'InternetGateways[].InternetGatewayId' 2>/dev/null); do
	[ "$igw" = "None" ] && continue
	"${AWS[@]}" ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID" >/dev/null 2>&1
	"${AWS[@]}" ec2 delete-internet-gateway --internet-gateway-id "$igw" >/dev/null 2>&1 && ok "IGW borrado: $igw"
done

# 6) Subnet
for sub in $("${AWS[@]}" ec2 describe-subnets --filters "$(tagf)" "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[].SubnetId' 2>/dev/null); do
	[ "$sub" = "None" ] && continue
	for i in $(seq 1 6); do
		"${AWS[@]}" ec2 delete-subnet --subnet-id "$sub" >/dev/null 2>&1 && { ok "Subnet borrada: $sub"; break; }
		sleep 5
	done
done

# 7) IAM instance profile + role
"${AWS[@]}" iam remove-role-from-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME" >/dev/null 2>&1
"${AWS[@]}" iam delete-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1 && ok "Instance profile borrado."
"${AWS[@]}" iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" >/dev/null 2>&1
"${AWS[@]}" iam delete-role --role-name "$ROLE_NAME" >/dev/null 2>&1 && ok "IAM role borrado."

# 8) Key pair (AWS; el .pem local NO se borra)
"${AWS[@]}" ec2 delete-key-pair --key-name "$KEY_NAME" >/dev/null 2>&1 && ok "Key pair borrado (conserva tu ${KEY_NAME}.pem local si quieres)."

# 9) Bucket S3 (a menos que KEEP_BUCKET=1)
if [ "$KEEP_BUCKET" = "1" ]; then
	ok "KEEP_BUCKET=1 → conservo el bucket ${BUCKET}."
else
	if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null 2>&1; then
		log "Vaciando y borrando bucket ${BUCKET}..."
		aws s3 rm "s3://${BUCKET}" --recursive --region "$REGION" >/dev/null 2>&1
		aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null 2>&1 && ok "Bucket borrado."
	fi
fi

ok "Teardown completado."
