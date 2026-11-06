  .extern main

  .text
  .global _start
_start:
  xor %ebp, %ebp            # effectively RBP := 0, mark the end of stack frames

  mov (%rsp), %rdi          # get argc from the stack (implicitly zero-extended to 64-bit)
  lea 8(%rsp), %rsi         # take the address of argv from the stack
  lea 16(%rsp,%rdi,8), %rdx # take the address of envp from the stack
  call main

  mov %eax, %edi    # transfer the return of main to the first argument of _exit syscall
  mov $60, %eax      # system call number 60 = exit
  syscall
  hlt               # just in case the syscall somehow returns
