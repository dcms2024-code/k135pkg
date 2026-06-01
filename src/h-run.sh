#!/bin/bash
# kangaroo135v2 como custom miner de HiveOS. Rol AUTO por IP (.48 = server, resto = client -> .48).
# Una sola flight sheet vale para los dos rigs. h-run.sh corre en PRIMER PLANO (HiveOS lo vigila).
KDIR=/hive/miners/custom/kangaroo135v2
SERVER_IP=192.168.1.48
SERVER_PORT=17403
LOG="$KDIR/log_kangaroo.txt"
cd "$KDIR" 2>/dev/null
chmod +x "$KDIR/kangaroo" 2>/dev/null
MYIP=$(ip -4 a | grep -oE '192\.168\.1\.[0-9]+' | head -1)
# Limpia cualquier kangaroo previo de este rig antes de arrancar
pkill -f "$KDIR/kangaroo" 2>/dev/null; sleep 2

if [ "$MYIP" = "$SERVER_IP" ]; then
  echo "[kangaroo135v2] SERVIDOR ($MYIP) + cliente local"
  # Al parar el miner (HiveOS mata el cliente en foreground), el trap mata tambien el server de fondo
  trap 'pkill -f "$KDIR/kangaroo" 2>/dev/null' EXIT INT TERM
  "$KDIR/kangaroo" -s -sp "$SERVER_PORT" -d 20 -w "$KDIR/work.save" -wi 300 \
    -o "$KDIR/resultado135.txt" "$KDIR/puzzle135.txt" > "$KDIR/log_server.txt" 2>&1 &
  sleep 6
  "$KDIR/kangaroo" -t 0 -gpu -c 127.0.0.1 2>&1 | tee "$LOG"
else
  echo "[kangaroo135v2] CLIENTE ($MYIP) -> $SERVER_IP"
  "$KDIR/kangaroo" -t 0 -gpu -c "$SERVER_IP" 2>&1 | tee "$LOG"
fi
