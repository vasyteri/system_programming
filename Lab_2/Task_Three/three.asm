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
    push rbx
    push rcx
    push rdx


    mov [place], al
    
    mov eax, 4
    mov ebx, 1
    mov ecx, place
    mov edx, 1
    int 0x80


    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80