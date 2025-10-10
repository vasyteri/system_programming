format ELF64
public _start

include '../../func.asm'
include '../../help.asm'

section '.data' writable
    truemsg db 'Number is in non-decreasing order', 10, 0
    falsemsg db 'Number is not in non-decreasing order', 10, 0

section '.bss' writable
    buffer rb 256
    prev dq 0

section '.text' executable
_start:
    mov rsi, buffer
    call input_keyboard

    call atoi

    mov rcx, 10
    xor rdx, rdx
    div rcx
    mov [prev], rdx

    .digit_loop:
        xor rdx, rdx
        div rcx

        cmp rdx, [prev]
        jg false

        mov [prev], rdx

        test rax, rax
        jnz .digit_loop
    mov rsi, truemsg
    jmp final

    false:
        mov rsi, falsemsg


    final:
        call print_str
        call exit