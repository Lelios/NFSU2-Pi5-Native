#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT/Spiel" || exit 1

echo "======================================"
echo " NEED FOR SPEED UNDERGROUND 2"
echo " RASPBERRY PI 5 - V26 GOLD"
echo "======================================"
echo
echo "Nativer ARM64-Port"
echo "Shader-Fix aktiviert"
echo

exec env \
-u NFSU2_ADAPTIVE_FRAMESKIP \
-u NFSU2_V12_SKIP_REFLECTION \
-u NFSU2_V13_NO_REFLECTION \
-u NFSU2_V18_CLAMP_BONE_Z \
-u NFSU2_V19_HIDE_SKIN \
-u NFSU2_V20_SINGLE_BONE \
-u NFSU2_V21_CLAMP_BONE_INDICES \
-u NFSU2_V22_EXPP_Y_FIX \
-u NFSU2_V23_MESH_DIAG \
-u NFSU2_SKIP_DRAWS \
-u NFSU2_SKIP_MATCH \
-u NFSU2_DUMP_SHADERS \
SDL_VIDEODRIVER=x11 \
NFSU2_V26_EXPP_Y_FIX=1 \
NFSU2_PARALLEL_GUEST=0 \
NFSU2_SCREEN=1280x720 \
NFSU2_RENDER=1280x720 \
NFSU2_WIDESCREEN=0 \
NFSU2_FOV_ONLY=1 \
NFSU2_ROTATE=0 \
NFSU2_STRETCH_FLIP_Y=1 \
NFSU2_SHADER_CACHE=0 \
NFSU2_V14_PROJECT_REFLECTION=1 \
./nfsu2-pi5-native-v26-real-expp-fix.aarch64 \
./gamedata --cap=0 --lang=German
