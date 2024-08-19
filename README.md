# fully x64 ASM keylogger

### /!\ this is for educational purpose only, any others use is prohibited /!\

## TABLE OF CONTENTS
* [Usage](#usage)
    * [Compilation](#compilation)
    * [Run](#run)
    * [Server](#server)
    * [Kill the keylogger](#kill-the-keylogger)
* [Docs](#docs)

## Usage

### Compilation
```bash
make
```

### Run
```bash
sudo build/keylogger
```

### Server
You can start a nc server with this command
```bash
nc -klnvp 1337
```
and the keylogger will automaticelly connect to it and send instantely the keys typed, I didn't implemented some args customisation for port/ip so for now it's only connect to localhost:1337

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
