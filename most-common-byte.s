.intel_syntax noprefix
.global _start

_start:
#r12 will be counter i
mov r12,0
#start allocating space on the stack, first by making the base pointer the top of the stack
mov rbp,rsp

#subtract size bytes from rsp, the top pointer, to allocate space, 512 bytes as we have 256 mem addresses each 2 bytes long
sub rsp,0x200

#get the size argument and move it into r13
mov r13,rsi

#get the src_addr argument and move it into r15
mov r15,rdi

#size-1
sub r13,1

Loop:
#if r12 (i) is greater than r13 (size-1), jump out of loop)
cmp r12,r13
ja PostFirstLoop

#move [src_addr+i] into r14
movzx r14, byte ptr [r15+r12]

#make r14 negative
neg r14


# [stack_base - curr_byte * 2] += 1, displacement of 2 because allocated space lives below rbp and doesn't include
inc word ptr [rbp+r14*2-2]

#i++
inc r12

jmp Loop

PostFirstLoop:

#now r12 with act as b instead of i
mov r12,0

#now r13 with act as max_freq
mov r13,0

#now r15 will act as max_freq_byte
mov r15,0

SecondLoop: 
cmp r12,0xff
ja PostSecondLoop

#make r14 contain stack_base-b*2
mov r14,rbp
sub r14,r12
sub r14,r12

#if statement, check if [stack_base-b*2]>maxfreq, displacement of 2 because we are accessing below the stack, noninclusive
cmp word ptr [r14-2],r13w
jbe skipIter

#max_freq = [stack_base-b*2]
movzx r13, word ptr [r14-2]
mov r15,r12
skipIter:

#b++
inc r12

#loop back
jmp SecondLoop

PostSecondLoop:
mov rsp,rbp
mov rax,r15
ret