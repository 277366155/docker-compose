
### FastDFS系统有三个角色：
- 跟踪服务器(Tracker Server)：跟踪服务器，主要做调度工作，起到均衡的作用；负责管理所有的 storage server和 group，每个 storage 在启动后会连接 Tracker，告知自己所属 group 等信息，并保持周期性心跳。

- 存储服务器(Storage Server)：存储服务器，主要提供容量和备份服务；以 group 为单位，每个 group 内可以有多台 storage server，数据互为备份。

- 客户端(Client)：上传下载数据的服务器，也就是我们自己的项目所部署在的服务器。

### docker容器启动完成以后需要进行一下操作：
1. 将tracker server的/etc/fdfs/client.conf配置做如下修改（可以在tracker_client_conf目录下.conf修改完成之后docker cp复制进去）：
```
track_server=[宿主机ip]:22122
```
2. tracker容器中/etc/fdfs目录下执行以下命令看是否成功：
```
fdfs_monitor client.conf
```
使用以下命令测试上传文件是否成功（报错时，百度错误信息解决方法）：
```
fdfs_upload_file client.conf xxx.txt
```
3. 创建nignx容器时，要修改/etc/nginx/nginx.conf配置中的local节点（脚本中已改好，挂载到容器中即可）：
```
location / {
    root /fastdfs/store_path/data;
    ngx_fastdfs_module;
}
```
4. FastDFS部署常见错误处理方式：https://www.modb.pro/db/162843
5. 本次发布参考资料：https://www.jb51.net/article/211928.htm
