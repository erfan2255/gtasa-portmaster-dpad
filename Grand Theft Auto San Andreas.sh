#!/bin/bash
CURR_TTY="/dev/tty1"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

[ "$(id -u 2>/dev/null)" = "0" ] && IS_ROOT=1 || IS_ROOT=0
[ -d /run/systemd/system ] && IS_SYSTEMD=1 || IS_SYSTEMD=0

IS_EMUELEC=0
case "${GTASA_PLATFORM:-}" in
  emuelec|coreelec|libreelec) IS_EMUELEC=1 ;;
  *)
    if grep -qi 'emuelec\|coreelec\|libreelec' /etc/os-release 2>/dev/null \
       || [ -f /etc/emuelec-version ] || [ -d /emuelec ] \
       || [ -d /storage/.config/emuelec ]; then
      IS_EMUELEC=1
    fi
    ;;
esac

priv() {
  if [ "$IS_ROOT" = "1" ]; then "$@"
  elif command -v sudo >/dev/null 2>&1; then sudo "$@"
  else "$@"
  fi
}

if [ -d "$SCRIPT_DIR/gtasa" ]; then
  GAME_DIR="$SCRIPT_DIR/gtasa"
elif [ -d "$(dirname "$SCRIPT_DIR")/../ports/gtasa" ]; then
  GAME_DIR="$(readlink -f "$(dirname "$SCRIPT_DIR")/../ports/gtasa")"
elif [ -d "/storage/roms/ports/gtasa" ]; then
  GAME_DIR="/storage/roms/ports/gtasa"
elif [ -d "/emuelec/roms/ports/gtasa" ]; then
  GAME_DIR="/emuelec/roms/ports/gtasa"
elif [ -d "/roms/ports/gtasa" ]; then
  GAME_DIR="/roms/ports/gtasa"
elif [ -d "/sdcard/ports/gtasa" ]; then
  GAME_DIR="/sdcard/ports/gtasa"
elif [ -d "/mnt/mmc/ports/gtasa" ]; then
  GAME_DIR="/mnt/mmc/ports/gtasa"
else
  GAME_DIR="$SCRIPT_DIR/gtasa"
fi

BINARY="$GAME_DIR/gtasa"
LOG="$GAME_DIR/gtasa.log"
DIAG_LOG="$GAME_DIR/gtasa.diag.log"
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

GTASA_DIAG=${GTASA_DIAG:-1}
GTASA_STDBUF=${GTASA_STDBUF:-1}

pkill -9 gtasa || true
sleep 1

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
elif [ -d "$SCRIPT_DIR/PortMaster" ]; then
  controlfolder="$SCRIPT_DIR/PortMaster"
elif [ -d "$(dirname "$GAME_DIR")/PortMaster" ]; then
  controlfolder="$(dirname "$GAME_DIR")/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

if [ -f "$controlfolder/control.txt" ]; then
  source "$controlfolder/control.txt"
  get_controls
fi

exec < "$CURR_TTY"

if [ ! -f "$BINARY" ]; then
  printf "\033c" > "$CURR_TTY"
  printf "Error: gtasa binary not found at %s\n" "$BINARY" > "$CURR_TTY"
  sleep 5
  exit 1
fi

for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  [ -f "$gov" ] && echo performance | priv tee "$gov" > /dev/null 2>&1 || true
done

if [ -d "$GAME_DIR/libs" ]; then
  export LD_LIBRARY_PATH="$GAME_DIR/libs:$GAME_DIR:$LD_LIBRARY_PATH"
  if [ ! -f "$GAME_DIR/libs/libbsd.so.0" ] && [ -f "$GAME_DIR/libs/libbsd.so" ]; then
    ln -sf "libbsd.so" "$GAME_DIR/libs/libbsd.so.0"
  fi
else
  export LD_LIBRARY_PATH="$GAME_DIR:$LD_LIBRARY_PATH"
fi

# Dynamic OS / Display Driver Auto-Detection
if [ "$IS_EMUELEC" = "1" ]; then
  unset SDL_VIDEODRIVER
  export SDL_FBDEV=/dev/fb0
  export SDL_NOMOUSE=1
  export LIBGL_FB=3
  export LIBGL_ES=2
elif [ -n "$WAYLAND_DISPLAY" ] || [ -f "/etc/knulli.conf" ] || [ -d "/userdata/system" ]; then
  # KNULLI / Batocera / ROCKNIX Wayland-based OS
  export SDL_VIDEODRIVER=wayland
elif [ -f "/etc/muos/config.ini" ] || [ -d "/opt/muos" ] || [ -f "/usr/bin/muos" ] || [ -d "/run/muos" ]; then
  # muOS (Anbernic RG35XX series) - let SDL auto-probe working display
  unset SDL_VIDEODRIVER
elif [ -e "/dev/dri/card0" ]; then
  # ArkOS / AmberELEC / Standard KMSDRM (R36S, RG351, etc.)
  [ -z "$SDL_VIDEODRIVER" ] && export SDL_VIDEODRIVER=kmsdrm
fi

export SDL_AUDIODRIVER=alsa
export ALSOFT_DRIVERS=alsa

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export MALLOC_CHECK_=0
export SDL_VIDEO_ALLOW_SCREENSAVER=0
export SDL_NO_SIGNAL_HANDLERS=1

setterm -blank 0 -powerdown 0 -powersave off >/dev/null 2>&1 <"$CURR_TTY" || true
if [ -n "$DISPLAY" ]; then
  xset s off       >/dev/null 2>&1 || true
  xset -dpms       >/dev/null 2>&1 || true
  xset s noblank   >/dev/null 2>&1 || true
fi

export MESA_GL_VERSION_OVERRIDE=2.1
export MESA_GLES_VERSION_OVERRIDE=2.0
export SDL_VIDEO_GL_DRIVER=libGLESv2.so
export SDL_VIDEO_EGL_DRIVER=libEGL.so

quiet_console() {
  if [ "$IS_SYSTEMD" = "1" ]; then
    kill -s SIGRTMIN+21 1 2>/dev/null || true
  fi
  echo 1 > /proc/sys/kernel/printk 2>/dev/null || true
}

quiet_console

printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY"
echo 0 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
echo 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true

for _o in main patch; do
  for _f in "$GAME_DIR"/${_o}.*.com.rockstargames.gtasa.obb; do
    if [ -f "$_f" ] && [ ! -f "$GAME_DIR/${_o}.obb" ]; then
      ln -sf "$(basename "$_f")" "$GAME_DIR/${_o}.obb"
    fi
  done
done

sync
echo 3 | priv tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
cd "$GAME_DIR"

for _d in audio data models texdb anim res obb; do
  _u=$(echo "$_d" | tr 'a-z' 'A-Z')
  if [ -d "$_d" ] && [ ! -e "$_u" ]; then ln -sf "$_d" "$_u" 2>/dev/null; fi
  if [ -d "$_u" ] && [ ! -e "$_d" ]; then ln -sf "$_u" "$_d" 2>/dev/null; fi
  if [ -d "assets/$_d" ] && [ ! -e "$_d" ]; then ln -sf "assets/$_d" "$_d" 2>/dev/null; fi
  if [ -d "assets/$_u" ] && [ ! -e "$_u" ]; then ln -sf "assets/$_u" "$_u" 2>/dev/null; fi
done

GAME_PID=
do_cleanup() {
  if [ -n "$GAME_PID" ] && kill -0 "$GAME_PID" 2>/dev/null; then
    kill -TERM "$GAME_PID" 2>/dev/null || true
    for _i in 1 2 3 4 5; do
      kill -0 "$GAME_PID" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$GAME_PID" 2>/dev/null || true
    wait "$GAME_PID" 2>/dev/null
  fi
}
trap 'do_cleanup' TERM INT HUP

run_gtasa() {
  if [ "$GTASA_STDBUF" = "1" ] && command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL "$@"
  else
    "$@"
  fi
}

: > "$LOG"
run_gtasa "$BINARY" >> "$LOG" 2>&1 &
GAME_PID=$!
while kill -0 "$GAME_PID" 2>/dev/null; do
  wait "$GAME_PID" 2>/dev/null
done
wait "$GAME_PID" 2>/dev/null
EXIT_CODE=$?
trap - TERM INT HUP

if [ "$GTASA_DIAG" = "1" ]; then
  {
    echo "=== gtasa diag $(date -Iseconds 2>/dev/null || date 2>/dev/null || date) ==="
    echo "exit_code=$EXIT_CODE"
    echo "platform: emuelec=$IS_EMUELEC systemd=$IS_SYSTEMD root=$IS_ROOT"
    if [ -f /proc/sys/vm/oom_kill_allocating_task ]; then
      echo "oom_kill_allocating_task=$(cat /proc/sys/vm/oom_kill_allocating_task 2>/dev/null)"
    fi
    if command -v dmesg >/dev/null 2>&1; then
      echo "--- dmesg (last 40 lines, OOM/GPU/kill) ---"
      dmesg 2>/dev/null | tail -n 40 | grep -E -i 'oom|killed process|Out of memory|mali|panfrost|gpu|gtasa' || true
    fi
    if [ -f "$LOG" ]; then
      echo "--- gtasa.log tail (last 15 lines) ---"
      tail -n 15 "$LOG" 2>/dev/null || true
    fi
  } >> "$DIAG_LOG" 2>&1
  sync
fi

quiet_console
echo 1 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
echo 1 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true
printf "\033c" > "$CURR_TTY"
printf "\e[?25h" > "$CURR_TTY"
exit $EXIT_CODE
