#!/bin/bash
set -e

trap "stop; exit 0;" SIGTERM SIGINT
# handler for SIGINT & SIGITEM
stop() {
    echo "SIGTERM caught, terminating <haproxy & keepalived> process..."

    # terminate haproxy
    h_pid=$(pidof haproxy)

    kill -TERM $h_pid > /dev/null 2>&1
    echo "HAProxy had terminated."

    # terminate keepalived
    k_pid=$(pidof keepalived)

    kill -TERM $k_pid > /dev/null 2>&1
    echo "Keepalived had terminated."

    echo "haproxy-keepalived service instance is successfuly terminated!"
}

mode_env() {
    # init haproxy
    /bin/bash -c /haproxy/haproxy_cfg_init.sh

    # if $HAPROXY_ONLY is not true, init keepalived conf ($HAPROXY_ONLY default is null)
    if [ "$HAPROXY_ONLY" != true ]; then
        # init keepalived
        /bin/bash -c /keepalived/init_keepalived_conf.sh
    fi
}

# If mode is null or error value
if [ "$MODE" = "ENV"  ]; then
    eval mode_env
fi

# exec haproxy entrypoint
exec /docker-entrypoint.sh "$@" &

# if $HAPROXY_ONLY is not true, start keepalived
if [ "$HAPROXY_ONLY" != true ]; then
    # start keepalived
    exec /start_keepalived.sh "$@" &
fi

# wait <haproxy & keepalived> service started
sleep 5

while true; do
  h_pid=$(pidof haproxy)

  # if h_pid is non-null, sleep; otherwise, break the cycle;
  while [ -n "$h_pid" ]; do
    sleep 1
  done
  
  break
done

# if haproxy is crashed, exit entrypoint
wait $h_pid
echo "Haproxy service is no longer running, exiting..."

exit 0;