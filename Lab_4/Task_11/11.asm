format ELF64

include '/workspaces/system_programming/func.asm'
include '/workspaces/system_programming/help.asm'

section '.bss' writeable
    buffer rb 256

section '.data' writeable
    msg_judges     db 'Введите общее количество судей (N): ', 0
    msg_vote       db 'Голос судьи (1=Да, 0=Нет): ', 0
    msg_yes        db ' голосов "Да"', 0
    msg_no         db ' голосов "Нет"', 0
    msg_result_yes db 'Решение принято: Да', 0
    msg_result_no  db 'Решение принято: Нет', 0

section '.text' executable
public _start

_start:
    ; 1. Запрос N (количества судей)
    mov rsi, msg_judges
    call print_str
    
    ; Устанавливаем RSI на buffer для input_keyboard
    mov rsi, buffer     
    call input_keyboard
    
    ; RSI все еще указывает на buffer, передаем его в atoi
    call atoi
    mov rbp, rax        ; Сохраняем N в RBP

    ; 2. Инициализация цикла голосования
    xor rcx, rcx        ; rcx = i (счетчик цикла, 0..N-1)
    xor rbx, rbx        ; rbx = votes_yes (счетчик "Да")

.vote_loop:
    ; Проверка (i < N ?)
    cmp rcx, rbp
    jge .show_results   ; Если i >= N, переходим к результатам

    ; 3. Запрос голоса
    mov rsi, msg_vote
    call print_str
    
    mov rsi, buffer     ; Снова устанавливаем RSI на buffer
    call input_keyboard
    
    ; RSI указывает на buffer
    call atoi            ; rax = 0 или 1
    
    ; 4. Подсчет голоса
    cmp rax, 1
    jne .next_vote      ; Если не 1 (т.е. 0 или мусор), не считаем
    inc rbx             ; votes_yes++

.next_vote:
    inc rcx             ; i++
    jmp .vote_loop

.show_results:
    ; 5. Расчет порогового значения большинства
    ; (N / 2) + 1
    mov rax, rbp        ; rax = N
    xor rdx, rdx
    mov rdi, 2
    div rdi             ; rax = N / 2 (целочисленно)
    inc rax             ; rax = (N / 2) + 1 (пороговое значение)
    mov rdi, rax        ; Сохраняем пороговое значение в RDI

    ; 6. Расчет голосов "Нет"
    mov rax, rbp        ; rax = N
    sub rax, rbx        ; rax = N - votes_yes
    mov rdx, rax        ; rdx = votes_no

    ; 7. Печать результатов
    mov rax, rbx        ; votes_yes
    call print_int
    mov rsi, msg_yes
    call print_str
    call new_line

    mov rax, rdx        ; votes_no
    call print_int
    mov rsi, msg_no
    call print_str
    call new_line
    
    ; 8. Сравнение и вывод решения
    ; rbx = votes_yes
    ; rdi = majority_threshold
    cmp rbx, rdi
    jge .decision_yes   ; Если votes_yes >= (N/2 + 1)

.decision_no:
    mov rsi, msg_result_no
    call print_str
    call new_line
    jmp .exit

.decision_yes:
    mov rsi, msg_result_yes
    call print_str
    call new_line

.exit:
    call exit
