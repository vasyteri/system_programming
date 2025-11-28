format ELF64

include '/workspaces/system_programming/func.asm'

section '.data'
    prompt db '> ', 0
    cd_cmd db 'cd', 0

section '.bss'
    buffer rb 256
    child_pid dq 0
    status dq 0

section '.text'
public _start

; Функция для вывода строки
print_string:
    mov rdx, 0
.count_loop:
    cmp byte [rdi + rdx], 0
    je .count_done
    inc rdx
    jmp .count_loop
.count_done:

    mov rax, 1          ; sys_write
    mov rsi, rdi        ; строка
    mov rdi, 1          ; stdout
    syscall
    ret

; Функция для сравнения строк
strcmp:
    mov al, byte [rdi]
    cmp al, byte [rsi]
    jne .not_equal
    test al, al
    jz .equal
    inc rdi
    inc rsi
    jmp strcmp
.equal:
    xor rax, rax
    ret
.not_equal:
    mov rax, 1
    ret

; Функция для пропуска пробелов в строке
skip_spaces:
.loop:
    mov al, byte [rdi]
    cmp al, ' '
    jne .done
    inc rdi
    jmp .loop
.done:
    ret

; Функция для получения переменных окружения
get_envp:
    mov rax, [rsp]          ; argc
    lea rax, [rsp + 8 + rax * 8 + 8]  ; envp = argv[argc + 1]
    ret

_start:
    ; Выравниваем стек по 16 байтам
    and rsp, -16

main_loop:
    ; Вывод приглашения
    mov rdi, prompt
    call print_string

    ; Ввод команды
    mov rsi, buffer
    call input_keyboard

    ; Проверка на пустую строку (только Enter)
    cmp byte [buffer], 0
    je main_loop        ; если пустая строка - продолжаем

    ; Проверяем, является ли команда "cd"
    mov rdi, buffer
    call skip_spaces    ; пропускаем начальные пробелы

    mov rsi, cd_cmd
    call strcmp
    test rax, rax
    jz handle_cd        ; если это команда cd

    ; Обычная команда - создаем дочерний процесс
    mov rax, 57         ; sys_fork
    syscall

    cmp rax, 0
    jz child_process    ; если 0 -> дочерний процесс
    jg parent_process   ; если >0 -> родительский процесс

    ; Ошибка fork - продолжаем цикл
    jmp main_loop

parent_process:
    ; Сохраняем PID дочернего процесса
    mov [child_pid], rax

    ; Ожидание завершения дочернего процесса
    mov rax, 61         ; sys_wait4
    mov rdi, [child_pid]
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    syscall

    jmp main_loop

child_process:
    ; Получаем текущие переменные окружения
    call get_envp
    mov rdx, rax        ; envp

    ; Подготовка аргументов для execve
    mov rdi, buffer     ; filename

    ; Создаем argv массив с правильным выравниванием
    xor rax, rax
    push rax            ; NULL terminator
    push rdi            ; pointer to filename
    mov rsi, rsp        ; argv

    ; Вызов execve
    mov rax, 59         ; sys_execve
    syscall

    ; Если execve завершился ошибкой
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; код ошибки
    syscall

; Обработчик команды cd
handle_cd:
    ; Пропускаем "cd" и пробелы после него
    mov rdi, buffer
    call skip_spaces    ; пропускаем начальные пробелы

    ; Пропускаем "cd"
    add rdi, 2
    call skip_spaces    ; пропускаем пробелы после cd

    ; Проверяем, есть ли аргумент (путь)
    cmp byte [rdi], 0
    jne .has_path

    ; Если нет аргумента - переходим в домашнюю директорию
    mov rdi, home_dir
    jmp .do_chdir

.has_path:
    mov rdi, buffer
    add rdi, 2          ; пропускаем "cd"
    call skip_spaces    ; пропускаем пробелы

.do_chdir:
    ; Вызываем chdir
    mov rax, 80         ; sys_chdir
    syscall

    ; Проверяем результат
    test rax, rax
    jns main_loop       ; если успешно - продолжаем цикл

    ; Ошибка chdir
    jmp main_loop

exit_program:
    ; Корректный выход из программы
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код 0
    syscall

section '.data'
home_dir db '/home', 0