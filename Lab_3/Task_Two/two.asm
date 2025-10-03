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

mov rdi, [rsp+16]  ; argv[1]
mov rsi, [rsp+24]  ; argv[2]
mov rdx, [rsp+32]  ; argv[3]

    mov rdi, [rsp+16]  ; argv[1]
    call str_number
    push rax

    mov rsi,[rsp+24]
    call str_number
    push rax

    mov rdx, [rsp+32]
    call str_number
    mov rcx, rax

    pop rbx
    pop rax
    mov rdi, rax

    xor rdx, rdx
    div rbx

    add rax, rdi

    xor rdx, rdx
    div rcx

    call print
    call print_newline
    call exit



str_number:
    push rcx
    push rbx

    xor rax,rax
    xor rcx,rcx

.loop:
    xor     rbx, rbx
    mov     bl, byte [rsi+rcx]
    cmp     bl, 48
    jl      .finished
    cmp     bl, 57
    jg      .finished

    sub     bl, 48
    add     rax, rbx
    mov     rbx, 10
    mul     rbx
    inc     rcx
    jmp     .loop

.finished:
    cmp     rcx, 0
    je      .restore
    mov     rbx, 10
    div     rbx

.restore:
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
    push rax            ; сохраняем исходное значение RAX
    push rbx            ; сохраняем RBX
    push rcx            ; сохраняем RCX
    push rdx            ; сохраняем RDX
    push rsi            ; сохраняем RSI
    push rdi            ; сохраняем RDI

    xor rbx, rbx        ; счётчик цифр

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

        push rbx        ; сохраняем счётчик
        mov rax, 1      ; sys_write
        mov rdi, 1      ; stdout
        mov rsi, place  ; буфер
        mov rdx, 1      ; длина
        syscall
        pop rbx         ; восстанавливаем счётчик

        dec rbx
        jnz .print_loop

    pop rdi             ; восстанавливаем RDI
    pop rsi             ; восстанавливаем RSI
    pop rdx             ; восстанавливаем RDX
    pop rcx             ; восстанавливаем RCX
    pop rbx             ; восстанавливаем RBX
    pop rax             ; восстанавливаем исходное значение RAX
    ret


exit:
    mov rax, 60        
    xor rdi, rdi        
    syscall     