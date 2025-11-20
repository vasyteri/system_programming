
format ELF64
public _start
public exit
include '/workspaces/system_programming/func.asm'
include '/workspaces/system_programming/help.asm'

section '.bss' writable
    buffer rb 256
    n dq 0
    sum dq 0

section '.text' executable
_start:
    mov rsi, buffer
    call input_keyboard

    call atoi
    mov [n], rax      
    
    mov rcx, 1        
    mov qword [sum], 0 

loop_start:
    mov rax, rcx
    imul rax, rax     
    

    test rcx, 1       
    jz even_k         
    

    add [sum], rax
    jmp next_iter
    
even_k:
    sub [sum], rax

next_iter:

    inc rcx
    cmp rcx, [n]
    jle loop_start    

    mov rax, [sum]
    call print_int
    call new_line

    call exit