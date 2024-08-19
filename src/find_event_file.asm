section .text
    global find_event_file

; make a loop to open every /dev/input/eventX
; check with ioctl where is located the keyboard event file
; inputs: 
;     none
;
; outputs:
;     source edited with the good path 
find_event_file:
  mov r8, '0'

.loop:
  sub r8, '0'
  inc r8
  add r8, '0'

  mov [source+17], r8

  mov rax, 2
  mov rdi, source+1 
  xor rsi, rsi
  syscall
  
  mov r10, rax

  mov rax, 16
  mov rdi, r10
  mov rsi, 0x82ff4521
  mov rdx, event_codes
  syscall

  mov rax, 3
  mov rdi, r10
  syscall

  test rax, rax
  js error

  cmp byte [event_codes], 0x2
  jna .loop

  mov rax, source+1 
  ret

section .data
  source db "//dev/input/event"

section .bss
  event_codes resb 64
