# haproxy-keepalived [v1.0.0]

> Refactored, make it great again. And add support for Kubernetes

* [For Docker](#for-docker)
* [For Kubernetes](#for-kubernetes)
* [Dynamic Reload HAProxy](#dynamic-reload-haproxy)
    * [OS Signal](#os-signal)
    * [Reload Command](#reload-command)
    * [Kill Signal](#kill-signal)
* [Logging](#help-improving-the-documents)

HAProxy with Keepalived for Docker and Kubernetes

DockerHub: https://hub.docker.com/r/pelin/haproxy-keepalived/

| Version | HAProxy | Keepalived |
| ------- | ------- | ---------- |
| v1.0.0  | v2.3.4  | v1.3.9     |

## For Docker

For Docker, you need to set HAProxy and Keepalived config file in host.

Below is an example, you should change `Keepalived.conf` for yourself.

``` bash
~$ cat /root/haproxy-keepalived/haproxy/haproxy.cfg
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

listen test
    bind *:6666
    mode http
    maxconn 10000
    balance roundrobin
    server server1 127.0.0.1:1080 maxconn 10000 check

listen stats
    bind *:1080
    mode http
    stats refresh 30s
    stats uri /stats

~$ cat /root/haproxy-keepalived/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER                 # Keepalived state.
    interface eth0               # Please replace this interface for yourself
    virtual_router_id 40         # Please replace this id for yourself
    priority 110                 # Please replace this value for yourself
    virtual_ipaddress {
        172.20.10.16             # Please replace this VIP for yourself
    }
    nopreempt
}
``` 

And then, you can run a container with Docker
```bash
docker run -it -d --name haproxy-keepalived --net=host --privileged \
    -v /root/haproxy-keepalived/haproxy/:/usr/local/etc/haproxy/ \
    -v /root/haproxy-keepalived/keepalived/:/etc/keepalived/ \
    pelin/haproxy-keepalived:v1.0.0
```

You can use `docker logs -f haproxy-keepalived` to see if any errors has occurred.

If everything is ok, you can ping `172.20.10.16`.

After start the first node, you can change keepalived.conf and start another node.

## For Kubernetes

**If you want it for Kubernetes, you should confirm that the Keepalived config is different between nodes.** 

There is an example in [deploy/kubernetes](deploy/kubernetes)

You can see the data of `keepalived-conf` ConfigMap is dynamic with NODE_NAME
```bash
---
...
metadata:
  name: keepalived-conf
  namespace: default
data:
  keepalived.conf-localhost.localdomain: |    # The name is dynamic with NODE_NAME
...
```

In `daemonset.yaml`, the volumeMount subPath is dynamic with NODE_NAME too.
```bash
volumeMounts:
  - name: keepalivedconf
    mountPath: /etc/keepalived/keepalived.conf
    subPathExpr: keepalived.conf-$(NODE_NAME)        # The subpath is dynamic
```

## Dynamic Reload HAProxy

Users can reload HAProxy in trhee ways as below

### OS Signal

You can use `docker kill -s HUP haproxy-keepalived` to reload HAProxy, if config is changed.

The container will handle `SIGHUP` signal.

### Reload Command

Exec to the container, and then reload.
```bash
[root@localhost ~]# kubectl exec -it haproxy-keepalived-6zrjz sh
/ # /haproxy-keepalived reload
I0122 23:38:40.769526      36 server.go:79] HAProxy Reloaded.
/ #
```

### Kill Signal

Also you can exec into contaienr, and exec `kill -SIGUSR2 $(pidof haproxy)` to reload.

## Logging

The HAProxy log path: /var/log/haproxy.log



## Discuss
If you have some problem about useage or some suggestion, welcome to create an ISSUE

## LICENSE
Based on [MIT LICENSE](https://github.com/penglongli/haproxy-keepalived/blob/master/LICENSE)

You can fork it or reference it for custom your own `haproxy-keepalived` image.
