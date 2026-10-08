#!/usr/bin/env bash
set -euo pipefail

STAGE="${1:?Specify qa or prod}"
IMAGE="${2:?Specify an image}"

case "$STAGE" in
  qa)
    SITE_HOST="qa.edgarstevenojeda.site"
    ;;
  prod)
    SITE_HOST="edgarstevenojeda.site"
    ;;
  *)
    echo "Invalid environment"
    exit 2
    ;;
esac

if [[ ! "$IMAGE" =~ ^ghcr\.io/[a-z0-9._/-]+:[0-9a-f]{40}$ ]]; then
  echo "Invalid image reference"
  exit 2
fi

export IMAGE STAGE SITE_HOST

docker compose \
  -p "is373-$STAGE" \
  -f /opt/is373-practical/compose.yaml \
  pull

docker compose \
  -p "is373-$STAGE" \
  -f /opt/is373-practical/compose.yaml \
  up -d --remove-orphans