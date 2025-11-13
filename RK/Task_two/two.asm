format ELF64

public _start
public exit
public print
public print_newline
public str_number
public print_error

section '.data' writable
    place db ?
    newline db 0xA
    error_msg db "Error: n must be positive integer (n > 0)", 0xA
    error_msg_len = $ - error_msg

section '.text' executable

_start:
    mov rax, [rsp]          
    cmp rax, 2              
    jne error              

    mov rsi, [rsp+8*2]      
    call str_number
    mov rbx, rax            
    
    test rbx, rbx
    jle error              
    
    xor r12, r12          
    xor r13, r13           
    mov r14, 10           
    
    mov r15, 1             

.sum_loop:
    imul r13, r14
    add r13, 1
    
    add r12, r13
    
    inc r15
    cmp r15, rbx
    jle .sum_loop
    
    mov rax, r12
    call print
    call print_newline
    jmp finish

error:
    call print_error

finish:
    call exit


print_error:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1             
    mov rdi, 1              
    mov rsi, error_msg        
    mov rdx, error_msg_len              
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

str_number:
    push rcx
    push rbx

    xor rax, rax       
    xor rcx, rcx        
    mov rbx, 10         

.loop:
    mov cl, byte [rsi]  
    test cl, cl         
    jz .finished
    
    cmp cl, '0'
    jl .invalid
    cmp cl, '9'
    jg .invalid
    
    sub cl, '0'         
    imul rax, rbx       
    add rax, rcx        
    
    inc rsi             
    jmp .loop

.invalid:
    mov rax, -1         

.finished:
    pop rbx
    pop rcx
    ret

print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1             
    mov rdi, 1              
    mov rsi, newline        
    mov rdx, 1              
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    xor rbx, rbx        
    mov rcx, 10

    test rax, rax       
    jnz .loop
    
    push 0
    inc rbx
    jmp .print_loop

.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    test rax, rax
    jnz .loop

.print_loop:
    pop rax
    add al, '0'
    mov [place], al

    push rbx
    mov rax, 1
    mov rdi, 1
    mov rsi, place
    mov rdx, 1
    syscall
    pop rbx

    dec rbx
    jnz .print_loop

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

exit:
    mov rax, 60        
    xor rdi, rdi        
    syscall