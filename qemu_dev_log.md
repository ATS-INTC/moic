# 在 QEMU 中实现 MOIC 中断控制器的开发日志

## 20240622

- 测试中断逻辑是否正常
  - 当接收方进程不在线时，OS 会唤醒接收方进程，放入到 OS 的就绪队列中，但软件上没有对计数增加，因此没有申请空间，会导致从 os 切换到 process 时，出现错误，使用控制器来更新任务的数量，不需要软件来主动更新
  - 接收方进程不在线，os 在线时，os 先唤醒接收方进程，修改了接收方内的任务状态，当切换到接收方进程时，再来唤醒接收方进程内的任务

## 20240619 - 20240621

- 重构，简化逻辑

## 20240618

- 写测试用例说明文档

## 20240617

- 完善驱动接口
  - TaskId 与 TaskControlBlock 之间的转换关系，以及优先级、抢占属性之间的定义
- 写了任务切换时，控制器与内存之间的交互测试
- 释放内存时，出现 bug，因为根据优先级生成 TaskId 时，没有取余，导致指针乱飞
- 驱动增加删除任务接口，fetch 和 remove 时，内存中的队列应该同步的缩减，在 fetch 时不会自动缩减空间，需要手动调用 shrink_to 函数，因此暂时不增加额外的处理

## 20240616

- 增加 dump 接口，将控制器中的信息写到指定内存中
- 增加 exit 接口，进程退出或者被杀死
- 完善驱动

## 20240615

- 尝试将驱动中的队列与 Rust 语言提供的 Vec 结合起来，但失败了
- 通过控制器接口操作队列时，内存中的队列长度没有增加，capacity 一直为 0，因此无法正常的进行交互，在调用驱动的 add 接口时，内存中的空间应该同步增长，Vec 中的字段偏移与数据结构定义的顺序不一致，cap 和 ptr 的顺序相反，因此导致信息交互出错
- 后续的任务
  - [ ] 后续应该增加错误处理的功能，暴露出调试信息的接口，方便后续在 FPGA 上进行测试
  - [ ] 写出较为完善的测试用例

## 20240614

- 增加抢占的机制
  - 若接收方在线，且目标任务允许抢占，则拉起 usoft
  - 若接收方不在线，但 os 在线，且接收方允许抢占，则拉起 ssoft
  - 使用 qemu_irq_raise 拉起中断信号后，CPU 没有进入中断，没有调用 CPU 中断处理的回调函数，
  - qemu 的 gpio 输入输出的管脚有顺序，在 riscv_moic_create 函数中对同样的位置，先初始化了 S_SOFT，后初始化 U_SOFT 把 S_SOFT 覆盖了，因此先根据 hart_id 来分配 S_SOFT 管脚，再根据 hart_id + i 分配 U_SOFT 管脚，引出管脚时也是按照同样的顺序，即可正常触发 CPU 中断的回调函数，产生中断
- 增加 os 不在线时的唤醒机制，但目前由于特权级的问题，先不考虑增加抢占的功能，暂时不支持 hypervisor 不在线的情况
- 写端口描述 svd 文件
- 生成 pac 库

## 20240613

- switch 在内存与控制器之间切换就绪队列正常工作
- switch 接口增加切换 device_cap、send_cap、recv_cap 表逻辑
- 实现 send_intr 逻辑
  - 接收方进程在线时直接唤醒
  - 接收方进程不在线时，直接唤醒进程，并修改接收方进程内的任务状态，等待接收方进程准备执行时，再将对应的任务唤醒
  - 目前上不支持抢占
  - 还不支持 OS 不在线的情况

## 20240612

- 实现 MOIC 的相关逻辑
  - switch 接口访问内存，与内存进行信息交互，调用 include/exec/cpu-common.h 文件中定义的 cpu_physical_memory_read、cpu_physical_memory_write 接口
  - 与内存之间的信息交互正确，但可能是由于 rust 的所有权机制，导致空间会被提前释放，需要增加打印语句才能现实正常的信息，改成了 static 生命周期之后，不需要打印语句也能正常工作

## 20240611

- 测试用户态中断的触发逻辑（目前不支持用户态时钟中断）
  - 需要先对 sideleg 寄存器修改，使能 u 态代理中断，使能 uie 寄存器，紧接着对 uip 设置相应的中断则会产生
- 在 s 态直接触发了用户态中断，qemu 报错 unhandled local interrupt，需要推迟到进入到 u 态进行处理
  - 在 target/riscv/cpu_helper.c 文件中的 riscv_cpu_local_irq_pending 函数里检查是否存在中断 pending 时，直接在检查 m-mode interrupt 时返回了
  - 在 riscv_cpu_do_interrupt 函数中，因为之前的判断条件都不满足，最后进入到默认的分支，直接在 m-mode 进行了处理
  - 在 riscv_cpu_do_interrupt 函数中，增加了判断，当 CPU 特权级不在 U 态时，不会触发用户态中断
- 测试在 u 态能否触发中断
  - 在 s 态对与 s 态中断相关的寄存器进行操作时，报错执行 sret 指令出错，但注释掉 sret，访问其他的 sCSRs 不会报错，原因是上下文没有设置正确
  - 在进入到用户态之后，没有正确的进入到用户态中断的处理逻辑，修改了 riscv_cpu_do_interrupt 的逻辑后，能够正常进入到处理函数中
  - 在用户态的中断处理函数中读取了 s 态的 CSR，导致提示了非法指令错误
  - 在没有操作 sideleg 使能用户态代理中断处理后，不会进入到用户态中断处理函数中，但没有进入到内核的中断处理逻辑中，暂时不增加内核处理用户态中断的逻辑
- 实现 MOIC 的相关逻辑
  - 增加 fetch 时的负载均衡逻辑

## 20240610

- 测试读写 N 扩展相关的寄存器
  - 使用 HKP 写的 riscv 库读写寄存器时，出现了指令非对齐错误（misaligned_fetch）
  - qemu 中定义的没有异常的返回值不为 0，返回值填写错误
  - ustatus、utvec、uscratch、uepc、ucause、utval、sedeleg、sideleg、uip、uie（存在问题，set_usoft 出错，需要增加 LOCAL_INTERRUPTS）

## 20240609

- 设置 riscv-virt 的默认 CPU 类型为实现了 N 扩展的 CPU：TYPE_RISCV_CPU_RV64GCSU_N
  - 在 hw/riscv/virt.c 中的 virt_machine_class_init 初始化函数将 mc->default_cpu_type = TYPE_RISCV_CPU_RV64GCSU_N
  - 在 target/riscv/cpu-qom.h 中增加 TYPE_RISCV_CPU_RV64GCSU_N 类型
  - 在 target/riscv/cpu.c 文件中，增加 rv64gcsu_n_cpu_init 初始化函数，与 rv64_base_cpu_init 初始化相同，但 misa_ext 增加了 N 扩展
  - 在 target/riscv/cpu.c 文件中，将 TYPE_RISCV_CPU_RV64GCSU_N 与 rv64gcsu_n_cpu_init 关联起来
  - 在 target/riscv/cpu.h 文件中增加了 RVN 的扩展
- CPU 初始化时使能 N 扩展
  - 在 target/riscv/cpu_cfg.h 中的 RISCVCPUConfig 增加了 bool ext_n
  - 在 target/riscv/cpu.c 中的 rv64gcsu_n_cpu_init 函数使能 ext_n
- 增加与 N 扩展相关的寄存器以及操作
  - 在 target/riscv/cpu.h 的 CPUArchState 中增加 user CSRs, sedeleg、sideleg CSR
  - 在 target/riscv/cpu_bits.h 中增加 SEDELEG、SIDELEG、USTATUS_UIE、USTATUS_UPIE、U_MODE_INTERRUPTS 的定义
  - 在 target/riscv/csr.c 中增加与 n 扩展寄存器相关的读写操作
- 在 target/riscv/cpu.c 文件中的 riscv_cpu_dump_state 函数增加与 N 扩展相关的 CSR

## 20240608

- 增加注册 IPC 发送方、接收方的处理逻辑
- 测试注册 IPC 发送方、接收方的处理逻辑

## 20240607

- 增加优先级队列实现
- 测试优先级队列读写接口
- 增加注册外部中断的处理逻辑

## 20240606

- 将 virtio 设备的中断连接到 moic_irqchip 上
  - 在 riscv_moic.h 的 RISCVMOICState 结构体中增加 external_irq_count 字段
  - 在 riscv_moic.c 文件中初始化 external_irq_count，并且将 external_irqs 字段初始化，并连接到 riscv_moic_irq_request 处理函数
  - 在 hw/riscv/virt.c 文件中，用总线将 moic_irqchip 连接到 virtio 设备的中断上
- 测试读写和中断处理函数
  - 写了 riscv_entry 宏，方便后续写裸机测试启动
  - 测试了读写端口
  - 测试中断接口，能够正常进入处理函数

## 20240605

- 修改 riscv_moic.h 和 riscv_moic.c 文件里的实现
- 修改 include/hw/riscv/virt.h
  - RISCVVirtState 结构体中增加 DeviceState *moic[VIRT_SOCKETS_MAX]
  - 增加 VIRT_MOIC 枚举类型
- 修改 hw/riscv/virt.c 
  - virt_memmap 中增加 `[VIRT_MOIC] =         {  0x1000000,     0x1000000 }`
  - 增加 create_fdt_socket_moic 函数，在 create_fdt_sockets 函数中调用 create_fdt_socket_moic 函数
  - 增加 virt_create_moic 函数，调用 riscv_moic_create 函数
  - 在 virt_machine_init 函数中，声明 moic_irqchip，并调用相关函数初始化
  - 在 hw/riscv/kconfig 中 RISCV_VIRT 配置中选择 RISCV_MOIC
  - 编译 qemu

## 20240604

- 在 hw/intc 目录下新增了 riscv_moic.c 文件，inlcude/hw/intc 目录下增加 riscv_moic.h 文件
- 阅读 riscv aia spec
- 在 hw/intc 目录下的 Kconfig 中增加配置
  ```
  config RISCV_MOIC
    bool
    select MSI_NONBROKEN
  ```
- 在 hw/intc 目录下的 meson.build 中增加配置 `specific_ss.add(when: 'CONFIG_RISCV_MOIC', if_true: files('riscv_moic.c'))`
- 尝试编译 riscv64-softmmu
  ```sh
  cd qemu_build
  # 若报错则增加 --extra-cflags=-Wno-error 配置
  ../qemu/configure --target-list="riscv64-softmmu" 
  make -j
  ```
