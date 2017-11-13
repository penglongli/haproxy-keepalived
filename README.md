# haproxy-keepalived
> If you want to use this image, you had better learned some of Docker、HAProxy、Keepalived, perhaps some Bash shell knowledge.

## Intro
Glad you can see this repo. If you are looking for an image that combine HAProxy and Keepalived, this repo can help you archieve this goal. 

`HAProxy` is used to setup a Load Balancer for TCP/HTTP applications. And `Keepalived` provides the characteristic of High-Availability for our `HAProxy` service.

Below link is the `haproxy-keepalived` image in docker-hub:
- [pelin/haproxy-keepalived](https://hub.docker.com/r/pelin/haproxy-keepalived/)

## Useage
This image has two-mode: `BIND`、`ENV`, default is `BIND`. Below will introduce the difference between the two modes, and how they are used.

### BIND
`BIND` mode can bind host's file with docker container's volume, such as HAProxy's and Keepalived's conf.

We can use docker-compose to up the `haproxy-keepalived`.

docker-compose.yml
```yml
version: '3'
services:

  haproxy-keepalived:
    image: "pelin/haproxy-keepalived"
    privileged: true
    network_mode: host
    restart: always
    volumes:
      - /data/keepalived.conf:/etc/keepalived/keepalived.conf
      - /data/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg
    environment:
      MODE: "BIND"
```
Then we can use `http://${host_ip}:1080/stats` to lookup `HAProxy` service's status.
(Port `1080` can see /haproxy/template.cfg)

### ENV
`ENV` mode can use docker environment variables to generate HAProxy's and Keepalived's conf.

We use docker-compose to up the `haproxy-keepalived`.

docker-compose.yml
```yml
version: '3'
services:

  haproxy-keepalived:
    image: "pelin/haproxy-keepalived"
    privileged: true
    network_mode: host
    restart: always
    environment:
      MODE: "ENV"
      KEEPALIVED_STATE: "MASTER"
      KEEPALIVED_INTERFACE: "ens18"
      KEEPALIVED_PRIORITY: "105"
      KEEPALIVED_V_ROUTER_ID: "40"
      KEEPALIVED_VIP: "192.168.0.40"
      haproxy_item1: |-
        listen app-1
            bind *:4000
            mode http
            maxconn 300
            balance roundrobin
            server server1 192.168.0.21:4001 maxconn 300 check
            server server2 192.168.0.22:4002 maxconn 300 check
      haproxy_item2: |-
        listen app-2
            bind *:5000
            mode http
            maxconn 300
            balance roundrobin
            server server1 192.168.0.21:5001 maxconn 300 check
            server server2 192.168.0.22:5002 maxconn 300 check
```
From above, we add some envs rather than use docker volumes. Below is the meaning of above environment variables:
- KEEPALIVED_STATE: Start-up default state
- KEEPALIVED_INTERFACE: Keepalived Binding interface
- KEEPALIVED_PRIORITY: Keepalived node priority
- KEEPALIVED_V_ROUTER_ID: String identifying router
- KEEPALIVED_VIP: Virtual ip
- haproxy_item1: haproxy's item, can haproxy_item2、haproxy_item3、haproxy_item4, for custom your own haproxy-conf

## Extend
In this image, it extends a feature. If you want to use HAProxy only rather than `haproxy & keepalived`, you can set `HAPROXY_ONLY=true` in docker env.

## Discuss
If you have some problem about useage or some suggestion, welcome to create an ISSUE: https://github.com/penglongli/haproxy-keepalived/issues

## LICENSE
Based on [MIT LICENSE](https://github.com/penglongli/haproxy-keepalived/blob/master/LICENSE)

You can fork it or reference it for custom your own `haproxy-keepalived` image.
