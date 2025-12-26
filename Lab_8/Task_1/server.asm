format ELF64

public _start

section '.data' writable
    server_addr:
        dw 2                 ; AF_INET
        db 0x0B, 0xB8       ; Port 3000
        dd 0                ; INADDR_ANY
        dq 0

section '.bss' writable
    server_sock     rq 1
    sock_p1         rq 1
    sock_p2         rq 1
    board           rb 9    ; Центральное поле
    buffer          rb 256
    current_turn    db 0    ; 0=P1, 1=P2
    moves_cnt       db 0

section '.text' executable
_start:
    ; === Создание сокета ===
    mov rax, 41             ; socket
    mov rdi, 2              ; AF_INET
    mov rsi, 1              ; SOCK_STREAM
    xor rdx, rdx
    syscall
    mov [server_sock], rax
    
    ; === Привязка сокета ===
    mov rax, 49             ; bind
    mov rdi, [server_sock]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    ; === Прослушивание ===
    mov rax, 50             ; listen
    mov rdi, [server_sock]
    mov rsi, 2              ; backlog
    syscall

    ; === Подключение игрока 1 ===
    mov rax, 43             ; accept
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p1], rax
    
    ; Отправляем P1 его символ (1 = X) и статус (1 = ходят сейчас)
    mov byte [buffer], 1     ; Символ X
    mov byte [buffer + 1], 1 ; Статус: активен
    mov rax, 1              ; write
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 2
    syscall

    ; === Подключение игрока 2 ===
    mov rax, 43             ; accept
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p2], rax
    
    ; Отправляем P2 его символ (2 = O) и статус (0 = ждет)
    mov byte [buffer], 2     ; Символ O
    mov byte [buffer + 1], 0 ; Статус: ждет
    mov rax, 1              
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 2
    syscall

game_loop:
    ; === Определяем, чей ход ===
    cmp byte [current_turn], 0
    je .p1_turn
    jmp .p2_turn
    
    .p1_turn:
        ; Обновляем статус P1 и P2
        mov byte [buffer + 9], 1  ; P1 активен
        call send_state_p1
        mov byte [buffer + 9], 0  ; P2 ждет
        call send_state_p2
        
        ; Ждем ход от P1
        mov rax, 0          ; read
        mov rdi, [sock_p1]
        lea rsi, [buffer]
        mov rdx, 1
        syscall
        
        ; Проверяем валидность хода
        movzx rbx, byte [buffer]
        sub rbx, '0'
        cmp rbx, 8
        ja game_loop
        cmp byte [board + rbx], 0
        jne game_loop
        
        ; Обновляем поле
        mov byte [board + rbx], 1  ; X
        inc byte [moves_cnt]
        mov byte [current_turn], 1 ; Передаем ход P2
        jmp .update_state
    
    .p2_turn:
        ; Обновляем статус P1 и P2
        mov byte [buffer + 9], 0  ; P1 ждет
        call send_state_p1
        mov byte [buffer + 9], 1  ; P2 активен
        call send_state_p2
        
        ; Ждем ход от P2
        mov rax, 0          ; read
        mov rdi, [sock_p2]
        lea rsi, [buffer]
        mov rdx, 1
        syscall
        
        ; Проверяем валидность хода
        movzx rbx, byte [buffer]
        sub rbx, '0'
        cmp rbx, 8
        ja game_loop
        cmp byte [board + rbx], 0
        jne game_loop
        
        ; Обновляем поле
        mov byte [board + rbx], 2  ; O
        inc byte [moves_cnt]
        mov byte [current_turn], 0 ; Передаем ход P1
    
    .update_state:
        ; Проверяем, не закончилась ли игра
        call check_winner
        test rax, rax
        jnz .game_over
        
        cmp byte [moves_cnt], 9
        je .game_over
        
        jmp game_loop
    
    .game_over:
        ; Отправляем финальное состояние
        mov byte [buffer + 9], 2  ; Статус: игра окончена
        call send_state_p1
        call send_state_p2
        
        ; Закрываем соединения
        mov rax, 3          
        mov rdi, [sock_p1]
        syscall
        
        mov rax, 3
        mov rdi, [sock_p2]
        syscall
        
        mov rax, 3
        mov rdi, [server_sock]
        syscall
        
        mov rax, 60         
        xor rdi, rdi
        syscall

; === Отправка состояния P1 ===
send_state_p1:
    ; Копируем поле в буфер
    mov rcx, 9
    lea rsi, [board]
    lea rdi, [buffer]
    rep movsb
    
    mov rax, 1              
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 10             
    syscall
    ret

; === Отправка состояния P2 ===
send_state_p2:
    ; Копируем поле в буфер
    mov rcx, 9
    lea rsi, [board]
    lea rdi, [buffer]
    rep movsb
    
    mov rax, 1              
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 10             
    syscall
    ret

; === Проверка победителя (упрощенная) ===
check_winner:
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
        movzx rax, dl
    
    .done:
        mov rsp, rbp
        pop rbp
        ret