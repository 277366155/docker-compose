##### 容器启动失败时
> 可以通过docker logs xxx 查看对应的打印信息



### ES查询常用接口
1, 查询所有索引
> get: {{ESUrl}}/_cat/indices?v

2, 查询ES服务器运行情况
> get: {{ESUrl}}/_cat/allocation?v

3, 创建索引
> put: {{ESUrl}}/boo_database

body:
```
{
    "settings":{
        "number_of_shards":"2",
        "number_of_replicas":"0"
    }
}
```
4, 更新索引的设置
> put: {{ESUrl}}/boo_database/_settings

body:
```
{
    "number_of_replicas":"2"    
}
```
5, 删除索引
> delete: {{ESUrl}}/boo_database

6, 查询指定索引下的所有数据
> get: {{ESUrl}}/boo_database/_search

7, 新增或者覆盖数据
> put: {{ESUrl}}/boo_database/_doc/102
```
{
    "id":"002",
    "name":"你好，我是Boo，在深圳工作 前面有个空格"
}
```
8, 查询指定id的数据
> get: {{ESUrl}}/boo_database/_doc/101

9, 删除指定数据
> delete: {{ESUrl}}/ropledata/_doc/101

10, standard分词
> post: {{ESUrl}}/_analyze
```
{
    "analyzer":"standard",
    "text":"你好，我是Boo，在深圳工作 前面有个空格"
}
```
11, 查询文档属性拆分分析
> post: {{ESUrl}}/boo_database/_analyze
```
{
    "analyzer":"simple",
    "field":"name",
    "text":"你好，我是Boo，在深圳工作 前面有个空格"
}
```
12, whitespace分词器
> post: {{ESUrl}}/boo_database/_analyze
```
{
    "analyzer":"whitespace",
    "text":"你好，我是Boo，在深圳工作 前面有个空格"
}
```
13, simple分词器
> post: {{ESUrl}}/boo_database/_analyze
```
{
    "analyzer":"simple",
    "text":"你好，我是Boo，在深圳工作 前面有个da空格"
}
```
14, stop分词器
> post: {{ESUrl}}/boo_database/_analyze
```
{
    "analyzer":"stop",
    "text":"你好，我是Boo，在深圳工作 前面有个da空格"
}
```
15, keyword分词器
> post: {{ESUrl}}/boo_database/_analyze
```
{
    "analyzer":"keyword",
    "text":"你好，我是Boo，在深圳工作 前面有个da空格"
}
```