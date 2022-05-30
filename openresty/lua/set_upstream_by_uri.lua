-- 声明两个变量，用于接收外部传参
-- 如：set_by_lua_file $backend /usr/local/openresty/nginx/lua/set_upstream_by_uri.lua api-net api-java;  
-- 将lua文件后面的两个upstream名称传过来
local default_net,redirect_java=...
local redirect_dic=ngx.shared.redirects
local result=redirect_dic:get(ngx.var.uri)
if result then 
    return redirect_java
else
    return default_net
end
