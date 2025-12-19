format ELF64
public _start

include '/workspaces/system_programming/help.asm'

section '.bss' writable
    input_fd     rq 1
    output_fd    rq 1
    bytes_read   rq 1
    line_count   rq 1
    BUFFER_SIZE equ 65536
    buffer       rb BUFFER_SIZE
    line_ptrs    rq 10000

section '.data' writable
    newline      db 0x0A


section '.text' executable
_start:
    mov rax, [rsp]
    cmp rax, 3
    jge .open_input
    jmp .exit

.open_input:
    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .exit
    mov [input_fd], rax

    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    cmp rax, 0
    jle .close_input
    mov [bytes_read], rax

.close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

    cmp qword [bytes_read], 0
    je .exit

    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 101o
    mov rdx, 644o
    syscall
    cmp rax, 0
    jl .exit
    mov [output_fd], rax

.parse_lines:
    mov rsi, buffer
    mov rdi, line_ptrs
    mov rbx, [bytes_read]
    mov qword [line_count], 1

    mov [rdi], rsi
    add rdi, 8

.parse_loop:
    test rbx, rbx
    jz .parse_done

    cmp byte [rsi], 0x0A
    jne .next_byte

    mov byte [rsi], 0


    inc rsi
    dec rbx
    jz .parse_done

    mov [rdi], rsi
    inc qword [line_count]
    add rdi, 8
    jmp .parse_loop

.next_byte:
    inc rsi
    dec rbx
    jmp .parse_loop

.parse_done:
    mov rcx, [line_count]
    test rcx, rcx
    jz .close_output

    dec rcx

.write_loop:
    push rcx
    mov rax, rcx
    shl rax, 3
    mov rsi, [line_ptrs + rax]

    mov rdi, rsi
    call .strlen
    mov rdx, rax

    test rdx, rdx
    jz .write_newline

    mov rax, 1
    mov rdi, [output_fd]
    syscall

.write_newline:
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rcx
    dec rcx
    jns .write_loop

.close_output:
    mov rax, 3
    mov rdi, [output_fd]
    syscall

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

.strlen:
    xor rax, rax
.strlen_loop:
    cmp byte [rdi + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    ret