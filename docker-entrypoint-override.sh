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
  kill -TERM $(cat /var/run/vrrp.pid)
  kill -TERM $(cat /var/run/keepalived.pid)
  echo "Keepalived had terminated."

  echo "haproxy-keepalived service instance is successfuly terminated!"
}

# init haproxy & keepalived conf
/bin/bash -c /haproxy/haproxy_cfg_init.sh
/bin/bash -c /keepalived/init_keepalived_conf.sh

# exec haproxy entrypoint
exec /docker-entrypoint.sh "$@" &

# start keepalived
exec /start_keepalived.sh "$@" &

# wait <haproxy & keepalived> service started
sleep 10

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

