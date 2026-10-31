# usage: make APP=base|plus  -> ../build/<APP>/rom.hex
APP    ?= base
CROSS  ?= riscv64-unknown-elf-
ARCH   ?= rv32i_zicsr
RAM_LEN ?= 1024
OUT    := ../build/$(APP)
CFLAGS := -march=$(ARCH) -mabi=ilp32 -Os -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
all: $(OUT)/rom.hex
# record RAM_LEN so a changed SRAM size forces a rebuild (stack top depends on it)
$(shell mkdir -p $(OUT); echo $(RAM_LEN) | cmp -s - $(OUT)/.ramlen || echo $(RAM_LEN) > $(OUT)/.ramlen)
$(OUT)/fw.elf: crt0.S main_$(APP).c soc.h link.ld $(OUT)/.ramlen
	@mkdir -p $(OUT)
	$(CROSS)gcc $(CFLAGS) -nostartfiles -Wl,-T,link.ld -Wl,--gc-sections -Wl,--defsym=RAM_LEN=$(RAM_LEN) crt0.S main_$(APP).c -o $@
$(OUT)/fw.bin: $(OUT)/fw.elf
	$(CROSS)objcopy -O binary $< $@
	$(CROSS)size $<
$(OUT)/rom.hex: $(OUT)/fw.bin
	python3 ../tools/bin2hex.py $< $@
	$(CROSS)objdump -d $(OUT)/fw.elf > $(OUT)/fw.lst
