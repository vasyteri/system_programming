format ELF
public _start
msg_1 db "Levochkin", 0xA, 0
msg_2 db "Vasiliy", 0xA, 0
msg_3 db "vasiliyvich", 0xA, 0


_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_1
    mov edx, 11
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_2
    mov edx, 9
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_3
    mov edx, 13
    int 0x80

    mov eax, 1
    mov ebx, 0 
    int 0x80
     