format ELF64 executable
entry start

segment readable writable
    child1_msg db "Child 1: Message ", 0
    child2_msg db "Child 2: Message ", 0
    exit_msg db "The End", 0xA
    pid1 dq 0
    pid2 dq 0
    counter1 dq 1
    counter2 dq 1
    place db ?
    newline_char db 0xA

segment readable executable

; =========== ФУНКЦИЯ ЗАДЕРЖКИ ===========
simple_delay:
    push rcx
    mov rcx, 3000000
.delay_loop:
    pause
    dec rcx
    jnz .delay_loop
    pop rcx
    ret

; =========== ПРИНУДИТЕЛЬНЫЙ СБРОС БУФЕРА ===========
flush_buffer:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Используем fsync на stdout
    mov rax, 74           ; syscall fsync
    mov rdi, 1            ; файловый дескриптор stdout
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; =========== ОСНОВНАЯ ПРОГРАММА ===========
start:
    ; Получаем количество аргументов
    pop rax
    cmp rax, 2
    jl .exit
    
    ; Получаем аргумент (количество повторений)
    mov rsi, [rsp+8]
    call str_number
    mov r8, rax           ; сохраняем N в r8
    
    ; Создаем первый дочерний процесс
    mov rax, 57            ; fork
    syscall
    cmp rax, 0
    je .child1
    
    ; Родительский процесс сохраняет PID первого дочернего
    mov [pid1], rax
    
    ; Создаем второй дочерний процесс
    mov rax, 57            ; fork
    syscall
    cmp rax, 0
    je .child2
    
    ; Родительский процесс сохраняет PID второго дочернего
    mov [pid2], rax
    
    ; Даем дочерним процессам время на инициализацию
    call simple_delay
    
    ; Останавливаем оба процесса
    mov rax, 62            ; kill - SIGSTOP
    
    mov rsi, 19
    mov rdi, [pid1]
    syscall
    
    mov rdi, [pid2]
    syscall
    
    ; Теперь управляем процессами по очереди
    mov r9, r8             ; копируем N в r9 для цикла
    jmp .parent

; =========== ПЕРВЫЙ ДОЧЕРНИЙ ПРОЦЕСС ===========
.child1:
    ; N уже в r8
    
    ; Ждем, пока родитель нас разбудит
.child1_loop:
    ; Выводим сообщение
    mov rsi, child1_msg
    call print_str
    
    ; Выводим номер сообщения
    mov rax, [counter1]
    call print_number
    
    ; Новая строка
    call new_line
    
    ; СБРАСЫВАЕМ БУФЕР!
    call flush_buffer
    
    ; Увеличиваем счетчик
    inc qword [counter1]
    
    ; Длинная пауза для синхронизации
    call simple_delay
    call simple_delay
    
    ; Уменьшаем счетчик итераций
    dec r8
    cmp r8, 0
    jg .child1_loop
    
    ; Завершаем процесс
    mov rax, 60            ; exit
    mov rdi, 0
    syscall

; =========== ВТОРОЙ ДОЧЕРНИЙ ПРОЦЕСС ===========
.child2:
    ; N уже в r8
    
    ; Ждем, пока родитель нас разбудит
.child2_loop:
    ; Выводим сообщение
    mov rsi, child2_msg
    call print_str
    
    ; Выводим номер сообщения
    mov rax, [counter2]
    call print_number
    
    ; Новая строка
    call new_line
    
    ; СБРАСЫВАЕМ БУФЕР!
    call flush_buffer
    
    ; Увеличиваем счетчик
    inc qword [counter2]
    
    ; Длинная пауза для синхронизации
    call simple_delay
    call simple_delay
    
    ; Уменьшаем счетчик итераций
    dec r8
    cmp r8, 0
    jg .child2_loop
    
    ; Завершаем процесс
    mov rax, 60            ; exit
    mov rdi, 0
    syscall

; =========== РОДИТЕЛЬСКИЙ ПРОЦЕСС ===========
.parent:
.parent_loop:
    ; 1. Будим первый процесс
    mov rax, 62            ; kill - SIGCONT
    mov rsi, 18
    mov rdi, [pid1]
    syscall
    
    ; Даем время на вывод И сброс буфера
    call simple_delay
    call simple_delay
    
    ; 2. Останавливаем первый процесс
    mov rax, 62            ; kill - SIGSTOP
    mov rsi, 19
    mov rdi, [pid1]
    syscall
    
    ; Короткая пауза между переключениями
    call simple_delay
    
    ; 3. Будим второй процесс
    mov rax, 62            ; kill - SIGCONT
    mov rsi, 18
    mov rdi, [pid2]
    syscall
    
    ; Даем время на вывод И сброс буфера
    call simple_delay
    call simple_delay
    
    ; 4. Останавливаем второй процесс
    mov rax, 62            ; kill - SIGSTOP
    mov rsi, 19
    mov rdi, [pid2]
    syscall
    
    ; Пауза перед следующим циклом
    call simple_delay
    
    ; Уменьшаем счетчик итераций
    dec r9
    cmp r9, 0
    jg .parent_loop
    
    ; ПОСЛЕДНИЙ ЦИКЛ: завершаем оба процесса
    
    ; 1. Будим первый процесс для завершения
    mov rax, 62            ; kill - SIGCONT
    mov rsi, 18
    mov rdi, [pid1]
    syscall
    
    ; 2. Будим второй процесс для завершения
    mov rdi, [pid2]
    syscall
    
    ; Даем много времени на завершение
    call simple_delay
    call simple_delay
    call simple_delay
    call simple_delay
    
    ; Выводим финальное сообщение
    call new_line
    mov rsi, exit_msg
    call print_str
    
    ; Завершаем родительский процесс
    mov rax, 60            ; exit
    mov rdi, 0
    syscall

.exit:
    mov rax, 60            ; exit
    mov rdi, 0
    syscall

; ================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==================

print_str:
    push rax
    push rdi
    push rdx
    push rcx
    push rsi
    push r11
    
    ; Вычисляем длину строки
    mov rdi, rsi
    xor rcx, rcx
    dec rcx
    xor al, al
    repne scasb
    not rcx
    dec rcx
    
    ; Выводим строку
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    mov rdx, rcx          ; длина
    syscall
    
    pop r11
    pop rsi
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

new_line:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    push r11
    
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    mov rsi, newline_char
    mov rdx, 1
    syscall
    
    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

str_number:
    push rcx
    push rbx
    push rdx
    
    xor rax, rax
    xor rcx, rcx
    
    cmp byte [rsi], '-'
    jne .convert
    inc rsi
    mov rcx, 1
    
.convert:
    xor rbx, rbx
    mov bl, byte [rsi]
    test bl, bl
    jz .done
    
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    
    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    jmp .convert
    
.done:
    test rcx, rcx
    jz .positive
    neg rax
    
.positive:
    pop rdx
    pop rbx
    pop rcx
    ret

print_char:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    push r11
    
    mov [place], al
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    lea rsi, [place]
    mov rdx, 1
    syscall
    
    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_number:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    test rax, rax
    jns .positive
    
    neg rax
    push rax
    mov al, '-'
    call print_char
    pop rax
    
.positive:
    mov rcx, 0
    mov rbx, 10
    lea rdi, [rbp-16]
    
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi+rcx], dl
    inc rcx
    test rax, rax
    jnz .convert_loop
    
.print_loop:
    dec rcx
    mov al, [rdi+rcx]
    call print_char
    test rcx, rcx
    jnz .print_loop
    
    mov rsp, rbp
    pop rbp
    ret