# 部署教程

自行部署 Policr Mini 非常容易，有基本的 Linux 服务器操作知识足以无障碍做到。本文档详细的介绍了过程，虽看起来显得冗长，但核心步骤却极其简单。

## 前提

您需要掌握以下技能（具备初级使用经验即可开始操作）：

- TG bot 的申请和设置
- Docker 和 Docker Compose 的使用
- Nginx 反向代理（可选）
- Cloudflare 的使用（可选）
- 主机商的防火墙设置（可选）

## 编辑机器人

使用 BotFather 选择你的 bot，打开 Edit Bot 菜单，再点击 Edit About。

此处并不是教你怎么写机器人的 info，而是附带一个小小的统一的约定。请在最后一个新行（电脑用户使用 Ctrl + Enter 组合键换行）写入：

```text
Powered by Policr Mini
```

作为本项目的第三方实例，仅添加上面那条信息足矣。不要在用户名或名称上带有 Policr Mini 相关的字符，也不建议。希望能规范添加相关文字，不要有空格、换行或大小写问题。强迫症看了会难受：）。

_提醒：如果您的实例是公开服务的，最好在此处添加上 web 访问链接。_

## 预备启动的前奏

跟着本章节安装必要软件、创建必要文件/目录。这些是让机器人在容器中成功启动的前提。

### 安装 Docker 和 Docker Compose

这里不对 Docker 相关软件的安装做步骤描述，因为互联网上已经有充分的资料，所以此处总结了一些常见的链接。

对于 CentOS/Debian/Fedora/Raspbian/Ubuntu 等流行系统，请参照 Docker [官方的页面](https://docs.docker.com/engine/install/)。官方有详细的步骤。对于其它系统，如果你有较好的英文阅读能力（或使用翻译软件），也推荐按照系统官方的教程走。如果没有，请 Google 搜索关键字 "`系统名称 docker install`" 来查找资料。

_注意：对于非滚动更新的系统，并不建议使用软件源自带的 Docker 包，因为它们提供的版本普遍太低。尤其是 CentOS 这类过于陈旧的发行版。_

如果 Docker 已安装完成，您还可以将当前系统用户加入 `docker` 组，这样可以避免使用 `sudo` 来执行命令。如果您没有这么做，且以非 root 权限用户操作，请在每一条 `docker` 命令前主动加上 `sudo`。

现在，请执行 `docker compose` 命令。如果返回的是错误消息如 `docker: 'compose' is not a docker command.`，那么您还需要进一步安装 Docker Compose，否则无需安装（已集成）。

可前往[官方页面](https://docs.docker.com/compose/install/)安装 `docker-compose` 程序。注意，这是一个单文件二进制程序，你需要跟着步骤**设置文件权限并放置到有效的系统目录中**。

_提示：后续教程将使用 `docker compose` 命令，如果您的 Docker 不存在 `compose` 子命令，请自行替换待 `docker-compose`。_

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
version: "3"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: policr_mini_prod
    volumes:
      - ./_data:/var/lib/postgresql/data
    restart: always

  server:
    image: gramoss/policr-mini:latest
    ports:
      - ${POLICR_MINI_SERVER_PORT}:${POLICR_MINI_SERVER_PORT}
      #- ${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}:${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}
    environment:
      POLICR_MINI_DATABASE_URL: "ecto://postgres:${POSTGRES_PASSWORD}@db/policr_mini_prod"
      POLICR_MINI_DATABASE_POOL_SIZE: ${POLICR_MINI_DATABASE_POOL_SIZE}
      POLICR_MINI_SERVER_ROOT_URL: ${POLICR_MINI_SERVER_ROOT_URL}
      POLICR_MINI_SERVER_SECRET_KEY_BASE: ${POLICR_MINI_SERVER_SECRET_KEY_BASE}
      POLICR_MINI_SERVER_PORT: ${POLICR_MINI_SERVER_PORT}
      POLICR_MINI_BOT_TOKEN: ${POLICR_MINI_BOT_TOKEN}
      POLICR_MINI_BOT_NAME: ${POLICR_MINI_BOT_NAME}
      POLICR_MINI_BOT_OWNER_ID: ${POLICR_MINI_BOT_OWNER_ID}
      #POLICR_MINI_BOT_WORK_MODE: ${POLICR_MINI_BOT_WORK_MODE}
      #POLICR_MINI_BOT_API_BASE_URL: ${POLICR_MINI_BOT_API_BASE_URL}
      #POLICR_MINI_BOT_WEBHOOK_URL: ${POLICR_MINI_BOT_WEBHOOK_URL}
      #POLICR_MINI_BOT_WEBHOOK_SERVER_PORT: ${POLICR_MINI_BOT_WEBHOOK_SERVER_PORT}
      POLICR_MINI_BOT_GRID_CAPTCHA_INDI_WIDTH: ${POLICR_MINI_BOT_GRID_CAPTCHA_INDI_WIDTH}
      POLICR_MINI_BOT_GRID_CAPTCHA_INDI_HEIGHT: ${POLICR_MINI_BOT_GRID_CAPTCHA_INDI_HEIGHT}
      POLICR_MINI_BOT_GRID_CAPTCHA_WATERMARK_FONT_FAMILY: ${POLICR_MINI_BOT_GRID_CAPTCHA_WATERMARK_FONT_FAMILY}
      POLICR_MINI_BOT_ASSETS_PATH: /_assets
      POLICR_MINI_BOT_AUTO_GEN_COMMANDS: ${POLICR_MINI_BOT_AUTO_GEN_COMMANDS}
      POLICR_MINI_BOT_MOSAIC_METHOD: ${POLICR_MINI_BOT_MOSAIC_METHOD}
      POLICR_MINI_UNBAN_METHOD: ${POLICR_MINI_UNBAN_METHOD}
      POLICR_MINI_OPTS: ${POLICR_MINI_OPTS}
    volumes:
      - ./_assets:/_assets
    restart: always
    depends_on:
      - db

```

一般情况下这个文件无需再进行任何编辑，因为它引用了大量的变量。我们只需要对这些变量一一赋值完成或更新配置，即编辑 `.env` 文件：

```env
POSTGRES_PASSWORD=<填入数据库密码> # 这里自定义一个密码，推荐随机一个较短的 hash 字符串
POLICR_MINI_DATABASE_POOL_SIZE=10 # 数据库连接池的大小，已预设值
POLICR_MINI_SERVER_ROOT_URL=<填入根 URL 地址> # 完成 web 配置以后的访问地址，如 https://mini.your.domain
POLICR_MINI_SERVER_SECRET_KEY_BASE=<填入密钥> # 推荐随机一个较长的 hash 字符串
POLICR_MINI_SERVER_PORT=<填入端口号> # 例如 8080
POLICR_MINI_BOT_NAME=<填入机器人名称> # 请使用自己的机器人的显示名称
POLICR_MINI_BOT_TOKEN=<填入机器人 Token> # 这里不解释了
POLICR_MINI_BOT_OWNER_ID=<填入机器人拥有者的 ID> # 就是机器人主人的 TG 账号的 ID
POLICR_MINI_BOT_WORK_MODE=<填入工作模式> # 可选 polling/webhook。留空默认 polling
POLICR_MINI_BOT_WEBHOOK_URL=<填入 Webhook URL> # 可选配置，非 webhook 模式请留空
POLICR_MINI_BOT_WEBHOOK_SERVER_PORT=<填入 Webhook 的服务端口> # 可选配置，非 webhook 模式请留空
POLICR_MINI_BOT_GRID_CAPTCHA_INDI_WIDTH=180 # 网格验证的单个图片格子宽度，视验证资源修改
POLICR_MINI_BOT_GRID_CAPTCHA_INDI_HEIGHT=120 # 网格验证的单个图片格子宽度，视验证资源修改
POLICR_MINI_BOT_GRID_CAPTCHA_WATERMARK_FONT_FAMILY=Lato # 网格验证的水印字体（每一个单元格编号文字的字体）
POLICR_MINI_BOT_AUTO_GEN_COMMANDS=true # 是否自动生成机器人命令，已预设值
POLICR_MINI_BOT_MOSAIC_METHOD=spoiler # 马赛克方法，预设值为 spoiler。也可设置为 classic
POLICR_MINI_UNBAN_METHOD=until_date # 解封方法，预设值为过期时间。也可设置为 api_call
POLICR_MINI_OPTS="" # 可选配置，此处预设为空
```

请根据以上内容和注释填充正确的变量值，注意值不需要尖括号（`<>`）。有些环境下无法识别注释，所以赋值后也建议将 `#` 及后面的中文解释一并删除。

对以上部分变量进行一些扩展解释：

- `POLICR_MINI_SERVER_ROOT_URL`: 必选变量，用于生成后台链接。如果 `/login` 命令生成的链接无法访问，可能是此处配置不正确。如果您确保此变量配置的地址是正确的，则可能是 Web 服务的反向代理出现了问题。记住，本项目 Web 是不可或缺的一部分。
- `POLICR_MINI_BOT_NAME`: 可选变量，用于显示官网的 LOGO 文字和网页标题的后缀。因为机器人很多时候名称带有版本信息（而显示这些是多余的），所以特地提供一个变量来自定义。当我们定义值为 `Policr Mini` 时，即便机器人当前的名称是 `Policr Mini (beta)` 仍可以让官网显示为 `Policr Mini`。**注意**：若未设置此变量，将直接使用 bot 的显示名称。
- `POLICR_MINI_BOT_OWNER_ID`: 必选变量，用于后台对最高管理员的身份的识别。这里的 ID 不是用户名，是一串数字。在官方 TG 客户端中，几乎不会显示这个 ID。通过向 [@userinfobot](https://t.me/userinfobot) 发送消息可以获取这个 ID。**注意**：不要复制任何教程中的 ID。

### 高级配置

在上面的配置模板中，存在一些注释为”已预设值“的配置字段。已预设值表示它们或许不需要修改，但它们中的一些可能非常有用。以下是已预设值字段的解释：

- `POLICR_MINI_DATABASE_POOL_SIZE`: 数据库连接池的大小。粗略的讲，越小的池服务器消耗越低（数据库内存、CPU 占用低），但是不适合并发高的实例。越大的池，服务器资源消耗越高，但是能应付更大的并发连接。对于仅仅部署用来服务自己的群的实例，将此值设置到尽可能小即可（可小于 10）。目前官方实例此配置的值为 `10`。
- `POLICR_MINI_BOT_AUTO_GEN_COMMANDS`: 自动生成机器人命令。将此值设置为 `true` 将在每次启动时自动生成或更新机器人的命令列表，不需要再人工通过 BotFather 设置。有时候，您或许想隐藏某些命令或全部命令，则可以将此值设置为 `false`。

### 可选配置

可选配置是一系列开关，这些开关不需要值，因此无需独立配置。当前可选配置存在以下参数：

- `--independent`: 让机器人处于完全独立的运营模式，包括不和官方实例通信（例如获取共享的第三方实例列表）。
- `--disable-image-rewrite`: 禁用验证图片重写。通常来讲不需要禁用，若服务器性能太低，此选项可以放弃安全性换取性能的提升。详情参见[图片重写机制](#图片重写机制)。
- `--allow-client-switch-grid`: 允许后台用户切换到网格验证。默认不允许，因为此选项对性能占用较高。详情参见[网格验证](#网格验证)。

可选配置的值就是一个个的可选参数，多个参数用空格间隔开来。如：

```env
POLICR_MINI_OPTS="--independent --<假想的可选参数2>"
```

>如果您想让自己的实例或所服务的用户受到足够的隐私保护，那么建议添加 `--independent` 可选参数。默认配置下部署的第三方实例的前台首页被访问时（后台不会），客户的浏览器会向官方实例发送请求以获取一些共享数据。此时官方实例是知道有来自第三方实例的用户请求，虽然官方实例并不在意这些请求数据。

### Webhook 模式

默认配置下机器人将以 `polling` 模式启动，这是一种简单有效的模式，无需额外配置。不过 `polling` 的工作模型决定了其响应速度会慢于 `webhook` 模式。

_供参考：Policr Mini 官方实例曾以 `polling` 模式长期运行，也因为如此 `webhook` 模式仍处于实验阶段。_

取消 `docker-compose.yml`  文件的部分注释：包括 `ports` 下对 Webhook 服务端口变量的引用、`environment` 下 `POLICR_MINI_BOT_WORK_MODE` 和 `POLICR_MINI_BOT_WEBHOOK_*` 变量的注入和引用。如果你不明白取消注释是什么意思，请直接删除相关行开头的井号。

取消注释后，编辑 `.env` 配置，将相关变量一一赋值：

- `POLICR_MINI_BOT_WORK_MODE` 赋值为 `webhook`，表示以 `webhook` 模式启动。
- `POLICR_MINI_BOT_WEBHOOK_URL` 赋值为 `<base_url>/updates_hook` 格式，如 `https://your.domain.com/updates_hook`，其中 `/updates_hook` 是固定的。具体如何获得请看后文。
- `POLICR_MINI_BOT_WEBHOOK_SERVER_PORT` 设置为监听 Webhook 服务的端口号。

根据 Webhook 服务的端口号配置反向代理，便可得到 Webhook 的 URL。假设您使用的域名是 `mini.domain.com`，在反向代理软件中将 `mini-receive.domain.com` 和 Webhook 端口绑定，那么 Webhook URL 就是 `https://mini-receive.domain.com/updates_hook`。

在 `webhook` 模式下，应用程序会监听两个 Web 服务端口。一个用于访问前后台（常规网站），一个提供 Webhook 服务，请注意区别。

_注意：如果 Webhook 服务直接暴露，可能会成为易于攻击的“弱点”。您可以使用不同于网站前后台的域名并保密它，或藏于 CDN 之后。_

### 本地 API 服务

部署本地 API 服务可让机器人获得最快的响应速度，并脱离主流的部署地域（荷兰之外）。此外，它还可以避免 Webhook 服务遭遇攻击，及其它的部分硬性限制的解除。

使用我们的 Bot API 镜像，详情可了解[这篇文章](https://blog.gramlabs.org/posts/our-telegram-bot-api-image.html)。下面是一个例子：

```yaml
services:
  # db 服务（已忽略）

  telegram-bot-api:
    image: gramoss/telegram-bot-api:ade0841
    environment:
      TELEGRAM_API_ID: ${TELEGRAM_API_ID}
      TELEGRAM_API_HASH: ${TELEGRAM_API_HASH}
      TELEGRAM_LOCAL_MODE: true

  server:
    # 机器人服务（已部分忽略）
    environment:
      POLICR_MINI_BOT_API_BASE_URL: http://telegram-bot-api:8081/bot
      POLICR_MINI_BOT_WEBHOOK_URL: http://server:4001/updates_hook
      POLICR_MINI_BOT_WEBHOOK_SERVER_PORT: 4001
```

如上，你需要向 bot 服务添加 `POLICR_MINI_BOT_API_BASE_URL`、`POLICR_MINI_BOT_WEBHOOK_URL` 和 `POLICR_MINI_BOT_WEBHOOK_SERVER_PORT` 这三个环境变量，它们在上面的模板中已经给出，取消注释即可。同时你需要在 `telegram-bot-api` 服务中注入 `TELEGRAM_API_ID` 和 `TELEGRAM_API_HASH` 两个环境变量。

我们预设 Bot API 服务的端口为 `8081`，这是该镜像默认的端口。有关 Bot API 服务需要的两个变量值，请参考[官方页面](https://core.telegram.org/api/obtaining_api_id)获取。

_部署本地 Bot API 时，你应该先找出机器人的数据中心位置，并将 Bot API 和机器人部署在离数据中心地域最近的位置。_

### 图片重写机制

图片重写机制会在发送原始的图片验证资源前，随机操作图片的单个像素，将其重写为其它颜色。这样做可以让每一次发送的图片都具有新的 Hash 值，避免总是引用服务器上的同一个 `file_id`。这个机制让收集所有验证图片的 `file_id` 和对应名称的行为变得没有意义，增加了破解难度。

图片重写机制是默认启用的，它可以提高图片验证的安全性，在图片体积合理的前提下对性能的影响也极小。如果你仍然想将其关闭，可在 `POLICR_MINI_OPTS` 变量中添加 `--disable-image-rewrite` 选项。

### 网格验证

网格验证是一种新的验证方式，它复用图片验证的资源，从中合成图片产生新的动态验证内容。网格验证的安全性和难度远大于常规的图片验证，其对服务器的性能要求也更高，所以它默认是不对后台用户开放的。向 `POLICR_MINI_OPTS` 添加 `--allow-client-switch-grid` 选项即可允许所有后台用户切换到该验证方式。

### 部署特定版本

文件 `docker-compose.yml` 中的 `server` -> `image` 就是以本项目代码构建而成的镜像，值 `gramoss/policr-mini:latest` 表示 `gramoss` 帐号下的 `policr-mini` 镜像，标签是 `latest`。此处的镜像是由 CI 服务器自动构建和推送的。

受文档的更新频率所限，上述配置中的镜像可能总是 `latest` 标签。此标签的镜像始终构建于最新的 `master` 分支之上，通常较为稳定，但功能上并不是最新的。您也可以将此标签修改为具体日期，如 `20241010` 表示构建于 `2024-10-10` 当天的镜像。若您想确保自己总是知道部署和升级的是什么版本时建议使用日期标签。从[此页面](https://hub.docker.com/r/gramoss/policr-mini/tags)可以看到最新构建的基于日期的镜像版本，通常在更新频道发布更新说明时也会附带镜像的日期标签。

除了日期标签和 `latest`，还有 `develop` 标签。它表示以 `develop` 分支（即开发中的代码）构建的镜像。此标签不会基于任何形式来表示版本（即没有版本），始终构建于最新的开发分支代码之上。 有时候开发分支会比 `master` 分支的更新内容多得多，通常用于大更新后的线上测试。

修改为 `gramoss/policr-mini:develop` 使用开发分支的镜像。

### 启动

若配置已确定无误，即可输入命令尝试启动容器：

```bash
docker compose up -d
```

查看容器日志：

```bash
docker compose logs server
```

如果输出以下内容，表示启动成功：

```log
18:51:36.722 [info] Buildtime/Runtime: [otp-26.2.1, elixir-1.16.0] / [erts-14.2]
18:51:36.899 [info] Already up
18:51:37.170 [info] Running PolicrMiniWeb.Endpoint with cowboy 2.10.0 at 0.0.0.0:8080 (http)
18:51:37.174 [info] Access PolicrMiniWeb.Endpoint at http://localhost:8080
18:51:37.401 [info] Checking bot information...
18:51:37.484 [info] Bot (@your_bot_username) is working (polling)
```

若发生致命错误，将启动失败，请复制日志中的报错信息到社区群求助。一旦问题被解决，再次执行 `docker-compose up -d` 即可。**注意**：一旦发生配置修改或镜像升级都需要重新执行这个命令，重启是不会让新东西生效的。

_提示：如果您以 `webhook` 模式启动，日志会输出 `[info] Bot (@your_bot_username) is working (webhook)`。_

## 反向代理

和常规 web 应用程序一样，如上配置代理到 `http://localhost:8080` 即可。

需要一提的是，Policr Mini 从某次更新开始大幅度提高了上传文件的限制大小（为 256MB）。文件上传，尤其是大文件上传主要用于验证资源的后台更新。当使用反向代理时，您需要确保代理软件允许 256MB 的文件大小上传。如果您的服务器所安装的 Nginx 没有进行相关配置，在上传过大的文件（通常大于 1MB）可能就会返回 `413` 错误。在 Nginx 配置中添加指令 `client_max_body_size 256M;` 即可解决上传时发生的 `413` 错误。

_待补充：因为 Nginx 涉及到的无关东西太多，例如 SSL 证书等。本章节预设了读者有基本的 Nginx 使用经验，所以几乎略过了所有步骤。但不排除未来在有时间的情况下，为没有相关知识的用户补充这部分内容。_

## Cloudflare 的使用

通过 Cloudflare 或类似产品提供的解析和代理服务，确保 ip 不会被暴露。因为 ip 一旦暴露可能成为 DDOS 流量攻击的目标。详情请去 Cloudflare 官网自行了解，它的免费服务即可达成目的。

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

第三方首先是配置中有独特的部分，例如新的 LOGO 文字，标题后缀。其次，官网的 LOGO 会有一个 `T-party` 标记，意为 Third-party（第三方）。

未来会有更多的区别于官方的地方，但几乎不会带来主要功能上的差异。

## 第三方实例的安全性

如果是根据原始源代码构建的机器人程序，包括官方提供的镜像，会是相对安全的。因为即便是机器人拥有者也不具备其它群组在后台的「可写」权限。也就是说拥有者至多做到查阅它群的设置（具备可读权限）或者操作机器人退群，并不能修改其它群的设置（包括通过后台封人、踢人都需要可写权限）。

在未来会有接管功能，它可以向指定群组管理员申请临时的可写权限（需要被申请人确认）。这个功能的目的在于帮助他人解决设置问题。

但请记住，程序的安全性不表示机器人的安全性。任何第三方实例的拥有者都可以通过修改源代码或者直接调用 bot API 的方式对具备权限的群做出超出功能限制的行为，所以在使用第三方实例前请确保它足以信任（如果可以，请自行部署）。

## 结束语

本文的发表不表示机器人的完成度已经相当高了，实际上并没有。但这不妨碍对自行部署的尝试或增加社区运营的稳定性考验时间。实际上在正式版本发布以后，镜像一定是带有版本 `tag` 的，并且有详细的 CHANGELOG，包含升级中需要修改或新增的不兼容部分。因为现在还处于开发阶段，所以并没有这样做。

如果你想让机器人成为将来会被官方推荐的社区运营实例，请在社区群中交流。

**注意**：此文档用于临时记录相关教程，在项目更稳定的未来会迁移至网站前台的文档页面中。
