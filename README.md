# PolicrMini

[加入群组](https://t.me/policr_community) | [更新频道](https://t.me/policr_changelog) | [自行部署](https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89) | [注册实例](https://github.com/Hentioe/policr-mini/issues/115) | [赞助项目](https://mini.telestd.me/?sponsorship=[谢谢，请获取我])

[![Build Status](https://ci.hentioe.dev/api/badges/Hentioe/policr-mini/status.svg)](https://ci.hentioe.dev/Hentioe/policr-mini)
[![GitHub issues](https://img.shields.io/github/issues/Hentioe/policr-mini)](https://github.com/Hentioe/policr-mini/issues)
![Languages top](https://img.shields.io/github/languages/top/Hentioe/policr-mini)
![GitHub](https://img.shields.io/github/license/Hentioe/policr-mini)

一个不断完善和改进的验证/审核机器人。

## 当前重心

目前 Policr Mini 已完成向 Telegex 框架 `1.x` 版本的迁移工作，但存在少量 bug 和未知风险。目前所有对 Telegex 1.x 版本迁移的更改都停留在开发分支，直到所有 bug 被修复并充分测试以后才会合并到主分支。

### 优势

- 更加即时的跟随 Bot API 变化
- 新的工作模式，更快的响应速度
- 新的部署模式，极限的响应速度

### 已知问题

- 添加到群组的同时设置管理权限，机器人将无法得知自身权限已被提升。

## 介绍

本项目是作为 Policr 机器人的替代品而诞生，最小化的实现了核心功能。

## 当前状态

目前正处于开发阶段，但足够可用。将本项目的官方实例 [@policr_mini_bot](https://t.me/policr_mini_bot) 邀请入群即可使用。

当前官方机器人仍在测试，这期间只提供少量途径修改机器人的部分设置。事实上正因为是测试，另一部分设置是动态变化的（因为要充分测试）。
如果你想要一个足够稳定的版本，请关注本项目的更新频道或等待第一个正式版本的发布。

请注意，即使项目仍在测试，也不表示其官方实例会是绝对开放的。在您决定使用本项目的官方实例之前，请仔细阅读[服务条款](https://mini.telestd.me/terms)，否则请考虑第三方实例或[自行部署](https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89)。

## 技术介绍

本项目使用 Elixir 语言开发，具备 Erlang 系统一切优点。为了在开发过程中更轻易的从根源解决问题，作者本人从零开发了 TG bot 库（[Telegex](https://github.com/telegex/telegex)），并基于该库构建了本项目。

作为 [Telegex](https://github.com/telegex/telegex) 的现实案例，从事实上证明了它可以让机器人足够可靠、稳定的运行。 并且 [Telegex](https://github.com/telegex/telegex) 相较于早已存在的多个同类库，仍然具有更正确、完整的支持，更加优雅的实现等优点。

## 关注我们

- [POLICR · 中文社区](https://t.me/policr_community)
- [POLICR · 更新通知](https://t.me/policr_changelog)

## 未来计划

原则上本项目的功能计划从一开始就规划且固定好了，除了优化和修复问题以外恐怕不会再进行新功能添加。但需要一提的是，本机器人目前展现出的所有优于 Policr 的设计也代表了 Policr 项目未来的进化方向。
