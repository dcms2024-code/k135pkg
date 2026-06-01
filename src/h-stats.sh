#!/usr/bin/env bash
# h-stats.sh: HiveOS SOURCEA este script y lee las variables $khs y $stats (NO echo).
# Reporta el hashrate del kangaroo de este rig (MK/s -> kH/s).
LOG=/hive/miners/custom/kangaroo135v3/log_kangaroo.txt
mk=$(grep -aoE '[0-9]+\.[0-9]+ MK(ey)?/s' "$LOG" 2>/dev/null | tail -1 | grep -oE '^[0-9.]+')
[ -z "$mk" ] && mk=0
khs=$(awk "BEGIN{printf \"%.0f\", $mk*1000}")
stats=$(jq -nc --arg k "$khs" '{hs:[($k|tonumber)],hs_units:"khs",temp:[],fan:[],uptime:0,ver:"2.2",ar:[0,0],algo:"kangaroo",total_khs:($k|tonumber)}' 2>/dev/null)
[ -z "$stats" ] && stats="{\"hs\":[$khs],\"hs_units\":\"khs\",\"total_khs\":$khs,\"ar\":[0,0],\"algo\":\"kangaroo\"}"
