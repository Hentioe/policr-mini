# PolicrMini

[![Build Status](https://cloud.drone.io/api/badges/Hentioe/policr-mini/status.svg)](https://cloud.drone.io/Hentioe/policr-mini)
[![GitHub issues](https://img.shields.io/github/issues/Hentioe/policr-mini)](https://github.com/Hentioe/policr-mini/issues)
![Languages top](https://img.shields.io/github/languages/top/Hentioe/policr-mini)
![GitHub](https://img.shields.io/github/license/Hentioe/policr-mini)

一个只保留本质功能的 Policr 精简版。

## 介绍

本项目是作为 Policr 机器人的临时替代品而诞生，最小化的实现了核心功能。

## 当前状态

目前正处于开发阶段，但足够可用。将本项目的官方实例 [@policr_mini_bot](https://t.me/policr_mini_bot) 邀请入群即可使用。

当前官方机器人仍在测试，这期间只提供少量途径修改机器人的部分设置。事实上正因为是测试，另一部分设置是动态变化的（因为要充分测试）。
如果你想要一个足够稳定的版本，请关注本项目的更新频道或等待第一个正式版本的发布。

请注意，即使项目仍在测试，也不表示其官方实例会是绝对开放的。在您决定使用本项目的官方实例之前，请仔细阅读[服务条款](https://mini.telestd.me/terms)，否则请考虑第三方实例或[自行部署](https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89)。

## 技术介绍

本项目使用 Elixir 语言开发，具备 Erlang 系统一切优点。为了在开发过程中更轻易的从根源解决问题，作者本人从零开发了 TG bot 库（[Telegex](https://github.com/Hentioe/telegex)），并基于该库构建了本项目。

作为 [Telegex](https://github.com/Hentioe/telegex) 的现实案例，从事实上证明了它可以让机器人足够可靠、稳定的运行。 并且 [Telegex](https://github.com/Hentioe/telegex) 相较于早已存在的多个同类库，仍然具有更正确、完整的支持，更加优雅的实现等优点。

## 加入或帮助我们

- [添加您的实例到首页](https://github.com/Hentioe/policr-mini/issues/115)

## 关注我们

- [POLICR · 中文社区](https://mini.telestd.me/community)
- [POLICR · 更新通知](https://t.me/policr_changelog)

## 功能设计

- [x] 管理后台
  - [x] 用户登入
  - [x] 数据统计
    - [x] 实时统计（显示于菜单）
    - [ ] 完整统计（显示于页面）
  - [x] 设置修改
    - [x] 接管状态
    - [x] 自定义验证
    - [x] 方案定制
      - [x] 验证方式
      - [ ] 验证场合
      - [ ] 验证入口
      - [x] 击杀方法
      - [x] 超时时间
    - [ ] 验证提示
    - [x] 管理员控制权
  - [x] 验证记录
  - [x] 操作记录
  - [x] 系统菜单（机器人拥有者可见）
    - [x] 批量管理
    - [x] 查阅日志
    - [ ] 定时任务
    - [x] 服务条款
- [x] 官网（前台）
  - [x] 首页
  - [x] 登录页面
  - [ ] 维基页面
  - [ ] 快速入门页面
  - [ ] 关于页面
  - [x] 服务条款页面
- [x] 设置预览
  - [x] 在网页上实时模拟预览
  - [ ] 在私聊消息中模拟预览
- [ ] 消息快照
  - [ ] 验证过程快照（根据数据记录模拟回放验证过程）
- [x] 权限控制
  - [x] 独立的后台设置权限模型（读/写）
  - [x] 解除用户限制时根据群内设置动态恢复权限
- [x] 验证场合
  - [x] 私聊验证（两个阶段，引导私聊再发验证消息）
  - [ ] 群聊验证（单个阶段，公屏直接发送验证消息）
- [x] 验证入口
  - [x] 统一验证入口（多人同时验证也仅显示单条验证消息，强制私聊。可应对炸群）
  - [ ] 独立验证入口（支持管理员菜单、可选私聊）
- [x] 验证方法
  - [x] 自定义（允许定制多个问题）
    - [x] 文字消息
    - [x] 包含附件
  - [x] 图片验证
  - [x] 算术验证
  - [x] 主动验证
- [x] 国际化
  - [x] 简体中文
  - [ ] 繁体中文
  - [ ] 英文

## 未来计划

原则上本项目的功能计划从一开始就规划且固定好了，除了优化和修复问题以外恐怕不会再进行新功能添加。但需要一提的是，本机器人目前展现出的所有优于 Policr 的设计也代表了 Policr 项目未来的进化方向。
