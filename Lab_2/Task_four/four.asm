format ELF64
public _start
public exit

section '.bss' writable
    N dq 2980480801
    res dq 0
    newline db 10
    place db 1

section '.text' executable
_start:
    mov rax, [N]
    mov rbx, 10
    mov rcx, 0

    .iter1:
        xor rdx, rdx
        div rbx
        add rcx, rdx
        test rax, rax
        jnz .iter1

    mov [res], rcx
    call print

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    call exit

print:
    mov rax, [res]
    xor rbx, rbx

    mov rcx, 10
    .loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .loop

    .print_loop:
        pop rax
        add rax, '0'
        mov [place], al


        push rbx
        mov rax, 1
        mov rdi, 1
        mov rsi, place
        mov rdx, 1
        syscall
        pop rbx

        dec rbx
        jnz .print_loop

        ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall