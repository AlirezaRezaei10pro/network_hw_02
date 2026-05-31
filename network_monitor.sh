#!/bin/bash

# network_monitor.sh - Network Statistics Monitor
# هر 5 ثانیه آمار شبکه را نمایش می‌دهد و به فایل log می‌نویسد

LOG_FILE="monitoring_log.txt"
INTERVAL=5
INTERFACE="${1:-}"   # می‌توان interface را به عنوان آرگومان داد

# ─── رنگ‌ها ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── پیدا کردن interface پیش‌فرض ─────────────────────────
get_default_interface() {
    ip route 2>/dev/null | awk '/^default/ {print $5; exit}' \
    || route -n 2>/dev/null | awk '/^0\.0\.0\.0/ {print $8; exit}' \
    || echo "eth0"
}

[ -z "$INTERFACE" ] && INTERFACE=$(get_default_interface)

# ─── خواندن bytes از /proc/net/dev ─────────────────────────
get_bytes() {
    local iface="$1"
    local dir="$2"   # rx یا tx
    awk -v iface="$iface:" -v dir="$dir" '
    $1 == iface {
        if (dir == "rx") print $2
        else             print $10
    }' /proc/net/dev 2>/dev/null || echo 0
}

# ─── فرمت bytes ─────────────────────────────────────────────
format_bytes() {
    local bytes=$1
    if   [ "$bytes" -ge 1073741824 ]; then printf "%.2f GB" "$(echo "scale=2; $bytes/1073741824" | bc)"
    elif [ "$bytes" -ge 1048576 ];    then printf "%.2f MB" "$(echo "scale=2; $bytes/1048576"    | bc)"
    elif [ "$bytes" -ge 1024 ];       then printf "%.2f KB" "$(echo "scale=2; $bytes/1024"       | bc)"
    else printf "%d B" "$bytes"
    fi
}

# ─── شمردن اتصالات فعال ─────────────────────────────────────
count_connections() {
    ss -tn state established 2>/dev/null | tail -n +2 | wc -l \
    || netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l \
    || echo 0
}

# ─── پیدا کردن Top 5 IP با بیشترین traffic ──────────────────
get_top_ips() {
    # اگر ss در دسترس باشد
    ss -tn state established 2>/dev/null | tail -n +2 \
    | awk '{print $5}' \
    | sed 's/:[0-9]*$//' \
    | sort | uniq -c | sort -rn | head -5 \
    | awk '{printf "  %3d connections - %s\n", $1, $2}'
}

# ─── لاگ کردن ───────────────────────────────────────────────
log() {
    local msg="$1"
    echo -e "$msg" | sed 's/\x1B\[[0-9;]*m//g' >> "$LOG_FILE"
}

# ─── بنر شروع ───────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║        Network Monitor - تمرین هشتم          ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo -e " Interface : ${GREEN}$INTERFACE${RESET}"
echo -e " Log File  : ${GREEN}$LOG_FILE${RESET}"
echo -e " Interval  : ${GREEN}${INTERVAL}s${RESET}"
echo -e " Press ${RED}Ctrl+C${RESET} to stop\n"

log "====== Network Monitor Started: $(date) ======"
log "Interface: $INTERFACE | Interval: ${INTERVAL}s"
log "=============================================="

# ─── مقادیر اولیه برای محاسبه bandwidth ─────────────────────
PREV_RX=$(get_bytes "$INTERFACE" rx)
PREV_TX=$(get_bytes "$INTERFACE" tx)
PREV_TIME=$(date +%s%N)

sleep "$INTERVAL"

# ─── حلقه اصلی ──────────────────────────────────────────────
while true; do
    NOW=$(date +%s%N)
    CUR_RX=$(get_bytes "$INTERFACE" rx)
    CUR_TX=$(get_bytes "$INTERFACE" tx)

    # محاسبه delta
    ELAPSED_NS=$(( NOW - PREV_TIME ))
    ELAPSED_S=$(echo "scale=3; $ELAPSED_NS / 1000000000" | bc)

    DIFF_RX=$(( CUR_RX - PREV_RX ))
    DIFF_TX=$(( CUR_TX - PREV_TX ))

    # محاسبه نرخ (bytes per second)
    RX_RATE=$(echo "scale=0; $DIFF_RX / $ELAPSED_S" | bc 2>/dev/null || echo 0)
    TX_RATE=$(echo "scale=0; $DIFF_TX / $ELAPSED_S" | bc 2>/dev/null || echo 0)

    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    CONNECTIONS=$(count_connections)

    # ─── نمایش در terminal ──────────────────────────────────
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║        Network Monitor - $TIMESTAMP   ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"

    echo -e "\n${BOLD}[1] Interface Stats: $INTERFACE${RESET}"
    echo -e "   Total RX (received): $(format_bytes $CUR_RX)"
    echo -e "   Total TX (sent):     $(format_bytes $CUR_TX)"

    echo -e "\n${BOLD}[2] Bandwidth Usage (last ${INTERVAL}s):${RESET}"
    echo -e "   ↓ Download: ${GREEN}$(format_bytes $RX_RATE)/s${RESET}  (${DIFF_RX} bytes in ${ELAPSED_S}s)"
    echo -e "   ↑ Upload:   ${YELLOW}$(format_bytes $TX_RATE)/s${RESET}  (${DIFF_TX} bytes in ${ELAPSED_S}s)"

    echo -e "\n${BOLD}[3] Active Connections:${RESET}"
    echo -e "   ${CYAN}$CONNECTIONS${RESET} established connections"

    echo -e "\n${BOLD}[4] Top 5 IPs by Active Connections:${RESET}"
    TOP_IPS=$(get_top_ips)
    if [ -n "$TOP_IPS" ]; then
        echo -e "${CYAN}$TOP_IPS${RESET}"
    else
        echo "   (no data available - may need root for ss)"
    fi

    echo -e "\n${RESET}Next update in ${INTERVAL}s... | Log: $LOG_FILE"

    # ─── لاگ کردن ────────────────────────────────────────────
    log ""
    log "[$TIMESTAMP]"
    log "  Interface: $INTERFACE"
    log "  Total RX: $(format_bytes $CUR_RX) | Total TX: $(format_bytes $CUR_TX)"
    log "  Download: $(format_bytes $RX_RATE)/s | Upload: $(format_bytes $TX_RATE)/s"
    log "  Active Connections: $CONNECTIONS"
    if [ -n "$TOP_IPS" ]; then
        log "  Top IPs:"
        log "$TOP_IPS"
    fi
    log "---"

    # ذخیره مقادیر فعلی برای دور بعد
    PREV_RX=$CUR_RX
    PREV_TX=$CUR_TX
    PREV_TIME=$NOW

    sleep "$INTERVAL"
done
