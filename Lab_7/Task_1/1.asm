format ELF64
public _start
public exit

section '.data' writeable
    input_buf       rb 256
    arg_array       rq 12

    prog_run5       db './lab_5', 0
    arg1_run5       db 'input.txt', 0
    arg2_run5       db 'output.txt', 0

    prog_run6       db './lab_6', 0

    cmd_run5        db 'Run5', 0
    cmd_run6        db 'Run6', 0
    cmd_exit        db 'exit', 0

    child_id        dq 0
    status          dq 0

    environ         dq 0

    cursor          db '$ ', 0
    err_cmd         db 'Command not found', 10, 0

section '.text' executable

_start:
    mov r12, rsp
    add r12, 8

    .env_scan:
        cmp qword [r12], 0
        je .env_found
        add r12, 8
        jmp .env_scan

    .env_found:
        add r12, 8
        mov [environ], r12

    .shell_loop:
        mov rax, 1
        mov rdi, 1
        mov rsi, cursor
        mov rdx, 2
        syscall

        mov rax, 0
        mov rdi, 0
        mov rsi, input_buf
        mov rdx, 255
        syscall

        cmp rax, 0
        jle exit

        mov rcx, rax
        dec rcx
        cmp byte [input_buf + rcx], 10
        jne .process_input
        mov byte [input_buf + rcx], 0

    .process_input:
        mov rsi, input_buf
        mov rdi, arg_array
        xor rcx, rcx

    .get_tokens:
        cmp byte [rsi], ' '
        je .next_char
        cmp byte [rsi], 9
        je .next_char
        cmp byte [rsi], 0
        je .all_tokens

        mov [rdi + rcx*8], rsi
        inc rcx

    .find_end:
        inc rsi
        cmp byte [rsi], ' '
        je .word_end
        cmp byte [rsi], 9
        je .word_end
        cmp byte [rsi], 0
        je .all_tokens
        jmp .find_end

    .word_end:
        mov byte [rsi], 0
        inc rsi
        jmp .get_tokens

    .next_char:
        inc rsi
        jmp .get_tokens

    .all_tokens:
        mov qword [rdi + rcx*8], 0

        cmp rcx, 0
        je .shell_loop

        mov rsi, [arg_array]

        mov rdi, cmd_exit
        call compare_strings
        test rax, rax
        jz exit

        mov rsi, [arg_array]
        mov rdi, cmd_run5
        call compare_strings
        test rax, rax
        jz .exec_run5

        mov rsi, [arg_array]
        mov rdi, cmd_run6
        call compare_strings
        test rax, rax
        jz .exec_run6

        mov rax, 1
        mov rdi, 1
        mov rsi, err_cmd
        mov rdx, 18
        syscall
        jmp .shell_loop

    .exec_run5:
        mov qword [arg_array], prog_run5
        mov qword [arg_array + 8], arg1_run5
        mov qword [arg_array + 16], arg2_run5
        mov qword [arg_array + 24], 0

        mov r13, prog_run5
        jmp .create_process

    .exec_run6:
        mov qword [arg_array], prog_run6

        mov r13, prog_run6
        jmp .create_process

    .create_process:
        mov rax, 57
        syscall

        cmp rax, 0
        je .run_program

        mov [child_id], rax
        jmp .wait_process

    .run_program:
        mov rax, 59
        mov rdi, r13
        mov rsi, arg_array
        mov rdx, [environ]
        syscall

        call error_exit

    .wait_process:
        mov rax, 61
        mov rdi, [child_id]
        mov rsi, status
        xor rdx, rdx
        xor r10, r10
        syscall

        jmp .shell_loop

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

compare_strings:
    push rsi
    push rdi
    push rbx

    .compare_loop:
        mov al, [rsi]
        mov bl, [rdi]
        cmp al, bl
        jne .different
        test al, al
        jz .identical
        inc rsi
        inc rdi
        jmp .compare_loop

    .different:
        mov rax, 1
        jmp .finish

    .identical:
        xor rax, rax

    .finish:
        pop rbx
        pop rdi
        pop rsi
        ret