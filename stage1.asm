BITS 64

%macro save_gp 0
   push rax
   push rcx
   push rdx
   push rbx
   push rbp
   push rsi
   push rdi
   push r8
   push r9
   push r10
   push r11
   push r12
   push r13
   push r14
   push r15
   pushfq
%endmacro

%macro restore_gp 0
   popfq
   pop r15
   pop r14
   pop r13
   pop r12
   pop r11
   pop r10
   pop r9
   pop r8
   pop rdi
   pop rsi
   pop rbp
   pop rbx
   pop rdx
   pop rcx
   pop rax
%endmacro

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

parent_loop:
   push r14
   ret

thread_fn:
   pop r13
child_loop:
   mov rdi, 1
   lea rsi, [r13 + msg - get_base]
   mov rdx, msg_len
   mov rax, 1
   syscall

   lea rdi, [r13 + timespec - get_base]
   xor rsi, rsi
   mov rax, 35
   syscall

   jmp child_loop

msg: db "Injected child process running..", 0xA
msg_len: equ $- msg

timespec:
   dq 1
   dq 0
