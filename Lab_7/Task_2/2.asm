format ELF64

; Константы
NUM_COUNT = 584
BUFFER_SIZE = NUM_COUNT * 4  ; 4 байта на число

section '.data' writable
    ; Сообщения для вывода
    msg_fork_failed db "Ошибка создания процесса", 0xA, 0

    msg_process1 db "Процесс 1 - Количество чисел, сумма цифр которых кратна 3: ", 0
    msg_process2 db "Процесс 2 - Пятое после минимального: ", 0
    msg_process3 db "Процесс 3 - 0.75 квантиль: ", 0
    msg_process4 db "Процесс 4 - Наиболее редко встречающаяся цифра: ", 0
    msg_newline db 0xA, 0

    random_state dq 123456789  ; начальное состояние для ГСЧ

    ; Структуры для nanosleep
    timespec1:
        tv_sec1  dq 0
        tv_nsec1 dq 100000000  ; 100ms

    timespec2:
        tv_sec2  dq 0
        tv_nsec2 dq 200000000  ; 200ms

    timespec3:
        tv_sec3  dq 0
        tv_nsec3 dq 300000000  ; 300ms

    timespec4:
        tv_sec4  dq 0
        tv_nsec4 dq 400000000  ; 400ms

section '.bss' writable
    ; Буфер для чисел
    numbers rb BUFFER_SIZE

    ; Временные буферы
    temp_buffer rb 64
    sorted_array rb BUFFER_SIZE
    digit_counts rb 10  ; Счетчики цифр 0-9

section '.text' executable
public _start

; Макрос для системных вызовов
macro syscall1 number {
    mov rax, number
    syscall
}

macro syscall3 number, arg1, arg2, arg3 {
    mov rax, number
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    syscall
}

; Функция вывода строки с синхронизацией
print_string_sync:
    push rsi
    push rdx
    push rdi
    push rcx

    mov rsi, rdi        ; указатель на строку
    xor rdx, rdx        ; счетчик длины

.count_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .count_length

.print:
    ; Используем системный вызов write для атомарного вывода
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, rsi        ; указатель на строку
    mov rdx, rdx        ; длина строки
    syscall

    pop rcx
    pop rdi
    pop rdx
    pop rsi
    ret

; Функция вывода числа с синхронизацией
print_number_sync:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    mov rbx, 10
    lea rsi, [temp_buffer + 63]
    mov byte [rsi], 0
    dec rsi

    test rax, rax
    jnz .convert_loop
    mov byte [rsi], '0'
    jmp .print_result

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .convert_loop

.print_result:
    inc rsi
    mov rdi, rsi
    call print_string_sync

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция вычисления суммы цифр числа
sum_digits:
    push rbx
    push rcx
    push rdx

    mov rax, rdi
    xor rcx, rcx        ; сумма цифр

.sum_loop:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add rcx, rdx
    test rax, rax
    jnz .sum_loop

    mov rax, rcx

    pop rdx
    pop rcx
    pop rbx
    ret

; Простой генератор случайных чисел (Xorshift)
random:
    push rbx
    push rcx
    push rdx

    mov rax, [random_state]
    mov rbx, rax
    shl rbx, 13
    xor rax, rbx
    mov rbx, rax
    shr rbx, 17
    xor rax, rbx
    mov rbx, rax
    shl rbx, 5
    xor rax, rbx
    mov [random_state], rax

    ; Ограничиваем диапазон
    and rax, 0x7FFFFFFF

    pop rdx
    pop rcx
    pop rbx
    ret

; Функция паузы через nanosleep
nanosleep:
    mov rax, 35         ; sys_nanosleep
    syscall
    ret

; Процесс 1: Количество чисел, сумма цифр которых кратна 3
process1:
    ; Пауза для упорядоченного вывода
    mov rdi, timespec1
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process1]
    call print_string_sync

    mov rsi, numbers
    mov rcx, NUM_COUNT
    xor rbx, rbx        ; счетчик

.process1_loop:
    mov edi, [rsi]      ; загружаем число
    call sum_digits

    ; Проверяем кратность 3
    xor rdx, rdx
    mov r8, 3
    div r8
    test rdx, rdx
    jnz .not_multiple

    inc rbx

.not_multiple:
    add rsi, 4
    dec rcx
    jnz .process1_loop

    mov rdi, rbx
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60         ; exit
    xor rdi, rdi
    syscall

; Процесс 2: Пятое после минимального
process2:
    ; Пауза побольше для второго процесса
    mov rdi, timespec2
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process2]
    call print_string_sync

    mov rsi, numbers
    mov rcx, NUM_COUNT

    ; Находим минимальное значение
    mov ebx, [rsi]      ; текущий минимум
    mov r8, rsi         ; указатель на минимум

.find_min_loop:
    mov eax, [rsi]
    cmp eax, ebx
    jge .not_min

    mov ebx, eax
    mov r8, rsi

.not_min:
    add rsi, 4
    dec rcx
    jnz .find_min_loop

    ; Ищем пятое после минимального
    mov rsi, r8
    add rsi, 20         ; 5 элементов * 4 байта

    ; Проверяем, не вышли ли за границы
    mov rax, numbers
    add rax, BUFFER_SIZE
    cmp rsi, rax
    jl .valid_ptr

    ; Если вышли за границы, берем последний элемент
    mov rsi, rax
    sub rsi, 4

.valid_ptr:
    mov edi, [rsi]
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60         ; exit
    xor rdi, rdi
    syscall

; Процесс 3: 0.75 квантиль
process3:
    ; Еще большая пауза для третьего процесса
    mov rdi, timespec3
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process3]
    call print_string_sync

    ; Копируем массив для сортировки
    mov rsi, numbers
    mov rdi, sorted_array
    mov rcx, NUM_COUNT
.copy_loop:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop

    ; Пузырьковая сортировка
    mov rcx, NUM_COUNT
    dec rcx
    jz .sort_done

.outer_loop:
    mov rbx, rcx
    mov rdi, sorted_array

.inner_loop:
    mov eax, [rdi]
    mov edx, [rdi + 4]
    cmp eax, edx
    jle .no_swap

    ; Меняем местами
    mov [rdi], edx
    mov [rdi + 4], eax

.no_swap:
    add rdi, 4
    dec rbx
    jnz .inner_loop

    loop .outer_loop

.sort_done:
    ; Вычисляем индекс для 0.75 квантиля
    mov rax, NUM_COUNT
    mov rbx, 3
    mul rbx
    mov rbx, 4
    div rbx

    ; Получаем значение (rax содержит индекс)
    mov rsi, sorted_array
    shl rax, 2
    add rsi, rax
    mov edi, [rsi]
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60         ; exit
    xor rdi, rdi
    syscall

; Процесс 4: Наиболее редко встречающаяся цифра
process4:
    ; Самая большая пауза для четвертого процесса
    mov rdi, timespec4
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process4]
    call print_string_sync

    ; Обнуляем счетчики цифр
    mov rdi, digit_counts
    mov rcx, 10
    xor al, al
.clear_loop:
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .clear_loop

    ; Подсчитываем цифры
    mov rsi, numbers
    mov rcx, NUM_COUNT

.count_digits_loop:
    mov edi, [rsi]
    test edi, edi
    jz .next_number

.digit_loop:
    xor rdx, rdx
    mov rax, rdi
    mov rbx, 10
    div rbx

    ; rdx содержит цифру
    mov rdi, rax
    lea r8, [digit_counts]
    inc byte [r8 + rdx]

    test rdi, rdi
    jnz .digit_loop

.next_number:
    add rsi, 4
    dec rcx
    jnz .count_digits_loop

    ; Находим наименее частую цифру (игнорируя нулевые вхождения)
    mov rsi, digit_counts
    mov al, 0xFF        ; текущий минимум
    mov bl, -1          ; цифра с минимумом
    mov rcx, 0

.find_min_digit:
    mov dl, [rsi + rcx]
    test dl, dl
    jz .skip_zero       ; пропускаем нулевые счетчики

    cmp dl, al
    jae .not_min_digit

    mov al, dl
    mov bl, cl

.not_min_digit:
.skip_zero:
    inc rcx
    cmp rcx, 10
    jl .find_min_digit

    ; Если не нашли ни одной цифры, выводим 0
    cmp bl, -1
    jne .found_digit
    mov bl, 0

.found_digit:
    mov dil, bl
    add dil, '0'
    mov [temp_buffer], dil
    mov byte [temp_buffer + 1], 0

    lea rdi, [temp_buffer]
    call print_string_sync

    lea rdi, [msg_newline]
    call print_string_sync

    mov rax, 60         ; exit
    xor rdi, rdi
    syscall

_start:
    ; Заполняем массив случайными числами
    mov rsi, numbers
    mov rcx, NUM_COUNT

.fill_loop:
    call random
    mov [rsi], eax
    add rsi, 4
    dec rcx
    jnz .fill_loop

    ; Создаем процессы
    mov r15, 4          ; счетчик процессов

.create_processes:
    syscall1 57         ; fork

    test rax, rax
    jz .child_process   ; если 0 - это дочерний процесс
    js .fork_error      ; если отрицательный - ошибка

    ; Родительский процесс сохраняет PID
    push rax
    dec r15
    jnz .create_processes

    ; Ожидаем завершения всех дочерних процессов
.wait_loop:
    xor rdi, rdi
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    mov rax, 61         ; wait4
    syscall

    test rax, rax
    jg .wait_loop

    ; Завершаем родительский процесс
    mov rax, 60
    xor rdi, rdi
    syscall

.child_process:
    ; Определяем, какой процесс мы создали
    mov rax, 4
    sub rax, r15

    cmp rax, 1
    je process1
    cmp rax, 2
    je process2
    cmp rax, 3
    je process3
    jmp process4

.fork_error:
    lea rdi, [msg_fork_failed]
    call print_string_sync
    mov rax, 60
    mov rdi, 1
    syscall