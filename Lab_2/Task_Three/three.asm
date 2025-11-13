format ELF64

public _start
public exit
public print_symbol

section '.data' writable
    place db 1
    array db 36 dup ('$')
    newline db 0xA

section '.text' executable
    _start:
        xor rdi, rdi
        mov rsi, 1
        .iter_1:
            xor rbx, rbx
            .iter_2:
                mov al, [array + rdi]
                call print_symbol
                inc rdi
                inc rbx
                cmp rbx, rsi
                jb .iter_2  

            mov al, 0xA
            call print_symbol

            inc rsi
            cmp rdi, 36
            jne .iter_1
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