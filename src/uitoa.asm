section .text
  global _uitoa

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
