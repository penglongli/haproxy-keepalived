#!/bin/sh

# graceful shutdown
trap "graceful_shutdown; exit 0;" SIGTERM SIGINT
graceful_shutdown() {
    echo "[INFO] SIGTERM caught, terminating <haproxy & keepalived> process..."
    stop_process
    echo "[INFO] haproxy-keepalived graceful shutdown successfully."
}
stop_process() {
    stop_haproxy
    stop_keepalived
}

KEEPALIVED_LAUNCH="keepalived --dont-fork --dump-conf --log-console --log-detail --log-facility 7 --vrrp -f /etc/keepalived/keepalived.conf"
# start keepalived
start_keepalived() {
    echo "[INFO] Keepalived is starting."
    eval ${KEEPALIVED_LAUNCH} &
}

# stop keepalived
stop_keepalived() {
    count=1

    k_pid=$(pidof keepalived)
    kill -TERM $k_pid > /dev/null 2>&1
    while true; do
        sleep 3
        
        k_pid=$(pidof keepalived)
        if [ ! -n "$k_id" ]; then
            break
        fi
       
        if [ ${count} -gt 5 ]; then
            echo "[Error] Keepalived stop failed."
            return
        fi
        kill -TERM $k_pid > /dev/null 2>&1
     done
     echo "[INFO] Keepalived terminated." 
#    kill -TERM $(cat /var/run/vrrp.pid)
#    kill -TERM $(cat /var/run/keepalived.pid)
}

HAPROXY_LAUNCH="/usr/local/sbin/haproxy -p /run/haproxy.pid -db -f /usr/local/etc/haproxy/haproxy.cfg -Ds"
# start haproxy
start_haproxy() {
    echo "[INFO] HAProxy is starting."
    eval ${HAPROXY_LAUNCH} &
    echo "[INFO] HAProxy started."
}

# stop haproxy
stop_haproxy() {
    kill -s SIGUSR1 $(pidof haproxy) > /dev/null 2>&1
    echo "[INFO] HAProxy terminated."
}

start_haproxy
start_keepalived

sleep 10

# while-loop to ensure haproxy & keepalived health.
while true; do
    h_pid=$(pidof haproxy)
    k_pid=$(pidof keepalived)

    if [ ! -n "$h_pid" ] || [ ! -n "$k_pid" ]; then
        # when one crash, graceful shutdown
        echo "[Error] one process crashed, will shutdown."
        stop_process
        break
    fi
    sleep 5
done

exit 1

