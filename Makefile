CC=nasm
LNK=ld

CFLAGS= -f elf64 -i ./src

SRCS := $(wildcard src/main.asm)
OBJECTS=$(SRCS:main.asm=main.o)

all: $(OBJECTS) link clean 

link: $(OBJECTS)
	$(LNK) $(OBJECTS) -o build/keylogger

%.o: %.asm
	$(CC) $(CFLAGS) $< -o $@ 

clean:
	rm -rf src/*.o
