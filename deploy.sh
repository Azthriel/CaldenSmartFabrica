#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  CaldenSmart Fábrica - Deploy Script (Linux)
#  Lee version desde pubspec.yaml, genera APK de release
# ============================================================

APP_DIR="/home/gonza-trillo/Desktop/caldensmartfabrica"
APKS_DIR="/home/gonza-trillo/Desktop/Apks"
PUBSPEC="$APP_DIR/pubspec.yaml"

# ── Verificar que existe pubspec.yaml ────────────────────────
if [[ ! -f "$PUBSPEC" ]]; then
    echo "[ERROR] No se encontró pubspec.yaml en $APP_DIR"
    exit 1
fi

# ── Leer version desde pubspec.yaml (sin build number) ───────
VERSION=$(grep -E '^version:' "$PUBSPEC" | head -n1 | sed -E 's/^version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]\r')

if [[ -z "$VERSION" ]]; then
    echo "[ERROR] No se pudo leer la versión de pubspec.yaml"
    exit 1
fi

# ── Cabecera ─────────────────────────────────────────────────
echo ""
echo " ╔══════════════════════════════════════════╗"
echo " ║   CaldenSmart Fábrica  -  Deploy Script  ║"
echo " ╠══════════════════════════════════════════╣"
echo " ║  Versión detectada : $VERSION"
echo " ╚══════════════════════════════════════════╝"
echo ""

# ── Verificar carpeta destino ────────────────────────────────
mkdir -p "$APKS_DIR"

# ============================================================
#  PASO 1 — flutter build apk (release)
# ============================================================
echo "[1/2] Ejecutando flutter build apk --release..."
echo ""

cd "$APP_DIR"
flutter build apk --release

echo ""
echo " OK - Build completado."
echo ""

# ============================================================
#  PASO 2 — Renombrar y mover el .apk
# ============================================================
echo "[2/2] Moviendo APK a \"Apks\"..."

APK_SRC="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$APKS_DIR/CSFABRICA$VERSION.apk"

if [[ ! -f "$APK_SRC" ]]; then
    echo "[ERROR] No se encontró el .apk en:"
    echo "        $APK_SRC"
    exit 1
fi

cp -f "$APK_SRC" "$APK_DEST"

echo " OK - APK copiado correctamente."
echo ""

# ============================================================
#  RESUMEN FINAL
# ============================================================
echo " ╔══════════════════════════════════════════╗"
echo " ║          Deploy Finalizado!              ║"
echo " ╠══════════════════════════════════════════╣"
echo " ║  Versión    : $VERSION"
echo " ║  APK        : CSFABRICA$VERSION.apk"
echo " ╚══════════════════════════════════════════╝"
echo ""

# Sonido de notificación (si existe paplay/canberra, si no, campana de terminal)
if command -v paplay &>/dev/null && [[ -f /usr/share/sounds/freedesktop/stereo/complete.oga ]]; then
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
else
    printf '\a'
fi