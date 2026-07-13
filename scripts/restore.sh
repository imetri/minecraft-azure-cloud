#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_DIR="${PROJECT_DIR:-/opt/minecraft-cloud}"
DATA_DIR="${DATA_DIR:-/srv/minecraft/data}"
CONTAINER_NAME="${CONTAINER_NAME:-minecraft-paper}"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-minecraft}"
LOCK_FILE="${LOCK_FILE:-/var/lock/minecraft-restore.lock}"

log() {
    printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
    fail "Run this restore script with sudo."
fi

backup_argument="${1:-}"

if [[ -z "$backup_argument" ]]; then
    echo "Usage:"
    echo "  sudo $0 /srv/minecraft/backups/minecraft-TIMESTAMP.tar.gz"
    exit 1
fi

backup_path="$(readlink -f "$backup_argument")"
checksum_path="${backup_path}.sha256"

[[ -f "$backup_path" ]] ||
    fail "Backup archive not found: $backup_path"

[[ -f "$checksum_path" ]] ||
    fail "Checksum file not found: $checksum_path"

[[ -d "$PROJECT_DIR" ]] ||
    fail "Deployment directory not found: $PROJECT_DIR"

for command in docker tar gzip sha256sum flock; do
    command -v "$command" >/dev/null 2>&1 ||
        fail "Required command is missing: $command"
done

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    fail "Another restore operation is already running."
fi

log "Verifying SHA-256 checksum."

(
    cd "$(dirname "$backup_path")"
    sha256sum --check "$(basename "$checksum_path")"
)

log "Testing compressed archive."
gzip -t "$backup_path"

cd "$PROJECT_DIR"

log "Stopping the Minecraft container."
docker compose stop "$COMPOSE_SERVICE"

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
rollback_dir="${DATA_DIR}.pre-restore-${timestamp}"

rollback_required="false"

rollback_restore() {
    if [[ "$rollback_required" == "true" ]]; then
        log "Restore failed. Returning to the previous data directory."

        docker compose stop "$COMPOSE_SERVICE" >/dev/null 2>&1 || true
        rm -rf "$DATA_DIR"

        if [[ -d "$rollback_dir" ]]; then
            mv "$rollback_dir" "$DATA_DIR"
        fi

        docker compose up -d "$COMPOSE_SERVICE" >/dev/null 2>&1 || true
    fi
}

trap 'rollback_restore; exit 1' ERR INT TERM

log "Moving current data to rollback directory:"
log "$rollback_dir"

mv "$DATA_DIR" "$rollback_dir"
mkdir -p "$DATA_DIR"

rollback_required="true"

log "Extracting backup into $DATA_DIR"

tar \
    --numeric-owner \
    --acls \
    --xattrs \
    -xzf "$backup_path" \
    -C "$DATA_DIR"

log "Starting Minecraft using the restored data."
docker compose up -d "$COMPOSE_SERVICE"

log "Waiting for the restored container to become healthy."

for attempt in $(seq 1 60); do
    status="$(
        docker inspect \
            --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$CONTAINER_NAME" 2>/dev/null || true
    )"

    if [[ "$status" == "healthy" ]]; then
        rollback_required="false"
        trap - ERR INT TERM

        log "Restore completed successfully."
        log "Container health: healthy"
        log "Previous data retained at:"
        log "$rollback_dir"
        exit 0
    fi

    if [[ "$status" == "unhealthy" || "$status" == "exited" || "$status" == "dead" ]]; then
        fail "Restored container entered state: $status"
    fi

    sleep 5
done

fail "Timed out while waiting for the restored container."