format ELF64

public _start

section '.data' writable
    success_msg db "File renaming completed", 10
    success_len = $ - success_msg
    error_msg db "Usage: ./task3_3 directory", 10
    error_len = $ - error_msg
    script_cmd db "./rename_files.sh", 0

section '.text' executable

_start:
    ; Проверяем аргументы
    pop rcx
    cmp rcx, 2
    jne show_error

    ; Получаем аргументы
    pop rdi
    pop rbx

    ; Вызываем скрипт
    mov rax, 59
    mov rdi, script_cmd
    push 0
    push rbx
    push script_cmd
    mov rsi, rsp
    mov rdx, 0
    syscall

    ; Сообщение об успехе
    mov rax, 1
    mov rdi, 1
    mov rsi, success_msg
    mov rdx, success_len
    syscall
    jmp exit

show_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_len
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall