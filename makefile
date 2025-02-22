CC = gcc15
NASM = nasm
CFLAGS = -Wall -Wextra -O2
ASFLAGS = -f bin

LOADER_SRC = loader.c
LOADER_BIN = loader
STAGE0_SRC = stage0.asm
STAGE0_BIN = stage0.bin
STAGE1_SRC = stage1.asm
STAGE1_BIN = stage1.bin

all: $(LOADER_BIN) $(STAGE0_BIN) $(STAGE1_BIN)

$(LOADER_BIN): $(LOADER_SRC) $(STAGE0_BIN)
	$(CC) $(CFLAGS) -o $(LOADER_BIN) $(LOADER_SRC)

$(STAGE0_BIN): $(STAGE0_SRC)
	$(NASM) $(ASFLAGS) -o $(STAGE0_BIN) $(STAGE0_SRC)

$(STAGE1_BIN): $(STAGE1_SRC)
	$(NASM) $(ASFLAGS) -o $(STAGE1_BIN) $(STAGE1_SRC)

clean:
	rm -rf $(LOADER_BIN) $(STAGE0_BIN) $(STAGE1_BIN)

.PHONY: all clean
