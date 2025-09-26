format ELF64
public _start
public exit

section '.bss' writable
sym db '$'
M dq 5
K dq 11
newline db 10

section '.text' executable
_start:
    mov rcx, [K]

    .iter1:
        push rcx
        mov rdx, [M]

        .iter2:
            push rdx

            mov rcx, sym

            mov rax, 4
            mov rbx, 1
            mov rdx, 1
            int 0x80

            pop rdx
            dec rdx
            cmp rdx, 0
            jne .iter2

        mov rax, 4
        mov rbx, 1

        mov rcx, newline
        mov rdx, 1
        int 0x80

        pop rcx
        dec rcx
        cmp rcx, 0
        jne .iter1


    call exit

exit:
  mov rax, 1
  xor rbx, rbx
  int 0x80