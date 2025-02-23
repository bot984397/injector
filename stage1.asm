BITS 64

section .text
_start:
   call get_base
get_base:
   pop rbx

   lea r15, [rbx + thread_fn - get_base]

   mov rax, 9
   mov rdi, 0
   mov rsi, 4096
   mov rdx, 3
   mov r10, 0x22
   mov r8, -1
   mov r9, 0
   syscall

   mov r12, rax
   add r12, 4096
   sub r12, r8
   mov [r12], rbx

   mov rax, 56
   mov rdi, 0x00000100
   or rdi, 0x00000200
   or rdi, 0x00000800
   mov rsi, r12
   mov rdx, 0
   mov r10, 0
   mov r8, r15
   syscall

   test rax, rax
   jz thread_fn

parent:
   push r14
   ret

thread_fn:
   pop r13
child:
   mov rdi, 1
   lea rsi, [r13 + msg - get_base]
   mov rdx, msg_len
   mov rax, 1
   syscall

   lea rdi, [r13 + timespec - get_base]
   xor rsi, rsi
   mov rax, 35
   syscall

   jmp child

msg: db "Injected child process running..", 0xA
msg_len: equ $- msg

timespec:
   dq 1
   dq 0
