.intel_syntax noprefix
.global _start


_start:
#set AF_INET
mov rdi,2

#set SOCK_STREAM
mov rsi, 1

#set default
mov rdx,0

#syscall # for socket
mov rax,41
syscall

#move sockfd into r12 from rax
push rax
mov r12,rax


#Allocate 16 bytes on the stack for struct sockaddr_in 
sub rsp,16

#set sin_family to AF_INET
mov word ptr [rsp],2

#set port, but make sure it will be correctly interpreted as big endian (0x5000 becomes 0x0050 once converted to little endian, which is 80)
mov word ptr [rsp+2],0x5000

#set IP address, which is 4 bytes long (dword), also need to ensure it will be correctly interpreted in big endian after storage in little endian
mov dword ptr [rsp+4], 0

#set the last 8 bytes used for padding to 0
mov qword ptr [rsp+8],0

#set sockfd for syscall
mov rdi,r12

#set sockaddr_in addr* for syscall
mov rsi,rsp

#set socklen_t addrlen to 16, as our struct is 16 bytes in size
mov rdx,16

#syscall # for bind
mov rax,49
syscall


#set sockfd for listen
mov rdi,r12

#set backlog for listen (max # of queued connections)
mov rsi,0

#syscall # for listen
mov rax,50
syscall

begin: 
mov rdi,r12
push r12

#set sock_addr and socklen to null
mov rsi,0
mov rdx,0

mov rax,43
syscall

#save the new fd returned by accept syscall
mov r12,rax

#syscall # for fork() to add concurrency
mov rax,57
syscall

#if the return value of fork() isn't 0 (basically if this isn't child process), jump to parent
cmp rax,0
jne Parent

pop rdi
mov rax,3
syscall

#set fd for read
mov rdi,r12

#allocate stack space
sub rsp,512

#provide destination buffer
mov rsi,rsp

#set # of bytes to read to 256
mov rdx,512

#syscall # for read
mov rax,0
syscall

#parse header to determine whether we are dealing with a POST or GET
cmp byte ptr [rsp], 'G'
jne POST
je GET



#if here we are dealing with a POST request
POST:
#save the number of bytes read which was returned by read syscall
mov rbx,rsp
push rax

#index variable r13
mov r13,0

checkBegin:
#number of consecutive correct ending letters (should be 4 matching \r\n\r\n)

#is the first character encountered a \r?
cmp byte ptr [rbx+r13],0x0d
je secondCheck
inc r13
jmp checkBegin

secondCheck:
#increment both the current char index and number of consec
inc r13

#is the next character a \n?
cmp byte ptr [rbx+r13],0x0a
je thirdCheck
jmp checkBegin

thirdCheck:
inc r13

cmp byte ptr [rbx+r13],0x0d
je lastCheck
jmp checkBegin

lastCheck:
inc r13
cmp byte ptr [rbx+r13],0x0a
je out
jmp checkBegin


out:


#if we've reached this point, the \r\n\r\n tail was matched completely, increment r13 to get size of the entire header (as r13 was 0-indexed)
inc r13

#take the saved # of bytes read off the stack
pop r14

#calculate body length via total_size-header_size
sub r14,r13


mov rbx,rsp

#save start address for body
lea rax,[rsp+r13]
push rax

#save calculated size on stack
push r14

#index variable for filepath
mov r13,0

#address of where the specified filepath begins +5 to skip POST + " "
lea r14, [rbx+5]

#allocate space on stack for parsed path
sub rsp,48

#looking for trailing space, if seen end loop
loopPostBegin:
cmp byte ptr [r14+r13],' '
je donePost

#move into al (byte sized partial of rax) the current character
mov al, [r14+r13]

#move the character into the stack to save
mov byte ptr [rsp+r13],al

#increment index and jump to loop start
inc r13
jmp loopPostBegin


donePost:
#add null terminator to parsed filepath
mov byte ptr [rsp+r13],0

#first parameter of open syscall, char* filename, set to pointer to filepath on stack
mov rdi,rsp

#set the write only | create flag  in the second parameter for open
mov rsi,0x41
mov rdx,0777

#syscall # for open
mov rax,2
syscall

#prepare for popping our saved values (total size and pointer for write) off stack
add rsp,48

#move number of bytes to write into third parameter for write syscall
pop rdx

#move char* of data to write into second parameter for write syscall
pop rsi


#set first parameter of write syscall (fd)
mov rdi,rax

#syscall # for write
mov rax,1
syscall

#rdi already set for close, just need to move syscall# and close
mov rax,3
syscall

#flag to skip the get write in closer
mov r14,1

#need some kind of jump to ending to skip GET
jmp closer

GET: 
#index variable r13
mov r13,0

#save the start address of our saved HTTP header, +4 to skip GET and space
lea r14, [rsp+4]

#allocate space on stack for the parsed path
sub rsp,48
#looking for trailing space, if seen end loop
loopBegin:
cmp byte ptr [r14+r13],' '
je done

#move into the byte-sized partial register of rax (al) the current character
mov al, [r14+r13]

#move the current char into our allocated memory on the stack for saving
mov byte ptr [rsp+r13],al

#increment index and loop again
inc r13
jmp loopBegin

done:
#add a null terminator for the filepath
mov byte ptr [rsp+r13],0
#save location of saved path (in r14)
mov r14,rsp

#set filepath parameter for open syscall
mov rdi,r14

#set 0_RDONLY flag for open syscall
mov rsi,0

#syscall # for open
mov rax,2

syscall

#save the new fd from open syscall
mov r15,rax

#allocate space on stack for read
sub rsp,256

#set fd parameter for read syscall
mov rdi,r15

#set char* buf where read data will go (parameter for read syscall)
mov rsi,rsp

#set read file size parameter for read syscall
mov rdx,256

#syscall # for read
mov rax,0

syscall

#save the return value of read, which was number of bytes read
push rax

#save the memory location of the read data
mov r14,rsp

#rdi already set to fd, so no need to reset it for syscall close
mov rax,3
syscall

closer:

#allocate 24 bytes on stack for string
sub rsp,24

#first 8 bytes(HTTP/1.0) but with swapped endianness 
mov rax,0x302e312f50545448

#move the first 8 bytes into stack memory
mov [rsp],rax

#move the next 8 bytes ( 200 OK\r) into rax w/ swapped endianness
mov rax,0x0d4b4f2030303220
mov [rsp+8],rax

#move the last 8 bytes (\n\r\n + 5 0s) into rax w/ swapped endianness
mov rax,0x30303030300a0d0a
mov [rsp+16],rax

#set fd for write
mov rdi,r12

#set char* buf for write
mov rsi,rsp

#set byte count for write
mov rdx,19

mov rax,1

syscall


add rsp,24

#prevent double write if came from POST path
cmp r14,1
je skipGetClose


#the two syscalls below happen exclusively for GET, so measures need to be taken to prevent a POST execution from running down here

#rdi, or fd parameter, was just set from the previous write syscall
pop rdx
mov rsi,rsp
mov rax,1
syscall

add rsp,304
skipGetClose:
#set fd for close syscall
mov rdi,r12

#syscall # for close
mov rax,3
syscall



#return global stack usage back to stack
add rsp,528

 
#syscall # for exit
mov rax,60

#exit code 0
mov rdi,0
syscall


Parent:
mov rdi,r12
mov rax,3
syscall
pop r12
jmp begin