format ELF64
public _start
public exit

include '/home/egorp/cpp/System-programming/help.asm'
include '/home/egorp/cpp/System-programming/func.asm'

section '.bss' writable
    buffer rb 256

section '.text' executable
_start:
    mov rsi, buffer
    call input_keyboard

    call atoi

    mov rcx, 10
    xor rbx, rbx
    .digit_loop:
        xor rdx, rdx
        div rcx

        imul rbx, rbx, 10
        add rbx, rdx

        test rax, rax
        jnz .digit_loop

    mov rax, rbx

    call print_int
    call new_line

    call exit