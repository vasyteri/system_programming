format ELF64
public _start
msg_1 db "Levochkin", 0xA, 0
msg_2 db "Vasiliy", 0xA, 0
msg_3 db "vasiliyvich", 0xA, 0


_start:
    mov rax, 4
    mov rbx, 1
    mov rcx, msg_1
    mov rdx, 11
    int 0x80

    mov rax, 4
    mov rbx, 1
    mov rcx, msg_2
    mov rdx, 9
    int 0x80

    mov rax, 4
    mov rbx, 1
    mov rcx, msg_3
    mov rdx, 13
    int 0x80

    mov rax, 1
    mov rbx, 0 
    int 0x80
     