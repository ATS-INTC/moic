# Starry 修改日志

## 20240626

- 写改造方案
- 使用 `kbuild patch add scheduler` 将 `scheduler` 拉取到本地，在其中添加 moic 调度器
- 使用 `kbuild patch add axfeat` 将 `axfeat` 拉取到本地，在 `axtask`、`axfeat`、`axstarry` 中增加 `sched_moic` feature，并修改依赖为本地仓库
- 增加 `riscv64-qemu-virt-moic` 平台
- 使用 `make A=apps/monolithic_userboot PLATFORM=riscv64-qemu-virt-moic SMP=4 FEATURES=img,sched_moic LOG=debug run` 运行系统，出现错误，因为没有调用 MoicScheduler 的 init 函数（实质是没有调用 switch_os 函数），直接调用 Add 函数，因此 qemu 出现了段错误。
- 在第一次 add 是调用了调度器的 init 函数后，可以成功添加任务，但由于 4 个处理器核使用了不同的调度器（starry 在软件上提供了负载均衡），因为未知的原因，导致没有从控制器中取出任务。

## 20240625

- 设计怎么修改的模块，调度对象所在的控制块，调度对象之间的区别和联系

## 20240624

- 阅读 axprocess，关于进程与线程的定义，沿用了 rCore-tutorial 中的定义，进程、线程使用单独的数据结构表示，进程用单独的 Process 结构表示，线程沿用了 axtask 中的 AxTaskRef 定义。
- 使用 `kbuild patch add axprocess` 将 `axprocess` 拉取到本地
- 使用 `kbuild patch add axtask` 将 `axtask` 拉取到本地
- 目前需要解决的问题是如何将控制需要的 `TaskMeta` 结构与这两个结构相结合，来构建任务标识
