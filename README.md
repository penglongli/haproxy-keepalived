# haproxy-keepalived [latest]

HAProxy with Keepalived base on Docker(Old version look `old` branch).

With `start.sh`, added graceful shutdown with it. And haproxy will print log with rsyslog.

## Usage ([DockerHub](https://hub.docker.com/r/pelin/haproxy-keepalived/))

This image use host config file, and then run it:

```bash
docker run -it -d --net=host --privileged \
    -v ${HAPROXY_CONFIG_FILE}:/usr/local/etc/haproxy/haproxy.cfg \
    -v ${KEEPALIVED_CONFIG_FILE}:/etc/keepalived/keepalived.conf \
    --name haproxy-keepalived \
    pelin/haproxy-keepalived
```


## Example

haproxy.cfg:
```
global
    daemon
    maxconn 30000
    log 127.0.0.1 local0 debug

defaults
    log global
    option tcplog
    maxconn 30000
    timeout connect 30000
    timeout client 1800000
    timeout server 1800000
    timeout check 1000
    log-format %ci\ [id=%ID]\ [%t]\ %f\ %b/%s\ %Tq/%Tw/%Tc/%Tr/%Tt\ %ST\ %B\ %CC\ %CS\ %tsc\ %ac/%fc/%bc/%sc/%rc\ %sq/%bq\ {%hrl}\ {%hsl}\ %{+Q}r

listen stats
    bind *:1080
    mode http
    stats refresh 30s
    stats uri /stats
```

keepalived.conf
```
vrrp_script chk_haproxy {
    script "/usr/local/bin/chk_haproxy.sh"
    interval 2
    weight 2
    rise 2
    fall 2
}

vrrp_instance VI_1 {
    state MASTER                # keepalived state
    interface eth0              # replace this with your interface
    virtual_router_id 40        
    priority 110
    track_interface {
        eth0                    # replace this with your interface
    }
    virtual_ipaddress {
        10.214.67.231           # replace this with your virtual IP
    }
    track_script {
        chk_haproxy
    }
    nopreempt
}

```

And then run it:
```bash
docker run -it -d --net=host --privileged \
    -v /data/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
    -v /data/keepalived.conf:/etc/keepalived/keepalived.conf \
    --name haproxy-keepalived \
    pelin/haproxy-keepalived
```

You can use `docker logs -f haproxy-keepalived` to look.

After start the first node, you can change `keepalived.conf` to start other nodes.

## Discuss
If you have some problem about useage or some suggestion, welcome to create an ISSUE

## LICENSE
Based on [MIT LICENSE](https://github.com/penglongli/haproxy-keepalived/blob/master/LICENSE)

You can fork it or reference it for custom your own `haproxy-keepalived` image.
