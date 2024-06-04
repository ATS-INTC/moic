# 在 QEMU 中实现 MOIC 中断控制器的开发日志

## 20240605

- 

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
