#!/usr/bin/lua

local host = "xx.rds.aliyuncs.com"
local password = "1qazTest"
local port = 6379
local db_num = 1
local key = "CloudPOS:xx_TenantIPList"
local key2 = "CloudPOS:xx_TenantIds"



local function init_tenantids(redis_key)
    local cmd = string.format("echo 'smembers %s' | redis-cli -h %s -p %d -a %s -n %d", redis_key, host, port, password, db_num)
    local f = io.popen(cmd)
    local tenantids = ngx.shared.tenantids
    tenantids:flush_all()
    local line = f:read()
    while line do
      tenantids:set(line, true)
      -- print(line)
      line = f:read()
    end
    f:close()
end


local function init_ips(redis_key)
    local cmd = string.format("echo 'smembers %s' | redis-cli -h %s -p %d -a %s -n %d", redis_key, host, port, password, db_num)
    local f = io.popen(cmd)
    local ips = ngx.shared.ips
    ips:flush_all()
    local line = f:read()
    while line do
        ips:set(line, true)
        -- print("ip is ", line)
	line = f:read()
    end
    f:close()
end


local function init_xy_tenantids(redis_key)
    local db_num = 2
    local cmd = string.format("echo 'smembers %s' | redis-cli -h %s -p %d -a %s -n %d", redis_key, host, port, password, db_num)
    local f = io.popen(cmd)
    local tenantids = ngx.shared.xy_tenantids
    tenantids:flush_all()
    local line = f:read()
    while line do
      tenantids:set(line, true)
      -- print(line)
      line = f:read()
    end
    f:close()
end


local function init_xy_ips(redis_key)
    local db_num = 2
    local cmd = string.format("echo 'smembers %s' | redis-cli -h %s -p %d -a %s -n %d", redis_key, host, port, password, db_num)
    local f = io.popen(cmd)
    local ips = ngx.shared.xy_ips
    ips:flush_all()
    local line = f:read()
    while line do
        ips:set(line, true)
        -- print("ip is ", line)
	line = f:read()
    end
    f:close()
end


-- xx
init_tenantids(key2)
init_ips(key)
-- xy
init_xy_tenantids(key2)
init_xy_ips(key)
