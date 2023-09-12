CC=nasm
LNK=ld

CFLAGS= -f elf64

SRCS := $(wildcard src/*.asm)
OBJECTS=$(SRCS:%.asm=%.o)

all: $(OBJECTS) link clean 

link: $(OBJECTS)
	$(LNK) $(OBJECTS) -o build/keylogger

%.o: %.asm
	$(CC) $(CFLAGS) $< -o $@ 

clean:
	rm -rf src/*.o
