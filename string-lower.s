.intel_syntax noprefix

.global _start

_start:
# spot/index tracker
mov r12,0

# counter i
mov r13,0

# store src_addr,which should be in rdi, in r14
mov r14,rdi

# if src_addr !=0
cmp r14,0
je done

Loop:
# if null terminator, byte ptr tells pointer how many bits to look at (8)
cmp byte ptr [r14+r12],0x00
je done

# 0x5a check, if the byte in memory is greater than 0x5a, jump past next block
cmp byte ptr [r14+r12],0x5a
ja AfterCall

# load the address of function foo into register r15
mov r15,0x403000

# move the byte we are currently on into 32 bit partial of rdi as an argument of foo
movzx edi, byte ptr [r14+r12]

# call foo
call r15

# replace the original byte from src with the returned byte from foo (via the 1 byte partial register al of rax)
mov byte ptr [r14+r12],al

# increment the counter variable
inc r13

# where the conditional would jump to
AfterCall:
inc r12
jmp Loop




done:
mov rax,r13
rest