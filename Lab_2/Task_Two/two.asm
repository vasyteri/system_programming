format ELF64

public _start
public exit
public print_symbol

section '.data' writable
    place db 1
    array db 45 dup ('$')
    newline db 0xA

section '.text' executable
    _start:
        xor rbx, rbx                
    .iter:
        mov al, [array + rbx]
        push rbx 
        call print_symbol
        pop rbx
        
        mov rax, rbx
        mov rcx, 5
        xor rdx, rdx
        div rcx                     
        
        cmp rdx, 4                  
        jne .continue
                
        
        mov al, 0xA
        push rbx
        call print_symbol
        pop rbx
        
    .continue:
        inc rbx
        cmp rbx, 45
        jl .iter
        
        call exit

print_symbol:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    
    mov [place], al      
    mov rax, 1           
    mov rdi, 1           
    mov rsi, place       
    mov rdx, 1           
    syscall
    
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

exit:
    mov rax, 60          
    mov rdi, 0           
    syscall