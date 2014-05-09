TARGET = main
.DEFAULT_GOAL = all

# Compiler configurations
CROSS_COMPILE ?= arm-none-eabi-
CC := $(CROSS_COMPILE)gcc

# Hardware setup
CPU = cortex-m4
CFLAGS = -mcpu=$(CPU) -march=armv7e-m -mtune=cortex-m4
CFLAGS += -mlittle-endian -mthumb

CFLAGS += -fno-common -ffreestanding -O0 \
         -gdwarf-2 -g3 -Wall -Werror \
         -Wl,-Tmain.ld -nostartfiles \
         -DUSER_NAME=\"$(USER)\"

# set the path to STM32F429I-Discovery firmware package
STDP ?= ../STM32F429I-Discovery_FW_V1.0.1

CMSIS_LIB=$(STDP)/Libraries/CMSIS
CMSIS_LIB_DEVICE=$(CMSIS_LIB)/Device/ST/STM32F4xx
STM32_LIB=$(STDP)/Libraries/STM32f4xx_StdPeriph_Driver

OUTDIR = build
SRCDIR = src \
         $(STM32_LIB)/src
INCDIR = include \
         $(CMSIS_LIB)/Include \
         $(CMSIS_LIB_DEVICE)/Include \
         $(STM32_LIB)/inc
INCLUDES = $(addprefix -I,$(INCDIR))
DATDIR = data
TOOLDIR = tool

SRC = $(wildcard $(addsuffix /*.c,$(SRCDIR))) \
      $(wildcard $(addsuffix /*.s,$(SRCDIR))) \
      $(CMSIS_LIB_DEVICE)/Source/Templates/gcc_ride7/startup_stm32f429_439xx.s
OBJ := $(addprefix $(OUTDIR)/,$(patsubst %.s,%.o,$(SRC:.c=.o)))
DEP = $(OBJ:.o=.o.d)
DAT =

MAKDIR = mk
MAK = $(wildcard $(MAKDIR)/*.mk)

include $(MAK)

all: $(OUTDIR)/$(TARGET).bin $(OUTDIR)/$(TARGET).lst

$(OUTDIR)/$(TARGET).bin: $(OUTDIR)/$(TARGET).elf
	@echo "    OBJCOPY "$@
	@$(CROSS_COMPILE)objcopy -Obinary $< $@

$(OUTDIR)/$(TARGET).lst: $(OUTDIR)/$(TARGET).elf
	@echo "    LIST    "$@
	@$(CROSS_COMPILE)objdump -S $< > $@

$(OUTDIR)/$(TARGET).elf: $(OBJ) $(DAT)
	@echo "    LD      "$@
	@echo "    MAP     "$(OUTDIR)/$(TARGET).map
	@$(CROSS_COMPILE)gcc $(CFLAGS) -Wl,-Map=$(OUTDIR)/$(TARGET).map -o $@ $^

$(OUTDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

$(OUTDIR)/%.o: %.s
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

clean:
	rm -rf $(OUTDIR)

-include $(DEP)
