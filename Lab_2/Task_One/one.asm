format ELF64

public _start
public exit
public print_symbol

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