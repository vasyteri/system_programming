format ELF64
public _start

section '.bss' writable
    input_fd     dq 0
    output_fd    dq 0
    bytes_read   dq 0
    counter      dq 0
    step         dq 0

section '.data' writable
    BUFFER_SIZE equ 65536
    buffer       rb BUFFER_SIZE
    out_buffer   rb BUFFER_SIZE

section '.text' executable
_start:
    mov rax, [rsp]
    cmp rax, 4
    jge .parse_args
    jmp .exit_error

.parse_args:
    mov rdi, [rsp + 32]
    call .atoi
    mov [step], rax
    
    cmp qword [step], 0
    jle .exit_error

.open_input:
    mov rax, 2
    mov rdi, [rsp + 16]
    mov rsi, 0
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl .exit_error
    mov [input_fd], rax

.open_output:
    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 101o
    mov rdx, 644o
    syscall
    
    cmp rax, 0
    jl .close_input_error
    mov [output_fd], rax

.read_loop:
    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    
    cmp rax, 0
    jle .close_files
    
    mov [bytes_read], rax

    mov rsi, buffer
    mov rdi, out_buffer
    mov rcx, [bytes_read]
    mov rbx, [counter]
    
.process_byte:
    test rcx, rcx
    jz .write_output
    
    ; Делим позицию на шаг
    mov rax, rbx
    xor rdx, rdx
    div qword [step]    
    
    mov rax, [step]
    dec rax             
    cmp rdx, rax        
    jne .skip_byte
    
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    
.skip_byte:
    inc rsi
    inc rbx
    dec rcx
    jmp .process_byte

.write_output:
    mov rax, rdi
    sub rax, out_buffer
    jz .update_counter
    
    mov rdx, rax
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, out_buffer
    syscall

.update_counter:
    mov [counter], rbx
    jmp .read_loop

.close_files:
    mov rax, 3
    mov rdi, [input_fd]
    syscall
    
    mov rax, 3
    mov rdi, [output_fd]
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

.close_input_error:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

.exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

.atoi:
    xor rax, rax
    xor rcx, rcx
    
.convert_loop:
    mov cl, [rdi]
    test cl, cl
    jz .atoi_done
    
    cmp cl, '0'
    jb .atoi_done
    cmp cl, '9'
    ja .atoi_done
    
    mov rdx, 10
    mul rdx
    
    sub cl, '0'
    add rax, rcx
    
    inc rdi
    jmp .convert_loop
    
.atoi_done:
    ret