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
        xor rbx, rbx                
    .iter:
        mov al, [array + rbx]
        push rbx 
        call print_symbol
        pop rbx
        
        mov rax, rbx
        mov rcx, 4
        xor rdx, rdx
        div rcx                     
        
        cmp rdx, 3                  
        jne .continue
                
        
        mov al, 0xA
        push rbx
        call print_symbol
        pop rbx
        
    .continue:
        inc rbx
        cmp rbx, 36
        jl .iter
        
        call exit

print_symbol:
    mov [place], al
    mov eax, 4
    mov ebx, 1
    mov ecx, place
    mov edx, 1
    int 0x80
    ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80