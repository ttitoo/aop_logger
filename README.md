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

## 功能概述


## 使用方法
Gemfile 里添加一行：

```ruby
gem 'mp_logger'
```

执行
```bash
$ bundle install
```