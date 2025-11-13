
section '.text' executable

print_str:
    push rax
    push rdi
    push rdx
    push rcx
    mov rax, rsi
    call len_str
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret


print_int:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp

    mov rbp, rsp
    xor rbx, rbx

    test rax, rax
    jns .positive_number

    push    rax         
    
    
    push    rax         
    mov     rsi, rsp    
    mov     byte [rsi], '-' ; 
    
    mov     rax, 1     
    mov     rdi, 1      
    mov     rdx, 1      
    syscall             

    pop     rax        
    pop     rax         
    neg     rax         


.positive_number:
    mov rcx, 10

.digit_loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    test rax, rax
    jnz .digit_loop

.print_loop:
    pop rax
    add al, '0'

    push rax
    mov rsi, rsp

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    pop rax

    dec rbx
    jnz .print_loop

.cleanup:
    mov rsp, rbp
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


new_line:
   push rax
   push rdi
   push rsi
   push rdx
   push rcx
   mov rax, 0xA
   push rax
   mov rdi, 1
   mov rsi, rsp
   mov rdx, 1
   mov rax, 1
   syscall
   pop rax
   pop rcx
   pop rdx
   pop rsi
   pop rdi
   pop rax
   ret


len_str:
  push rdx
  mov rdx, rax
.iter:
    cmp byte [rax], 0
    je .next
    inc rax
    jmp .iter
.next:
   sub rax, rdx
   pop rdx
   ret