# Starry 修改日志

## 20240626

- 写改造方案

## 20240625

- 设计怎么修改的模块，调度对象所在的控制块，调度对象之间的区别和联系

## 20240624

- 阅读 axprocess，关于进程与线程的定义，沿用了 rCore-tutorial 中的定义，进程、线程使用单独的数据结构表示，进程用单独的 Process 结构表示，线程沿用了 axtask 中的 AxTaskRef 定义。
- 使用 `kbuild patch add axprocess` 将 `axprocess` 拉取到本地
- 使用 `kbuild patch add axtask` 将 `axtask` 拉取到本地
- 目前需要解决的问题是如何将控制需要的 `TaskMeta` 结构与这两个结构相结合，来构建任务标识
