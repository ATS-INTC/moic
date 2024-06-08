# 在 QEMU 中实现 MOIC 中断控制器的开发日志

## 20240608

- 增加注册 IPC 发送方、接收方的处理逻辑
- 测试注册 IPC 发送方、接收方的处理逻辑
- 

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
