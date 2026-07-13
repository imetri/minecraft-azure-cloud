#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_DIR="${PROJECT_DIR:-/opt/minecraft-cloud}"
DATA_DIR="${DATA_DIR:-/srv/minecraft/data}"
BACKUP_DIR="${BACKUP_DIR:-/srv/minecraft/backups}"
CONTAINER_NAME="${CONTAINER_NAME:-minecraft-paper}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
LOCK_FILE="${LOCK_FILE:-/var/lock/minecraft-backup.lock}"

log() {
    printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"
}

fail() {
    log "ERROR: $*"
    exit 1
}

for command in docker tar gzip sha256sum flock find sync; do
    command -v "$command" >/dev/null 2>&1 ||
        fail "Required command is missing: $command"
done

[[ -d "$DATA_DIR" ]] ||
    fail "Minecraft data directory does not exist: $DATA_DIR"

mkdir -p "$BACKUP_DIR"

# Prevent two backups from running simultaneously.
exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    log "Another backup is already running. Exiting."
    exit 0
fi

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
archive_name="minecraft-${timestamp}.tar.gz"
archive_path="${BACKUP_DIR}/${archive_name}"

server_was_running="false"

resume_world_saves() {
    if [[ "$server_was_running" == "true" ]]; then
        log "Re-enabling Minecraft world saving."
        docker exec "$CONTAINER_NAME" rcon-cli save-on \
            >/dev/null 2>&1 || true
    fi
}

trap resume_world_saves EXIT

if docker inspect \
    --format='{{.State.Running}}' \
    "$CONTAINER_NAME" 2>/dev/null | grep -qx 'true'; then

    server_was_running="true"

    log "Temporarily disabling automatic world saves."
    docker exec "$CONTAINER_NAME" rcon-cli save-off

    log "Flushing Minecraft world data to disk."
    docker exec "$CONTAINER_NAME" rcon-cli save-all flush

    # Flush operating-system filesystem buffers.
    sync
fi

log "Creating backup: $archive_path"

tar \
    --numeric-owner \
    --acls \
    --xattrs \
    -C "$DATA_DIR" \
    -czf "$archive_path" \
    .

log "Testing archive compression integrity."
gzip -t "$archive_path"

log "Generating SHA-256 checksum."

(
    cd "$BACKUP_DIR"
    sha256sum "$archive_name" > "${archive_name}.sha256"
)

if [[ "$server_was_running" == "true" ]]; then
    log "Re-enabling Minecraft world saving."
    docker exec "$CONTAINER_NAME" rcon-cli save-on
    server_was_running="false"
fi

log "Removing backups older than ${RETENTION_DAYS} days."

find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    \( \
        -name 'minecraft-*.tar.gz' \
        -o -name 'minecraft-*.tar.gz.sha256' \
    \) \
    -mtime "+${RETENTION_DAYS}" \
    -delete

archive_size="$(du -h "$archive_path" | awk '{print $1}')"

log "Backup completed successfully."
log "Archive: $archive_path"
log "Size: $archive_size"
log "Checksum: ${archive_path}.sha256"