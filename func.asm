
section '.text' executable

atoi:
    push    rcx
    push    rbx
    push    rdx     

    xor     rax, rax
    xor     rcx, rcx
.loop:
    xor     rbx, rbx
    mov     bl, byte [rsi+rcx]

    cmp     bl, '0'
    jl      .finished
    cmp     bl, '9'
    jg      .finished

    ; 4. rax = rax * 10
    mov     rbx, 10
    mul     rbx         

    ; 5. rax = rax + (bl - '0')
    xor     rbx, rbx
    mov     bl, byte [rsi+rcx] 
    sub     bl, '0'
    add     rax, rbx

    inc     rcx
    jmp     .loop

.finished:
    pop     rdx     
    pop     rbx
    pop     rcx
    ret

input_keyboard:
    push rax
    push rdi
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rdx, 255
    syscall

    xor rcx, rcx
.loop:
    mov al, [rsi + rcx]
    cmp al, 0x0A    ; LF
    je .found
    cmp al, 0x0D    ; CR
    je .found
    cmp al, 0       ; null
    je .found
    inc rcx
    jmp .loop

.found:
    mov byte [rsi + rcx], 0

    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret


exit:
    mov rax, 60
    mov rdi, 0   
    syscall