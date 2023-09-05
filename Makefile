CC=nasm
LNK=ld

CFLAGS= -f elf64

SRCS := $(wildcard src/*.asm)
OBJECTS=$(SRCS:%.asm=%)

all: $(OBJECTS)

%: %.o
	mkdir build
	$(LNK) $(OBJECTS).o -o build/keylogger

%.o: %.asm
	$(CC) $(CFLAGS) $< -o $@ 

clean:
	rm -rf *.o
