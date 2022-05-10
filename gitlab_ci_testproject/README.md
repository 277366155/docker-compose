## 关于修改gitlab-runner默认目录的说明
1, centos系统下gitlab-runner的工作目录默认为 /home/gitlab-runner。runner拉取的gitlab仓库本地目录也会建在/home/gitlab-runner/builds/下

2, 如果不想使用runner的默认目录路径，可以通过修改/etc/gitlab-runner/config.toml配置来指定自定义路径(windows下在D:\Tools\gitrunner\config.toml)，注意修改之后需要重启服务++systemctl restart gitlab-runner++：

==修改前：==

    ```
    concurrent = 1
    check_interval = 0

    [session_server]
    session_timeout = 1800

    [[runners]]
    name = "k8s-node1-server"
    url = "https://code.td365.com.cn/"
    token = "U-DmkZ8o-xh23nvq9dMG"
    executor = "shell"
    [runners.custom_build_dir]
    [runners.cache]
        [runners.cache.s3]
        [runners.cache.gcs]
        [runners.cache.azure]
    ```

==修改后：==
```
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "k8s-node1-server"
  url = "https://code.td365.com.cn/"
  token = "U-DmkZ8o-xh23nvq9dMG"
  executor = "shell"
  builds_dir = "/data/testproject"
  [runners.custom_build_dir]
    enalbe = true
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
```
但注意，自定义的目录，其目录下仍然会被创建例如这样的子目录(/data/testproject/U-DmkZ8o/0/testgroup/testproject)：
```
.
└── U-DmkZ8o
    └── 0
        └── testgroup
            ├── testproject
            │   ├── docker-compose.yml
            │   └── src
            │       ├── config.py
            │       ├── Dockerfile
            │       ├── main.py
            │       └── __pycache__
            │           └── config.cpython-37.pyc
            └── testproject.tmp
                └── git-template
                    └── config
```

3, 修改路径之后，执行.gitlab-ci.yml会提示gitlab-runner在创建目录的时候没有权限。需要进行以下命令操作：
```
ps aux|grep gitlab-runner  #查看当前runner用户
 
sudo gitlab-runner uninstall  #删除gitlab-runner
 
gitlab-runner install --working-directory /home/gitlab-runner --user root   #安装并设置--user(例如我想设置为root)
 
sudo service gitlab-runner restart  #重启gitlab-runner
 
ps aux|grep gitlab-runner #再次执行会发现--user的用户名已经更换成root了
```

