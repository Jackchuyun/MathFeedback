<div align="center">

# MathFeedback

### 面向高中数学教师的本地优先课后反馈工作台

[English](./README.md) | [简体中文](./README.zh-CN.md)

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://www.swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-black.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Local First](https://img.shields.io/badge/Data-local--first-0ea5e9.svg)](#隐私)
[![DeepSeek](https://img.shields.io/badge/AI-DeepSeek_optional-6366f1.svg)](#deepseek-教师评语)

[核心功能](#核心功能) · [DeepSeek](#deepseek-教师评语) · [快速开始](#快速开始) · [隐私](#隐私) · [参与贡献](#参与贡献)

</div>

MathFeedback 是一款面向高中数学家教和教师的 iPhone App，用来快速创建课后反馈、跟踪学生进步、导出学生报告，并在需要时通过 DeepSeek 生成中文教师评语。

它的设计原则很简单：课堂数据应该由教师自己掌控。学生、班级、反馈、评分和报告默认都使用 SwiftData 保存在本机。AI 评语是可选能力，只有用户主动填写自己的 DeepSeek API Key 后才会启用。

## 核心功能

### 学生与班级管理

- 按年级和班级组织学生。
- 集中管理学生资料和备注。
- 首页支持按班级筛选，方便日常上课后快速回看。

### 结构化课后反馈

- 记录课题、学习内容、作业、优点、改进点和教师评语。
- 支持综合评分和技能维度评分。
- 使用作业完成度和课堂参与度记录学习状态。

### 学习进步洞察

- 查看本周反馈、本周均分、学生总数和累计反馈。
- 自动突出需要关注的学生。
- 查看最近动态、技能对比、趋势总结和持续薄弱点。

### 报告与数据迁移

- 导出学生报告，方便分享和归档。
- 将全部本地数据备份为 JSON。
- 换手机时可从备份恢复并合并数据。

### iOS 原生体验

- 使用 SwiftUI 和 SwiftData 构建。
- 采用接近 iOS 26 的液态玻璃视觉风格，并为较早 iOS 版本提供兼容回退。
- 界面围绕教师的高频工作流设计，尽量减少无关干扰。

## DeepSeek 教师评语

MathFeedback 可以根据当前反馈表单生成中文教师评语。

生成内容会综合：

- 学生、年级和班级。
- 课题与学习内容。
- 综合评分。
- 概念理解、计算能力、解题思路、规范书写等技能维度。
- 作业完成度和课堂参与度。
- 用户选择或填写的优点与改进点。

AI 生成是可选功能。App 只会在用户点击生成按钮后，把当前反馈表单中的相关内容发送给 DeepSeek。API Key 保存在 iPhone 钥匙串中，不会写死在代码仓库里。

## 快速开始

### 环境要求

- Xcode 17 或更新版本
- iOS 17.0 或更新版本
- 如果需要从 `project.yml` 重新生成工程，需要安装 XcodeGen

### 克隆仓库

```sh
git clone https://github.com/Jackchuyun/MathFeedback.git
cd MathFeedback
```

### 生成 Xcode 工程

```sh
xcodegen generate
```

### 命令行构建

```sh
xcodebuild -project MathFeedback.xcodeproj \
  -scheme MathFeedback \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

真机运行时，请在 Xcode 的签名设置里填写你自己的 Apple Developer Team。

## 项目结构

```text
MathFeedbackApp.swift        App 入口
Models/                      学生、班级、反馈、技能评分等 SwiftData 模型
Views/                       SwiftUI 页面和可复用界面组件
Utilities/                   备份、导出、DeepSeek、样式和平台辅助工具
Assets.xcassets/             App 图标与资源目录
AppStore/                    App Store 隐私、支持与审核说明
project.yml                  XcodeGen 工程定义
```

## 隐私

MathFeedback 是本地优先应用。学生和反馈数据默认通过 SwiftData 存储在用户自己的 iPhone 上。

可选的 AI 生成功能只会在用户进入设置填写 DeepSeek API Key，并主动点击 AI 生成按钮后运行。使用该功能时，App 会把当前反馈表单中的内容发送给 DeepSeek，用于生成教师评语。DeepSeek API Key 存储在本机钥匙串中。

MathFeedback 不包含第三方分析、广告或追踪代码。

## 参与贡献

欢迎提交 issue 和 pull request。比较适合贡献的方向包括：

- Bug 修复和 iOS 兼容性改进。
- 更好的导出模板和报告排版。
- 无障碍与本地化优化。
- 文档、截图和 App Store 准备资料。

提交 pull request 时，请尽量保持改动聚焦，并附上必要的测试说明。

## 开源协议

MathFeedback 使用 MIT 协议开源，详见 [LICENSE](./LICENSE)。
