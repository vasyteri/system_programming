format ELF64

public _start
public exit
public print_buffer
public print_newline

section '.data' writable
    buffer db 4 dup(?)
    newline db 0xA 
    

section '.text' executable
    _start:
        mov rsi, [rsp+16]      
        mov al, byte [rsi]

        mov rdi, buffer
        mov bl, 100
        div bl                 
        
        add al, '0'
        mov [rdi], al
        inc rdi
        
        mov al, ah
        xor ah, ah
        mov bl, 10
        div bl                 
        
        add al, '0'
        mov [rdi], al
        inc rdi
        
        add ah, '0'
        mov [rdi], ah
        call print_buffer
        call print_newline
        call exit


print_buffer:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 3
    syscall
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


exit:
    mov rax, 60        
    xor rdi, rdi        
    syscall     