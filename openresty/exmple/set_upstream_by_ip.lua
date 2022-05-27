#!/usr/bin/lua

local redis_host = "127.0.0.1"
local redis_port = 6380
-- key 为Redis的Set类型
local key = "td:stage:shops"


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

local function get_ip()
    local client_ip = ngx.req.get_headers()["X-Real-IP"]
    if client_ip == nil then
        client_ip = ngx.req.get_headers()["x_forwarded_for"]
    end

    if client_ip == nil then
        client_ip = ngx.var.remote_addr
    end

    return client_ip
end
local function get_header(key)
  local headers = ngx.req.get_headers();
  for k, v in pairs(headers) do
    -- ngx.log(ngx.ERR, "k is ", k, "v is ", v)
    if(k == key) then
        return v
    end
  end
  return "nil"
end

local function is_stage(ip)
    local result = 0
    local resty_redis = require "resty.redis"
    local redis = resty_redis:new()
    local ok, err = redis:connect(redis_host, redis_port)
    if err then
        colse_redis(redis)
        ngx.log(ngx.ERR, "Connect to redis failed ", err)
    else
        -- ngx.log(ngx.ERR, "Connect success")
        local _result, err = redis:sismember(key, ip)
        if err then
            ngx.log(ngx.ERR, "Get key failed", err)
        else
            result = _result
        end
    end

    if result == 1 then
        return true
    else
        return false
    end
end


-- IP
local default, stage = ...
local ngx_dic = ngx.shared.ips
local remote_ip = get_ip()
-- ngx.log(ngx.ERR, "Request ip is ", remote_ip, "\n")
result = ngx_dic:get(remote_ip)
-- ngx.log(ngx.ERR, "result is ", result)
if  result then
    return stage
else
    return default
end
