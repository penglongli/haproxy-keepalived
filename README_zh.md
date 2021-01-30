# haproxy-keepalived [v1.0.0]

> Refactored, make it great again. And add support for Kubernetes

* [For Docker](#for-docker)
* [For Kubernetes](#for-kubernetes)
* [Dynamic Reload HAProxy](#dynamic-reload-haproxy)
    * [OS Signal](#os-signal)
    * [Reload Command](#reload-command)
    * [Kill Signal](#kill-signal)
* [Logging](#logging)
* [License](#license)

HAProxy with Keepalived for Docker and Kubernetes

DockerHub: https://hub.docker.com/r/pelin/haproxy-keepalived/

| Version | HAProxy | Keepalived |
| ------- | ------- | ---------- |
| v1.0.0  | v2.3.4  | v1.3.9     |

## For Docker

如果仅使用 Docker 来做部署，需要将 HAProxy 和 Keepalived 的配置文件存放到宿主机上。

下边是一个例子，用户需要修改 `keepalived.conf` 来适配自己的环境。

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
    interface eth0               # 将此处修改为个人主机的网卡
    virtual_router_id 40         # 修改此处的 router_id
    priority 110                 # 修改此处的 priority
    virtual_ipaddress {
        172.20.10.16             # 修改此处的虚拟 IP
    }
    nopreempt
}
``` 

在如上配置文件准备好之后，通过下述命令即可拉起来 haproxy-keepalived.

```bash
docker run -it -d --name haproxy-keepalived --net=host --privileged \
    -v /root/haproxy-keepalived/haproxy/:/usr/local/etc/haproxy/ \
    -v /root/haproxy-keepalived/keepalived/:/etc/keepalived/ \
    pelin/haproxy-keepalived:v1.0.0
```

在拉起来后，可以通过 `docker logs` 来查看日志是否出现错误。如果 HAProxy 或 Keepalived 进程挂掉，则容器会自动结束。

如果一切正常，此时虚拟 IP 是可以 PING 通的。

在第一个节点起来后，就可以修改 Keepalived 的配置，然后去启动后续其它节点。

## For Kubernetes

**如果使用 Kubernetes，需要保证每一个 Pod 中的 Keepalived 配置是不相同的**

使用 Kubernetes 的一个示例： [deploy/kubernetes](deploy/kubernetes)

在示例中，可以看到 keepalived-conf 这个 ConfigMap 里边的 Data 名称是动态的（使用 NODE_NAME 来动态调整）

如下示例，keepalived.conf-localhost.localdomain 名称是：keepalived.conf-${NODE_NAME} 

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

在 `daemonset.yaml` 中，在挂载 Keepalived 配置的时候，同样需要使用 NODE_NAME 来做动态调整

```bash
volumeMounts:
  - name: keepalivedconf
    mountPath: /etc/keepalived/keepalived.conf
    subPathExpr: keepalived.conf-$(NODE_NAME)        # The subpath is dynamic
```

## Dynamic Reload HAProxy

在 Docker 或者 Kubernetes 中，挂载的 HAProxy 配置是通过挂载映射进容器的。

当对配置做了修改后，此处可以通过 3 种方式来做动态更新

### OS Signal

可以使用如下方式来刷新：

```bash
docker kill -s HUP haproxy-keepalived
```

容器会接收 `SIGHUP` 信号，并去处理动态更新

### Reload Command

通过 exec 进入容器，使用 `haproxy-keepalived reload` 命令来刷新配置

```bash
[root@localhost ~]# kubectl exec -it haproxy-keepalived-6zrjz sh
/ # /haproxy-keepalived reload
I0122 23:38:40.769526      36 server.go:79] HAProxy Reloaded.
/ #
```

### Kill Signal

用户也可以在 exec 进入容器后，通过如下命令来刷新配置
```bash
kill -SIGUSR2 $(pidof haproxy)
```

## Logging

容器中使用了 rsyslogd，所有 HAProxy 的日志可以在 `/var/log/haproxy.log` 中查看。

## Discuss
If you have some problem about useage or some suggestion, welcome to create an ISSUE

## LICENSE
Based on [MIT LICENSE](https://github.com/penglongli/haproxy-keepalived/blob/master/LICENSE)

You can fork it or reference it for custom your own `haproxy-keepalived` image.
