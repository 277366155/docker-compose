-- 用于演示：lua文档接收参数，并进行数据类型转换
-- 运行命令：lua test.lua 2
local default,second=...
-- 字符串转为number类型
if (tonumber(default)>1) then
    print("default"..default)
else
    print("what's wrong..")
end