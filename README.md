# mp_logger

## 简介
0. mp_logger 是一个 [Rails Engine](https://guides.rubyonrails.org/engines.html)
1. 作者：胡腾。
3. 使用场景：目前(2023-4-26) 只有 [mp 项目](https://github.com/MiraclePlus/mp) 用到了 mp_logger。
4. 备注：胡腾不爱写注释，目前你读的这个文档是郑诚写的。

## 下面简单介绍一下 Rails Engine 是什么。
1. Rails Engine 最终也是一个 gem，可用于其他 Rails 项目里，使用方法是在 Gemfile 里写上名字即可（假设发布到了 rubygems.org）
   1. 如果 Engine 还属于本地开发阶段，还没有发布到 rubygems.org，那么使用方法依然也是在 Gemfile 里写上名字，但是要指定本地路径，比如 `gem 'mp_logger', path: '/Users/huteng/Code/mp_logger'`
2. 把 Rails Engine 当成一个 Rails App 就行，因为 Engine 也有 Controller, Model, View, Routes, Migration 等等。
3. 新建 Rails Engine 的方法是运行 `rails plugin new [名字] --mountable`，这会生成一个目录结构。
5. 以上只是简要概述，具体细节可参阅 [Rails Engine](https://guides.rubyonrails.org/engines.html) 文档，阅读时间大概需要1个小时左右。

## 其他信息
1. 第一个 commit 是 2022年10月16号。

## 使用场景
1. 目前只用于 mp 项目，没有用于齐思项目（截止至 2023年4月27号）

## 功能概述
1. 日志。
   1. Rails 输出的默认日志格式太啰嗦了，线上环境的日志在 CloudWatch 里特别难看。
   2. 并且有些关键信息缺失了，
   3. 解决办法是改成 JSON 格式，并且不要输出执行的 SQL 语句，比如：
```json
{
    "name": "rails",
    "hostname": "044988a20821",
    "pid": 8,
    "level": 30,
    "time": "2023-04-27T05:20:11.229+00:00",
    "msg": "Statistics",
    "controller": "PhoneTokensController",
    "action": "sign_in",
    "format": "html",
    "method": "POST",
    "status": 200,
    "ip": "52.167.144.77, 64.252.70.147",
    "path": "/phone_tokens/sign_in",
    "params": {
        "phone": "+8613252070421",
        "_rucaptcha": "xhhkc",
        "phone_token": {
            "phone": "+8613252070421"
        }
    },
    "view": 0,
    "db": 2,
    "allocations": 945,
    "duration": 8,
    "track_id": "kpUjQXXTxrpZOzfbBna"
}
```
1. 线上调试。

## 疑问
1. 是怎么本地开发的？
   1. 方法1：直接在 mp 里 Gemfile path: 指向 (胡腾说主要用这种)
   2. 方法2：使用 spec/dummy/ （基本不用这种）


## 需要过一遍的文件。
* 所有这些 controller 和 model 是干什么。


mp_logger 
https://github.com/lucagrulla/cw


## 使用方法
Gemfile 里添加一行：

```ruby
gem 'mp_logger'
```

执行
```bash
$ bundle install
```



## 2023年4月27号下午2点，郑诚和胡腾开会。
会议目的：聊 mp_logger 是什么。

### 结论
一句话总结：mp_logger 的用途是做"日志"和"调试"。

### 具体
目前主要是日志功能在用，调试功能暂时不用。

### 介绍"日志"功能
1. Rails 原本的日志输出，我们开的层级太低了，输出了过多内容，好像是开到 debug 级别。
2. "日志"功能的改动是把 Rails 的日志输出格式改成 JSON 格式。

### 介绍"调试"功能
1. 这个目前没有在使用。所以胡腾也没和大家做具体介绍。
2. 截图如下：（待补充）
3. 目前访问 /logging 页面，正常情况是点击"添加"按钮会有效果，但现在完全没反应，这个 bug 我们暂时不去管他了，因为现在没有在用。

### 2. 在 mp 项目里，是如何整合 mp_logger 的。
1. Gemfile 里写上 gem 'mp_logger'

