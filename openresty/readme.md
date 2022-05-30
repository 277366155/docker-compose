## 一、准备工作
#### 环境搭建，基础配置
使用docker容器搭建环境，docker-compose.yml如下内容：
```
version: '3'
services:
  yapi01:
    image: openresty/openresty
    privileged: true
    # build: ./
    container_name: openresty
    restart: always
    environment:
        TZ: Asia/Shanghai
    ports:
        - 80:80
    volumes:
        #可根据域名命名，添加conf配置文件，便于维护不同域名的配置信息
        - ./nginx/conf.d/:/etc/nginx/conf.d/
        #注意：需要先将docker中的nginx.conf文件拷贝出来，才能添加此文件映射
        - ./conf/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf
        #存放lua脚本文件
        - ./lua:/usr/local/openresty/nginx/lua
        #存放lua的调试日志error.log文件和nginx的access_log文件
        - ./logs:/usr/local/openresty/nginx/logs
```
注意，此时./conf/nginx.conf内容如下
> 其中 [ ++include /etc/nginx/conf.d/*.conf;++ ] 一行声明了/etc/nginx/conf.d/目录下的所有conf文件都被包含到nginx配置中：
```
# nginx.conf  --  docker-openresty
#
# This file is installed to:
#   `/usr/local/openresty/nginx/conf/nginx.conf`
# and is the file loaded by nginx at startup,
# unless the user specifies otherwise.
#
# It tracks the upstream OpenResty's `nginx.conf`, but removes the `server`
# section and adds this directive:
#     `include /etc/nginx/conf.d/*.conf;`
#
# The `docker-openresty` file `nginx.vh.default.conf` is copied to
# `/etc/nginx/conf.d/default.conf`.  It contains the `server section
# of the upstream `nginx.conf`.
#
# See https://github.com/openresty/docker-openresty/blob/master/README.md#nginx-config-files
#

# user  nobody;
# worker_processes 1;

# Enables the use of JIT for regular expressions to speed-up their processing.
pcre_jit on;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;
events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    
    # https://github.com/openresty/docker-openresty/issues/119
    client_body_temp_path /var/run/openresty/nginx-client-body;
    proxy_temp_path       /var/run/openresty/nginx-proxy;
    fastcgi_temp_path     /var/run/openresty/nginx-fastcgi;
    uwsgi_temp_path       /var/run/openresty/nginx-uwsgi;
    scgi_temp_path        /var/run/openresty/nginx-scgi;

    sendfile        on;
    # tcp_nopush     on;
    keepalive_timeout  65;

    # gzip  on;
    include /etc/nginx/conf.d/*.conf;
}
```

## 二、修改nginx的conf配置文件、及lua脚本
#### 1, 配置简单的转发策略
> 主要实现以/td-cloud/operation-service/开头的路由请求转发至api-java节点，其他的默认转发至api-net节点

./nginx/conf.d/目录下，创建一个test-api-local.xx.com.cn.conf文件，内容如下：
```
upstream api-net{
    server 128.0.202.105:1013   weight=100; 
}
upstream api-java{
    server 128.0.255.96:12402   weight=100;
}

server{
    listen 80;
    server_name test-api-local.xx.com.cn;
    access_log /usr/local/openresty/nginx/logs/test-api-local.xx.com.cn.log;

    # 匹配以/td-cloud/operation-service/开头的请求转向http://128.0.255.96:12402/页面。例如：
    # http://test-api-local.xx.com.cn/td-cloud/operation-service/ping.html 实际请求的是http://128.0.255.96:12402/ping.html
    location /td-cloud/operation-service/{
         proxy_pass http://api-java/;
    }
    location / {       
        default_type text/html;
        #其中jq_one对应着upstream设置的集群名称
        proxy_pass http://api-net/;
    }
```
执行nginx重新加载命令之后，验证即可成功：
> docker exec [containerId] nginx -s reload

#### 2，将redis中配置的url列表，转发至特定服务节点
##### 2.1，在nginx配置中的http节点下，声明一个字典变量，并声明在初始化阶段加载lua脚本
./nginx/conf.d/test-api-local.xx.com.cn.conf中添加以下内容：
```
# http节点下，声明共享内存区域，大小为50m
lua_shared_dict redirects 50m;
# http节点下，初始化阶段执行lua脚本内容
init_worker_by_lua_file /usr/local/openresty/nginx/lua/redisfilter.lua;

upstream api-net{
    server 128.0.202.105:1013   weight=100; 
}
......配置内容同上。此处省略
```
##### 2.2，在lua中实现读取redis，并将redis的set类型缓存数据读取到redirects变量中
```
#!/usr/bin/lua

local host="128.0.255.96"
local password=...
local port=6379
local db=1
local key ="redirect_to_java_api"

local function close_redis(red)
    if not red then
        return
    end
    local pool_max_idle_time = 100
    local pool_size = 20
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.log(ngx.ERR, "set keepalive err ", err)
    end
end
-- 连接redis
local function init_redirects()
    local val=ngx.var.uri
    local redis = require "resty.redis"
    local red =redis:new()
    red:set_timeout(1000) --1s
    local ok,err =red:connect(host,port)
    if err then
        close_redis(redis)
        --error日志会记录到logs/error.log中，用于调试
        ngx.log(ngx.ERR, "Connect to redis failed ", err)
        return nil,err24
    end
    --如果有配置密码，则进行密码验证
    if password ~=nil 
    then
        red:auth(password)
    end
    --切换到1号数据库
    red:select(db)
    -- result是列表 在lua中是table类型。可以打印type(result)查看
    local result, err = red:smembers(key)
    if err then
        ngx.log(ngx.ERR, "Get key failed:", err)
        return nil
    else
        local redirects=ngx.shared.redirects
        -- 清理原有的缓存
        redirects:flush_all()
        --遍历table，将table列写入缓存
        for id,member in pairs(result) do
            redirects:set(member,true)
            ngx.say(member.."<br/>")
        end
        return nil
    end
end

--调用
init_redirects()
```

##### 2.3，test-api-local.xx.com.cn.conf中增加location /redis配置
>  可以通过访问/redis，来重新执行redisfilter.lua脚本，以实现nginx缓存的刷新。调试时，可以通过lua中ngx.say()方法来打印调试内容
```
    ......
    location /td-cloud/operation-service/{
         proxy_pass http://api-java/;
    }
    
    location /redis {
        default_type text/html;
        lua_code_cache on;
        charset utf-8;
        # 限制只有指定ip可以访问此地址，用以重读redis配置、更新nginx缓存
        if ($remote_addr !~* "128.0.23.63") {
            return 403;
        }
        content_by_lua_file /usr/local/openresty/nginx/lua/redisfilter.lua;
    }

    location / {
    ......
```
##### 2.4，不匹配以“/td-cloud/operation-service/”开头的路由规则时，其他请求地址需要判断url是否存在于redis配置列表中，不存在则走默认net站点负载节点，存在则走特定的java站点负载节点
```
-- 先测试lua文件接收参数的方式，创建test.lua文件：
-- 用于演示：lua文档接收参数，并进行数据类型转换
-- 运行命令：ua test.lua 2
local default,second=...
if (tonumber(default)>1) then
    print("default"..default)
else
    print("what's wrong..")
end
```

创建set_upstream_by_uri.lua文件
> 接收两个不同的负载节点名称。判断当前url是否存在于redirects中，并根据逻辑返回不同的负载节点名
```
-- 声明两个变量，用于接收外部传参
-- 如：set_by_lua_file $backend /usr/local/openresty/nginx/lua/set_upstream_by_uri.lua star-net star-java;  
-- .lua文件后面的两个upstream名称传过来
local default_net,redirect_java=...
local redirect_dic=ngx.shared.redirects
local result=redirect_dic:get(ngx.var.uri)
if result then 
    return redirect_java
else
    return default_net
end
```
修改conf文件的location /节点。当前test-api-local.xx.com.cn.conf的完整内容如下：
```
# http节点下，声明共享内存区域，大小为50m
lua_shared_dict redirects 50m;
# http节点下，初始化阶段执行lua脚本内容
init_worker_by_lua_file /usr/local/openresty/nginx/lua/redisfilter.lua;

upstream api-net{
    server 128.0.202.105:1013   weight=100; 
}
upstream api-java{
    server 128.0.255.96:12402   weight=100;
}
server{
    listen 80;
    server_name test-api-local.xx.com.cn;

    access_log /usr/local/openresty/nginx/logs/test-api-local.xx.com.cn.log;

    # 匹配以/td-cloud/operation-service/开头的请求转向http://128.0.255.96:12402/页面。例如：
    # http://test-api-local.xx.com.cn/td-cloud/operation-service/ping.html 实际请求的是http://128.0.255.96:12402/ping.html
    location /td-cloud/operation-service/{
         proxy_pass http://api-java/;
    }
    
   # 可在白名单主机上运行定时任务，定时调用/redis接口，用以更新缓存
   location /redis {
        default_type text/html;
        lua_code_cache on;
        charset utf-8;
        # 限制只有指定ip可以访问此地址，用以重读redis配置、更新nginx缓存
        if ($remote_addr !~* "128.0.23.63") {
            return 403;
        }
        content_by_lua_file /usr/local/openresty/nginx/lua/redisfilter.lua;
    }

    location / {       
        default_type text/html;
        # charset utf-8;
        set_by_lua_file $backend /usr/local/openresty/nginx/lua/set_upstream_by_uri.lua api-net api-java;
        #其中jq_one对应着upstream设置的集群名称
        proxy_pass http://$backend;
    }
}
```
修改完成之后，执行命令让nginx重新加载配置：
> docker exec [containerId] nginx -s reload

==如果有报错，可以查看./logs/error.log中的报错信息和具体报错行数==