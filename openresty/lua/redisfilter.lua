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
        end
        return nil
    end
end

--调用
init_redirects()
