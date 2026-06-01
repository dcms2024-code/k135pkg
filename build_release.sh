#!/usr/bin/env bash
# build_release.sh NAME TAG KANGAROO_BIN
# Empaqueta src/ (renombrado a NAME) + el binario kangaroo, y publica un release GitHub con el tar.gz.
# Requiere: export GH_TOKEN=ghp_...   (PAT scope repo)
# Ej: GH_TOKEN=ghp_xxx ./build_release.sh kangaroo135v3 v4 ~/kangaroo
set -euo pipefail

NAME="${1:?uso: build_release.sh NAME TAG KANGAROO_BIN}"
TAG="${2:?falta TAG (p.ej. v4)}"
KBIN="${3:?falta ruta al binario kangaroo}"
REPO="dcms2024-code/k135pkg"
: "${GH_TOKEN:?export GH_TOKEN=ghp_...}"

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/$NAME"

# Copia los scripts y reescribe el nombre del miner en rutas/manifest
cp "$HERE/src/"* "$WORK/$NAME/"
cp "$KBIN" "$WORK/$NAME/kangaroo"
sed -i "s#kangaroo135v2#$NAME#g; s#/custom/kangaroo135#/custom/$NAME#g" "$WORK/$NAME/h-run.sh" "$WORK/$NAME/h-stats.sh"
printf 'CUSTOM_NAME=%s\nCUSTOM_VERSION=2.9\nCUSTOM_BUILD=9\nCUSTOM_ALGO=kangaroo\n' "$NAME" > "$WORK/$NAME/h-manifest.conf"
chmod +x "$WORK/$NAME/h-run.sh" "$WORK/$NAME/h-stats.sh" "$WORK/$NAME/h-config.sh" "$WORK/$NAME/kangaroo"

ASSET="$NAME-hiveos.tar.gz"
( cd "$WORK" && tar czf "$ASSET" "$NAME/" )
echo "Empaquetado $WORK/$ASSET"
bash -n "$WORK/$NAME/h-run.sh" && echo "h-run.sh syntax OK"

# Crea el release y sube el asset
resp=$(curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\",\"draft\":false,\"prerelease\":false}")
RID=$(echo "$resp" | grep -oE 'releases/[0-9]+/assets' | head -1 | grep -oE '[0-9]+')
[ -z "$RID" ] && { echo "ERROR creando release:"; echo "$resp" | head -20; exit 1; }

curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/gzip" \
  --data-binary @"$WORK/$ASSET" \
  "https://uploads.github.com/repos/$REPO/releases/$RID/assets?name=$ASSET" \
  | grep -oE '"(state|browser_download_url)": ?"[^"]*"'

echo "LISTO. Recuerda editar flightsheet.json: miner_alt/miner=$NAME e install_url=.../$TAG/$ASSET"
