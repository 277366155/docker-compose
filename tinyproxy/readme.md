
### docker run 命令运行方法
```
docker run -d --name='tinyproxy' -p 6666:8888 dannydirect/tinyproxy:latest ANY
docker run -d --name='tinyproxy' -p 7777:8888 dannydirect/tinyproxy:latest 87.115.60.124
docker run -d --name='tinyproxy' -p 8888:8888 dannydirect/tinyproxy:latest 10.103.0.100/24 192.168.1.22/16
```

> 命令中的arg参数在docker-compose.yml中应配置到command节点
