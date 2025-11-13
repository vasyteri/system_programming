format ELF64

public _start


section '.data' writable
    place db 1
    s db "iJEcfjYGYkTaRdjdLixIKVNkM"

section '.text' executable
    _start:
        xor rcx, rcx
        add rcx, 25
        .iter:
            mov al, [s + rcx]
            push rcx
            call print_symbol
            pop rcx
            dec rcx
            cmp rcx, -1
            jne .iter

        mov al, 0xA
        call print_symbol
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