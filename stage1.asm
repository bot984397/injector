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

   mov rax, 1
   mov rdi, 1
   lea rsi, [rbx + msg - get_base]
   mov rdx, msg_len
   syscall

   mov rax, 60
   mov rdi, 5
   syscall

msg: db "Test", 0xA
msg_len: equ $- msg
