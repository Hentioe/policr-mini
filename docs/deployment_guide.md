# 部署教程

自行部署 Policr Mini 非常容易，有基本的 Linux 服务器操作知识足以无障碍做到。本文档详细的介绍了过程，看起来有些冗长，但核心步骤极为简单。

## 前提

您需要掌握以下技能（具备初级经验即可）：

- Telegram Bot 的申请和设置
- Docker 和 Docker Compose 的使用
- Nginx 反向代理（可选）
- Cloudflare 的使用（可选）
- 主机商的防火墙设置（可选）

## 创建/编辑机器人

私聊 [BotFather](https://t.me/botfather) 创建好 bot 以后，进入 Edit Bot（编辑机器人）菜单，点击 Edit About（编辑关于）。在最后一个新行（使用 Ctrl + Enter 组合键换行）写入：

```text
Powered by Policr Mini
```

此处并不是教你怎么写机器人的资料，而是附带一个小小的统一的约定。作为本项目的第三方实例，仅添加上面那条信息足矣。

> [!WARNING]\
> 请不要在用户名或名称上带有 Policr Mini 相关的字符，以免造成混淆。

## 预备启动

跟着本章节安装必要软件、创建必要文件/目录。这些是让机器人在容器中成功启动的前提。

### 安装 Docker

这里不针对具体系统对 Docker 的安装做步骤描述，因为互联网上已经有充分的资料。此处总结了一些常见的链接。

- 常见 Linux 发行版：参照 Docker 官方的[安装教程](https://docs.docker.com/engine/install/)。
- 其它系统：请 Google 搜索关键字 "`<os_name> docker install`" 来查找资料。

_注意：对于非滚动更新的系统，不建议使用软件源自带的 Docker 包，因为它们提供的版本普遍太低。尤其是 CentOS 这类过于陈旧的发行版。_

> [!WARNING]
> 如果 Docker 已安装完成，您还可以将当前系统用户加入 `docker` 组，这样可以避免使用 `sudo` 来执行命令。**如果您没有这么做，且以非 root 权限用户操作，请在每一条 `docker` 命令前主动加上 `sudo`**。

现在，请执行 `docker compose` 命令。如果返回的是错误消息如 `docker: 'compose' is not a docker command.`，那么您还需要进一步安装 Docker Compose，否则无需安装（已集成）。

可前往此[官方教程](https://docs.docker.com/compose/install/)页面安装独立的 `docker-compose` 程序。注意，这是一个单文件二进制程序，你需要跟着步骤**设置文件权限并放置到有效的系统目录中**。

> [!WARNING]
> 后续教程将使用 `docker compose` 命令，如果您的 Docker 不存在 `compose` 子命令，请自行替换为 `docker-compose`。

### 创建数据目录

首先创建目录，此目录是配置、编排容器和存储数据的根目录：

```bash
mkdir policr-mini
```

创建 `docker-compose.yml` 和 `.env` 文件：

```bash
touch policr-mini/docker-compose.yml
touch policr-mini/.env
```

这两个文件是空的，因为我们会在下一章节编辑和解释它们。

此时，文件树如下：

```bash
.
└── policr-mini
    ├── docker-compose.yml
    └── .env
```

## 配置并启动

从此刻开始，我们进入 `policr-mini` 目录进行后续操作：

```bash
cd policr-mini
```

将以下内容写入 `docker-compose.yml` 文件中：

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POLICR_MINI_DATABASE_PASSWORD}
      POSTGRES_DB: policr_mini_prod
    volumes:
      - ./_data:/var/lib/postgresql/data
      - ./dumps:/dumps
    restart: always

  tsdb:
    image: influxdb:2.7
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: ${POLICR_MINI_INFLUX_PASSWORD}
      DOCKER_INFLUXDB_INIT_ORG: policr_mini
      DOCKER_INFLUXDB_INIT_BUCKET: policr_mini_prod
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: ${POLICR_MINI_INFLUX_TOKEN}
    restart: always

  # bot-api:
  #   image: gramoss/telegram-bot-api:9.1
  #   environment:
  #     TELEGRAM_API_ID: ${TELEGRAM_API_ID}
  #     TELEGRAM_API_HASH: ${TELEGRAM_API_HASH}
  #     TELEGRAM_LOCAL_MODE: true
  #   restart: always

  capinde:
    image: hentioe/capinde:0.1.1
    environment:
      CAPINDE_HOST: 0.0.0.0
      CAPINDE_WORKING_MODE: localized
    volumes:
      - ./shared_assets:/home/capinde/namespace/out
      - ./albums:/home/capinde/albums
    healthcheck:
      test: ["CMD", "capinde", "--healthcheck"]
      start_period: 3s
      interval: 60s
      timeout: 1s
      retries: 3

  server:
    image: gramoss/policr-mini:weekly
    ports:
      - ${POLICR_MINI_WEB_PORT}:${POLICR_MINI_WEB_PORT}
    environment:
      POLICR_MINI_DATABASE_URL: "ecto://postgres:${POLICR_MINI_DATABASE_PASSWORD}@db/policr_mini_prod"
      # POLICR_MINI_DATABASE_POOL_SIZE: ${POLICR_MINI_DATABASE_POOL_SIZE}
      POLICR_MINI_INFLUX_TOKEN: ${POLICR_MINI_INFLUX_TOKEN}
      POLICR_MINI_INFLUX_HOST: tsdb
      POLICR_MINI_CAPINDE_BASE_URL: http://capinde:8080
      POLICR_MINI_WEB_PORT: ${POLICR_MINI_WEB_PORT}
      POLICR_MINI_WEB_SECRET_KEY_BASE: ${POLICR_MINI_WEB_SECRET_KEY_BASE}
      POLICR_MINI_WEB_URL_BASE: ${POLICR_MINI_WEB_URL_BASE}
      POLICR_MINI_BOT_TOKEN: ${POLICR_MINI_BOT_TOKEN}
      POLICR_MINI_BOT_OWNER_ID: ${POLICR_MINI_BOT_OWNER_ID}
      # POLICR_MINI_BOT_WORK_MODE: ${POLICR_MINI_BOT_WORK_MODE}
      # POLICR_MINI_BOT_API_BASE_URL: ${POLICR_MINI_BOT_API_BASE_URL}
      # POLICR_MINI_BOT_WEBHOOK_URL: ${POLICR_MINI_BOT_WEBHOOK_URL}
      # POLICR_MINI_BOT_WEBHOOK_SERVER_PORT: ${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}
      # POLICR_MINI_BOT_AUTO_GEN_COMMANDS: ${POLICR_MINI_BOT_AUTO_GEN_COMMANDS}
      # POLICR_MINI_PLAUSIBLE_DOMAIN: ${POLICR_MINI_PLAUSIBLE_DOMAIN}
      # POLICR_MINI_PLAUSIBLE_SCRIPT_SRC: ${POLICR_MINI_PLAUSIBLE_SCRIPT_SRC}
      # POLICR_MINI_UNBAN_METHOD: ${POLICR_MINI_UNBAN_METHOD}
      # POLICR_MINI_OPTS: ${POLICR_MINI_OPTS}
    volumes:
      - ./shared_assets:/home/policr_mini/shared_assets
    restart: always
    depends_on:
      capinde:
        condition: service_healthy
      db:
        condition: service_started
      # bot-api:
      #   condition: service_started
      tsdb:
        condition: service_started
```

通常情况下这个文件无需进行编辑，它被设计为通用的部署模板，其中引用了大量的外部变量。我们对这些变量一一赋值即可完成最终配置，编辑 `.env` 文件：

```env
POLICR_MINI_DATABASE_PASSWORD=
POLICR_MINI_INFLUX_PASSWORD=
POLICR_MINI_INFLUX_TOKEN=
POLICR_MINI_WEB_PORT=
POLICR_MINI_WEB_SECRET_KEY_BASE=
POLICR_MINI_WEB_URL_BASE=
POLICR_MINI_BOT_TOKEN=
POLICR_MINI_BOT_OWNER_ID=
```

对以上部分变量进行逐一解释：

- `POLICR_MINI_DATABASE_PASSWORD`: 必要选项，表示数据库的密码。推荐通过 `openssl rand -hex 16` 命令生成一个 `32` 字符的随机文本作为密码。
- `POLICR_MINI_INFLUX_PASSWORD`: 必要选项，表示 InfluxDB 的密码。推荐通过 `openssl rand -hex 16` 命令生成一个 `32` 字符的随机文本作为密码。
- `POLICR_MINI_INFLUX_TOKEN`: 必要选项，表示 InfluxDB 的访问令牌。推荐通过 `openssl rand -hex 32` 命令生成一个 `64` 字符的随机文本作为令牌。
- `POLICR_MINI_WEB_PORT`: 可选变量，表示 web 服务的端口号。默认是 `4000`。如果你有其它服务占用此端口，请指定为其它未被占用的端口号。
- `POLICR_MINI_WEB_SECRET_KEY_BASE`: 必要变量，参与 web 认证加密的密钥。请使用 `openssl rand -base64 64 | tr -d '=' | head -c 64; echo` 命令生成。
- `POLICR_MINI_WEB_URL_BASE`: 必要变量，完成 web 配置后的访问地址。**它必须是 HTTPS 协议的**，例如 `https://mini.example.com/`。
- `POLICR_MINI_BOT_TOKEN`: 必要变量，表示机器人的 Token。请在 BotFather 中获取。
- `POLICR_MINI_BOT_OWNER_ID`: 必要变量，机器人拥有者（运营者）帐号的 ID。此处的 ID 不是用户名，是一串数字。在官方 TG 客户端中，几乎不会显示这个 ID。可以向 [@userinfobot](https://t.me/userinfobot) 发送消息以获取你的帐号 ID。**注意**：不要复制任何教程中的 ID。

请将变量的值放在 `=` 的后面，值中间不要有空格。保持一行一个。以上配置变量只是一小部分，还有更多的可选变量（或以预设值的变量），后文会继续介绍。

### 可选配置

- `POLICR_MINI_DATABASE_POOL_SIZE`: 可选，数据库连接池的大小。简单来说，越小的池服务器消耗越低，但不适合并发高的实例。越大的池，服务器资源消耗越高，但是能应付更大的并发连接。对于仅仅部署用来服务自己的群的实例，将此值设置到尽可能小即可（可小于 `10`）。
- `POLICR_MINI_BOT_AUTO_GEN_COMMANDS`: 可选，是否自动生成机器人的命令。将此值设置为 `true` 的话，每次启动时将自动生成或更新机器人的命令列表，不需要人工通过 BotFather 设置。有时候，您或许想隐藏某些命令或全部命令，则可以将此值设置为 `false`（当前默认为 `false`）。

_还有一些其它的可选配置，部分将在独立的小章节中介绍。_

### 部署的服务

虽然配置可以轻易生成，但你可能对其中的一些选项感到疑惑。本小章节将对它们做简单介绍。基于以上 Docker Compose 模板，我们部署了 5 个服务，它们共同支撑了 Policr Mini 项目的运行。分别是：

- `db`: PostgreSQL 数据库服务，存储机器人、群和用户的几乎所有项目数据。
- `tsdb`: InfluxDB 数据库服务，存储统计数据。这里的 ts 是 Time Series（时间序列）的缩写，它表示“时序”数据库。
- `bot-api`: 本地的 Telegram Bot API 服务，用于优化机器人的响应速度。它可以让机器人连接本地 API 服务而非荷兰的服务器。这是可选的。
- `capinde`: 验证生成服务。本项目所有基于图片的验证生成都是通过它来完成的。它是将 Policr Mini 的图片合成代码剥离后的独立开源产品。
- `server`: Policr Mini 的核心服务，提供 Mini Apps 控制台、web 后台和机器人服务。

### Webhook 模式

默认配置下机器人将以 `polling` 模式（轮询）启动，这是一种简单有效的模式，无需额外配置。轮询的工作模型决定了其响应速度会慢于 `webhook` 模式。如果您需要 `webhook` 模式，请将 `docker-compose.yml` 部分注释取消（留意 `+` 开头的行）：

```diff
       POLICR_MINI_WEB_URL_BASE: ${POLICR_MINI_WEB_URL_BASE}
       POLICR_MINI_BOT_TOKEN: ${POLICR_MINI_BOT_TOKEN}
       POLICR_MINI_BOT_OWNER_ID: ${POLICR_MINI_BOT_OWNER_ID}
-      # POLICR_MINI_BOT_WORK_MODE: ${POLICR_MINI_BOT_WORK_MODE}
+      POLICR_MINI_BOT_WORK_MODE: ${POLICR_MINI_BOT_WORK_MODE}
       # POLICR_MINI_BOT_API_BASE_URL: ${POLICR_MINI_BOT_API_BASE_URL}
       # POLICR_MINI_BOT_WEBHOOK_URL: ${POLICR_MINI_BOT_WEBHOOK_URL}
       # POLICR_MINI_BOT_WEBHOOK_SERVER_PORT: ${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}
```

在 `.env` 文件中添加它们：

- `POLICR_MINI_BOT_WORK_MODE`: 值为 `webhook`，表示以 `webhook` 模式启动。如果你想回到 `polling` 模式，可将此变量重新注释掉或填入 `polling` 值。

根据 Webhook 服务的端口号配置反向代理，便可得到 Webhook 的 URL。假设您使用的域名是 `mini.example.com`，在反向代理软件中将 `mini-receive.example.com` 和 Webhook 端口绑定，那么 Webhook URL 就是 `https://mini-receive.example.com/updates_hook`。

在 `webhook` 模式下，应用程序会监听两个 Web 服务端口。一个供用户访问控制台和后台，一个向 Telegram 服务器提供 Webhook 服务。请注意区分。

_注意：如果 Webhook 服务直接暴露，可能会成为易于攻击的“弱点”。您可以使用不同于网站前后台的域名并保密它，或藏于 CDN 之后。_

### 本地 API 服务

部署本地 API 服务可让机器人获得最快的响应速度，并脱离主流的部署地域（荷兰之外）。此外，它还可以避免 Webhook 服务遭遇攻击，及其它的部分硬性限制的解除。

使用我们的 Bot API 镜像，详情可了解[这篇文章](https://blog.gramlabs.org/posts/our-telegram-bot-api-image.html)。在 `docker-compose.yml` 部署模板中，我们需要 `bot-api` 服务并添加 `POLICR_MINI_BOT_API_BASE_URL` 变量，请将它的注释取消（留意 `+` 开头的行）：

```diff
-  # bot-api:
-  #   image: gramoss/telegram-bot-api:9.1
-  #   environment:
-  #     TELEGRAM_API_ID: ${TELEGRAM_API_ID}
-  #     TELEGRAM_API_HASH: ${TELEGRAM_API_HASH}
-  #     TELEGRAM_LOCAL_MODE: true
-  #   restart: always
+  bot-api:
+    image: gramoss/telegram-bot-api:9.1
+    environment:
+      TELEGRAM_API_ID: ${TELEGRAM_API_ID}
+      TELEGRAM_API_HASH: ${TELEGRAM_API_HASH}
+      TELEGRAM_LOCAL_MODE: true
+    restart: always

   capinde:
     image: hentioe/capinde:0.1.1
       POLICR_MINI_BOT_TOKEN: ${POLICR_MINI_BOT_TOKEN}
       POLICR_MINI_BOT_OWNER_ID: ${POLICR_MINI_BOT_OWNER_ID}
       # POLICR_MINI_BOT_WORK_MODE: ${POLICR_MINI_BOT_WORK_MODE}
-      # POLICR_MINI_BOT_API_BASE_URL: ${POLICR_MINI_BOT_API_BASE_URL}
+      POLICR_MINI_BOT_API_BASE_URL: ${POLICR_MINI_BOT_API_BASE_URL}
       # POLICR_MINI_BOT_WEBHOOK_URL: ${POLICR_MINI_BOT_WEBHOOK_URL}
       # POLICR_MINI_BOT_WEBHOOK_SERVER_PORT: ${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}
       # POLICR_MINI_BOT_AUTO_GEN_COMMANDS: ${POLICR_MINI_BOT_AUTO_GEN_COMMANDS}
@@ -75,7 +75,7 @@ services:
         condition: service_healthy
       db:
         condition: service_started
-      # bot-api:
-      #   condition: service_started
+      bot-api:
+        condition: service_started
       tsdb:
         condition: service_started
```

请注意 `bot-api` 服务中还需要 `TELEGRAM_API_ID` 和 `TELEGRAM_API_HASH` 两个环境变量，所以连同 `POLICR_MINI_BOT_API_BASE_URL` 一并添加到 `.env` 文件中。我们预设了 Bot API 服务的端口为 `8081`，这是该镜像默认的端口，所以 `POLICR_MINI_BOT_API_BASE_URL` 的值为 `http://bot-api:8081`。有关 Bot API 服务需要的两个变量值，请参考[官方页面](https://core.telegram.org/api/obtaining_api_id)获取。

> [!NOTE]
> 在 Docker Compose 配置中的服务是可以通过名称互相访问的，所以上述的 `http://bot-api:8081` 在内部相当于访问该容器 IP 的 8081 端口的 HTTP 服务（即本地 Bot API 服务）。

注意，你还可以将本地 Bot API 服务和 Webhook 模式联合起来用，这几乎能让机器人达到最快的响应速度。

_部署本地 Bot API 时，你应该先找出机器人的数据中心位置，并将 Bot API 和机器人部署在离数据中心地域最近的位置。_

### 网格验证

网格验证是一种新的验证方式，它复用图片验证的资源，从中合成图片产生「动态」的验证内容。网格验证的安全性和难度远大于常规的图片验证，其对服务器的性能要求也更高，所以它默认是不对后台用户开放的。向 `POLICR_MINI_OPTS` 变量添加 `--allow-client-switch-grid` 选项即可允许所有后台用户切换到该验证方式。

### 部署特定版本

本教程提供的 `docker-compose.yml` 模板中的 `server` -> `image` 是以本项目代码构建而成的镜像，值 `gramoss/policr-mini:weekly` 表示 `gramoss` 帐号下的 `policr-mini` 镜像，标签是 `weekly`。此处的镜像是由 GitHub Actions 服务器自动构建和推送的。

> [!NOTE]
> 这里的 `gramoss` 的含义是 GramLabs Open Source Software 的缩写，表示 GramLabs 开源软件。

受文档的更新频率所限，上述配置中的镜像可能总是 `weekly` 标签。此标签的镜像始终构建于最新的 `main` 分支代码之上，它可能不太稳定但功能上是最新的。您也可以将此标签修改为具体日期，如 `20241010` 表示构建于 `2024-10-10` 当天的镜像。若您想确保自己总是知道部署和升级的是什么版本时建议使用日期标签。从[此页面](https://hub.docker.com/r/gramoss/policr-mini/tags)可以看到最新构建的基于日期的镜像版本，通常在更新频道发布更新说明时也会附带镜像的日期标签。

除了日期标签和 `weekly`，还有少数特定功能的标签。它们通常是基于未完整开发完成的「大更新」分支代码构建的镜像。这类标签不会基于任何形式来表示版本（即没有版本），始终构建于该分支的最新分支代码上。通常用于大更新后的线上测试。

> [!NOTE]
> 单词 `weekly` 即「每周」，字面含义是表示每周构建的版本。但实际中它表示发布较频繁，没有版本号的一类更新通道。

### 启动

若配置已确定无误，便可输入命令尝试启动容器：

```bash
docker compose up -d
```

查看容器日志：

```bash
docker compose logs server -f
```

如果输出以下内容，表示启动成功：

```log
██████╗  ██████╗ ██╗     ██╗ ██████╗██████╗     ███╗   ███╗██╗███╗   ██╗██╗
██╔══██╗██╔═══██╗██║     ██║██╔════╝██╔══██╗    ████╗ ████║██║████╗  ██║██║
██████╔╝██║   ██║██║     ██║██║     ██████╔╝    ██╔████╔██║██║██╔██╗ ██║██║
██╔═══╝ ██║   ██║██║     ██║██║     ██╔══██╗    ██║╚██╔╝██║██║██║╚██╗██║██║
██║     ╚██████╔╝███████╗██║╚██████╗██║  ██║    ██║ ╚═╝ ██║██║██║ ╚████║██║
╚═╝      ╚═════╝ ╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝

18:51:36.722 [info] TOOLCHAINS: [ELIXIR-1.18.4, ERTS-16.0.1]
18:51:36.899 [info] Already up
18:51:37.170 [info] Running PolicrMiniWeb.Endpoint with cowboy 2.10.0 at 0.0.0.0:8080 (http)
18:51:37.174 [info] Access PolicrMiniWeb.Endpoint at http://localhost:8080
18:51:37.401 [info] Checking bot information...
18:51:37.484 [info] Bot (@your_bot_username) is working (polling)
```

若发生致命错误，将启动失败，请复制日志中的红色报错信息到社区群求助。一旦问题被解决，再次执行 `docker-compose up -d` 即可。**注意**：一旦发生配置修改或镜像升级都需要重新执行这个命令，重启是不会让新东西生效的。

_提示：如果您以 `webhook` 模式启动，日志会输出 `[info] Bot (@your_bot_username) is working (webhook)`。_

_如果日志输出没有问题，请 Ctrl + C 结束日志查看。它是安全的，不会导致容器停止。_

部署完成后，会多出一些目录。新的文件树如下：

```bash
.
├── albums
├── _data
├── docker-compose.yml
├── dumps
├── .env
└── shared_assets

5 directories, 2 files
```

它们的用途如下：

- `albums`: 存储部署的验证资源。内部是一个个图集文件夹。
- `_data`: PostgreSQL 数据库的数据目录。
- `dumps`: 存储数据库备份文件（升级或迁移时使用）。
- `shared_assets`: 验证生成器 Capinde 和机器人两个服务共享的目录，一个在其中生成验证图片另一个读取并发送。

其中 `_data` 目录的数据是非常重要的，**任何时候请谨慎对待**。

## 反向代理

和一般的 web 应用程序一样，代理到 `http://localhost:4000` 即可（请替换为自己的端口号）。

需要一提的是，Policr Mini 从某次更新开始大幅度提高了上传文件的限制大小（为 256MB）。文件上传，尤其是大文件上传主要用于验证资源的后台更新。当使用反向代理时，您需要确保代理软件允许 256MB 的文件大小上传。如果您的服务器所安装的 Nginx 没有进行相关配置，在上传过大的文件（通常大于 1MB）可能就会返回 `413` 错误。在 Nginx 配置中添加指令 `client_max_body_size 256M;` 即可解决上传时发生的 `413` 错误。

_待补充：由于 Nginx 涉及到的无关东西太多，如 SSL 证书等。本章节预设了读者有基本的 Nginx 使用经验，所以几乎略过了所有步骤。但不排除未来在有时间的情况下，为没有相关知识的用户补充这部分内容。_

## Cloudflare 的使用

通过 Cloudflare 或类似产品提供的解析和代理服务，确保 ip 不会被暴露。因为 ip 暴露可能成为 DDOS 流量攻击的目标。详情请去 Cloudflare 官网自行了解，它的免费服务即可达成目的。

**注意**：没有防御能力的第三方实例不会成为社区运营实例。因为它太脆弱，无法保障相对稳定的服务。

当然，如果你认为你的机器人只是自己使用，应该不会遭遇攻击，也可以不必做这种步骤。但若要开放服务，为了其它群组着想，请务必考虑。

## 主机商的防火墙设置

为了彻底杜绝 ip 暴漏导致的风险，还可以考虑为 80 和 443 端口设置 ip 白名单。参照 Cloudflare 官方的 [ip 范围页面](https://www.cloudflare.com/ips/) 将所有 ip 添加到白名单即可。

当然，像例如 22 这类端口更应设置白名单，通过跳板服务器连入。这样 bot 服务器就彻底的没有为流量攻击创造条件，只能被 CC 攻击。但 CC 攻击可通过 Cloudflare 的防火墙规则或速率限制轻松抵御。实际上，官方实例曾一直有遭遇 CC 攻击，但是强度太低，甚至不需要打工干戈的防御。

而这一切，都是免费的。

## 制作图片验证资源

由于官方实例的图片验证资源并非项目的一部分，所以它并不会提供出来。您可以使用 [mini-assets](https://github.com/Hentioe/mini-assets) 项目制作图片资源，并通过后台线上安装。该项目有非常详细的教程和解释。

如果您当前并不打算制作自己的图片验证资源，也不会影响机器人的工作。因为图片验证会因为没有验证资源而生成失败，将自动切换到后备验证方式上。在不提供图片验证资源的情况下，实例拥有者可通过修改全局默认验证方式（为非图片验证的其它方式），以避免切换到后备验证上。

## 第三方和官方的区别

自 2025 年 7 月底更新以来，官方和第三方实例几乎没有区别了。该更新移除了首页部分，将首页独立成了官网（[mini.gramlabs.org](https://mini.gramlabs.org)）。同时移除了旧的综合性后台，以及对赞助历史、社区服务列表的托管。简单来说第三方实例（包括官方实例）都不再有「首页」的存在。

由于没有为首页（即基础 URL 地址）添加任何内容，所以当访问首页时将自动重定向到本项目的官网。实际被访问的两个主要部分都在子路径中，例如控制台是 `/console/v2`，后台是 `/admin/v2`。根路径没有内容，所以暂时进行重定向。

未来会有更多的区别于官方的地方，但应该不会带来主要功能上的差异。

## 第三方实例的安全性

如果是根据原始源代码构建的机器人程序，包括官方提供的镜像，会是相对安全的。因为即便是机器人拥有者也不具备其它群组在后台的「可写」权限。也就是说拥有者至多做到查阅它群的设置（具备可读权限）或者操作机器人退群，并不能修改其它群的设置（包括通过后台封人、踢人都需要可写权限）。

在未来会有接管功能，它可以向指定群组管理员申请临时的可写权限（需要被申请人确认）。这个功能的目的在于帮助他人解决设置问题。

但请记住，程序的安全性不表示机器人的安全性。任何第三方实例的拥有者都可以通过修改源代码或者直接调用 bot API 的方式对具备权限的群做出超出功能限制的行为，所以在使用第三方实例前请确保它足以信任（如果可以，请自行部署）。
