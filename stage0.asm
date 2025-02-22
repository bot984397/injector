BITS 64

%define SYS_READ  0x00
%define SYS_OPEN  0x02
%define SYS_CLOSE 0x03
%define SYS_STAT  0x04
%define SYS_MMAP  0x09
%define SYS_EXIT  0x3C

%macro m_exit 1
   mov rdi, %1
   mov rax, SYS_EXIT
   syscall
%endmacro

section .text
_start:
   call get_base
get_base:
   pop r15

   ; stat
   sub rsp, 0x90
   mov rax, SYS_STAT
   lea rdi, [r15 + stage1 - get_base]
   mov rsi, rsp
   syscall
   test rax, rax
   jns _cont1
   m_exit 1
_cont1:
   mov rsi, [rsp + 0x30]
   add rsp, 0x90
   
   ; mmap
   xor rdi, rdi
   mov rdx, 0x7
   mov r10, 0x2 | 0x20
   mov r8, -1
   xor r9, r9
   mov rax, 0x9
   syscall
   cmp rax, -1
   jne _cont2
   m_exit 1
_cont2:
   mov r8, rax
   mov r9, rsi

   ; open
   mov rax, SYS_OPEN
   lea rdi, [r15 + stage1 - get_base]
   xor rsi, rsi
   syscall
   test rax, rax
   jns _cont3
   m_exit 1
_cont3:
   mov rdi, rax

   ; read
   mov rsi, r8
   mov rdx, r9
   mov rax, SYS_READ
   syscall
   test rax, rax
   jns _cont4
   m_exit 1
_cont4:

   ; close
   mov rax, SYS_CLOSE
   syscall
   test rax, rax
   jns _cont5
   m_exit 1
_cont5:
   int 3
exit:
   m_exit rax

stage1: db "stage1.bin", 0x0
stage1_len: equ $- stage1
