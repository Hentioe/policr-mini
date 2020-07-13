# PolicrMini

[![Build Status](https://cloud.drone.io/api/badges/Hentioe/policr-mini/status.svg)](https://cloud.drone.io/Hentioe/policr-mini)
[![GitHub issues](https://img.shields.io/github/issues/Hentioe/policr-mini)](https://github.com/Hentioe/policr-mini/issues)
![Languages top](https://img.shields.io/github/languages/top/Hentioe/policr-mini)
![GitHub](https://img.shields.io/github/license/Hentioe/policr-mini)

一个只保留本质功能的 Policr 精简版。

## 介绍

本项目是作为 Policr 机器人的临时替代品而诞生，最小化的实现了核心功能。

## 当前状态

目前正处于开发阶段，但足够可用。将本项目的官方实例 [@policr_mini_bot](https://t.me/policr_mini_bot) 拉入群组可立即使用。

当前使用本机器人会被视作参与内测，这期间不会提供任何途径修改机器人的任何设置。事实上正因为是测试，所有的设置都是动态变化的（因为要充分测试）。  
如果你想要一个足够稳定的版本，请关注本项目的公测计划或第一个版本的正式发布。

## 技术介绍

本项目使用 Elixir 语言开发，具备 Erlang 系统一切优点。为了在开发过程中更轻易的从根源解决问题，作者本人从零开发了 Telegram bot 库（[Telegex](https://github.com/Hentioe/telegex)），并基于该库构建了本项目。

作为 [Telegex](https://github.com/Hentioe/telegex) 的现实案例，从事实上证明了它可以让机器人足够可靠、稳定的运行。 并且 [Telegex](https://github.com/Hentioe/telegex) 想较于早已存在的多个同类库，仍然具有更正确、完整的支持，更加优雅的实现等优点。

## 加入我们

- [POLICR · 中文社区](https://mini.telestd.me/community)
- [POLICR · 更新通知](https://t.me/policr_changelog)

## 功能设计

- [ ] 管理后台
  - [ ] 用户登入
  - [ ] 机器人设置修改
  - [ ] 查看日志
  - [ ] 管理封禁列表
- [ ] 设置预览
  - [ ] 在网页上实时模拟预览
  - [ ] 在私聊消息中模拟预览
- [ ] 消息快照
  - [ ] 验证过程快照（根据数据模拟回放验证过程，包括时间、消息内容和用户所选择的答案）
- [x] 权限控制
  - [ ] 群主可配置任意管理员对机器人的控制权（包括各项设置的读写权、历史记录/封禁列表的访问控制）
  - [x] 解除用户限制时会根据群组的设置动态恢复权限（定义好的静态权限无法满足特别设置过权限的群组）
- [x] 验证场合
  - [x] 私聊验证（两个阶段，引导私聊再发验证消息）
  - [ ] 群聊验证（单个阶段，公屏直接发送验证消息）
- [x] 验证入口
  - [x] 统一验证入口（多人同时验证也仅显示单条验证消息，强制私聊。可应对炸群）
  - [ ] 独立验证入口（支持管理员菜单、可选私聊）
- [x] 验证方式
  - [ ] 自定义问答（允许多套）
  - [x] 图片验证
  - [x] 算术验证
  - [x] 主动验证
- [x] 详细设置
  - [x] 启用/关闭接管状态（当前可通过 `/sync` 指令）
  - [ ] 添加/修改自定义验证
  - [ ] 切换验证方式
  - [ ] 修改验证提示（即消息文字）模板
  - [ ] 调整管理员控制权
- [x] 国际化
  - [x] 简体中文
  - [ ] 繁体中文
  - [ ] 英文

## 未来计划

原则上本项目的功能计划从一开始就规划且固定好了，除了优化和修复问题以外恐怕不会再进行新功能添加。但需要一提的是，本机器人目前展现出的所有优于 Policr 的设计也代表了 Policr 项目未来的进化方向。
