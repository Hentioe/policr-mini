# POLICR MINI 开发分支更新说明&更新教程

## 介绍

自 2021 年 12 月底起，[policr-mini](https://github.com/Hentioe/policr-mini) 项目的开发几乎停滞了，这是因为新的代码不再向 master 分支合并（或直接提交）了。考虑到零零碎碎的更新和频繁的升级并不是非常有必要的，还会致使机器人可靠性降低。

而新的代码长期以来都在另一个重要的次分支 [develop](https://github.com/Hentioe/policr-mini/tree/develop) 上继续提交，并且直到本文的发布也没有合并到主分支，也没有上线到官方实例中。大量的更新如果一次上线，因为长久未大规模测试，是非常危险的。所以短期内本文的更新并不会上线到官方实例中，**自行部署的用户可以更新到开发分支帮助测试**，以让更新能早日上线官方实例。

## 更新教程

一般来讲，部署 policr-mini 的方式几乎都是通过 Docker 和 docker-compose，因为这是官方教程中的内容。在 Docker 中，镜像是由某个集中式的 registry 服务器负责存储和分发的，当前的 registry 就是官方的 [DockerHub](https://hub.docker.com/)，所以你仍然能直接通过 `docker pull` 命令简单的升级镜像。

在 registry 中是如果定位某个镜像的呢？镜像由 `organization/image:tag` 组成，如果 tag 缺失，那么默认以 `latest` 替代。拿此前的镜像 bluerain/policr-mini 来举例，此处的 `blueran` 就是 organization（组织名），`policr-mini` 就是该组织下的镜像，而 tag 就是缺省的 `latest`。

自本文发表开始，之前的组织已被废弃（但未删除），镜像不会再更新（也有可能保持短期内的更新支持）。现在 policr-mini 镜像在 `telestd` 组织下，这也是官方所用的域名。当前 telestd/policr-mini 镜像没有 `latest` 分支，因为并没有上线到官方实例。所以你要显式的添加 `develop` 这个 tag 来定位镜像，即 `telestd/policr-mini:develop`。

### 开始更新

编辑配置文件

1. 编辑 `docker-compse.yml` 文件，将 `bluerain/policr-mini` 替换为 `telestd/policr-mini:develop`
1. 编辑 `.env` 文件，添加 `POLICR_MINI_UNBAN_METHOD=until_date`
1. 编辑 `docker-compse.yml` 文件，在 `services:server:environment` 中添加 `POLICR_MINI_UNBAN_METHOD: ${POLICR_MINI_UNBAN_METHOD}`。添加前请换行，并用空格与其它变量对齐

假设原有 `docker-compose.yml` 的内容是：

```yml
version: "3"

services:
  db:
    ......
  server:
    image: bluerain/policr-mini
    ......
    environment:
      POLICR_MINI_DATABASE_URL: "ecto://postgres:${POSTGRES_PASSWORD}@db/policr_mini_prod"
      ......
    ......
```

修改后：

```yml
version: "3"

services:
  db:
    ......
  server:
    image: telestd/policr-mini:develop
    ......
    environment:
      POLICR_MINI_DATABASE_URL: "ecto://postgres:${POSTGRES_PASSWORD}@db/policr_mini_prod"
      POLICR_MINI_UNBAN_METHOD: ${POLICR_MINI_UNBAN_METHOD}
      ......
    ......
```

内容中的 `......` 表示忽略的配置或环境变量。

确保当前目录中存在上述配置文件，执行更新命令：

```
docker-compose pull server
docker-compose up -d
```

更新介绍

_还在编写中……_
