format ELF64

public _start
public exit
public print
public print_newline

section '.data' writable
    place db ?
    newline db 0xA

section '.text' executable

_start:
    mov rax, [rsp]
    cmp rax, 4
    jl finish

    mov rsi, [rsp+8*2]
    call str_number
    mov r8, rax

    mov rsi, [rsp+8*3]
    call str_number
    mov rbx, rax

    mov rsi, [rsp+8*4]
    call str_number
    mov rcx, rax

    mov rax, r8

    test rbx, rbx
    jz finish
    test rcx, rcx
    jz finish
    
    xor rdx, rdx
    div rbx
    
    push rax
    
    mov rax, r8
    
    pop rbx
    add rax, rbx
    
    xor rdx, rdx
    div rcx

    call print
    call print_newline

finish:
    call exit

str_number:
    push rcx
    push rbx

    xor rax, rax
    xor rcx, rcx
    mov rbx, 10

.loop:
    mov cl, byte [rsi]
    test cl, cl
    jz .finished
    
    cmp cl, '0'
    jl .finished
    cmp cl, '9'
    jg .finished
    
    sub cl, '0'
    imul rax, rbx
    add rax, rcx
    
    inc rsi
    jmp .loop

.finished:
    pop rbx
    pop rcx
    ret

print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    xor rbx, rbx
    mov rcx, 10

    test rax, rax
    jnz .loop
    
    
    push 0
    inc rbx
    jmp .print_loop

.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    test rax, rax
    jnz .loop

.print_loop:
    pop rax
    add al, '0'
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

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall