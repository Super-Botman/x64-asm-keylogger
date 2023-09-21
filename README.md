# fully x64 ASM keylogger

### /!\ this is for educational purpose only, any others use is prohibited /!\

## TABLE OF CONTENTS

1. [Usage](#usage)
   1. [Compilation](#compilation)
   2. [Run](#run)
   3. [Kill the keylogger](#kill-the-keylogger)
2. [Docs](#docs)

## Usage

### Compilation
```bash
make
```

### Run
```bash
sudo build/keylogger
```

### Kill the keylogger
you first have to find the PID of the process, for that the keylloger create a dir with pid like this:
![pid screenshot](screenshots/keylogger_pid.png)

then umount it and kill it
```bash
sudo umount /proc/<pid>
sudo killall -9 build/keylogger
```

## Docs
[man for all the syscalls](https://man7.org/linux/man-pages/)

[asm doc](https://www.tutorialspoint.com/assembly_programming)

[calltable](https://x64.syscall.sh/)

[linux source code (easier than github official repo)](https://elixir.bootlin.com/linux/latest/source)
