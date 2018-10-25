#!/bin/sh
set -e

# graceful shutdown
trap "stop; exit 0;" SIGTERM SIGINT
stop() {
    echo "[INFO] SIGTERM caught, terminating <haproxy & keepalived> process..."

    # terminate haproxy
    h_pid=$(pidof haproxy)

    kill -TERM $h_pid > /dev/null 2>&1
    echo "[INFO] HAProxy terminated."

    # terminate keepalived
    k_pid=$(pidof keepalived)

    kill -TERM $k_pid > /dev/null 2>&1
    echo "[INFO] Keepalived terminated."

    echo "[INFO] haproxy-keepalived graceful shutdown successfully."
}

KEEPALIVED_LAUNCH="keepalived --dont-fork --dump-conf --log-console --log-detail --log-facility 7 --vrrp -f /etc/keepalived/keepalived.conf"
count=1
# start keepalived
start_keepalived() {
    echo "[INFO] Keepalived is starting."
    eval ${KEEPALIVED_LAUNCH} &
    while true; do
        # wait keepalived started
        sleep 5

        k_pid=$(pidof keepalived)
        if [ -n "$k_id" ]; then
            break
        fi

        if [ ${count} > 3 ]; then
            echo "[Error] Keepalived start failed! Exit -1."
            exit -1
        fi
        
        # if failed, kill vrrp.pid & keepliaved.pid
        stop_keepalived
        echo "[Warning] Keepalived start failed, attempting restart(${count})..."
        eval ${KEEPALIVED_LAUNCH} &
        count++
    done

    echo "[INFO] Keepalived started."
}

# stop keepalived
stop_keepalived() {
    kill -TERM $(cat /var/run/vrrp.pid)
    kill -TERM $(cat /var/run/keepalived.pid)
}

HAPROXY_LAUNCH="/usr/local/sbin/haproxy -p /run/haproxy.pid -db -f /usr/local/etc/haproxy/haproxy.cfg -Ds"
# start haproxy
start_haproxy() {
    echo "[INFO] HAProxy is starting."
    eval ${HAPROXY_LAUNCH}
    echo "[INFO] HAProxy started."
}

start_keepalived
start_haproxy  &

sleep 10

# while-loop to ensure haproxy & keepalived health.
while true; do
    h_pid=$(pidof haproxy)
    k_pid=$(pidof keepalived)

    if [ ! -n "$h_pid" ] || [ ! -n "$k_pid" ]; then
        break
    fi
    sleep 10
done

exit -1;
