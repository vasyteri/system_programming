format ELF64

public _start

section '.data' writable
    msg_enter_ip    db "Enter Server IP: ", 0
    wait_msg        db "Connecting to server...", 10, 0
    err_msg         db "Connection failed!", 10, 0
    
    ; Сообщения игры
    msg_turn        db "Your turn (0-8): ", 0
    msg_wait        db "Waiting for opponent...", 10, 0
    msg_win         db "You WIN!", 10, 0
    msg_lose        db "You LOSE!", 10, 0
    msg_draw        db "Draw!", 10, 0
    msg_invalid     db "Invalid move!", 10, 0
    
    ; Графика поля
    hor_line        db "-----------", 10, 0
    
    server_addr:
        dw 2              ; AF_INET
        db 0x0B, 0xB8     ; Port 3000
        dd 0              ; IP будет заполнен
        dq 0

section '.bss' writable
    sock_fd         rq 1
    buffer          rb 256
    ip_input        rb 32  
    board           rb 9    ; Локальная копия поля
    my_symbol       db 0    ; Мой символ (1=X, 2=O)
    game_active     db 1    ; Флаг активности игры

section '.text' executable

; === Функция вывода строки ===
std_print_string:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    
    mov rsi, rdi        ; Указатель на строку
    xor rcx, rcx        ; Счетчик длины
    
    .count_loop:
        cmp byte [rsi + rcx], 0
        je .print
        inc rcx
        jmp .count_loop
    
    .print:
        mov rax, 1          ; write
        mov rdi, 1          ; stdout
        mov rdx, rcx        ; длина
        syscall
    
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; === Функция вывода числа ===
std_print_number:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Создаем буфер на стеке
    sub rsp, 32
    mov rsi, rsp
    add rsi, 31
    mov byte [rsi], 0
    dec rsi
    
    mov rax, rdi        ; Число
    mov rbx, 10
    xor rcx, rcx
    
    .convert_loop:
        xor rdx, rdx
        div rbx         ; rax / 10
        add dl, '0'
        mov [rsi], dl
        dec rsi
        inc rcx
        
        test rax, rax
        jnz .convert_loop
    
    .print:
        inc rsi
        mov rdi, rsi
        call std_print_string
    
    add rsp, 32
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; === Отрисовка поля ===
draw_board:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    ; Верхняя граница
    mov rdi, hor_line
    call std_print_string
    
    mov rcx, 0          ; Строка (0-2)
    
.row_loop:
    cmp rcx, 3
    jge .done
    
    ; Начинаем строку
    mov rbx, buffer
    mov byte [rbx], '|'
    inc rbx
    mov byte [rbx], ' '
    inc rbx
    
    mov rdx, 0          ; Колонка (0-2)
    
.col_loop:
    cmp rdx, 3
    jge .print_row
    
    ; Индекс = строка*3 + колонка
    mov rax, rcx
    imul rax, 3
    add rax, rdx
    
    ; Получаем символ из board
    movzx rsi, byte [board + rax]
    
    cmp rsi, 0
    je .empty_cell
    cmp rsi, 1
    je .x_cell
    ; O клетка
    mov byte [rbx], 'O'
    jmp .after_symbol
    
.empty_cell:
    mov byte [rbx], ' '
    jmp .after_symbol
    
.x_cell:
    mov byte [rbx], 'X'

.after_symbol:
    inc rbx
    mov byte [rbx], ' '
    inc rbx
    mov byte [rbx], '|'
    inc rbx
    mov byte [rbx], ' '
    inc rbx
    
    inc rdx
    jmp .col_loop

.print_row:
    ; Завершаем строку
    mov byte [rbx], 10      ; новая строка
    inc rbx
    mov byte [rbx], 0
    
    ; Выводим строку
    mov rdi, buffer
    call std_print_string
    
    ; Нижняя граница
    mov rdi, hor_line
    call std_print_string
    
    inc rcx
    jmp .row_loop

.done:
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; === Проверка победителя ===
check_win:
    push rbp
    mov rbp, rsp
    
    ; Проверка строк
    mov rcx, 0
.check_rows:
    cmp rcx, 3
    jge .check_cols
    
    mov rax, rcx
    imul rax, 3
    movzx rdx, byte [board + rax]
    cmp rdx, 0
    je .next_row
    
    cmp dl, byte [board + rax + 1]
    jne .next_row
    cmp dl, byte [board + rax + 2]
    je .found_winner
    
.next_row:
    inc rcx
    jmp .check_rows

.check_cols:
    mov rcx, 0
.col_loop:
    cmp rcx, 3
    jge .check_diags
    
    movzx rdx, byte [board + rcx]
    cmp rdx, 0
    je .next_col
    
    cmp dl, byte [board + rcx + 3]
    jne .next_col
    cmp dl, byte [board + rcx + 6]
    je .found_winner
    
.next_col:
    inc rcx
    jmp .col_loop

.check_diags:
    ; Главная диагональ
    movzx rdx, byte [board]
    cmp rdx, 0
    je .check_sec_diag
    
    cmp dl, byte [board + 4]
    jne .check_sec_diag
    cmp dl, byte [board + 8]
    je .found_winner

.check_sec_diag:
    movzx rdx, byte [board + 2]
    cmp rdx, 0
    je .no_winner
    
    cmp dl, byte [board + 4]
    jne .no_winner
    cmp dl, byte [board + 6]
    je .found_winner

.no_winner:
    xor rax, rax
    jmp .done

.found_winner:
    movzx rax, dl    ; Возвращаем символ победителя

.done:
    mov rsp, rbp
    pop rbp
    ret

; === Проверка ничьей ===
check_draw:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, 0
.check_loop:
    cmp rbx, 9
    jge .draw_found
    
    cmp byte [board + rbx], 0
    je .not_draw
    
    inc rbx
    jmp .check_loop

.draw_found:
    mov rax, 1
    jmp .done

.not_draw:
    xor rax, rax

.done:
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; === Парсинг IP ===
parse_ip:
    push rbx
    push rcx
    push rdx
    
    xor eax, eax    
    xor ecx, ecx    
    xor rdx, rdx    

.next_char:
    mov bl, [rsi]
    inc rsi
    
    cmp bl, '.' 
    je .save_byte
    cmp bl, 10      
    je .finish
    cmp bl, 0       
    je .finish
    
    sub bl, '0'
    movzx rbx, bl
    
    imul ecx, 10
    add ecx, ebx
    jmp .next_char

.save_byte:
    mov [rdi], cl
    inc rdi
    xor ecx, ecx
    jmp .next_char

.finish:
    mov [rdi], cl
    pop rdx
    pop rcx
    pop rbx
    ret

_start:
    ; === Ввод IP ===
    mov rdi, msg_enter_ip
    call std_print_string

    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, ip_input
    mov rdx, 31
    syscall
    
    ; Парсинг IP
    mov rsi, ip_input
    mov rdi, server_addr + 4
    call parse_ip

    mov rdi, wait_msg
    call std_print_string

    ; === Подключение к серверу ===
    mov rax, 41         ; socket
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    mov rdx, 0
    syscall
    mov [sock_fd], rax

    mov rax, 42         ; connect
    mov rdi, [sock_fd]
    mov rsi, server_addr
    mov rdx, 16
    syscall
    
    test rax, rax
    js conn_error

    ; === Получаем наш символ от сервера ===
    mov rax, 0          ; read
    mov rdi, [sock_fd]
    mov rsi, buffer
    mov rdx, 2
    syscall
    
    cmp rax, 2
    jl conn_error
    
    ; Первый байт - наш символ, второй - чей ход
    mov al, [buffer]
    mov [my_symbol], al
    mov al, [buffer + 1]
    mov [game_active], al

game_loop:
    ; === Получаем обновление состояния ===
    mov rax, 0
    mov rdi, [sock_fd]
    mov rsi, buffer
    mov rdx, 10         ; 9 байт поле + 1 байт статус
    syscall
    
    test rax, rax
    jz server_disconnected
    
    ; Копируем поле из буфера в board
    mov rcx, 0
.copy_loop:
    cmp rcx, 9
    jge .copy_done
    mov al, [buffer + rcx]
    mov [board + rcx], al
    inc rcx
    jmp .copy_loop
.copy_done:
    
    ; Получаем статус игры
    mov al, [buffer + 9]
    mov [game_active], al
    
    ; === Отрисовываем поле ===
    call draw_board
    
    ; === Проверяем состояние игры ===
    call check_win
    test rax, rax
    jnz .game_over
    
    call check_draw
    test rax, rax
    jnz .draw
    
    ; === Проверяем, наш ли ход ===
    cmp byte [game_active], 0
    je .wait_opponent
    
    ; === Наш ход ===
    mov rdi, msg_turn
    call std_print_string
    
.get_input:
    mov rax, 0          ; read
    mov rdi, 0          ; stdin
    mov rsi, buffer
    mov rdx, 2
    syscall
    
    cmp byte [buffer], '0'
    jl .invalid_move
    cmp byte [buffer], '8'
    jg .invalid_move
    
    ; Проверяем, свободна ли клетка
    movzx rbx, byte [buffer]
    sub rbx, '0'
    cmp byte [board + rbx], 0
    jne .invalid_move
    
    ; Отправляем ход серверу
    mov rax, 1          ; write
    mov rdi, [sock_fd]
    mov rsi, buffer     ; Позиция
    mov rdx, 1
    syscall
    
    jmp game_loop

.invalid_move:
    mov rdi, msg_invalid
    call std_print_string
    jmp .get_input

.wait_opponent:
    mov rdi, msg_wait
    call std_print_string
    jmp game_loop

.game_over:
    ; Определяем, кто победил
    cmp al, [my_symbol]
    jne .lost
    
    mov rdi, msg_win
    call std_print_string
    jmp exit_game
    
.lost:
    mov rdi, msg_lose
    call std_print_string
    jmp exit_game

.draw:
    mov rdi, msg_draw
    call std_print_string

exit_game:
    mov rax, 3          
    mov rdi, [sock_fd]
    syscall
    
    mov rax, 60         ; exit
    xor rdi, rdi
    syscall

server_disconnected:
    mov rax, 3
    mov rdi, [sock_fd]
    syscall
    
    mov rax, 60
    mov rdi, 0
    syscall

conn_error:
    mov rdi, err_msg
    call std_print_string
    
    mov rax, 60
    mov rdi, 1
    syscall