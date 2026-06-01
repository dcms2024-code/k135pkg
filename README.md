# kangaroo135 — HiveOS custom miner (puzzle Bitcoin #135)

Custom miner de HiveOS que corre **JeanLucPons/Kangaroo** en los rigs (octominers) para el
puzzle BTC #135, coordinando un **server** + varios **clientes** que comparten puntos
distinguidos (no se pisan). Se aplica como **flight sheet** y se alterna con PEARL desde el panel.

## Cómo funciona (rol AUTO por IP)
`h-run.sh` detecta la IP local del rig:
- **192.168.1.48** → arranca el **server** (`kangaroo -s -sp 17403 ...`) **+** un cliente local.
- **cualquier otra IP** → arranca solo **cliente** conectando a `192.168.1.48:17403`.

Por eso **UNA sola flight sheet vale para todos los rigs**.

## ➕ Añadir otro rig / ampliar
**No hay que reconstruir nada.** Solo:
1. En HiveOS, aplica la **misma flight sheet** (`kangaroo135v2-puzzle`) al worker nuevo.
2. Si su IP no es la `.48`, se vuelve cliente y se conecta solo al server.

Si el rig nuevo va a ser el **server** (o cambia la IP del server), edita `SERVER_IP` en
`src/h-run.sh` y publica una versión nueva (ver abajo). Conviene **reserva DHCP** para el server.

## 🔄 Alternar PEARL ↔ puzzle
Solo cambiar la flight sheet en el panel web: `kangaroo135v2-puzzle` ↔ la de PEARL.
(El custom miner y PEARL no coexisten; aplicar una para la otra.)

## Lecciones aprendidas (por qué funciona ESTA versión)
1. **`h-config.sh` es OBLIGATORIO.** HiveOS lo *sourcea* antes de arrancar; sin él NO ejecuta
   `h-run.sh` (instala los archivos pero no hay proceso ni log). Era el bloqueador histórico.
2. **HiveOS cachea el custom miner por NOMBRE.** Si ya existe `/hive/miners/custom/<nombre>`,
   NO re-descarga aunque cambie el `install_url`. Para forzar una versión nueva: **renombrar el
   miner** (kangaroo135 → kangaroo135v2 …) o `rm -rf /hive/miners/custom/<nombre>` en la Hive Shell.
3. `h-run.sh` debe correr en **primer plano** (HiveOS lo vigila por screen). El `trap` mata el
   server de fondo cuando HiveOS para el miner (necesario para volver a PEARL limpio).
4. `h-stats.sh` **setea** las variables `khs`/`stats` (HiveOS lo sourcea), NO hace `echo`.
5. Los rigs HiveOS **no tienen SSH** (puerto 22 cerrado); solo **Hive Shell** (terminal web).
   Verificar que el server arrancó desde otra máquina de la LAN: conectar a `192.168.1.48:17403`.

## Estructura
- `src/h-run.sh`, `src/h-config.sh`, `src/h-stats.sh`, `src/h-manifest.conf` — paquete custom miner.
- `flightsheet.json` — flight sheet importable (HiveOS → Flight Sheets → Import from Clipboard).
- `build_release.sh` — empaqueta `src/` + binario `kangaroo` y publica un release en GitHub.

> El binario `kangaroo` NO está en git (va en el release como asset). Compilar con JLP Kangaroo:
> `conda create -n kbuild -c nvidia cuda-nvcc=12.4 cuda-cudart-dev/static=12.4` y
> `make gpu=1 ccap=86 cudart_static` (portable, corre en HiveOS Ubuntu).

## Publicar una versión nueva (cambiar SERVER_IP, subir mejoras, etc.)
```bash
# Renombra el miner para esquivar la caché de HiveOS (p.ej. kangaroo135v3)
export GH_TOKEN=ghp_xxx
./build_release.sh kangaroo135v3 v4 /ruta/al/binario/kangaroo
# Luego edita flightsheet.json: miner_alt/miner = kangaroo135v3, install_url = .../v4/...
```

## Notas de red
- Rigs (HiveOS, LAN, NO Tailscale): server `192.168.1.48` (rigD79DCD, 9×A2000),
  cliente `192.168.1.49` (rigD79CED, 6×A2000+1×3070). Pi `192.168.1.60` y 3080 `192.168.1.45`
  están en la misma LAN; este PC Windows NO.
- El premio, si se resuelve, queda en `/hive/miners/custom/<nombre>/resultado135.txt` (clave
  privada) en el **server**. La wallet de la flight sheet es cosmética; Kangaroo no envía nada.
